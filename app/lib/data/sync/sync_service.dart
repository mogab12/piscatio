import 'package:drift/drift.dart';

import '../../core/clock.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/species.dart';
import '../../domain/services/moon.dart';
import '../db/app_database.dart';
import '../db/converters.dart';
import '../remote/piscatio_api.dart';

String? _iso(DateTime? t) => t?.toUtc().toIso8601String();

DateTime? _time(Object? v) =>
    v == null ? null : DateTime.parse(v as String).toUtc();

double? _real(Object? v) => (v as num?)?.toDouble();

int? _int(Object? v) => (v as num?)?.toInt();

/// A row read for pushing: its id and the `updated_at` it had, so it is
/// marked synced only if nobody edited it meanwhile.
typedef PushedRow = ({String table, String id, DateTime updatedAt});

/// What a pull brought that needs follow-up work.
class PullOutcome {
  PullOutcome({required this.newTrips, required this.missingPhotos});

  /// Trips new to this device: their weather and map are fetched here.
  final List<String> newTrips;

  /// Photo rows whose image is on the server but not on this device.
  final List<String> missingPhotos;
}

/// Moves the logbook between this device's database and the server's
/// format. Tables in parent-before-child order.
class SyncService {
  SyncService(this._db, this._clock, {required this.photoExists});

  final AppDatabase _db;
  final Clock _clock;

  /// Whether a photo's file (relative path) is on this device.
  final bool Function(String relativePath) photoExists;

  static const tables = [
    'trips',
    'baits',
    'gear',
    'species',
    'catches',
    'photos',
  ];

  /// Up to [limit] rows edited on this device and not yet on the server.
  Future<(Map<String, List<Map<String, Object?>>>, List<PushedRow>)> pending({
    int limit = 400,
  }) async {
    final changes = <String, List<Map<String, Object?>>>{};
    final rows = <PushedRow>[];
    var left = limit;
    void add(
      String table,
      String id,
      DateTime updated,
      Map<String, Object?> j,
    ) {
      (changes[table] ??= []).add(j);
      rows.add((table: table, id: id, updatedAt: updated));
      left--;
    }

    Expression<bool> isPending(GeneratedColumn<String> status) =>
        status.equals(SyncStatus.pending.name);

    for (final t
        in await (_db.select(_db.trips)
              ..where((r) => isPending(r.syncStatus))
              ..limit(left))
            .get()) {
      add('trips', t.id, t.updatedAt, tripJson(t));
    }
    if (left > 0) {
      for (final b
          in await (_db.select(_db.baits)
                ..where((r) => isPending(r.syncStatus))
                ..limit(left))
              .get()) {
        add('baits', b.id, b.updatedAt, {
          ..._sync(b.id, b.createdAt, b.updatedAt, b.deletedAt),
          'name': b.name,
          'type': b.type.name,
          'notes': b.notes,
          'archived': b.archived,
        });
      }
    }
    if (left > 0) {
      for (final g
          in await (_db.select(_db.gearItems)
                ..where((r) => isPending(r.syncStatus))
                ..limit(left))
              .get()) {
        add('gear', g.id, g.updatedAt, {
          ..._sync(g.id, g.createdAt, g.updatedAt, g.deletedAt),
          'name': g.name,
          'type': g.type.name,
          'notes': g.notes,
          'archived': g.archived,
        });
      }
    }
    if (left > 0) {
      for (final s
          in await (_db.select(_db.speciesTable)
                ..where((r) => r.isCustom & isPending(r.syncStatus))
                ..limit(left))
              .get()) {
        final names = await (_db.select(
          _db.speciesNames,
        )..where((n) => n.speciesId.equals(s.id))).get();
        add('species', s.id, s.updatedAt, {
          ..._sync(s.id, s.createdAt, s.updatedAt, s.deletedAt),
          'scientific_name': s.scientificName,
          'habitats': const HabitatListConverter().toSql(s.habitats),
          'region_tags': const StringListConverter().toSql(s.regionTags),
          'names': [
            for (final n in names)
              {'lang': n.lang, 'name': n.name, 'is_primary': n.isPrimary},
          ],
        });
      }
    }
    if (left > 0) {
      for (final c
          in await (_db.select(_db.catches)
                ..where((r) => isPending(r.syncStatus))
                ..limit(left))
              .get()) {
        add('catches', c.id, c.updatedAt, catchJson(c));
      }
    }
    if (left > 0) {
      for (final p
          in await (_db.select(_db.catchPhotos)
                ..where((r) => isPending(r.syncStatus))
                ..limit(left))
              .get()) {
        add('photos', p.id, p.updatedAt, {
          ..._sync(p.id, p.createdAt, p.updatedAt, p.deletedAt),
          'catch_id': p.catchId,
          'width': p.width,
          'height': p.height,
          'taken_at': _iso(p.takenAt),
          'sort_order': p.sortOrder,
        });
      }
    }
    return (changes, rows);
  }

