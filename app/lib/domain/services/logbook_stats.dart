import '../models/catch.dart';
import '../models/trip.dart';

/// Numbers for the whole logbook. Always computed from trips and catches,
/// never stored.
class LogbookStats {
  const LogbookStats({
    required this.tripCount,
    required this.catchCount,
    required this.timeFished,
    required this.speciesCount,
    required this.releasedCount,
    required this.species,
    required this.baits,
    required this.byHour,
    this.bestTripId,
    this.bestTripCatches = 0,
  });

  static const empty = LogbookStats(
    tripCount: 0,
    catchCount: 0,
    timeFished: Duration.zero,
    speciesCount: 0,
    releasedCount: 0,
    species: [],
    baits: [],
    byHour: [
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
    ],
  );

  final int tripCount;
  final int catchCount;
  final Duration timeFished;

  /// Distinct identified species.
  final int speciesCount;
  final int releasedCount;

  /// Species ids with their catch counts, most caught first.
  final List<(String, int)> species;

  /// Bait ids with their catch counts, most productive first.
  final List<(String, int)> baits;

  /// Catches per hour of the day (24 buckets, local time).
  final List<int> byHour;

  /// The trip with the most catches (the earliest on ties).
  final String? bestTripId;
  final int bestTripCatches;

  bool get isEmpty => tripCount == 0;

  /// Catches per hour actually fished.
  double get catchesPerHour {
    final hours = timeFished.inMinutes / 60;
    return hours <= 0 ? 0 : catchCount / hours;
  }

  /// The hour of day with the most catches; null without catches.
  int? get peakHour => peakOf(byHour);

  /// Index of the largest bucket (the earliest on ties); null if all zero.
  static int? peakOf(List<int> buckets) {
    var best = -1;
    var bestCount = 0;
    for (var h = 0; h < buckets.length; h++) {
      if (buckets[h] > bestCount) {
        best = h;
        bestCount = buckets[h];
      }
    }
    return best < 0 ? null : best;
  }
}

int _localHour(DateTime utc) => utc.toLocal().hour;

/// Ranks keys by count, most first; ties keep first-seen order.
List<(String, int)> _ranked(Iterable<String> keys) {
  final counts = <String, int>{};
  for (final k in keys) {
    counts[k] = (counts[k] ?? 0) + 1;
  }
  final order = counts.keys.toList();
  final entries = [for (final (i, k) in order.indexed) (k, counts[k]!, i)]
    ..sort((a, b) {
      final byCount = b.$2.compareTo(a.$2);
      return byCount != 0 ? byCount : a.$3.compareTo(b.$3);
    });
  return [for (final e in entries) (e.$1, e.$2)];
}

/// Summarizes the logbook. [catches] should be the live catches of live
/// [trips]; an active trip counts up to [now]. [hourOf] maps a UTC instant
/// to the hour of day shown to the person (device time by default).
LogbookStats logbookStats(
  List<Trip> trips,
  List<Catch> catches,
  DateTime now, {
  int Function(DateTime utc) hourOf = _localHour,
}) {
  if (trips.isEmpty) return LogbookStats.empty;
  final chronological = [...catches]
    ..sort((a, b) {
      final t = a.caughtAt.compareTo(b.caughtAt);
      return t != 0 ? t : a.id.compareTo(b.id);
    });
  var time = Duration.zero;
  for (final t in trips) {
    final d = t.duration(now);
    if (!d.isNegative) time += d;
  }
  final byHour = List<int>.filled(24, 0);
  for (final c in chronological) {
    byHour[hourOf(c.caughtAt)]++;
  }
  final perTrip = <String, int>{};
  for (final c in chronological) {
    perTrip[c.tripId] = (perTrip[c.tripId] ?? 0) + 1;
  }
  String? bestTrip;
  var bestCount = 0;
  final byStart = [...trips]
    ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
  for (final t in byStart) {
    final n = perTrip[t.id] ?? 0;
    if (n > bestCount) {
      bestTrip = t.id;
      bestCount = n;
    }
  }
  final species = _ranked([for (final c in chronological) ?c.speciesId]);
  return LogbookStats(
    tripCount: trips.length,
    catchCount: chronological.length,
    timeFished: time,
    speciesCount: species.length,
    releasedCount: chronological.where((c) => c.released ?? false).length,
    species: species,
    baits: _ranked([for (final c in chronological) ?c.baitId]),
    byHour: byHour,
    bestTripId: bestTrip,
    bestTripCatches: bestCount,
  );
}
