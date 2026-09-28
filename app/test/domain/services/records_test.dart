import 'package:flutter_test/flutter_test.dart';
import 'package:piscatio/domain/models/catch.dart';
import 'package:piscatio/domain/services/records.dart';

final _t0 = DateTime.utc(2026);

Catch _c(
  String id, {
  String? species = 'traira',
  int day = 0,
  int? g,
  int? mm,
}) => Catch(
  id: id,
  tripId: 't',
  speciesId: species,
  caughtAt: _t0.add(Duration(days: day)),
  weightGrams: g,
  lengthMillimeters: mm,
  createdAt: _t0,
  updatedAt: _t0,
);

void main() {
  group('recordStatus', () {
    test('first catch of a species is marked first, without %', () {
      final c = _c('a', g: 900);
      final s = recordStatus(c, [c]);
      expect(s.firstOfSpecies, isTrue);
      expect(s.isRecord, isFalse);
    });

    test('heavier than every earlier catch: record with improvement', () {
      final all = [
        _c('a', g: 1000),
        _c('b', day: 1, g: 1200),
        _c('c', day: 2, g: 1500),
      ];
      final s = recordStatus(all[2], all);
      expect(s.weight!.previous, 1200);
      expect(s.weight!.improvement, closeTo(0.25, 1e-9));
      expect(s.headline!.kind, RecordKind.weight);
    });

    test('equal to the best is not a record', () {
      final all = [_c('a', g: 1200), _c('b', day: 1, g: 1200)];
      expect(recordStatus(all[1], all).isRecord, isFalse);
    });

    test('only earlier catches count, even if logged later', () {
      // A past trip entered afterwards with a bigger fish does not take
      // the record away from a catch that was a record when it happened.
      final recent = _c('recent', day: 10, g: 2000);
      final older = _c('older', day: 5, g: 3000);
      final all = [recent, older];
      expect(recordStatus(older, all).firstOfSpecies, isTrue);
      expect(recordStatus(recent, all).isRecord, isFalse);
    });

    test('weight and length are independent records', () {
      final all = [
        _c('a', g: 2000, mm: 500),
        _c('b', day: 1, g: 1800, mm: 560),
      ];
      final s = recordStatus(all[1], all);
      expect(s.weight, isNull);
      expect(s.length!.previous, 500);
      expect(s.length!.improvement, closeTo(0.12, 1e-9));
      expect(s.headline!.kind, RecordKind.length);
    });

    test('first time a species is weighed: record without previous', () {
      final all = [_c('a', mm: 400), _c('b', day: 1, g: 900)];
      final s = recordStatus(all[1], all);
      expect(s.weight!.previous, isNull);
      expect(s.weight!.improvement, isNull);
    });

    test('other species and unidentified catches do not interfere', () {
      final all = [
        _c('a', species: 'dourado', g: 9000),
        _c('b', species: null, day: 1, g: 9000),
        _c('c', day: 2, g: 800),
      ];
      expect(recordStatus(all[2], all).firstOfSpecies, isTrue);
      expect(recordStatus(all[1], all), same(CatchRecordStatus.none));
    });

    test('same time: ties are broken by id, deterministically', () {
      final a = _c('a', g: 1000);
      final b = _c('b', g: 1100);
      expect(recordStatus(a, [a, b]).firstOfSpecies, isTrue);
      expect(recordStatus(b, [a, b]).weight!.previous, 1000);
    });
  });

  test('personalBests keeps the heaviest and longest per species', () {
    final bests = personalBests([
      _c('a', g: 1000, mm: 450),
      _c('b', day: 1, g: 1400, mm: 440),
      _c('c', day: 2, g: 1400, mm: 470),
      _c('d', species: 'dourado', day: 3, mm: 700),
      _c('e', species: null, g: 9999),
    ]);
    expect(bests.keys, unorderedEquals(['traira', 'dourado']));
    expect(bests['traira']!.heaviest!.id, 'b');
    expect(bests['traira']!.longest!.id, 'c');
    expect(bests['dourado']!.heaviest, isNull);
    expect(bests['dourado']!.longest!.id, 'd');
  });
}