  static Map<String, Object?> _sync(
    String id,
    DateTime created,
    DateTime updated,
    DateTime? deleted,
  ) => {
    'id': id,
    'created_at': _iso(created),
    'updated_at': _iso(updated),
    'deleted_at': _iso(deleted),
  };

  static Map<String, Object?> tripJson(TripRow t) => {
    ..._sync(t.id, t.createdAt, t.updatedAt, t.deletedAt),
    'started_at': _iso(t.startedAt),
    'ended_at': _iso(t.endedAt),
    'timezone': t.timezone,
    'latitude': t.latitude,
    'longitude': t.longitude,
    'location_accuracy_m': t.locationAccuracyM,
    'location_name': t.locationName,
    'location_region': t.locationRegion,
    'privacy_level': t.privacyLevel.name,
    'moon_phase': t.moonPhase.name,
    'moon_illumination': t.moonIllumination,
    'notes': t.notes,
    'is_retroactive': t.isRetroactive,
    'venue_id': t.venueId,
  };

  static Map<String, Object?> catchJson(CatchRow c) => {
    ..._sync(c.id, c.createdAt, c.updatedAt, c.deletedAt),
    'trip_id': c.tripId,
    'species_id': c.speciesId,
    'caught_at': _iso(c.caughtAt),
    'weight_g': c.weightG,
    'length_mm': c.lengthMm,
    'released': c.released,
    'bait_id': c.baitId,
    'gear_id': c.gearId,
    'depth_mm': c.depthMm,
    'latitude': c.latitude,
    'longitude': c.longitude,
    'notes': c.notes,
  };

  /// Marks pushed rows by the server's answer, unless they were edited
  /// again while the push was on its way.
  Future<void> markPushed(List<PushedRow> rows, PushResult result) async {
    final refused = {for (final (t, id) in result.rejected) '$t/$id'};
    await _db.transaction(() async {
      for (final r in rows) {
        final status = refused.contains('${r.table}/${r.id}')
            ? SyncStatus.rejected
            : SyncStatus.synced;
        await _db.customUpdate(
          'UPDATE ${_sqlTable(r.table)} SET sync_status = ? '
          'WHERE id = ? AND updated_at = ?',
          variables: [
            Variable.withString(status.name),
            Variable.withString(r.id),
            // Encoded like the column (text dates in this database).
            Variable<DateTime>(r.updatedAt),
          ],
          updates: {_tableInfo(r.table)},
        );
      }
    });
  }

  /// After signing out: every row goes up again to whichever account
  /// signs in next (a server that already has a row answers "stale").
  Future<void> forgetServer() => _db.transaction(() async {
    for (final table in tables) {
      await _db.customUpdate(
        'UPDATE ${_sqlTable(table)} SET sync_status = ? '
        'WHERE sync_status != ?',
        variables: [
          Variable.withString(SyncStatus.pending.name),
          Variable.withString(SyncStatus.pending.name),
        ],
        updates: {_tableInfo(table)},
      );
    }
  });

  static String _sqlTable(String table) => switch (table) {
    'trips' => 'trips',
    'baits' => 'baits',
    'gear' => 'gear',
    'species' => 'species',
    'catches' => 'catches',
    _ => 'catch_photos',
  };

  TableInfo<Table, Object?> _tableInfo(String table) => switch (table) {
    'trips' => _db.trips,
    'baits' => _db.baits,
    'gear' => _db.gearItems,
    'species' => _db.speciesTable,
    'catches' => _db.catches,
    _ => _db.catchPhotos,
  };

