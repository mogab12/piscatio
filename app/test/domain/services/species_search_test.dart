import 'package:flutter_test/flutter_test.dart';
import 'package:piscatio/domain/models/species.dart';
import 'package:piscatio/domain/services/species_search.dart';
import 'package:piscatio/domain/services/text_normalizer.dart';

const _traira = Species(
  id: 'hoplias-malabaricus',
  scientificName: 'Hoplias malabaricus',
  names: [
    SpeciesName(lang: 'pt', name: 'Traíra', isPrimary: true),
    SpeciesName(lang: 'en', name: 'Trahira', isPrimary: true),
    SpeciesName(lang: 'en', name: 'Wolf fish'),
    SpeciesName(lang: 'es', name: 'Tararira', isPrimary: true, region: 'AR'),
    SpeciesName(lang: 'es', name: 'Dientudo', region: 'UY'),
  ],
);

const _dourado = Species(
  id: 'salminus-brasiliensis',
  scientificName: 'Salminus brasiliensis',
  names: [
    SpeciesName(lang: 'pt', name: 'Dourado', isPrimary: true),
    SpeciesName(lang: 'en', name: 'Golden dorado', isPrimary: true),
    SpeciesName(lang: 'es', name: 'Dorado', isPrimary: true),
    SpeciesName(lang: scientificSynonymLang, name: 'Salminus maxillosus'),
  ],
);

const _tucunare = Species(
  id: 'cichla-ocellaris',
  scientificName: 'Cichla ocellaris',
  names: [
    SpeciesName(lang: 'pt', name: 'Tucunaré-açu', isPrimary: true),
    SpeciesName(lang: 'pt', name: 'Tucunaré'),
    SpeciesName(lang: 'en', name: 'Butterfly peacock bass', isPrimary: true),
    SpeciesName(lang: 'es', name: 'Pavón mariposa', isPrimary: true),
  ],
);

const _largemouth = Species(
  id: 'micropterus-salmoides',
  scientificName: 'Micropterus salmoides',
  names: [
    SpeciesName(lang: 'pt', name: 'Black bass', isPrimary: true),
    SpeciesName(lang: 'en', name: 'Largemouth bass', isPrimary: true),
    SpeciesName(lang: 'es', name: 'Lobina negra', isPrimary: true),
  ],
);

void main() {
  final search = SpeciesSearch([_traira, _dourado, _tucunare, _largemouth]);
  List<String> ids(String q, {String lang = 'pt', Map<String, int>? usage}) =>
      search
          .search(q, lang: lang, usage: usage ?? const {})
          .map((m) => m.species.id)
          .toList();

  group('normalizeForSearch', () {
    test('folds accents, case and punctuation', () {
      expect(normalizeForSearch('  Tucunaré-Açu '), 'tucunare acu');
      expect(normalizeForSearch('PAVÓN'), 'pavon');
      expect(normalizeForSearch('Ñandú'), 'nandu');
    });
  });

  test('regional synonyms in any language find the same species', () {
    for (final q in ['traira', 'TRAÍRA', 'trahira', 'tararira', 'dientudo']) {
      expect(ids(q).first, 'hoplias-malabaricus', reason: q);
    }
  });

  test('accents are optional in both directions', () {
    expect(ids('tucunare').first, 'cichla-ocellaris');
    expect(ids('pavon').first, 'cichla-ocellaris');
    expect(ids('tucunaré acu').first, 'cichla-ocellaris');
  });

  test('scientific names and old synonyms match', () {
    expect(ids('hoplias').first, 'hoplias-malabaricus');
    expect(ids('salminus maxillosus').first, 'salminus-brasiliensis');
  });

  test('matches any word prefix, e.g. "bass"', () {
    expect(
      ids('bass'),
      containsAll(['micropterus-salmoides', 'cichla-ocellaris']),
    );
    expect(ids('peacock bass').first, 'cichla-ocellaris');
  });

  test('reports which name matched', () {
    final m = search.search('tararira', lang: 'pt').first;
    expect(m.matchedName, 'Tararira');
  });

  test('no match returns empty', () {
    expect(ids('zzz'), isEmpty);
  });

  test('prefers names in the user language on equal matches', () {
    // "dorado" is a Spanish primary name; "Golden dorado" only contains it.
    expect(ids('dorado', lang: 'es').first, 'salminus-brasiliensis');
  });

  test('empty query lists most used species first, then by name', () {
    expect(
      ids('', usage: {'micropterus-salmoides': 3, 'hoplias-malabaricus': 9}),
      [
        'hoplias-malabaricus',
        'micropterus-salmoides',
        'salminus-brasiliensis', // Dourado
        'cichla-ocellaris', // Tucunaré-açu
      ],
    );
  });

  test('usage breaks ties between equally good matches', () {
    final both = ids('bass', usage: {'micropterus-salmoides': 10});
    expect(both.first, 'micropterus-salmoides');
  });

  test('displayName falls back to English, then scientific name', () {
    expect(_traira.displayName('pt'), 'Traíra');
    expect(_traira.displayName('fr'), 'Trahira');
    expect(
      const Species(id: 'x', scientificName: 'Xus yus').displayName('pt'),
      'Xus yus',
    );
  });
}
