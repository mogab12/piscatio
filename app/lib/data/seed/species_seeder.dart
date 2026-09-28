import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/clock.dart';
import '../../domain/models/species.dart';
import '../db/app_database.dart';
import '../repositories/settings_repository.dart';

/// Loads `assets/seed/species.json` into the database when its
/// `seed_version` is newer than the one already applied. Catalog rows are
/// upserted and their names replaced; custom species are never touched.
class SpeciesSeeder {
  SpeciesSeeder(this._db, this._settings, this._clock);

  final AppDatabase _db;
  final SettingsRepository _settings;
  final Clock _clock;

  /// Returns true when the catalog was (re)applied.
  Future<bool> apply(String json) async {
    final data = jsonDecode(json) as Map<String, dynamic>;
    final version = data['seed_version'] as int;
    final applied = int.tryParse(
      await _settings.getRaw(SettingKeys.speciesSeedVersion) ?? '',
    );
    if (applied != null && applied >= version) return false;

    final entries = [
      for (final e in data['species'] as List<dynamic>)
        e as Map<String, dynamic>,
    ];
    final now = _clock.now();
    await _db.transaction(() async {
      await _db.batch((b) {
        for (final e in entries) {
          final id = e['id'] as String;
          b.insert(
            _db.speciesTable,
            SpeciesTableCompanion.insert(
              id: id,
              scientificName: e['sci'] as String,
              habitats: Value([
                for (final h in e['hab'] as List<dynamic>)
                  Habitat.values.byName(h as String),
              ]),
              regionTags: Value([
                for (final r in e['reg'] as List<dynamic>) r as String,
              ]),
              createdAt: now,
              updatedAt: now,
            ),
            onConflict: DoUpdate(
              (old) => SpeciesTableCompanion(
                scientificName: Value(e['sci'] as String),
                habitats: Value([
                  for (final h in e['hab'] as List<dynamic>)
                    Habitat.values.byName(h as String),
                ]),
                regionTags: Value([
                  for (final r in e['reg'] as List<dynamic>) r as String,
                ]),
                deletedAt: const Value(null),
                updatedAt: Value(now),
              ),
            ),
          );
          b.deleteWhere(_db.speciesNames, (n) => n.speciesId.equals(id));
          final review = {
            for (final l in e['review'] as List<dynamic>? ?? const []) l,
          };
          for (final lang in const ['pt', 'en', 'es', scientificSynonymLang]) {
            final names = e[lang] as List<dynamic>? ?? const [];
            for (var i = 0; i < names.length; i++) {
              b.insert(
                _db.speciesNames,
                SpeciesNamesCompanion.insert(
                  speciesId: id,
                  lang: lang,
                  name: names[i] as String,
                  isPrimary: Value(i == 0 && lang != scientificSynonymLang),
                  needsReview: Value(review.contains(lang)),
                ),
              );
            }
          }
        }
      });
      await _settings.setRaw(SettingKeys.speciesSeedVersion, '$version');
    });
    return true;
  }
}
