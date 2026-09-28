import 'dart:convert';

import 'package:drift/drift.dart';

import '../db/app_database.dart';
import '../repositories/settings_repository.dart';

/// Everything the person logged, as JSON they can keep or take elsewhere.
/// Photos are listed by their relative path (the files stay on the phone).
/// The install's privacy secret is never included.
class LogbookExporter {
  LogbookExporter(this._db);

  final AppDatabase _db;

  /// Bumped when the file's shape changes.
  static const formatVersion = 1;

  static const _private = [
    SettingKeys.privacySecret,
    SettingKeys.speciesSeedVersion,
  ];

  Future<Map<String, Object?>> build(DateTime now) async {
    const s = ValueSerializer.defaults(serializeDateTimeValuesAsString: true);
    List<Map<String, dynamic>> rows(List<DataClass> r) => [
      for (final x in r) x.toJson(serializer: s),
    ];
    final trips =
        await (_db.select(_db.trips)
              ..where((t) => t.deletedAt.isNull())
              ..orderBy([(t) => OrderingTerm.asc(t.startedAt)]))
            .get();
    final catches =
        await (_db.select(_db.catches)
              ..where((c) => c.deletedAt.isNull())
              ..orderBy([(c) => OrderingTerm.asc(c.caughtAt)]))
            .get();
    final photos = await (_db.select(
      _db.catchPhotos,
    )..where((p) => p.deletedAt.isNull())).get();
    final baits = await (_db.select(
      _db.baits,
    )..where((b) => b.deletedAt.isNull())).get();
    final gear = await (_db.select(
      _db.gearItems,
    )..where((g) => g.deletedAt.isNull())).get();
    final custom = await (_db.select(
      _db.speciesTable,
    )..where((x) => x.isCustom & x.deletedAt.isNull())).get();
    final customNames = custom.isEmpty
        ? const <SpeciesNameRow>[]
        : await (_db.select(
                _db.speciesNames,
              )..where((n) => n.speciesId.isIn([for (final c in custom) c.id])))
              .get();
    final weather = await _db.select(_db.weatherSnapshots).get();
    final settings = await (_db.select(
      _db.settings,
    )..where((x) => x.key.isNotIn(_private))).get();
    return {
      'app': 'piscatio',
      'format': formatVersion,
      'exportedAt': now.toUtc().toIso8601String(),
      'trips': rows(trips),
      'catches': rows(catches),
      'photos': rows(photos),
      'baits': rows(baits),
      'gear': rows(gear),
      'customSpecies': rows(custom),
      'customSpeciesNames': rows(customNames),
      'weather': rows(weather),
      'settings': {for (final r in settings) r.key: r.value},
    };
  }

  Future<String> toJson(DateTime now) async =>
      const JsonEncoder.withIndent('  ').convert(await build(now));
}
