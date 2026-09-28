import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:piscatio/core/clock.dart';
import 'package:piscatio/core/ids.dart';
import 'package:piscatio/data/db/app_database.dart';
import 'package:piscatio/data/repositories/settings_repository.dart';
import 'package:piscatio/data/repositories/species_repository.dart';
import 'package:piscatio/data/seed/species_seeder.dart';
import 'package:piscatio/domain/models/species.dart';
import 'package:piscatio/domain/services/species_search.dart';

import '../helpers/test_db.dart';

void main() {
  late AppDatabase db;
  late SpeciesSeeder seeder;
  late SpeciesRepository species;

  setUp(() {
    db = newTestDatabase();
    final clock = FixedClock(DateTime.utc(2026));
    seeder = SpeciesSeeder(db, SettingsRepository(db), clock);
    species = SpeciesRepository(db, clock, SequentialIdGenerator());
  });
  tearDown(() => db.close());

  group('catalog content', () {
    final json = jsonDecode(readSpeciesSeed()) as Map<String, dynamic>;
    final entries = [
      for (final e in json['species'] as List<dynamic>)
        e as Map<String, dynamic>,
    ];

    test('has ~40 South American and ~20 North American species', () {
      final saOnly = entries.where((e) => (e['reg'] as List).first == 'SA');
      final naFirst = entries.where((e) => (e['reg'] as List).first == 'NA');
      expect(saOnly.length, inInclusiveRange(38, 50));
      expect(naFirst.length, inInclusiveRange(18, 25));
    });

    test('every species has names in pt, en and es', () {
      for (final e in entries) {
        for (final lang in ['pt', 'en', 'es']) {
          expect(e[lang], isNotEmpty, reason: '${e['id']} $lang');
        }
      }
    });

    test('ids are unique slugs of the scientific name', () {
      final ids = entries.map((e) => e['id']).toList();
      expect(ids.toSet().length, ids.length);
      for (final e in entries) {
        final slug = (e['sci'] as String).toLowerCase().replaceAll(' ', '-');
        expect(e['id'], slug);
      }
    });
  });

  test('applies the catalog once per seed version', () async {
    final seed = readSpeciesSeed();
    expect(await seeder.apply(seed), isTrue);
    expect(await seeder.apply(seed), isFalse);
    final all = await species.all();
    expect(all.length, greaterThanOrEqualTo(60));

    final traira = all.firstWhere((s) => s.id == 'hoplias-malabaricus');
    expect(traira.displayName('pt'), 'Traíra');
    expect(traira.displayName('es'), 'Tararira');
    expect(traira.displayName('en'), 'Trahira');
  });

  test('marks uncertain translations for review', () async {
    await seeder.apply(readSpeciesSeed());
    final walleye = (await species.all()).firstWhere(
      (s) => s.id == 'sander-vitreus',
    );
    expect(
      walleye.names.where((n) => n.lang == 'pt').every((n) => n.needsReview),
      isTrue,
    );
    expect(
      walleye.names.where((n) => n.lang == 'en').any((n) => n.needsReview),
      isFalse,
    );
  });

  test('a newer seed version updates names and keeps custom species', () async {
    await seeder.apply(readSpeciesSeed());
    await species.addCustomSpecies('Lambari-do-rabo-vermelho', lang: 'pt');

    final v2 = jsonEncode({
      'seed_version': 2,
      'species': [
        {
          'id': 'hoplias-malabaricus',
          'sci': 'Hoplias malabaricus',
          'hab': ['freshwater'],
          'reg': ['SA'],
          'pt': ['Traíra', 'Taraíra'],
          'en': ['Trahira'],
          'es': ['Tararira'],
          'review': <String>[],
        },
      ],
    });
    expect(await seeder.apply(v2), isTrue);
    final all = await species.all();
    final traira = all.firstWhere((s) => s.id == 'hoplias-malabaricus');
    expect(traira.names.map((n) => n.name), contains('Taraíra'));
    expect(all.where((s) => s.isCustom), hasLength(1));
  });

  test(
    'the seeded catalog is searchable by synonyms without accents',
    () async {
      await seeder.apply(readSpeciesSeed());
      final search = SpeciesSearch(await species.all());
      String top(String q) => search.search(q, lang: 'pt').first.species.id;
      expect(top('traira'), 'hoplias-malabaricus');
      expect(top('tararira'), 'hoplias-malabaricus');
      expect(top('paiche'), 'arapaima-gigas');
      expect(top('largemouth'), 'micropterus-salmoides');
      expect(top('salminus maxillosus'), 'salminus-brasiliensis');
      expect(top('surubi'), startsWith('pseudoplatystoma'));
    },
  );

  test('scientific synonyms are stored but never primary', () async {
    await seeder.apply(readSpeciesSeed());
    final dourado = (await species.all()).firstWhere(
      (s) => s.id == 'salminus-brasiliensis',
    );
    final synonym = dourado.names.firstWhere(
      (n) => n.lang == scientificSynonymLang,
    );
    expect(synonym.name, 'Salminus maxillosus');
    expect(synonym.isPrimary, isFalse);
  });
}
