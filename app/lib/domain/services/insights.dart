import '../models/catch.dart';
import '../models/trip.dart';
import '../models/weather.dart';
import 'moon.dart';

/// "What worked": patterns in the person's own logbook. Always computed,
/// never stored.
///
/// Conditions are compared by catches per hour fished, not by raw counts:
/// someone who only fishes at dawn catches most fish at dawn, which says
/// nothing. Every pattern needs [minCatches] catches over [minTrips] trips
/// and must beat the average by [minLift].
const minCatches = 3;
const minTrips = 2;
const minLift = 1.25;

/// Moon phases in the four groups anglers talk about.
enum MoonGroup { newMoon, waxing, fullMoon, waning }

MoonGroup moonGroupOf(MoonPhase phase) => switch (phase) {
  MoonPhase.newMoon => MoonGroup.newMoon,
  MoonPhase.waxingCrescent ||
  MoonPhase.firstQuarter ||
  MoonPhase.waxingGibbous => MoonGroup.waxing,
  MoonPhase.fullMoon => MoonGroup.fullMoon,
  MoonPhase.waningGibbous ||
  MoonPhase.lastQuarter ||
  MoonPhase.waningCrescent => MoonGroup.waning,
};

enum PressureTrend { falling, steady, rising }

/// Same thresholds as the weather panel: more than 1 hPa in 3 hours.
PressureTrend? pressureTrendOf(double? change3hHpa) => switch (change3hHpa) {
  null => null,
  < -1 => PressureTrend.falling,
  > 1 => PressureTrend.rising,
  _ => PressureTrend.steady,
};

sealed class Insight {
  const Insight();
}

/// A condition (hours of the day, moon, pressure) when the fish came
/// faster than usual.
sealed class RateInsight extends Insight {
  const RateInsight({
    required this.rate,
    required this.average,
    required this.catches,
    required this.trips,
  });

  /// Catches per hour fished under the condition.
  final double rate;

  /// Catches per hour over all the fishing compared.
  final double average;
  final int catches;
  final int trips;
}

/// Three hours of the day, local time: [startHour] to [startHour] + 3.
class HoursInsight extends RateInsight {
  const HoursInsight({
    required this.startHour,
    required super.rate,
    required super.average,
    required super.catches,
    required super.trips,
  });

  final int startHour;

  int get endHour => (startHour + HoursInsight.span) % 24;

  static const span = 3;
}

class MoonInsight extends RateInsight {
  const MoonInsight({
    required this.group,
    required super.rate,
    required super.average,
    required super.catches,
    required super.trips,
  });

  final MoonGroup group;
}

class PressureInsight extends RateInsight {
  const PressureInsight({
    required this.trend,
    required super.rate,
    required super.average,
    required super.catches,
    required super.trips,
  });

  final PressureTrend trend;
}

/// The bait that took most of a species' catches.
class BaitInsight extends Insight {
  const BaitInsight({
    required this.speciesId,
    required this.baitId,
    required this.catches,
    required this.speciesCatches,
  });

  final String speciesId;
  final String baitId;

  /// Catches of the species with this bait.
  final int catches;

  /// Catches of the species with any recorded bait.
  final int speciesCatches;
}

int _localHour(DateTime utc) => utc.toLocal().hour;

/// Tallies of one condition: hours fished, catches and the trips behind
/// them.
class _Tally {
  double hours = 0;
  int catches = 0;
  final trips = <String>{};

  double get rate => hours <= 0 ? 0 : catches / hours;

  bool get enough =>
      catches >= minCatches && trips.length >= minTrips && hours >= 1;
}

/// The best condition if it clearly beats the average.
(K, _Tally)? _best<K>(Map<K, _Tally> tallies, double average) {
  if (average <= 0) return null;
  // Comparing needs fishing under at least two conditions.
  if (tallies.values.where((t) => t.hours > 0).length < 2) return null;
  (K, _Tally)? best;
  for (final MapEntry(:key, :value) in tallies.entries) {
    if (!value.enough) continue;
    if (best == null || value.rate > best.$2.rate) best = (key, value);
  }
  if (best == null || best.$2.rate < average * minLift) return null;
  return best;
}

/// Patterns in [trips] and their [catches]; [weather] by trip id. An
/// active trip counts up to [now]. [hourOf] maps a UTC instant to the hour
/// of day shown to the person (device time by default).
List<Insight> whatWorked({
  required List<Trip> trips,
  required List<Catch> catches,
  Map<String, TripWeather> weather = const {},
  required DateTime now,
  int Function(DateTime utc) hourOf = _localHour,
}) {
  final byId = {for (final t in trips) t.id: t};
  final live = [
    for (final c in catches)
      if (byId.containsKey(c.tripId)) c,
  ];
  if (live.length < minCatches) return const [];
  final hoursOf = {
    for (final t in trips) t.id: _clampHours(t.duration(now).inMinutes / 60),
  };
  final totalHours = hoursOf.values.fold(0.0, (a, b) => a + b);
  final average = totalHours <= 0 ? 0.0 : live.length / totalHours;

  return [
    ?_hours(trips, live, now, average, hourOf),
    ?_byTrip<MoonGroup>(
      trips,
      live,
      hoursOf,
      (t) => moonGroupOf(t.moonPhase),
      (group, t, average) => MoonInsight(
        group: group,
        rate: t.rate,
        average: average,
        catches: t.catches,
        trips: t.trips.length,
      ),
    ),
    ?_byTrip<PressureTrend>(
      trips,
      live,
      hoursOf,
      (t) => pressureTrendOf(weather[t.id]?.pressureTrend3hHpa),
      (trend, t, average) => PressureInsight(
        trend: trend,
        rate: t.rate,
        average: average,
        catches: t.catches,
        trips: t.trips.length,
      ),
    ),
    ..._baits(live),
  ];
}

