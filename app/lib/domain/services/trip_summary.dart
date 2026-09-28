import 'package:collection/collection.dart';

import '../models/catch.dart';
import '../models/trip.dart';

class TripSummary {
  const TripSummary({
    required this.duration,
    required this.catchCount,
    required this.speciesCount,
    required this.releasedCount,
    this.biggest,
    this.topBaitId,
  });

  final Duration duration;
  final int catchCount;

  /// Distinct identified species.
  final int speciesCount;
  final int releasedCount;

  /// Heaviest catch; if none was weighed, the longest one.
  final Catch? biggest;

  /// Bait with the most catches (ties: the one used first).
  final String? topBaitId;
}

TripSummary summarizeTrip(Trip trip, List<Catch> catches, DateTime now) {
  final byTime = catches.sortedBy((c) => c.caughtAt);
  return TripSummary(
    duration: trip.duration(now),
    catchCount: catches.length,
    speciesCount: catches.map((c) => c.speciesId).nonNulls.toSet().length,
    releasedCount: catches.where((c) => c.released ?? false).length,
    biggest: biggestCatch(byTime),
    topBaitId: _topBait(byTime),
  );
}

/// Heaviest catch, else longest; earliest wins ties. Null if nothing was
/// measured.
Catch? biggestCatch(List<Catch> catches) {
  final byTime = catches.sortedBy((c) => c.caughtAt);
  Catch? best(int? Function(Catch) measure) {
    Catch? winner;
    for (final c in byTime) {
      final v = measure(c);
      if (v == null) continue;
      if (winner == null || v > measure(winner)!) winner = c;
    }
    return winner;
  }

  return best((c) => c.weightGrams) ?? best((c) => c.lengthMillimeters);
}

String? _topBait(List<Catch> byTime) {
  final counts = <String, int>{};
  for (final c in byTime) {
    if (c.baitId != null) counts[c.baitId!] = (counts[c.baitId!] ?? 0) + 1;
  }
  if (counts.isEmpty) return null;
  // Map iteration follows insertion (first use), so ties keep the earliest.
  var top = counts.entries.first;
  for (final e in counts.entries) {
    if (e.value > top.value) top = e;
  }
  return top.key;
}
