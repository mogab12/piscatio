import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../domain/models/enums.dart';
import '../../domain/models/species.dart';
import '../../domain/models/weather.dart';
import '../../domain/services/moon.dart';
import 'app_database.steps.dart';
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
    Jobs,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// The on-device database file.
  factory AppDatabase.open() => AppDatabase(driftDatabase(name: 'piscatio'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _createIndexes();
      await _createJobIndex();
    },
    onUpgrade: stepByStep(
      from1To2: (m, schema) async {
        // v1 never wrote weather rows, so the reshaped table (job columns
        // moved to `jobs`, POWER fields added) is simply recreated.
        await m.deleteTable('weather_snapshots');
        await m.createTable(schema.weatherSnapshots);
        await m.createTable(schema.jobs);
        await _createJobIndex();
      },
    ),
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

  Future<void> _createJobIndex() =>
      customStatement('CREATE INDEX idx_jobs_due ON jobs (next_attempt_at)');

  /// Physically removes every user record ("delete all my data"). The
  /// species catalog is kept, custom species are removed.
  Future<void> wipeUserData() => transaction(() async {
    await delete(jobs).go();
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