/// A trip left running for weeks would drown every rate: count at most
/// two days of it.
double _clampHours(double h) => h.clamp(0, 48).toDouble();

/// The three hours of the day with the most catches per hour fished.
HoursInsight? _hours(
  List<Trip> trips,
  List<Catch> catches,
  DateTime now,
  double average,
  int Function(DateTime utc) hourOf,
) {
  // Effort per hour of the day, in quarter hours.
  final effort = List<double>.filled(24, 0);
  final tripsAt = List.generate(24, (_) => <String>{});
  const step = Duration(minutes: 15);
  for (final t in trips) {
    final end = t.endedAt ?? now;
    final last = t.startedAt.add(const Duration(hours: 48));
    for (
      var at = t.startedAt;
      at.isBefore(end) && at.isBefore(last);
      at = at.add(step)
    ) {
      effort[hourOf(at)] += 0.25;
    }
  }
  final caught = List<int>.filled(24, 0);
  for (final c in catches) {
    final h = hourOf(c.caughtAt);
    caught[h]++;
    tripsAt[h].add(c.tripId);
  }
  final windows = <int, _Tally>{};
  for (var start = 0; start < 24; start++) {
    // Only hours actually fished: "between 5 and 8" means nothing if no
    // one was out at 5.
    if (Iterable.generate(
      HoursInsight.span,
      (i) => effort[(start + i) % 24],
    ).any((e) => e == 0)) {
      continue;
    }
    final w = _Tally();
    for (var i = 0; i < HoursInsight.span; i++) {
      final h = (start + i) % 24;
      w
        ..hours += effort[h]
        ..catches += caught[h];
      w.trips.addAll(tripsAt[h]);
    }
    windows[start] = w;
  }
  final best = _best(windows, average);
  if (best == null) return null;
  return HoursInsight(
    startHour: best.$1,
    rate: best.$2.rate,
    average: average,
    catches: best.$2.catches,
    trips: best.$2.trips.length,
  );
}

/// A condition that holds for a whole trip (the moon, the pressure trend
/// when it started). Trips without the condition are left out of the
/// average too.
RateInsight? _byTrip<K>(
  List<Trip> trips,
  List<Catch> catches,
  Map<String, double> hoursOf,
  K? Function(Trip) conditionOf,
  RateInsight Function(K, _Tally, double average) make,
) {
  final tallies = <K, _Tally>{};
  final conditionOfTrip = <String, K>{};
  for (final t in trips) {
    final k = conditionOf(t);
    if (k == null) continue;
    conditionOfTrip[t.id] = k;
    (tallies[k] ??= _Tally()).hours += hoursOf[t.id]!;
  }
  for (final c in catches) {
    final k = conditionOfTrip[c.tripId];
    if (k == null) continue;
    tallies[k]!
      ..catches += 1
      ..trips.add(c.tripId);
  }
  final hours = tallies.values.fold(0.0, (a, t) => a + t.hours);
  final count = tallies.values.fold(0, (a, t) => a + t.catches);
  final average = hours <= 0 ? 0.0 : count / hours;
  final best = _best(tallies, average);
  return best == null ? null : make(best.$1, best.$2, average);
}

/// Per species, the bait behind at least half of its catches (with a
/// bait recorded). Most caught species first, at most three.
List<BaitInsight> _baits(List<Catch> catches) {
  final bySpecies = <String, List<Catch>>{};
  for (final c in catches) {
    if (c.speciesId == null || c.baitId == null) continue;
    (bySpecies[c.speciesId!] ??= []).add(c);
  }
  final out = <BaitInsight>[];
  for (final MapEntry(key: species, value: list) in bySpecies.entries) {
    if (list.length < minCatches) continue;
    final perBait = <String, List<Catch>>{};
    for (final c in list) {
      (perBait[c.baitId!] ??= []).add(c);
    }
    final top = perBait.entries.reduce(
      (a, b) => b.value.length > a.value.length ? b : a,
    );
    final n = top.value.length;
    final tripCount = {for (final c in top.value) c.tripId}.length;
    if (n < minCatches || tripCount < minTrips || n * 2 < list.length) {
      continue;
    }
    out.add(
      BaitInsight(
        speciesId: species,
        baitId: top.key,
        catches: n,
        speciesCatches: list.length,
      ),
    );
  }
  out.sort((a, b) => b.speciesCatches.compareTo(a.speciesCatches));
  return out.take(3).toList();
}
