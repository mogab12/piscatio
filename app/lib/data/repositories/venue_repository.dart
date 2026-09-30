import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/clock.dart';
import '../../domain/models/venue.dart';
import '../db/app_database.dart';

/// Venues seen on the server, kept to show them offline (a cache, not the
/// person's data).
class VenueRepository {
  VenueRepository(this._db, this._clock);

  final AppDatabase _db;
  final Clock _clock;

  /// Stores (or refreshes) venues as the server sent them.
  Future<void> remember(List<Map<String, Object?>> venues) async {
    if (venues.isEmpty) return;
    final now = _clock.now();
    await _db.batch((b) {
      for (final v in venues) {
        b.insert(
          _db.venueCache,
          VenueCacheCompanion.insert(
            id: v['id']! as String,
            data: jsonEncode(v),
            fetchedAt: now,
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<Venue?> get(String id) async {
    final row = await (_db.select(
      _db.venueCache,
    )..where((v) => v.id.equals(id))).getSingleOrNull();
    return row == null ? null : _venue(row);
  }

  Stream<Venue?> watch(String id) =>
      (_db.select(_db.venueCache)..where((v) => v.id.equals(id)))
          .watchSingleOrNull()
          .map((row) => row == null ? null : _venue(row));

  static Venue _venue(VenueCacheRow row) =>
      Venue.fromJson(jsonDecode(row.data) as Map<String, Object?>);
}
