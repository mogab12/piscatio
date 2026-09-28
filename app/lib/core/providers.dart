import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart';
import '../data/repositories/catch_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/species_repository.dart';
import '../data/repositories/tackle_repository.dart';
import '../data/repositories/trip_repository.dart';
import '../domain/models/app_settings.dart';
import '../domain/models/catch.dart';
import '../domain/models/species.dart';
import '../domain/models/tackle.dart';
import '../domain/models/trip.dart';
import '../domain/services/species_search.dart';
import '../domain/services/units.dart';
import 'clock.dart';
import 'ids.dart';

// Infrastructure. The database is opened in main() and injected here; tests
// override it with an in-memory one.

final appDatabaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('appDatabaseProvider must be overridden'),
);

final clockProvider = Provider<Clock>((ref) => const SystemClock());

final idGeneratorProvider = Provider<IdGenerator>(
  (ref) => const UuidV7Generator(),
);

/// The device locale (language + region), independent of the app language.
final deviceLocaleProvider = Provider<Locale>(
  (ref) => WidgetsBinding.instance.platformDispatcher.locale,
);

// Repositories.

final tripRepositoryProvider = Provider(
  (ref) => TripRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(clockProvider),
    ref.watch(idGeneratorProvider),
  ),
);

final catchRepositoryProvider = Provider(
  (ref) => CatchRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(clockProvider),
    ref.watch(idGeneratorProvider),
  ),
);

final speciesRepositoryProvider = Provider(
  (ref) => SpeciesRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(clockProvider),
    ref.watch(idGeneratorProvider),
  ),
);

final tackleRepositoryProvider = Provider(
  (ref) => TackleRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(clockProvider),
    ref.watch(idGeneratorProvider),
  ),
);

final settingsRepositoryProvider = Provider(
  (ref) => SettingsRepository(ref.watch(appDatabaseProvider)),
);

// Settings.

final settingsProvider = StreamProvider<AppSettings>(
  (ref) => ref.watch(settingsRepositoryProvider).watch(),
);

/// Units in effect: the user's choice, or the device region's default.
final unitSystemProvider = Provider<UnitSystem>((ref) {
  final chosen = ref.watch(settingsProvider).value?.unitSystem;
  return chosen ??
      defaultUnitSystemFor(ref.watch(deviceLocaleProvider).countryCode);
});

// Data streams.

final activeTripProvider = StreamProvider<Trip?>(
  (ref) => ref.watch(tripRepositoryProvider).watchActiveTrip(),
);

final recentTripsProvider = StreamProvider<List<TripOverview>>(
  (ref) => ref.watch(tripRepositoryProvider).watchOverviews(limit: 5),
);

final tripHistoryProvider = StreamProvider<List<TripOverview>>(
  (ref) => ref.watch(tripRepositoryProvider).watchOverviews(),
);

final tripProvider = StreamProvider.family<Trip?, String>(
  (ref, id) => ref.watch(tripRepositoryProvider).watchTrip(id),
);

final tripCatchesProvider = StreamProvider.family<List<Catch>, String>(
  (ref, tripId) =>
      ref.watch(catchRepositoryProvider).watchCatchesForTrip(tripId),
);

final catchProvider = StreamProvider.family<Catch?, String>(
  (ref, id) => ref.watch(catchRepositoryProvider).watchCatch(id),
);

final speciesListProvider = StreamProvider<List<Species>>(
  (ref) => ref.watch(speciesRepositoryProvider).watchAll(),
);

final speciesByIdProvider = Provider<Map<String, Species>>((ref) {
  final list = ref.watch(speciesListProvider).value ?? const [];
  return {for (final s in list) s.id: s};
});

final speciesSearchProvider = Provider<SpeciesSearch>(
  (ref) => SpeciesSearch(ref.watch(speciesListProvider).value ?? const []),
);

final speciesUsageProvider = StreamProvider<Map<String, int>>(
  (ref) => ref.watch(catchRepositoryProvider).watchSpeciesUsage(),
);

final baitsProvider = StreamProvider<List<Bait>>(
  (ref) => ref.watch(tackleRepositoryProvider).watchBaits(),
);

final gearProvider = StreamProvider<List<Gear>>(
  (ref) => ref.watch(tackleRepositoryProvider).watchGear(),
);
