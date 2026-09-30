import '../models/catch.dart';
import '../models/trip.dart';

/// A year of fishing, for "Year in review" and its card. Computed from the
/// logbook, never stored.
class YearSummary {
  const YearSummary({
    required this.year,
    required this.tripCount,
    required this.catchCount,
    required this.releasedCount,
    required this.daysFished,
    required this.timeFished,
    required this.species,
    required this.byMonth,
    required this.newSpecies,
    this.biggest,
    this.topBaitId,
    this.bestTripId,
    this.bestTripCatches = 0,
  });

  final int year;
  final int tripCount;
  final int catchCount;
  final int releasedCount;

  /// Distinct days with a trip (local dates).
  final int daysFished;
  final Duration timeFished;

  /// Species ids with their catch counts, most caught first.
  final List<(String, int)> species;

  /// Catches per month, January first.
  final List<int> byMonth;

  /// Species caught for the first time ever this year, in order.
  final List<String> newSpecies;

  /// The heaviest catch, or the longest when none was weighed.
  final Catch? biggest;
  final String? topBaitId;

  /// The trip with the most catches (the earliest on ties).
  final String? bestTripId;
  final int bestTripCatches;

  bool get isEmpty => tripCount == 0;
  int get speciesCount => species.length;
  String? get topSpeciesId => species.isEmpty ? null : species.first.$1;

  /// The month (1–12) with the most catches; null without catches.
  int? get bestMonth {
    var best = 0;
    var count = 0;
    for (var m = 0; m < 12; m++) {
      if (byMonth[m] > count) {
        best = m + 1;
        count = byMonth[m];
      }
    }
    return count == 0 ? null : best;
  }
}

DateTime _local(DateTime utc) => utc.toLocal();

const _maxTrip = Duration(hours: 48);

/// Most first; ties keep the order first seen.
List<(String, int)> _ranked(Iterable<String> keys) {
  final counts = <String, int>{};
  for (final k in keys) {
    counts[k] = (counts[k] ?? 0) + 1;
  }
  final order = counts.keys.toList();
  return [for (final k in order) (k, counts[k]!)]..sort((a, b) {
    final byCount = b.$2.compareTo(a.$2);
    return byCount != 0 ? byCount : order.indexOf(a.$1) - order.indexOf(b.$1);
  });
}

/// The years that have at least one trip, newest first.
List<int> fishingYears(List<Trip> trips, {DateTime Function(DateTime)? local}) {
  final toLocal = local ?? _local;
  return {for (final t in trips) toLocal(t.startedAt).year}.toList()
    ..sort((a, b) => b.compareTo(a));
}

/// Sums up [year]: its trips (by local start date) and their catches.
/// [allCatches] are every live catch of the logbook, to tell which species
/// were new that year. An active trip counts up to [now].
YearSummary yearSummary({
  required int year,
  required List<Trip> trips,
  required List<Catch> allCatches,
  required DateTime now,
  DateTime Function(DateTime utc)? local,
}) {
  final toLocal = local ?? _local;
  final ofYear = [
    for (final t in trips)
      if (toLocal(t.startedAt).year == year) t,
  ]..sort((a, b) => a.startedAt.compareTo(b.startedAt));
  final tripIds = {for (final t in ofYear) t.id};
  final chronological = [...allCatches]
    ..sort((a, b) {
      final t = a.caughtAt.compareTo(b.caughtAt);
      return t != 0 ? t : a.id.compareTo(b.id);
    });
  final catches = [
    for (final c in chronological)
      if (tripIds.contains(c.tripId)) c,
  ];

  var time = Duration.zero;
  final days = <(int, int)>{};
  for (final t in ofYear) {
    final d = t.duration(now);
    // A trip left running for weeks counts at most two days.
    if (!d.isNegative) time += d > _maxTrip ? _maxTrip : d;
    final start = toLocal(t.startedAt);
    days.add((start.month, start.day));
  }

  final byMonth = List<int>.filled(12, 0);
  for (final c in catches) {
    byMonth[toLocal(c.caughtAt).month - 1]++;
  }

  // First catch ever of each species: new if it is one of this year's.
  final firstOf = <String, Catch>{};
  for (final c in chronological) {
    if (c.speciesId != null) firstOf.putIfAbsent(c.speciesId!, () => c);
  }
  final newSpecies = [
    for (final MapEntry(key: species, value: first) in firstOf.entries)
      if (tripIds.contains(first.tripId)) species,
  ];

  Catch? biggest;
  for (final c in catches) {
    final w = c.weightGrams ?? 0;
    final best = biggest?.weightGrams ?? 0;
    if (w > best) biggest = c;
  }
  if (biggest == null) {
    for (final c in catches) {
      final l = c.lengthMillimeters ?? 0;
      if (l > (biggest?.lengthMillimeters ?? 0)) biggest = c;
    }
  }

  final perTrip = <String, int>{};
  for (final c in catches) {
    perTrip[c.tripId] = (perTrip[c.tripId] ?? 0) + 1;
  }
  String? bestTrip;
  var bestCount = 0;
  for (final t in ofYear) {
    final n = perTrip[t.id] ?? 0;
    if (n > bestCount) {
      bestTrip = t.id;
      bestCount = n;
    }
  }
  final baits = _ranked([for (final c in catches) ?c.baitId]);

  return YearSummary(
    year: year,
    tripCount: ofYear.length,
    catchCount: catches.length,
    releasedCount: catches.where((c) => c.released ?? false).length,
    daysFished: days.length,
    timeFished: time,
    species: _ranked([for (final c in catches) ?c.speciesId]),
    byMonth: byMonth,
    newSpecies: newSpecies,
    biggest: biggest,
    topBaitId: baits.isEmpty ? null : baits.first.$1,
    bestTripId: bestTrip,
    bestTripCatches: bestCount,
  );
}
