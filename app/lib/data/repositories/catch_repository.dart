import 'package:collection/collection.dart';
import 'package:drift/drift.dart';

import '../../core/clock.dart';
import '../../core/ids.dart';
import '../../domain/models/catch.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/geo_point.dart';
import '../db/app_database.dart';
import 'mappers.dart';

/// A photo already copied into the app's photo directory (EXIF stripped).
class StoredPhoto {
  const StoredPhoto({
    required this.relativePath,
    required this.width,
    required this.height,
    this.takenAt,
  });

  final String relativePath;
  final int width;
  final int height;
  final DateTime? takenAt;
}

class CatchRepository {
  CatchRepository(this._db, this._clock, this._ids);

  final AppDatabase _db;
  final Clock _clock;
  final IdGenerator _ids;

  /// Catches of a trip with their photos, newest first.
  Stream<List<Catch>> watchCatchesForTrip(String tripId) {
    final query =
        _db.select(_db.catches).join([
            leftOuterJoin(
              _db.catchPhotos,
              _db.catchPhotos.catchId.equalsExp(_db.catches.id) &
                  _db.catchPhotos.deletedAt.isNull(),
            ),
          ])
          ..where(
            _db.catches.tripId.equals(tripId) & _db.catches.deletedAt.isNull(),
          )
          ..orderBy([
            OrderingTerm.desc(_db.catches.caughtAt),
            OrderingTerm.asc(_db.catchPhotos.sortOrder),
          ]);
    return query.watch().map(_groupPhotos);
  }

  /// Every live catch of every trip (for records and statistics).
  Stream<List<Catch>> watchAll() {
    final query =
        _db.select(_db.catches).join([
            leftOuterJoin(
              _db.catchPhotos,
              _db.catchPhotos.catchId.equalsExp(_db.catches.id) &
                  _db.catchPhotos.deletedAt.isNull(),
            ),
          ])
          ..where(
            _db.catches.deletedAt.isNull() &
                _db.catches.tripId.isInQuery(
                  _db.selectOnly(_db.trips)
                    ..addColumns([_db.trips.id])
                    ..where(_db.trips.deletedAt.isNull()),
                ),
          )
          ..orderBy([
            OrderingTerm.asc(_db.catches.caughtAt),
            OrderingTerm.asc(_db.catchPhotos.sortOrder),
          ]);
    return query.watch().map(_groupPhotos);
  }

  Stream<Catch?> watchCatch(String id) =>
      _catchQuery(id).watch().map((rows) => _groupPhotos(rows).firstOrNull);

  Future<Catch?> getCatch(String id) async =>
      _groupPhotos(await _catchQuery(id).get()).firstOrNull;

  JoinedSelectStatement<HasResultSet, dynamic> _catchQuery(String id) =>
      _db.select(_db.catches).join([
          leftOuterJoin(
            _db.catchPhotos,
            _db.catchPhotos.catchId.equalsExp(_db.catches.id) &
                _db.catchPhotos.deletedAt.isNull(),
          ),
        ])
        ..where(_db.catches.id.equals(id) & _db.catches.deletedAt.isNull())
        ..orderBy([OrderingTerm.asc(_db.catchPhotos.sortOrder)]);

  List<Catch> _groupPhotos(List<TypedResult> rows) {
    final grouped = groupBy(
      rows,
      (TypedResult r) => r.readTable(_db.catches).id,
    );
    return [
      for (final group in grouped.values)
        group.first
            .readTable(_db.catches)
            .toModel(
              photos: [
                for (final r in group)
                  if (r.readTableOrNull(_db.catchPhotos) case final p?)
                    p.toModel(),
              ],
            ),
    ];
  }

