import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:piscatio/core/clock.dart';
import 'package:piscatio/core/ids.dart';
import 'package:piscatio/data/account/account_repository.dart';
import 'package:piscatio/data/db/app_database.dart';
import 'package:piscatio/data/db/tables.dart';
import 'package:piscatio/data/jobs/job_queue.dart';
import 'package:piscatio/data/jobs/job_runner.dart';
import 'package:piscatio/data/jobs/sync_job.dart';
import 'package:piscatio/data/remote/piscatio_api.dart';
import 'package:piscatio/data/repositories/catch_repository.dart';
import 'package:piscatio/data/repositories/settings_repository.dart';
import 'package:piscatio/data/repositories/trip_repository.dart';
import 'package:piscatio/data/sync/sync_service.dart';
import 'package:piscatio/domain/models/enums.dart';
import 'package:piscatio/domain/models/geo_point.dart';
import 'package:piscatio/domain/models/venue.dart';

import '../../helpers/fake_server.dart';
import '../../helpers/fakes.dart';
import '../../helpers/test_db.dart';

/// One phone: its own database, photo folder, ids and clock.
class Phone {
  Phone(this.server, this.db, this.clock)
    : root = Directory.systemTemp.createTempSync('piscatio_phone'),
      tokens = FakeTokenStore() {
    settings = SettingsRepository(db);
    account = AccountRepository(db, settings, tokens);
    trips = TripRepository(db, clock, const UuidV7Generator());
    catches = CatchRepository(db, clock, const UuidV7Generator());
    queue = JobQueue(db, clock, const UuidV7Generator());
    PiscatioApi api(String base, String? token) =>
        PiscatioApi(server.client(), base: base, token: token);
    final sync = SyncService(
      db,
      clock,
      photoExists: (rel) => File(p.join(root.path, rel)).existsSync(),
    );
    runner = JobRunner(queue, [
      SyncJobHandler(
        account: account,
        sync: sync,
        settings: settings,
        queue: queue,
        api: api,
        clock: clock,
        onNewTrip: (id) async => newTrips.add(id),
        onSecretChanged: () => secretChanges++,
        kick: () {},
      ),
      PhotoUploadHandler(
        db: db,
        account: account,
        api: api,
        root: () async => root,
        clock: clock,
      ),
      PhotoDownloadHandler(
        db: db,
        account: account,
        api: api,
        root: () async => root,
      ),
    ], clock);
  }

  static Future<Phone> create(FakeServer server, DateTime now) async =>
      Phone(server, await newSeededDatabase(), FixedClock(now));

  final FakeServer server;
  final AppDatabase db;
  final FixedClock clock;
  final Directory root;
  final FakeTokenStore tokens;
  late final SettingsRepository settings;
  late final AccountRepository account;
  late final TripRepository trips;
  late final CatchRepository catches;
  late final JobQueue queue;
  late final JobRunner runner;
  final newTrips = <String>[];
  var secretChanges = 0;

  Future<void> signIn() => account.signedIn(
    const ApiSession(token: FakeServer.token, email: FakeServer.email),
  );

  /// Runs the sync, then any photo transfers it queued.
  Future<void> sync() async {
    await queue.enqueue(JobKind.sync, syncSubject);
    await runner.runDue();
    await runner.runDue();
  }

  Future<void> dispose() async {
    await db.close();
    root.deleteSync(recursive: true);
  }
}

