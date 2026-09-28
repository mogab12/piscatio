import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:piscatio/core/clock.dart';
import 'package:piscatio/core/ids.dart';
import 'package:piscatio/data/db/app_database.dart';
import 'package:piscatio/data/repositories/settings_repository.dart';
import 'package:piscatio/data/seed/species_seeder.dart';

/// In-memory database for tests.
AppDatabase newTestDatabase() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(NativeDatabase.memory());
}

/// The real catalog shipped with the app.
String readSpeciesSeed() => File('assets/seed/species.json').readAsStringSync();

/// Database with the species catalog applied.
Future<AppDatabase> newSeededDatabase({Clock? clock}) async {
  final db = newTestDatabase();
  await SpeciesSeeder(
    db,
    SettingsRepository(db),
    clock ?? FixedClock(DateTime.utc(2026)),
  ).apply(readSpeciesSeed());
  return db;
}

/// Shared fixtures for repository tests.
class TestDeps {
  TestDeps(this.db)
    : clock = FixedClock(DateTime.utc(2026, 9, 12, 6)),
      ids = SequentialIdGenerator();

  final AppDatabase db;
  final FixedClock clock;
  final SequentialIdGenerator ids;
}
