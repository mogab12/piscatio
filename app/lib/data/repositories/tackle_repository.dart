import 'package:drift/drift.dart';

import '../../core/clock.dart';
import '../../core/ids.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/tackle.dart';
import '../db/app_database.dart';
import 'mappers.dart';

/// Baits and gear: simple user-created lists.
class TackleRepository {
  TackleRepository(this._db, this._clock, this._ids);

  final AppDatabase _db;
  final Clock _clock;
  final IdGenerator _ids;

  Stream<List<Bait>> watchBaits({bool includeArchived = false}) {
    final query = _db.select(_db.baits)
      ..where(
        (b) =>
            b.deletedAt.isNull() &
            (includeArchived ? const Constant(true) : b.archived.not()),
      )
      ..orderBy([(b) => OrderingTerm.asc(b.name.collate(Collate.noCase))]);
    return query.watch().map((rows) => [for (final r in rows) r.toModel()]);
  }

  Stream<List<Gear>> watchGear({bool includeArchived = false}) {
    final query = _db.select(_db.gearItems)
      ..where(
        (g) =>
            g.deletedAt.isNull() &
            (includeArchived ? const Constant(true) : g.archived.not()),
      )
      ..orderBy([(g) => OrderingTerm.asc(g.name.collate(Collate.noCase))]);
    return query.watch().map((rows) => [for (final r in rows) r.toModel()]);
  }

  Future<Bait> addBait(String name, BaitType type) async {
    final now = _clock.now();
    final row = await _db
        .into(_db.baits)
        .insertReturning(
          BaitsCompanion.insert(
            id: _ids.newId(),
            name: _validName(name),
            type: type,
            createdAt: now,
            updatedAt: now,
          ),
        );
    return row.toModel();
  }

  Future<Gear> addGear(String name, GearType type) async {
    final now = _clock.now();
    final row = await _db
        .into(_db.gearItems)
        .insertReturning(
          GearItemsCompanion.insert(
            id: _ids.newId(),
            name: _validName(name),
            type: type,
            createdAt: now,
            updatedAt: now,
          ),
        );
    return row.toModel();
  }

  Future<void> renameBait(String id, String name) =>
      (_db.update(_db.baits)..where((b) => b.id.equals(id))).write(
        BaitsCompanion(
          name: Value(_validName(name)),
          updatedAt: Value(_clock.now()),
          syncStatus: const Value(SyncStatus.pending),
        ),
      );

  /// Archived baits leave the pickers but keep their catches' history.
  Future<void> setBaitArchived(String id, {required bool archived}) =>
      (_db.update(_db.baits)..where((b) => b.id.equals(id))).write(
        BaitsCompanion(
          archived: Value(archived),
          updatedAt: Value(_clock.now()),
          syncStatus: const Value(SyncStatus.pending),
        ),
      );

  Future<void> renameGear(String id, String name) =>
      (_db.update(_db.gearItems)..where((g) => g.id.equals(id))).write(
        GearItemsCompanion(
          name: Value(_validName(name)),
          updatedAt: Value(_clock.now()),
          syncStatus: const Value(SyncStatus.pending),
        ),
      );

  Future<void> setGearArchived(String id, {required bool archived}) =>
      (_db.update(_db.gearItems)..where((g) => g.id.equals(id))).write(
        GearItemsCompanion(
          archived: Value(archived),
          updatedAt: Value(_clock.now()),
          syncStatus: const Value(SyncStatus.pending),
        ),
      );

  static String _validName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw ArgumentError('Name is empty');
    return trimmed;
  }
}