void main() {
  late FakeServer server;
  late Phone a;
  late Phone b;
  final t0 = DateTime.utc(2026, 9, 12, 12);

  setUp(() async {
    server = FakeServer();
    a = await Phone.create(server, t0);
    b = await Phone.create(server, t0);
    await a.signIn();
    await b.signIn();
  });

  tearDown(() async {
    await a.dispose();
    await b.dispose();
  });

  Future<String> logTrip(Phone phone, {String? photoBytes}) async {
    final trip = await phone.trips.createPastTrip(
      startedAt: t0.subtract(const Duration(hours: 5)),
      endedAt: t0.subtract(const Duration(hours: 2)),
      timezone: 'America/Cuiaba',
      privacy: PrivacyLevel.approximate,
      location: const GeoPoint(-16.52, -56.41),
      locationName: 'Poço do Dourado',
    );
    if (photoBytes != null) {
      final rel = 'photos/${trip.id}.jpg';
      File(p.join(phone.root.path, rel))
        ..createSync(recursive: true)
        ..writeAsStringSync(photoBytes);
      await phone.catches.addCatch(
        tripId: trip.id,
        speciesId: 'salminus-brasiliensis',
        caughtAt: t0.subtract(const Duration(hours: 4)),
        photo: StoredPhoto(relativePath: rel, width: 1200, height: 1600),
      );
    }
    return trip.id;
  }

  test(
    'a trip logged on one phone reaches the other, photo included',
    () async {
      final id = await logTrip(a, photoBytes: 'jpeg-bytes');
      await a.sync();
      expect(server.tables['trips']!.keys, [id]);
      expect(
        server.files.values.single,
        Uint8List.fromList('jpeg-bytes'.codeUnits),
      );

      await b.sync();
      final trip = await b.trips.getTrip(id);
      expect(trip!.locationName, 'Poço do Dourado');
      expect(trip.location, const GeoPoint(-16.52, -56.41));
      expect(b.newTrips, [id]);
      final catches = await b.db.select(b.db.catches).get();
      expect(catches.single.speciesId, 'salminus-brasiliensis');
      final photo = (await b.db.select(b.db.catchPhotos).get()).single;
      expect(
        File(p.join(b.root.path, photo.relativePath)).readAsStringSync(),
        'jpeg-bytes',
      );
      // Everything on A is now marked as on the server.
      final trips = await a.db.select(a.db.trips).get();
      expect(trips.single.syncStatus, SyncStatus.synced);
      expect(await a.account.read().then((x) => x!.lastSync), t0);
    },
  );

  test('the latest edit wins, wherever it was made', () async {
    final id = await logTrip(a);
    await a.sync();
    await b.sync();

    final onA = (await a.trips.getTrip(id))!;
    await a.trips.updateTrip(onA.copyWith(notes: 'Água turva'));
    b.clock.advance(const Duration(minutes: 10));
    final onB = (await b.trips.getTrip(id))!;
    await b.trips.updateTrip(onB.copyWith(notes: 'Água limpa'));

    await a.sync();
    await b.sync();
    await a.sync();
    expect((await a.trips.getTrip(id))!.notes, 'Água limpa');
    expect((await b.trips.getTrip(id))!.notes, 'Água limpa');
  });

  test('an edit made here after the server copy is not overwritten', () async {
    final id = await logTrip(a);
    await a.sync();
    await b.sync();
    // B edits and syncs; A edits later without having pulled.
    final onB = (await b.trips.getTrip(id))!;
    b.clock.advance(const Duration(minutes: 1));
    await b.trips.updateTrip(onB.copyWith(notes: 'de B'));
    await b.sync();
    a.clock.advance(const Duration(minutes: 5));
    final onA = (await a.trips.getTrip(id))!;
    await a.trips.updateTrip(onA.copyWith(notes: 'de A, depois'));
    await a.sync();
    expect((await a.trips.getTrip(id))!.notes, 'de A, depois');
    await b.sync();
    expect((await b.trips.getTrip(id))!.notes, 'de A, depois');
  });

  test('deleting on one phone deletes on the other', () async {
    final id = await logTrip(a, photoBytes: 'x');
    await a.sync();
    await b.sync();
    a.clock.advance(const Duration(minutes: 1));
    await a.trips.deleteTrip(id);
    await a.sync();
    await b.sync();
    expect(await b.trips.getTrip(id), isNull);
    final catches = await b.db.select(b.db.catches).get();
    expect(catches.single.deletedAt, isNotNull);
  });

  test('all phones share the first one\'s privacy secret', () async {
    await a.sync();
    final secretA = await a.settings.privacySecret();
    await b.sync();
    expect(await b.settings.privacySecret(), secretA);
    expect(b.secretChanges, 1);
    expect(a.secretChanges, 0);
  });

  test('rows the server refuses wait for the next edit', () async {
    final id = await logTrip(a);
    server.refuse.add(id);
    await a.sync();
    final row = (await a.db.select(a.db.trips).get()).single;
    expect(row.syncStatus, SyncStatus.rejected);
    final pushes = server.requests.where((r) => r.url.path == '/api/sync/push');
    final before = pushes.length;
    await a.sync();
    expect(
      server.requests.where((r) => r.url.path == '/api/sync/push').length,
      before,
    );
  });

  test('a revoked session signs this phone out, the logbook stays', () async {
    final id = await logTrip(a);
    await a.sync();
    a.tokens.token = 'revoked';
    await a.sync();
    expect(await a.account.read(), isNull);
    expect(await a.trips.getTrip(id), isNotNull);
    expect(await a.queue.find(JobKind.sync, syncSubject), isNull);
    // Whatever account signs in next receives the whole logbook.
    final row = (await a.db.select(a.db.trips).get()).single;
    expect(row.syncStatus, SyncStatus.pending);
    server.tables.clear();
    await a.signIn();
    await a.sync();
    expect(server.tables['trips']!.keys, [id]);
  });

  test('server down: nothing is lost, the sync tries again later', () async {
    await logTrip(a);
    server.down = true;
    await a.sync();
    final job = await a.queue.find(JobKind.sync, syncSubject);
    expect(job!.attempts, 1);
    expect(job.nextAttemptAt.isAfter(t0), isTrue);
    final row = (await a.db.select(a.db.trips).get()).single;
    expect(row.syncStatus, SyncStatus.pending);

    server.down = false;
    a.clock.advance(const Duration(hours: 1));
    await a.runner.runDue();
    expect(server.tables['trips'], hasLength(1));
    // The sync stays scheduled every 15 minutes.
    final next = await a.queue.find(JobKind.sync, syncSubject);
    expect(next!.attempts, 0);
    expect(next.nextAttemptAt, a.clock.now().add(SyncJobHandler.every));
  });

  test('each sync brings the server switches for this account', () async {
    expect(await a.account.watchFlags().first, isA<FeatureFlags>());
    server.features['venues'] = true;
    await a.sync();
    final flags = await a.account.watchFlags().first;
    expect(flags.isOn(FeatureFlags.venues), isTrue);
    expect(flags.isOn('unknown'), isFalse);
    // Signing out forgets them.
    await a.account.signOut();
    final after = await a.account.watchFlags().first;
    expect(after.isOn(FeatureFlags.venues), isFalse);
  });

  test("a trip's venue reaches the other phone", () async {
    final id = await logTrip(a);
    await a.trips.setVenue(id, 'venue-1');
    await a.sync();
    expect(server.tables['trips']![id]!['venue_id'], 'venue-1');
    await b.sync();
    expect((await b.trips.getTrip(id))!.venueId, 'venue-1');
  });
}
