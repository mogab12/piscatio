import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../data/db/tables.dart';
import '../data/jobs/job_queue.dart';
import '../data/jobs/job_runner.dart';
import '../data/jobs/job_scheduler.dart';
import '../data/jobs/place_map_job.dart';
import '../data/jobs/place_name_job.dart';
import '../data/jobs/weather_job.dart';
import '../data/remote/nasa_power_client.dart';
import '../data/remote/overpass_client.dart';
import '../data/remote/place_name_service.dart';
import '../data/repositories/place_map_repository.dart';
import '../data/repositories/weather_repository.dart';
import '../domain/models/enums.dart';
import '../domain/models/place_map.dart';
import '../domain/models/weather.dart';
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

final jobRunnerProvider = Provider(
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
      client: ref.watch(overpassClientProvider),
      secret: () => ref.read(settingsRepositoryProvider).privacySecret(),
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
final jobSchedulerProvider = Provider<JobScheduler>((ref) {
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

  Future<void> cancelFor(String tripId) async {
    await _queue.cancel(JobKind.weather, tripId);
    await _queue.cancel(JobKind.placeName, tripId);
    await _queue.cancel(JobKind.placeMap, tripId);
  }
}

final backgroundWorkProvider = Provider(BackgroundWork.new);
