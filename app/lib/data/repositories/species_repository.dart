import 'package:collection/collection.dart';
import 'package:drift/drift.dart';

import '../../core/clock.dart';
import '../../core/ids.dart';
import '../../domain/models/species.dart';
import '../db/app_database.dart';
import 'mappers.dart';

class SpeciesRepository {
  SpeciesRepository(this._db, this._clock, this._ids);

  final AppDatabase _db;
  final Clock _clock;
  final IdGenerator _ids;

  /// Catalog plus the user's custom species, with every name.
  Stream<List<Species>> watchAll() {
    final query =
        _db.select(_db.speciesTable).join([
            leftOuterJoin(
              _db.speciesNames,
              _db.speciesNames.speciesId.equalsExp(_db.speciesTable.id),
            ),
          ])
          ..where(_db.speciesTable.deletedAt.isNull())
          ..orderBy([
            OrderingTerm.asc(_db.speciesTable.id),
            OrderingTerm.asc(_db.speciesNames.id),
          ]);
    return query.watch().map((rows) {
      final grouped = groupBy(
        rows,
        (TypedResult r) => r.readTable(_db.speciesTable).id,
      );
      return [
        for (final group in grouped.values)
          group.first.readTable(_db.speciesTable).toModel([
            for (final r in group)
              if (r.readTableOrNull(_db.speciesNames) case final n?) n,
          ]),
      ];
    });
  }

  Future<List<Species>> all() => watchAll().first;

  /// A species the catalog does not have, named by the user in [lang].
  Future<Species> addCustomSpecies(String name, {required String lang}) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw ArgumentError('Species name is empty');
    return _db.transaction(() async {
      final now = _clock.now();
      final id = _ids.newId();
      await _db
          .into(_db.speciesTable)
          .insert(
            SpeciesTableCompanion.insert(
              id: id,
              scientificName: trimmed,
              isCustom: const Value(true),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await _db
          .into(_db.speciesNames)
          .insert(
            SpeciesNamesCompanion.insert(
              speciesId: id,
              lang: lang,
              name: trimmed,
              isPrimary: const Value(true),
            ),
          );
      return (await all()).firstWhere((s) => s.id == id);
    });
  }
}
