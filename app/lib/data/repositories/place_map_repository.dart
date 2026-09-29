import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/clock.dart';
import '../../domain/models/geo_point.dart';
import '../../domain/models/place_map.dart';
import '../db/app_database.dart';

/// Stored map data, one row per approximate point (see `mapAreaFor`).
class PlaceMapRepository {
  PlaceMapRepository(this._db, this._clock);

  final AppDatabase _db;
  final Clock _clock;

  SimpleSelectStatement<$PlaceMapsTable, PlaceMapRow> _row(String key) =>
      _db.select(_db.placeMaps)..where((m) => m.areaKey.equals(key));

  Future<bool> has(String key) async =>
      await _row(key).getSingleOrNull() != null;

  Future<PlaceMap?> get(String key) async =>
      _decode(await _row(key).getSingleOrNull());

  Stream<PlaceMap?> watch(String key) =>
      _row(key).watchSingleOrNull().map(_decode);

  Future<void> save(String key, PlaceMap map) {
    final now = _clock.now();
    return _db
        .into(_db.placeMaps)
        .insertOnConflictUpdate(
          PlaceMapsCompanion.insert(
            areaKey: key,
            centerLatitude: map.center.latitude,
            centerLongitude: map.center.longitude,
            halfSizeMeters: map.halfSizeMeters.round(),
            data: jsonEncode(map.toJson()),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  static PlaceMap? _decode(PlaceMapRow? row) => row == null
      ? null
      : PlaceMap.fromJson(
          jsonDecode(row.data) as Map<String, Object?>,
          center: GeoPoint(row.centerLatitude, row.centerLongitude),
          halfSizeMeters: row.halfSizeMeters.toDouble(),
        );
}