  /// Quick capture: only the essentials. Everything else is optional and
  /// edited later with [updateDetails].
  Future<Catch> addCatch({
    required String tripId,
    String? speciesId,
    DateTime? caughtAt,
    StoredPhoto? photo,
    GeoPoint? location,
  }) {
    return _db.transaction(() async {
      final now = _clock.now();
      final id = _ids.newId();
      await _db
          .into(_db.catches)
          .insert(
            CatchesCompanion.insert(
              id: id,
              tripId: tripId,
              speciesId: Value(speciesId),
              caughtAt: (caughtAt ?? now).toUtc(),
              latitude: Value(location?.latitude),
              longitude: Value(location?.longitude),
              createdAt: now,
              updatedAt: now,
            ),
          );
      if (photo != null) await _insertPhoto(id, photo, now);
      return (await getCatch(id))!;
    });
  }

  Future<void> addPhoto(String catchId, StoredPhoto photo) async {
    await _insertPhoto(catchId, photo, _clock.now());
    await _touch(catchId);
  }

  Future<void> _insertPhoto(String catchId, StoredPhoto photo, DateTime now) {
    return _db
        .into(_db.catchPhotos)
        .insert(
          CatchPhotosCompanion.insert(
            id: _ids.newId(),
            catchId: catchId,
            relativePath: photo.relativePath,
            width: photo.width,
            height: photo.height,
            takenAt: Value(photo.takenAt?.toUtc()),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<void> removePhoto(String photoId) async {
    final now = _clock.now();
    await (_db.update(
      _db.catchPhotos,
    )..where((p) => p.id.equals(photoId))).write(
      CatchPhotosCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
        syncStatus: const Value(SyncStatus.pending),
      ),
    );
  }

  /// Replaces every optional field with the values in [details].
  Future<void> updateDetails(String id, CatchDetails details) async {
    await (_db.update(_db.catches)..where((c) => c.id.equals(id))).write(
      CatchesCompanion(
        speciesId: Value(details.speciesId),
        caughtAt: details.caughtAt == null
            ? const Value.absent()
            : Value(details.caughtAt!.toUtc()),
        weightG: Value(details.weightGrams),
        lengthMm: Value(details.lengthMillimeters),
        released: Value(details.released),
        baitId: Value(details.baitId),
        gearId: Value(details.gearId),
        depthMm: Value(details.depthMillimeters),
        notes: Value(details.notes),
        updatedAt: Value(_clock.now()),
        syncStatus: const Value(SyncStatus.pending),
      ),
    );
  }

  Future<void> deleteCatch(String id) {
    final now = Value(_clock.now());
    return _db.transaction(() async {
      await (_db.update(_db.catchPhotos)..where((p) => p.catchId.equals(id)))
          .write(CatchPhotosCompanion(deletedAt: now, updatedAt: now));
      await (_db.update(_db.catches)..where((c) => c.id.equals(id))).write(
        CatchesCompanion(deletedAt: now, updatedAt: now),
      );
    });
  }

  /// Brings back a catch deleted by mistake (the "Undo" after saving).
  Future<void> restoreCatch(String id) {
    final now = Value(_clock.now());
    return _db.transaction(() async {
      await (_db.update(
        _db.catchPhotos,
      )..where((p) => p.catchId.equals(id))).write(
        CatchPhotosCompanion(deletedAt: const Value(null), updatedAt: now),
      );
      await (_db.update(_db.catches)..where((c) => c.id.equals(id))).write(
        CatchesCompanion(deletedAt: const Value(null), updatedAt: now),
      );
    });
  }

  /// Catch count per species id, to list the species used most first.
  Stream<Map<String, int>> watchSpeciesUsage() {
    final count = _db.catches.id.count();
    final query = _db.selectOnly(_db.catches)
      ..addColumns([_db.catches.speciesId, count])
      ..where(
        _db.catches.deletedAt.isNull() & _db.catches.speciesId.isNotNull(),
      )
      ..groupBy([_db.catches.speciesId]);
    return query.watch().map(
      (rows) => {
        for (final r in rows) r.read(_db.catches.speciesId)!: r.read(count)!,
      },
    );
  }

  Future<void> _touch(String id) async {
    await (_db.update(_db.catches)..where((c) => c.id.equals(id))).write(
      CatchesCompanion(
        updatedAt: Value(_clock.now()),
        syncStatus: const Value(SyncStatus.pending),
      ),
    );
  }
}
