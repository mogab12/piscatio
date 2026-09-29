import 'package:drift/drift.dart';

import '../../domain/models/enums.dart';
import '../../domain/models/weather.dart';
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

/// Weather for a trip, filled by the job queue. Derived data: not synced.
@DataClassName('WeatherRow')
class WeatherSnapshots extends Table {
  TextColumn get tripId =>
      text().references(Trips, #id, onDelete: KeyAction.cascade)();
  TextColumn get status => textEnum<WeatherStatus>()();
  TextColumn get source => text().nullable()();
  DateTimeColumn get fetchedAt => dateTime().nullable()();
  RealColumn get temperatureC => real().nullable()();
  RealColumn get pressureHpa => real().nullable()();
  RealColumn get pressureTrend3hHpa => real().nullable()();
  RealColumn get windSpeedKmh => real().nullable()();
  RealColumn get windDirectionDeg => real().nullable()();
  RealColumn get precipitationMm => real().nullable()();
  RealColumn get humidityPct => real().nullable()();

  /// Hourly series covering the trip, so each catch gets its own conditions.
  TextColumn get hourlyJson => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {tripId};
}

/// Work that needs the network. Rows exist only while pending: a finished
/// job is deleted. Retried on app start, resume and when the connection
/// returns, honoring [nextAttemptAt].
enum JobKind { weather, placeName, placeMap, sync, photoUpload, photoDownload }

@DataClassName('JobRow')
class Jobs extends Table {
  TextColumn get id => text()();
  TextColumn get kind => textEnum<JobKind>()();

  /// What the job is about (a trip id for every current kind).
  TextColumn get subjectId => text()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextAttemptAt => dateTime()();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {kind, subjectId},
  ];
}

/// Map data (water and main roads) around an approximate point, from
/// OpenStreetMap. A cache, not user data: rebuilt when missing, never
/// exported or synced, erased with "delete all data".
@DataClassName('PlaceMapRow')
class PlaceMaps extends Table {
  /// The approximate point, "lat,lng" with 5 decimals.
  TextColumn get areaKey => text()();
  RealColumn get centerLatitude => real()();
  RealColumn get centerLongitude => real()();
  IntColumn get halfSizeMeters => integer()();

  /// [PlaceMap.toJson].
  TextColumn get data => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {areaKey};
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
