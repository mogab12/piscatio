import 'package:drift/drift.dart';

import '../../domain/models/enums.dart';
import '../../domain/services/moon.dart';
import 'converters.dart';

/// Columns every user-owned table carries so Phase 2 can sync offline edits:
/// `updated_at` for last-write-wins and `deleted_at` tombstones so deletions
/// propagate. All timestamps are UTC.
mixin SyncColumns on Table {
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus =>
      textEnum<SyncStatus>().withDefault(const Constant('pending'))();
}

@DataClassName('TripRow')
class Trips extends Table with SyncColumns {
  TextColumn get id => text()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  TextColumn get timezone => text()();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  RealColumn get locationAccuracyM => real().nullable()();
  TextColumn get locationName => text().nullable()();
  TextColumn get locationRegion => text().nullable()();
  TextColumn get privacyLevel => textEnum<PrivacyLevel>()();
  TextColumn get moonPhase => textEnum<MoonPhase>()();
  RealColumn get moonIllumination => real()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isRetroactive =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

enum WeatherStatus { pending, ok, unavailable }

/// Weather for a trip, fetched by the job queue. Derived data: not synced.
@DataClassName('WeatherRow')
class WeatherSnapshots extends Table {
  TextColumn get tripId =>
      text().references(Trips, #id, onDelete: KeyAction.cascade)();
  TextColumn get status => textEnum<WeatherStatus>()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextAttemptAt => dateTime().nullable()();
  TextColumn get lastError => text().nullable()();
  TextColumn get source => text().nullable()();
  DateTimeColumn get fetchedAt => dateTime().nullable()();
  RealColumn get temperatureC => real().nullable()();
  RealColumn get pressureHpa => real().nullable()();
  RealColumn get pressureTrend3hHpa => real().nullable()();
  RealColumn get windSpeedKmh => real().nullable()();
  RealColumn get windDirectionDeg => real().nullable()();
  RealColumn get windGustKmh => real().nullable()();
  RealColumn get cloudCoverPct => real().nullable()();
  RealColumn get precipitationMm => real().nullable()();
  IntColumn get weatherCode => integer().nullable()();

  /// Hourly series covering the trip, so each catch gets its own conditions.
  TextColumn get hourlyJson => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {tripId};
}

@DataClassName('SpeciesRow')
class SpeciesTable extends Table with SyncColumns {
  @override
  String get tableName => 'species';

  /// Stable slug (catalog) or UUID (custom species).
  TextColumn get id => text()();
  TextColumn get scientificName => text()();
  TextColumn get habitats => text()
      .map(const HabitatListConverter())
      .withDefault(const Constant(''))();
  TextColumn get regionTags =>
      text().map(const StringListConverter()).withDefault(const Constant(''))();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('SpeciesNameRow')
class SpeciesNames extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get speciesId =>
      text().references(SpeciesTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get lang => text()();
  TextColumn get name => text()();
  BoolColumn get isPrimary => boolean().withDefault(const Constant(false))();
  TextColumn get region => text().nullable()();
  BoolColumn get needsReview => boolean().withDefault(const Constant(false))();
}

@DataClassName('BaitRow')
class Baits extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get type => textEnum<BaitType>()();
  TextColumn get notes => text().nullable()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('GearRow')
class GearItems extends Table with SyncColumns {
  @override
  String get tableName => 'gear';

  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get type => textEnum<GearType>()();
  TextColumn get notes => text().nullable()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('CatchRow')
class Catches extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get tripId => text().references(Trips, #id)();
  TextColumn get speciesId => text().nullable().references(SpeciesTable, #id)();
  DateTimeColumn get caughtAt => dateTime()();
  IntColumn get weightG => integer().nullable()();
  IntColumn get lengthMm => integer().nullable()();
  BoolColumn get released => boolean().nullable()();
  TextColumn get baitId => text().nullable().references(Baits, #id)();
  TextColumn get gearId => text().nullable().references(GearItems, #id)();
  IntColumn get depthMm => integer().nullable()();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('CatchPhotoRow')
class CatchPhotos extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get catchId => text().references(Catches, #id)();
  TextColumn get relativePath => text()();
  IntColumn get width => integer()();
  IntColumn get height => integer()();
  DateTimeColumn get takenAt => dateTime().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('SettingRow')
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}
