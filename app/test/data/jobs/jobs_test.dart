import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:piscatio/data/db/app_database.dart';
import 'package:piscatio/data/db/tables.dart';
import 'package:piscatio/data/jobs/job_queue.dart';
import 'package:piscatio/data/jobs/job_runner.dart';
import 'package:piscatio/data/jobs/place_map_job.dart';
import 'package:piscatio/data/jobs/place_name_job.dart';
import 'package:piscatio/data/jobs/weather_job.dart';
import 'package:piscatio/data/remote/nasa_power_client.dart';
import 'package:piscatio/data/remote/overpass_client.dart';
import 'package:piscatio/data/remote/place_name_service.dart';
import 'package:piscatio/data/repositories/place_map_repository.dart';
import 'package:piscatio/data/repositories/trip_repository.dart';
import 'package:piscatio/data/repositories/weather_repository.dart';
import 'package:piscatio/domain/models/enums.dart';
import 'package:piscatio/domain/models/geo_point.dart';
import 'package:piscatio/domain/models/place_map.dart';
import 'package:piscatio/domain/models/weather.dart';
import 'package:piscatio/domain/services/map_sketch.dart';

import '../../helpers/fakes.dart';
import '../../helpers/test_db.dart';

final _power = File('test/fixtures/power_hourly.json').readAsStringSync();
final _overpass = File('test/fixtures/overpass_reservoir.json')
    .readAsStringSync();

/// Records calls and answers with scripted outcomes.
class _ScriptedHandler implements JobHandler {
  _ScriptedHandler(this.outcomes);

  final List<Object> outcomes; // JobOutcome or an exception to throw
  final runs = <String>[];
  final gaveUp = <String>[];

  @override
  JobKind get kind => JobKind.weather;

  @override
  Future<JobOutcome> run(JobRow job) async {
    runs.add(job.subjectId);
    final next = outcomes.isEmpty ? const JobDone() : outcomes.removeAt(0);
    if (next is JobOutcome) return next;
    throw next as Exception;
  }

  @override
  Future<void> giveUp(JobRow job) async => gaveUp.add(job.subjectId);
}

