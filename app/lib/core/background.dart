import 'dart:convert';
import 'dart:isolate';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../data/account/account_repository.dart';
import '../data/db/tables.dart';
import '../data/jobs/job_queue.dart';
import '../data/jobs/job_runner.dart';
import '../data/jobs/job_scheduler.dart';
import '../data/jobs/place_map_job.dart';
import '../data/jobs/place_name_job.dart';
import '../data/jobs/sync_job.dart';
import '../data/jobs/weather_job.dart';
import '../data/media/photo_storage.dart';
import '../data/remote/nasa_power_client.dart';
import '../data/remote/overpass_client.dart';
import '../data/remote/piscatio_api.dart';
import '../data/remote/place_name_service.dart';
import '../data/repositories/place_map_repository.dart';
import '../data/repositories/weather_repository.dart';
import '../data/sync/sync_service.dart';
import '../domain/models/enums.dart';
import '../domain/models/geo_point.dart';
import '../domain/models/place_map.dart';
import '../domain/models/weather.dart';
import '../domain/services/overpass_map.dart';
import '../features/settings/application/preferences.dart';
import 'providers.dart';

// Network-backed work: weather, place names and maps, run through a
// persistent job queue so everything keeps working offline.

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final nasaPowerClientProvider = Provider(
  (ref) => NasaPowerClient(ref.watch(httpClientProvider)),
);

final placeNameServiceProvider = Provider<PlaceNameService>(
  (ref) => const PlatformPlaceNameService(),
);

final overpassClientProvider = Provider(
  (ref) => OverpassClient(ref.watch(httpClientProvider)),
);

final placeMapRepositoryProvider = Provider(
  (ref) => PlaceMapRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(clockProvider),
  ),
);

/// Stored map data for an area key (see `mapAreaFor`).
final placeMapProvider = StreamProvider.family<PlaceMap?, String>(
  (ref, key) => ref.watch(placeMapRepositoryProvider).watch(key),
);

/// The sign-in token's safe (overridden in tests).
final tokenStoreProvider = Provider<TokenStore>(
  (ref) => const SecureTokenStore(),
);

final accountRepositoryProvider = Provider(
  (ref) => AccountRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(settingsRepositoryProvider),
    ref.watch(tokenStoreProvider),
  ),
);

/// The signed-in account; null when signed out.
final accountProvider = StreamProvider<Account?>(
  (ref) => ref.watch(accountRepositoryProvider).watch(),
);

/// Talks to a Piscatio server at [base] (with a session [token] if any).
final apiFactoryProvider = Provider<ApiFactory>((ref) {
  final http = ref.watch(httpClientProvider);
  return (base, token) => PiscatioApi(http, base: base, token: token);
});

final syncServiceProvider = Provider(
  (ref) => SyncService(
    ref.watch(appDatabaseProvider),
    ref.watch(clockProvider),
    photoExists: (relative) {
      final root = ref.read(photoRootProvider).value;
      return root != null && resolvePhoto(root, relative).existsSync();
    },
  ),
);

/// OpenStreetMap data for a map area: through our server when signed in
/// (shared cache, fair use of Overpass), directly otherwise or when the
/// server is down.
final mapFetcherProvider = Provider<Future<PlaceMap> Function(GeoPoint)>((ref) {
  return (center) async {
    final accounts = ref.read(accountRepositoryProvider);
    final account = await accounts.read();
    final token = await accounts.token();
    if (account != null && token != null) {
      try {
        final bytes = await ref
            .read(apiFactoryProvider)(account.server, token)
            .mapArea(center.latitude, center.longitude);
        return await Isolate.run(
          () => OverpassMap.parse(
            jsonDecode(utf8.decode(bytes)) as Map<String, Object?>,
            center,
          ),
        );
      } on ApiUnavailable {
        // Fall through to Overpass.
      } on ApiSignedOut {
        // Fall through to Overpass.
      }
    }
    return ref.read(overpassClientProvider).fetchAround(center);
  };
});

/// The per-install secret behind approximate locations.
final privacySecretProvider = FutureProvider<List<int>>(
  (ref) => ref.watch(settingsRepositoryProvider).privacySecret(),
);

final weatherRepositoryProvider = Provider(
  (ref) => WeatherRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(clockProvider),
  ),
);

final tripWeatherProvider = StreamProvider.family<TripWeather?, String>(
  (ref, tripId) => ref.watch(weatherRepositoryProvider).watchForTrip(tripId),
);

final jobQueueProvider = Provider(
  (ref) => JobQueue(
    ref.watch(appDatabaseProvider),
    ref.watch(clockProvider),
    ref.watch(idGeneratorProvider),
  ),
);

