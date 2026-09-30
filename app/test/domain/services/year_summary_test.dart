import 'package:flutter_test/flutter_test.dart';
import 'package:piscatio/domain/models/catch.dart';
import 'package:piscatio/domain/models/enums.dart';
import 'package:piscatio/domain/models/trip.dart';
import 'package:piscatio/domain/services/moon.dart';
import 'package:piscatio/domain/services/year_summary.dart';

final _t0 = DateTime.utc(2025);

Trip _trip(String id, DateTime start, {int hours = 4}) => Trip(
  id: id,
  startedAt: start,
  endedAt: start.add(Duration(hours: hours)),
  timezone: 'UTC',
  privacyLevel: PrivacyLevel.private,
  moonPhase: MoonPhase.fullMoon,
  moonIllumination: 1,
  createdAt: _t0,
  updatedAt: _t0,
);

var _n = 0;

Catch _c(
  Trip trip, {
  String? species = 'salminus-brasiliensis',
  int? grams,
  int? mm,
  bool? released,
  String? bait,
  int afterHours = 1,
}) => Catch(
  id: 'c${_n++}',
  tripId: trip.id,
  speciesId: species,
  caughtAt: trip.startedAt.add(Duration(hours: afterHours)),
  weightGrams: grams,
  lengthMillimeters: mm,
  released: released,
  baitId: bait,
  createdAt: _t0,
  updatedAt: _t0,
);

YearSummary _run(int year, List<Trip> trips, List<Catch> catches) =>
    yearSummary(
      year: year,
      trips: trips,
      allCatches: catches,
      now: DateTime.utc(2026, 12, 31),
      local: (utc) => utc,
    );

void main() {
  final old = _trip('old', DateTime.utc(2025, 11, 2, 6));
  final jan = _trip('jan', DateTime.utc(2026, 1, 10, 6));
  final janAgain = _trip('jan2', DateTime.utc(2026, 1, 10, 15), hours: 2);
  final sep = _trip('sep', DateTime.utc(2026, 9, 12, 5), hours: 6);
  final catches = [
    _c(old, species: 'hoplias-malabaricus', grams: 9000),
    _c(jan, grams: 4200, released: true, bait: 'tuvira'),
    _c(jan, species: 'hoplias-malabaricus', grams: 1300, bait: 'jig'),
    _c(janAgain, species: null),
    _c(sep, grams: 3100, released: true, bait: 'tuvira'),
    _c(sep, species: 'cichla-ocellaris', mm: 520, bait: 'tuvira'),
  ];

  test('only the trips of the year and their catches', () {
    final y = _run(2026, [old, jan, janAgain, sep], catches);
    expect(y.tripCount, 3);
    expect(y.catchCount, 5);
    expect(y.releasedCount, 2);
    // Two trips on the same day are one day fished.
    expect(y.daysFished, 2);
    expect(y.timeFished, const Duration(hours: 12));
    expect(y.species, [
      ('salminus-brasiliensis', 2),
      ('hoplias-malabaricus', 1),
      ('cichla-ocellaris', 1),
    ]);
    expect(y.topSpeciesId, 'salminus-brasiliensis');
    expect(y.byMonth[0], 3);
    expect(y.byMonth[8], 2);
    expect(y.bestMonth, 1);
    expect(y.topBaitId, 'tuvira');
    expect(y.bestTripId, 'jan');
    expect(y.bestTripCatches, 2);
  });

  test('new species are those caught for the first time that year', () {
    final y = _run(2026, [old, jan, janAgain, sep], catches);
    // Traíra was first caught in 2025.
    expect(y.newSpecies, ['salminus-brasiliensis', 'cichla-ocellaris']);
  });

  test('the biggest is the heaviest, else the longest', () {
    expect(
      _run(2026, [old, jan, janAgain, sep], catches).biggest!.weightGrams,
      4200,
    );
    final unweighed = [_c(sep, mm: 400), _c(sep, mm: 610)];
    expect(_run(2026, [sep], unweighed).biggest!.lengthMillimeters, 610);
  });

  test('a year without trips is empty', () {
    final y = _run(2024, [old, jan], catches);
    expect(y.isEmpty, isTrue);
    expect(y.bestMonth, isNull);
    expect(y.biggest, isNull);
  });

  test('years with trips, newest first', () {
    expect(fishingYears([old, jan, sep], local: (u) => u), [2026, 2025]);
  });
}