  /// Applies one page from the server. A row edited here after the server's
  /// version, and not pushed yet, wins: it goes up on the next push.
  Future<PullOutcome> apply(PullPage page) async {
    final newTrips = <String>[];
    final missingPhotos = <String>[];
    await _db.transaction(() async {
      bool keepLocal(String status, DateTime localUpdated, DateTime remote) =>
          status == SyncStatus.pending.name && localUpdated.isAfter(remote);

      for (final j in page.changes['trips'] ?? const <Map<String, Object?>>[]) {
        final id = j['id']! as String;
        final updated = _time(j['updated_at'])!;
        final local = await (_db.select(
          _db.trips,
        )..where((t) => t.id.equals(id))).getSingleOrNull();
        if (local != null &&
            keepLocal(local.syncStatus.name, local.updatedAt, updated)) {
          continue;
        }
        if (local == null && j['deleted_at'] == null) newTrips.add(id);
        await _db
            .into(_db.trips)
            .insertOnConflictUpdate(
              TripsCompanion.insert(
                id: id,
                createdAt: _time(j['created_at'])!,
                updatedAt: updated,
                deletedAt: Value(_time(j['deleted_at'])),
                syncStatus: const Value(SyncStatus.synced),
                startedAt: _time(j['started_at'])!,
                endedAt: Value(_time(j['ended_at'])),
                timezone: j['timezone']! as String,
                latitude: Value(_real(j['latitude'])),
                longitude: Value(_real(j['longitude'])),
                locationAccuracyM: Value(_real(j['location_accuracy_m'])),
                locationName: Value(j['location_name'] as String?),
                locationRegion: Value(j['location_region'] as String?),
                privacyLevel:
                    PrivacyLevel.values.asNameMap()[j['privacy_level']] ??
                    PrivacyLevel.private,
                moonPhase:
                    MoonPhase.values.asNameMap()[j['moon_phase']] ??
                    MoonPhase.newMoon,
                moonIllumination: _real(j['moon_illumination']) ?? 0,
                notes: Value(j['notes'] as String?),
                isRetroactive: Value(j['is_retroactive'] == true),
                venueId: Value(j['venue_id'] as String?),
              ),
            );
      }

      for (final table in ['baits', 'gear']) {
        for (final j in page.changes[table] ?? const <Map<String, Object?>>[]) {
          final id = j['id']! as String;
          final updated = _time(j['updated_at'])!;
          if (table == 'baits') {
            final local = await (_db.select(
              _db.baits,
            )..where((t) => t.id.equals(id))).getSingleOrNull();
            if (local != null &&
                keepLocal(local.syncStatus.name, local.updatedAt, updated)) {
              continue;
            }
            await _db
                .into(_db.baits)
                .insertOnConflictUpdate(
                  BaitsCompanion.insert(
                    id: id,
                    createdAt: _time(j['created_at'])!,
                    updatedAt: updated,
                    deletedAt: Value(_time(j['deleted_at'])),
                    syncStatus: const Value(SyncStatus.synced),
                    name: j['name']! as String,
                    type:
                        BaitType.values.asNameMap()[j['type']] ??
                        BaitType.other,
                    notes: Value(j['notes'] as String?),
                    archived: Value(j['archived'] == true),
                  ),
                );
          } else {
            final local = await (_db.select(
              _db.gearItems,
            )..where((t) => t.id.equals(id))).getSingleOrNull();
            if (local != null &&
                keepLocal(local.syncStatus.name, local.updatedAt, updated)) {
              continue;
            }
            await _db
                .into(_db.gearItems)
                .insertOnConflictUpdate(
                  GearItemsCompanion.insert(
                    id: id,
                    createdAt: _time(j['created_at'])!,
                    updatedAt: updated,
                    deletedAt: Value(_time(j['deleted_at'])),
                    syncStatus: const Value(SyncStatus.synced),
                    name: j['name']! as String,
                    type:
                        GearType.values.asNameMap()[j['type']] ??
                        GearType.other,
                    notes: Value(j['notes'] as String?),
                    archived: Value(j['archived'] == true),
                  ),
                );
          }
        }
      }

      for (final j
          in page.changes['species'] ?? const <Map<String, Object?>>[]) {
        final id = j['id']! as String;
        final updated = _time(j['updated_at'])!;
        final local = await (_db.select(
          _db.speciesTable,
        )..where((t) => t.id.equals(id))).getSingleOrNull();
        if (local != null &&
            keepLocal(local.syncStatus.name, local.updatedAt, updated)) {
          continue;
        }
        await _db
            .into(_db.speciesTable)
            .insertOnConflictUpdate(
              SpeciesTableCompanion.insert(
                id: id,
                createdAt: _time(j['created_at'])!,
                updatedAt: updated,
                deletedAt: Value(_time(j['deleted_at'])),
                syncStatus: const Value(SyncStatus.synced),
                scientificName: j['scientific_name']! as String,
                habitats: Value(_habitats(j['habitats'] as String? ?? '')),
                regionTags: Value(
                  const StringListConverter().fromSql(
                    j['region_tags'] as String? ?? '',
                  ),
                ),
                isCustom: const Value(true),
              ),
            );
        await (_db.delete(
          _db.speciesNames,
        )..where((n) => n.speciesId.equals(id))).go();
        for (final n in (j['names'] as List? ?? const [])) {
          final name = (n as Map).cast<String, Object?>();
          await _db
              .into(_db.speciesNames)
              .insert(
                SpeciesNamesCompanion.insert(
                  speciesId: id,
                  lang: name['lang']! as String,
                  name: name['name']! as String,
                  isPrimary: Value(name['is_primary'] == true),
                ),
              );
        }
      }

      for (final j
          in page.changes['catches'] ?? const <Map<String, Object?>>[]) {
        final id = j['id']! as String;
        final updated = _time(j['updated_at'])!;
        final local = await (_db.select(
          _db.catches,
        )..where((t) => t.id.equals(id))).getSingleOrNull();
        if (local != null &&
            keepLocal(local.syncStatus.name, local.updatedAt, updated)) {
          continue;
        }
        // A species this app version does not know yet: kept unnamed rather
        // than failing the whole page.
        var speciesId = j['species_id'] as String?;
        if (speciesId != null &&
            await (_db.select(
                  _db.speciesTable,
                )..where((s) => s.id.equals(speciesId!))).getSingleOrNull() ==
                null) {
          speciesId = null;
        }
        await _db
            .into(_db.catches)
            .insertOnConflictUpdate(
              CatchesCompanion.insert(
                id: id,
                createdAt: _time(j['created_at'])!,
                updatedAt: updated,
                deletedAt: Value(_time(j['deleted_at'])),
                syncStatus: const Value(SyncStatus.synced),
                tripId: j['trip_id']! as String,
                speciesId: Value(speciesId),
                caughtAt: _time(j['caught_at'])!,
                weightG: Value(_int(j['weight_g'])),
                lengthMm: Value(_int(j['length_mm'])),
                released: Value(j['released'] as bool?),
                baitId: Value(j['bait_id'] as String?),
                gearId: Value(j['gear_id'] as String?),
                depthMm: Value(_int(j['depth_mm'])),
                latitude: Value(_real(j['latitude'])),
                longitude: Value(_real(j['longitude'])),
                notes: Value(j['notes'] as String?),
              ),
            );
      }

      for (final j
          in page.changes['photos'] ?? const <Map<String, Object?>>[]) {
        final id = j['id']! as String;
        final updated = _time(j['updated_at'])!;
        final local = await (_db.select(
          _db.catchPhotos,
        )..where((t) => t.id.equals(id))).getSingleOrNull();
        if (local != null &&
            keepLocal(local.syncStatus.name, local.updatedAt, updated)) {
          continue;
        }
        final path = local?.relativePath ?? 'photos/$id.jpg';
        await _db
            .into(_db.catchPhotos)
            .insertOnConflictUpdate(
              CatchPhotosCompanion.insert(
                id: id,
                createdAt: _time(j['created_at'])!,
                updatedAt: updated,
                deletedAt: Value(_time(j['deleted_at'])),
                syncStatus: const Value(SyncStatus.synced),
                catchId: j['catch_id']! as String,
                relativePath: path,
                width: _int(j['width']) ?? 0,
                height: _int(j['height']) ?? 0,
                takenAt: Value(_time(j['taken_at'])),
                sortOrder: Value(_int(j['sort_order']) ?? 0),
              ),
            );
        if (j['has_file'] == true &&
            j['deleted_at'] == null &&
            !photoExists(path)) {
          missingPhotos.add(id);
        }
      }
    });
    return PullOutcome(newTrips: newTrips, missingPhotos: missingPhotos);
  }

  static List<Habitat> _habitats(String sql) {
    final byName = Habitat.values.asNameMap();
    return [for (final h in sql.split(',')) ?byName[h]];
  }

  DateTime now() => _clock.now();
}
