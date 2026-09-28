import 'package:flutter_test/flutter_test.dart';
import 'package:piscatio/domain/models/catch.dart';
import 'package:piscatio/domain/models/enums.dart';
import 'package:piscatio/domain/models/trip.dart';
import 'package:piscatio/domain/services/logbook_stats.dart';
import 'package:piscatio/domain/services/moon.dart';

final _t0 = DateTime.utc(2026, 9);

Trip _trip(String id, {int day = 0, int hours = 2, bool active = false}) {
  final start = _t0.add(Duration(days: day, hours: 6));
  return Trip(
    id: id,
    startedAt: start,
    endedAt: active ? null : start.add(Duration(hours: hours)),
    timezone: 'UTC',
    privacyLevel: PrivacyLevel.private,
    moonPhase: MoonPhase.newMoon,
    moonIllumination: 0,
    createdAt: _t0,
    updatedAt: _t0,
  );
}

Catch _c(
  String id,
  String trip, {
  int day = 0,
  int hour = 6,
  String? species = 'traira',
  String? bait,
  bool? released,
}) => Catch(
  id: id,
  tripId: trip,
  speciesId: species,
  caughtAt: _t0.add(Duration(days: day, hours: hour)),
  baitId: bait,
  released: released,
  createdAt: _t0,
  updatedAt: _t0,
);

int _utcHour(DateTime utc) => utc.hour;

void main() {
  test('empty logbook', () {
    final s = logbookStats(const [], const [], _t0);
    expect(s.isEmpty, isTrue);
    expect(s.byHour, hasLength(24));
    expect(s.peakHour, isNull);
    expect(s.catchesPerHour, 0);
  });

  test('totals, rankings, hours and the best trip', () {
    final trips = [
      _trip('a'),
      _trip('b', day: 3, hours: 4),
      _trip('c', day: 5, active: true),
    ];
    final catches = [
      _c('1', 'a', bait: 'minhoca', released: true),
      _c('2', 'b', day: 3, hour: 7, species: 'dourado', bait: 'tuvira'),
      _c('3', 'b', day: 3, hour: 7, species: 'dourado', bait: 'tuvira'),
      _c('4', 'b', day: 3, hour: 8, species: null, bait: 'minhoca'),
      _c('5', 'c', day: 5, hour: 7, bait: 'tuvira', released: true),
    ];
    final now = _t0.add(const Duration(days: 5, hours: 7));
    final s = logbookStats(trips, catches, now, hourOf: _utcHour);
    expect(s.tripCount, 3);
    expect(s.catchCount, 5);
    // 2 h + 4 h + 1 h of the running trip.
    expect(s.timeFished, const Duration(hours: 7));
    expect(s.speciesCount, 2);
    expect(s.releasedCount, 2);
    // Ties keep the first seen: traíra was caught before dourado.
    expect(s.species, [('traira', 2), ('dourado', 2)]);
    expect(s.baits, [('tuvira', 3), ('minhoca', 2)]);
    expect(s.byHour[7], 3);
    expect(s.peakHour, 7);
    expect(s.bestTripId, 'b');
    expect(s.bestTripCatches, 3);
    expect(s.catchesPerHour, closeTo(5 / 7, 1e-9));
  });
}