final Provider<JobRunner> jobRunnerProvider = Provider<JobRunner>(
  (ref) => JobRunner(ref.watch(jobQueueProvider), [
    WeatherJobHandler(
      trips: ref.watch(tripRepositoryProvider),
      weather: ref.watch(weatherRepositoryProvider),
      client: ref.watch(nasaPowerClientProvider),
      clock: ref.watch(clockProvider),
    ),
    PlaceNameJobHandler(
      trips: ref.watch(tripRepositoryProvider),
      service: ref.watch(placeNameServiceProvider),
      languageCode: () => ref.read(effectiveLanguageProvider),
    ),
    PlaceMapJobHandler(
      trips: ref.watch(tripRepositoryProvider),
      maps: ref.watch(placeMapRepositoryProvider),
      fetch: (center) => ref.read(mapFetcherProvider)(center),
      secret: () => ref.read(settingsRepositoryProvider).privacySecret(),
    ),
    SyncJobHandler(
      account: ref.watch(accountRepositoryProvider),
      sync: ref.watch(syncServiceProvider),
      settings: ref.watch(settingsRepositoryProvider),
      queue: ref.watch(jobQueueProvider),
      api: ref.watch(apiFactoryProvider),
      clock: ref.watch(clockProvider),
      onNewTrip: (id) async {
        final work = ref.read(backgroundWorkProvider);
        final trip = await ref.read(tripRepositoryProvider).getTrip(id);
        if (trip == null) return;
        if (!trip.isActive) await work.weatherFor(id);
        await work.mapFor(id, trip.privacyLevel);
      },
      onSecretChanged: () => ref.invalidate(privacySecretProvider),
      kick: () => ref.read(jobSchedulerProvider).kick(),
    ),
    PhotoUploadHandler(
      db: ref.watch(appDatabaseProvider),
      account: ref.watch(accountRepositoryProvider),
      api: ref.watch(apiFactoryProvider),
      root: () => ref.read(photoRootProvider.future),
      clock: ref.watch(clockProvider),
    ),
    PhotoDownloadHandler(
      db: ref.watch(appDatabaseProvider),
      account: ref.watch(accountRepositoryProvider),
      api: ref.watch(apiFactoryProvider),
      root: () => ref.read(photoRootProvider.future),
    ),
  ], ref.watch(clockProvider)),
);

/// Fires whenever the device regains any connection.
final connectionRestoredProvider = Provider<Stream<void>>(
  (ref) => Connectivity().onConnectivityChanged
      .where((r) => r.any((c) => c != ConnectivityResult.none))
      .map((_) {}),
);

/// Started once by the app. Tests replace it with a scheduler that is never
/// started (no timers), whose [JobScheduler.kick] runs the queue on demand.
final Provider<JobScheduler> jobSchedulerProvider = Provider<JobScheduler>((
  ref,
) {
  final scheduler = JobScheduler(
    ref.watch(jobRunnerProvider),
    connectionRestored: ref.watch(connectionRestoredProvider),
  )..start();
  ref.onDispose(scheduler.dispose);
  return scheduler;
});

/// Enqueues network work for trips and nudges the scheduler.
class BackgroundWork {
  BackgroundWork(this._ref);

  final Ref _ref;

  JobQueue get _queue => _ref.read(jobQueueProvider);

  Future<void> weatherFor(String tripId) async {
    await _ref.read(weatherRepositoryProvider).markPending(tripId);
    await _queue.enqueue(JobKind.weather, tripId);
    _ref.read(jobSchedulerProvider).kick();
  }

  Future<void> placeNameFor(String tripId) async {
    await _queue.enqueue(JobKind.placeName, tripId);
    _ref.read(jobSchedulerProvider).kick();
  }

  /// Only trips whose cards may show a map need one.
  Future<void> mapFor(String tripId, PrivacyLevel privacy) async {
    if (privacy == PrivacyLevel.private || privacy == PrivacyLevel.friends) {
      return;
    }
    await _queue.enqueue(JobKind.placeMap, tripId);
    _ref.read(jobSchedulerProvider).kick();
  }

  /// Syncs as soon as possible (when signed in).
  Future<void> syncSoon() async {
    if (await _ref.read(accountRepositoryProvider).read() == null) return;
    await _queue.enqueue(JobKind.sync, syncSubject);
    _ref.read(jobSchedulerProvider).kick();
  }

  /// Makes sure the recurring sync is queued, without moving it.
  Future<void> ensureSync() async {
    if (await _ref.read(accountRepositoryProvider).read() == null) return;
    if (await _queue.find(JobKind.sync, syncSubject) != null) return;
    await syncSoon();
  }

  Future<void> cancelSync() => _queue.cancel(JobKind.sync, syncSubject);

  Future<void> cancelFor(String tripId) async {
    await _queue.cancel(JobKind.weather, tripId);
    await _queue.cancel(JobKind.placeName, tripId);
    await _queue.cancel(JobKind.placeMap, tripId);
  }
}

final backgroundWorkProvider = Provider(BackgroundWork.new);