void main() {
  late AppDatabase db;
  late TestDeps deps;
  late JobQueue queue;

  setUp(() async {
    db = await newSeededDatabase();
    deps = TestDeps(db);
    queue = JobQueue(db, deps.clock, deps.ids);
  });
  tearDown(() => db.close());

  group('JobQueue', () {
    test(
      'one job per kind and subject; enqueueing again reschedules',
      () async {
        await queue.enqueue(JobKind.weather, 't1');
        await queue.retryAt(
          (await queue.find(JobKind.weather, 't1'))!.id,
          deps.clock.now().add(const Duration(days: 1)),
          error: 'x',
        );
        await queue.enqueue(JobKind.weather, 't1');
        await queue.enqueue(JobKind.placeName, 't1');
        final all = await queue.all();
        expect(all, hasLength(2));
        final weather = all.firstWhere((j) => j.kind == JobKind.weather);
        expect(weather.attempts, 0);
        expect(weather.nextAttemptAt, deps.clock.now());
        expect(weather.lastError, isNull);
      },
    );

    test('due() honors nextAttemptAt', () async {
      await queue.enqueue(JobKind.weather, 'now');
      await queue.enqueue(
        JobKind.weather,
        'later',
        notBefore: deps.clock.now().add(const Duration(hours: 2)),
      );
      expect((await queue.due()).map((j) => j.subjectId), ['now']);
      deps.clock.advance(const Duration(hours: 2));
      expect(await queue.due(), hasLength(2));
    });
  });

  group('JobRunner', () {
    test('done removes the job; retry reschedules without backoff', () async {
      final handler = _ScriptedHandler([
        JobRetryAt(deps.clock.now().add(const Duration(hours: 5))),
      ]);
      final runner = JobRunner(queue, [handler], deps.clock);
      await queue.enqueue(JobKind.weather, 't');
      await runner.runDue();
      final job = (await queue.find(JobKind.weather, 't'))!;
      expect(job.attempts, 1);
      expect(job.nextAttemptAt, deps.clock.now().add(const Duration(hours: 5)));

      deps.clock.advance(const Duration(hours: 5));
      await runner.runDue();
      expect(await queue.all(), isEmpty);
    });

    test('exceptions retry with exponential backoff', () async {
      final handler = _ScriptedHandler([
        const SocketException('offline'),
        const SocketException('offline'),
      ]);
      final runner = JobRunner(queue, [handler], deps.clock);
      await queue.enqueue(JobKind.weather, 't');
      await runner.runDue();
      var job = (await queue.find(JobKind.weather, 't'))!;
      expect(
        job.nextAttemptAt,
        deps.clock.now().add(const Duration(minutes: 15)),
      );
      expect(job.lastError, contains('offline'));

      deps.clock.advance(const Duration(minutes: 15));
      await runner.runDue();
      job = (await queue.find(JobKind.weather, 't'))!;
      expect(
        job.nextAttemptAt,
        deps.clock.now().add(const Duration(minutes: 30)),
      );
      expect(JobRunner.backoff(10), const Duration(hours: 12));
    });

    test('gives up after too many attempts', () async {
      final handler = _ScriptedHandler([
        for (var i = 0; i < JobRunner.maxAttempts; i++)
          const SocketException('offline'),
      ]);
      final runner = JobRunner(queue, [handler], deps.clock);
      await queue.enqueue(JobKind.weather, 't');
      for (var i = 0; i < JobRunner.maxAttempts; i++) {
        await runner.runDue();
        deps.clock.advance(const Duration(hours: 13));
      }
      expect(await queue.all(), isEmpty);
      expect(handler.gaveUp, ['t']);
    });

    test('overlapping calls are coalesced into one pass', () async {
      final handler = _ScriptedHandler([]);
      final runner = JobRunner(queue, [handler], deps.clock);
      await queue.enqueue(JobKind.weather, 'a');
      await Future.wait([runner.runDue(), runner.runDue(), runner.runDue()]);
      expect(handler.runs, ['a']);
    });
  });

  group('WeatherJobHandler', () {
    late TripRepository trips;
    late WeatherRepository weather;
    late List<Uri> requests;
    late int status;

    WeatherJobHandler handler() => WeatherJobHandler(
      trips: trips,
      weather: weather,
      client: NasaPowerClient(
        MockClient((req) async {
          requests.add(req.url);
          return http.Response(_power, status);
        }),
      ),
      clock: deps.clock,
    );

    setUp(() {
      trips = TripRepository(db, deps.clock, deps.ids);
      weather = WeatherRepository(db, deps.clock);
      requests = [];
      status = 200;
    });

    /// A trip on 2026-09-10 06:40–10:05 UTC at the fixture's grid cell.
    Future<String> pastTrip({
      GeoPoint? at = const GeoPoint(-16.52, -56.41),
    }) async {
      final t = await trips.createPastTrip(
        startedAt: DateTime.utc(2026, 9, 10, 6, 40),
        endedAt: DateTime.utc(2026, 9, 10, 10, 5),
        timezone: 'America/Cuiaba',
        privacy: PrivacyLevel.private,
        location: at,
      );
      await weather.markPending(t.id);
      await queue.enqueue(JobKind.weather, t.id);
      return t.id;
    }

    test('waits until POWER has published the trip (2–3 days)', () async {
      deps.clock.set(DateTime.utc(2026, 9, 10, 12));
      final id = await pastTrip();
      await JobRunner(queue, [handler()], deps.clock).runDue();
      expect(requests, isEmpty);
      final job = (await queue.find(JobKind.weather, id))!;
      expect(
        job.nextAttemptAt,
        DateTime.utc(
          2026,
          9,
          10,
          10,
          5,
        ).add(WeatherJobHandler.publicationDelay),
      );
      expect((await weather.forTrip(id))!.status, WeatherStatus.pending);
    });

    test('fetches and stores the trip weather once published', () async {
      deps.clock.set(DateTime.utc(2026, 9, 13, 12));
      final id = await pastTrip();
      await JobRunner(queue, [handler()], deps.clock).runDue();
      expect(requests.single.queryParameters['start'], '20260910');
      final w = (await weather.forTrip(id))!;
      expect(w.status, WeatherStatus.ok);
      expect(w.source, 'nasa_power');
      expect(w.temperatureC, 27);
      expect(w.windSpeedKmh, closeTo(9, 1e-9));
      expect(w.precipitationMm, closeTo(0.8, 1e-9));
      expect(w.hourly, isNotEmpty);
      expect(await queue.all(), isEmpty);
    });

    test('no location: weather is unavailable, no request', () async {
      deps.clock.set(DateTime.utc(2026, 9, 13));
      final id = await pastTrip(at: null);
      await JobRunner(queue, [handler()], deps.clock).runDue();
      expect(requests, isEmpty);
      expect((await weather.forTrip(id))!.status, WeatherStatus.unavailable);
    });

    test('service errors retry later; bad requests give up', () async {
      deps.clock.set(DateTime.utc(2026, 9, 13));
      status = 503;
      final id = await pastTrip();
      await JobRunner(queue, [handler()], deps.clock).runDue();
      expect((await queue.find(JobKind.weather, id))!.attempts, 1);

      status = 400;
      deps.clock.advance(const Duration(hours: 1));
      await JobRunner(queue, [handler()], deps.clock).runDue();
      expect(await queue.all(), isEmpty);
      expect((await weather.forTrip(id))!.status, WeatherStatus.unavailable);
    });

    test('deleted trips drop their job', () async {
      deps.clock.set(DateTime.utc(2026, 9, 13));
      final id = await pastTrip();
      await trips.deleteTrip(id);
      await JobRunner(queue, [handler()], deps.clock).runDue();
      expect(requests, isEmpty);
      expect(await queue.all(), isEmpty);
    });
  });

  group('PlaceNameJobHandler', () {
    late TripRepository trips;
    late FakePlaceNameService places;

    setUp(() {
      trips = TripRepository(db, deps.clock, deps.ids);
      places = FakePlaceNameService();
    });

    JobRunner runner() => JobRunner(queue, [
      PlaceNameJobHandler(
        trips: trips,
        service: places,
        languageCode: () => 'pt',
      ),
    ], deps.clock);

    test('fills the region from the coordinates', () async {
      final t = await trips.startTrip(
        timezone: 'UTC',
        privacy: PrivacyLevel.private,
        location: const GeoPoint(-16.523456, -56.41),
      );
      await queue.enqueue(JobKind.placeName, t.id);
      await runner().runDue();
      expect((await trips.getTrip(t.id))!.locationRegion, 'Cuiabá, MT');
    });

    test('never overwrites a region typed by the user', () async {
      final t = await trips.startTrip(
        timezone: 'UTC',
        privacy: PrivacyLevel.private,
        location: const GeoPoint(-16.5, -56.4),
      );
      await trips.updateTrip(t.copyWith(locationRegion: 'Pantanal'));
      await queue.enqueue(JobKind.placeName, t.id);
      await runner().runDue();
      expect((await trips.getTrip(t.id))!.locationRegion, 'Pantanal');
      expect(places.asked, isEmpty);
    });

    test('offline: retried later', () async {
      places.error = const SocketException('offline');
      final t = await trips.startTrip(
        timezone: 'UTC',
        privacy: PrivacyLevel.private,
        location: const GeoPoint(-16.5, -56.4),
      );
      await queue.enqueue(JobKind.placeName, t.id);
      await runner().runDue();
      expect((await queue.find(JobKind.placeName, t.id))!.attempts, 1);
    });
  });

  group('place name helpers', () {
    test('coordinates are rounded to about 1 km before lookup', () {
      expect(
        roundForLookup(const GeoPoint(-16.523456, -56.419999)),
        const GeoPoint(-16.52, -56.42),
      );
    });

    test('composeRegion prefers city and state', () {
      expect(
        composeRegion(locality: 'Cuiabá', administrativeArea: 'MT'),
        'Cuiabá, MT',
      );
      expect(
        composeRegion(
          subAdministrativeArea: 'Poconé',
          administrativeArea: 'MT',
        ),
        'Poconé, MT',
      );
      expect(composeRegion(administrativeArea: 'MT'), 'MT');
      expect(composeRegion(country: 'Brasil'), 'Brasil');
      expect(composeRegion(locality: ' '), isNull);
    });
  });

  group('PlaceMapJobHandler', () {
    late TripRepository trips;
    late PlaceMapRepository maps;
    late List<http.Request> requests;
    late int status;
    final secret = List<int>.generate(32, (i) => i);

    setUp(() {
      trips = TripRepository(db, deps.clock, deps.ids);
      maps = PlaceMapRepository(db, deps.clock);
      requests = [];
      status = 200;
    });

    JobRunner runner() => JobRunner(queue, [
      PlaceMapJobHandler(
        trips: trips,
        maps: maps,
        fetch: OverpassClient(
          MockClient((request) async {
            requests.add(request);
            return http.Response(_overpass, status);
          }),
        ).fetchAround,
        secret: () async => secret,
      ),
    ], deps.clock);

    Future<String> trip(PrivacyLevel privacy, {GeoPoint? at}) async {
      final start = deps.clock.now().subtract(const Duration(hours: 5));
      final t = await trips.createPastTrip(
        startedAt: start,
        endedAt: start.add(const Duration(hours: 2)),
        timezone: 'UTC',
        privacy: privacy,
        location: at ?? const GeoPoint(-16.5205, -56.4102),
      );
      return t.id;
    }

    test(
      'fetches the map around the approximate point, once per area',
      () async {
        final id = await trip(PrivacyLevel.approximate);
        await queue.enqueue(JobKind.placeMap, id);
        await runner().runDue();
        expect(requests, hasLength(1));
        final query = requests.single.bodyFields['data']!;
        // The real spot never leaves the phone.
        expect(query, isNot(contains('-16.5205')));
        expect(query, isNot(contains('-56.4102')));
        final area = mapAreaFor(const GeoPoint(-16.5205, -56.4102), secret);
        final stored = await maps.get(area.key);
        expect(stored, isNotNull);
        expect(stored!.center, area.center);
        expect(
          stored.features.map((f) => f.kind),
          contains(MapFeatureKind.water),
        );
        expect(await queue.all(), isEmpty);

        // Another trip in the same place reuses it.
        final again = await trip(
          PrivacyLevel.exact,
          at: const GeoPoint(-16.52051, -56.41021),
        );
        await queue.enqueue(JobKind.placeMap, again);
        await runner().runDue();
        expect(requests, hasLength(1));
      },
    );

    test('private trips never ask for a map', () async {
      final id = await trip(PrivacyLevel.private);
      await queue.enqueue(JobKind.placeMap, id);
      await runner().runDue();
      expect(requests, isEmpty);
      expect(await queue.all(), isEmpty);
    });

    test('a busy server is retried later', () async {
      status = 429;
      final id = await trip(PrivacyLevel.exact);
      await queue.enqueue(JobKind.placeMap, id);
      await runner().runDue();
      final job = (await queue.all()).single;
      expect(job.attempts, 1);
      expect(job.lastError, contains('429'));
    });
  });
}
