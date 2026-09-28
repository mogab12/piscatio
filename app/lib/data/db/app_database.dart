import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../domain/models/enums.dart';
import '../../domain/models/species.dart';
import '../../domain/services/moon.dart';
import 'converters.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Trips,
    WeatherSnapshots,
    SpeciesTable,
    SpeciesNames,
    Baits,
    GearItems,
    Catches,
    CatchPhotos,
    Settings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// The on-device database file.
  factory AppDatabase.open() => AppDatabase(driftDatabase(name: 'piscatio'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _createIndexes();
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Future<void> _createIndexes() async {
    await customStatement(
      'CREATE INDEX idx_trips_started_at ON trips (started_at)',
    );
    await customStatement(
      'CREATE INDEX idx_catches_trip ON catches (trip_id, caught_at)',
    );
    await customStatement(
      'CREATE INDEX idx_catches_species ON catches (species_id)',
    );
    await customStatement(
      'CREATE INDEX idx_catch_photos_catch ON catch_photos (catch_id)',
    );
    await customStatement(
      'CREATE INDEX idx_species_names_species ON species_names (species_id)',
    );
  }

  /// Physically removes every user record ("delete all my data"). The
  /// species catalog is kept, custom species are removed.
  Future<void> wipeUserData() => transaction(() async {
    await delete(catchPhotos).go();
    await delete(catches).go();
    await delete(weatherSnapshots).go();
    await delete(trips).go();
    await delete(baits).go();
    await delete(gearItems).go();
    await (delete(speciesTable)..where((s) => s.isCustom)).go();
    await delete(settings).go();
  });
}
