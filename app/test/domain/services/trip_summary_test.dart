import 'package:flutter_test/flutter_test.dart';
import 'package:piscatio/domain/models/catch.dart';
import 'package:piscatio/domain/models/enums.dart';
import 'package:piscatio/domain/models/trip.dart';
import 'package:piscatio/domain/services/moon.dart';
import 'package:piscatio/domain/services/trip_summary.dart';

final _t0 = DateTime.utc(2026, 9, 12, 6);

Trip _trip({DateTime? end}) => Trip(
  id: 't',
  startedAt: _t0,
  endedAt: end,
  timezone: 'UTC',
  privacyLevel: PrivacyLevel.private,
  moonPhase: MoonPhase.fullMoon,
  moonIllumination: 1,
  createdAt: _t0,
  updatedAt: _t0,
);

var _n = 0;
Catch _c({
  int minute = 0,
  String? species,
  int? g,
  int? mm,
  String? bait,
  bool? released,
}) => Catch(
  id: 'c${_n++}',
  tripId: 't',
  speciesId: species,
  caughtAt: _t0.add(Duration(minutes: minute)),
  weightGrams: g,
  lengthMillimeters: mm,
  baitId: bait,
  released: released,
  createdAt: _t0,
  updatedAt: _t0,
);

void main() {
  test('empty trip', () {
    final s = summarizeTrip(
      _trip(end: _t0.add(const Duration(hours: 2))),
      const [],
      _t0,
    );
    expect(s.duration, const Duration(hours: 2));
    expect(s.catchCount, 0);
    expect(s.speciesCount, 0);
    expect(s.biggest, isNull);
    expect(s.topBaitId, isNull);
  });

  test('active trip duration runs until now', () {
    final s = summarizeTrip(
      _trip(),
      const [],
      _t0.add(const Duration(minutes: 95)),
    );
    expect(s.duration, const Duration(minutes: 95));
  });

  test('counts catches, distinct identified species and releases', () {
    final s = summarizeTrip(_trip(), [
      _c(species: 'a', released: true),
      _c(species: 'a'),
      _c(species: 'b', released: false),
      _c(),
    ], _t0);
    expect(s.catchCount, 4);
    expect(s.speciesCount, 2);
    expect(s.releasedCount, 1);
  });

  test('biggest is the heaviest; earliest wins ties', () {
    final first = _c(minute: 10, g: 3000);
    final s = summarizeTrip(_trip(), [
      _c(minute: 5, g: 1200, mm: 900),
      _c(minute: 30, g: 3000),
      first,
    ], _t0);
    expect(s.biggest, first);
  });

  test('without weights, biggest is the longest', () {
    final long = _c(mm: 700);
    expect(biggestCatch([_c(mm: 400), long, _c()]), long);
    expect(biggestCatch([_c(), _c()]), isNull);
  });

  test('top bait is the one with most catches, first used on ties', () {
    final s = summarizeTrip(_trip(), [
      _c(minute: 1, bait: 'jig'),
      _c(minute: 2, bait: 'minhoca'),
      _c(minute: 3, bait: 'minhoca'),
      _c(minute: 4, bait: 'jig'),
      _c(minute: 5),
    ], _t0);
    expect(s.topBaitId, 'jig');

    final s2 = summarizeTrip(_trip(), [
      _c(minute: 1, bait: 'jig'),
      _c(minute: 2, bait: 'minhoca'),
      _c(minute: 3, bait: 'minhoca'),
    ], _t0);
    expect(s2.topBaitId, 'minhoca');
  });
}
