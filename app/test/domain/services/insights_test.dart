import 'package:flutter_test/flutter_test.dart';
import 'package:piscatio/domain/models/catch.dart';
import 'package:piscatio/domain/models/enums.dart';
import 'package:piscatio/domain/models/trip.dart';
import 'package:piscatio/domain/models/weather.dart';
import 'package:piscatio/domain/services/insights.dart';
import 'package:piscatio/domain/services/moon.dart';

final _t0 = DateTime.utc(2026, 9);

/// A trip on [day], from [from] to [to] o'clock (UTC stands for local).
Trip _trip(
  String id, {
  required int day,
  int from = 6,
  int to = 12,
  MoonPhase moon = MoonPhase.firstQuarter,
}) => Trip(
  id: id,
  startedAt: _t0.add(Duration(days: day, hours: from)),
  endedAt: _t0.add(Duration(days: day, hours: to)),
  timezone: 'UTC',
  privacyLevel: PrivacyLevel.private,
  moonPhase: moon,
  moonIllumination: 0.5,
  createdAt: _t0,
  updatedAt: _t0,
);

var _n = 0;

Catch _c(
  Trip trip, {
  required int hour,
  String? species = 'salminus-brasiliensis',
  String? bait,
}) => Catch(
  id: 'c${_n++}',
  tripId: trip.id,
  speciesId: species,
  caughtAt: DateTime.utc(
    trip.startedAt.year,
    trip.startedAt.month,
    trip.startedAt.day,
    hour,
    20,
  ),
  baitId: bait,
  createdAt: _t0,
  updatedAt: _t0,
);

List<Insight> _run(
  List<Trip> trips,
  List<Catch> catches, {
  Map<String, TripWeather> weather = const {},
}) => whatWorked(
  trips: trips,
  catches: catches,
  weather: weather,
  now: _t0.add(const Duration(days: 60)),
  hourOf: (utc) => utc.hour,
);

TripWeather _trend(String tripId, double change) => TripWeather(
  tripId: tripId,
  status: WeatherStatus.ok,
  temperatureC: 25,
  pressureTrend3hHpa: change,
);

void main() {
  test('nothing to say with fewer than three catches', () {
    final a = _trip('a', day: 0);
    expect(_run([a], [_c(a, hour: 6), _c(a, hour: 7)]), isEmpty);
  });

  test('the hours when fish came faster, over several trips', () {
    // Two mornings (6–12): catches bunch up between 6 and 9.
    final a = _trip('a', day: 0);
    final b = _trip('b', day: 1);
    final insights = _run(
      [a, b],
      [
        _c(a, hour: 6),
        _c(a, hour: 7),
        _c(b, hour: 6),
        _c(b, hour: 8),
        _c(b, hour: 11),
      ],
    );
    final hours = insights.whereType<HoursInsight>().single;
    expect(hours.startHour, 6);
    expect(hours.endHour, 9);
    expect(hours.catches, 4);
    expect(hours.trips, 2);
    // 4 catches in 6 hours fished, against 5 in 12.
    expect(hours.rate, closeTo(4 / 6, 1e-9));
    expect(hours.average, closeTo(5 / 12, 1e-9));
  });

  test('fishing only at dawn does not make dawn "the best hours"', () {
    // Every hour fished produced the same: no window beats the average.
    final a = _trip('a', day: 0, from: 5, to: 8);
    final b = _trip('b', day: 1, from: 5, to: 8);
    final insights = _run(
      [a, b],
      [
        _c(a, hour: 5),
        _c(a, hour: 6),
        _c(a, hour: 7),
        _c(b, hour: 5),
        _c(b, hour: 6),
        _c(b, hour: 7),
      ],
    );
    expect(insights.whereType<HoursInsight>(), isEmpty);
  });

  test('one lucky trip is not a pattern', () {
    final a = _trip('a', day: 0);
    final b = _trip('b', day: 1);
    final insights = _run(
      [a, b],
      [_c(a, hour: 6), _c(a, hour: 6), _c(a, hour: 7), _c(a, hour: 7)],
    );
    expect(insights.whereType<HoursInsight>(), isEmpty);
  });

  test('the moon when the person catches more per hour', () {
    final full1 = _trip('f1', day: 0, moon: MoonPhase.fullMoon);
    final full2 = _trip('f2', day: 30, moon: MoonPhase.fullMoon);
    final waning = _trip('w', day: 7, moon: MoonPhase.lastQuarter);
    final waxing = _trip('x', day: 21, moon: MoonPhase.waxingGibbous);
    final insights = _run(
      [full1, full2, waning, waxing],
      [
        _c(full1, hour: 6),
        _c(full1, hour: 10),
        _c(full2, hour: 7),
        _c(full2, hour: 11),
        _c(waning, hour: 8),
        _c(waxing, hour: 9),
      ],
    );
    final moon = insights.whereType<MoonInsight>().single;
    expect(moon.group, MoonGroup.fullMoon);
    expect(moon.catches, 4);
    expect(moon.trips, 2);
    expect(moon.rate, closeTo(4 / 12, 1e-9));
    expect(moon.average, closeTo(6 / 24, 1e-9));
  });

  test('pressure trend only compares trips with weather', () {
    final a = _trip('a', day: 0);
    final b = _trip('b', day: 3);
    final c = _trip('c', day: 6);
    final d = _trip('d', day: 9);
    final insights = _run(
      [a, b, c, d],
      [
        _c(a, hour: 6),
        _c(a, hour: 9),
        _c(b, hour: 7),
        _c(b, hour: 10),
        // Trip c (steady) caught nothing. Trip d has no weather: its catches do not count.
        _c(d, hour: 6),
        _c(d, hour: 7),
        _c(d, hour: 8),
        _c(d, hour: 9),
      ],
      weather: {
        'a': _trend('a', -2.5),
        'b': _trend('b', -1.4),
        'c': _trend('c', 0.3),
      },
    );
    final pressure = insights.whereType<PressureInsight>().single;
    expect(pressure.trend, PressureTrend.falling);
    expect(pressure.catches, 4);
    expect(pressure.rate, closeTo(4 / 12, 1e-9));
    expect(pressure.average, closeTo(4 / 18, 1e-9));
  });

  test('the bait behind most catches of a species', () {
    final a = _trip('a', day: 0);
    final b = _trip('b', day: 1);
    final insights = _run(
      [a, b],
      [
        _c(a, hour: 6, bait: 'tuvira'),
        _c(a, hour: 7, bait: 'tuvira'),
        _c(b, hour: 8, bait: 'tuvira'),
        _c(b, hour: 9, bait: 'jig'),
        // Another species, too few catches.
        _c(a, hour: 10, species: 'hoplias-malabaricus', bait: 'jig'),
        _c(b, hour: 11, species: 'hoplias-malabaricus', bait: 'jig'),
      ],
    );
    final bait = insights.whereType<BaitInsight>().single;
    expect(bait.speciesId, 'salminus-brasiliensis');
    expect(bait.baitId, 'tuvira');
    expect(bait.catches, 3);
    expect(bait.speciesCatches, 4);
  });

  test('a bait with less than half the catches is no pattern', () {
    final a = _trip('a', day: 0);
    final b = _trip('b', day: 1);
    final insights = _run(
      [a, b],
      [
        _c(a, hour: 6, bait: 'tuvira'),
        _c(b, hour: 7, bait: 'tuvira'),
        _c(a, hour: 8, bait: 'tuvira'),
        _c(b, hour: 9, bait: 'jig'),
        _c(a, hour: 10, bait: 'jig'),
        _c(b, hour: 11, bait: 'colher'),
        _c(a, hour: 11, bait: 'colher'),
      ],
    );
    expect(insights.whereType<BaitInsight>(), isEmpty);
  });

  test('moon groups follow the phases', () {
    expect(moonGroupOf(MoonPhase.newMoon), MoonGroup.newMoon);
    expect(moonGroupOf(MoonPhase.waxingCrescent), MoonGroup.waxing);
    expect(moonGroupOf(MoonPhase.waxingGibbous), MoonGroup.waxing);
    expect(moonGroupOf(MoonPhase.fullMoon), MoonGroup.fullMoon);
    expect(moonGroupOf(MoonPhase.lastQuarter), MoonGroup.waning);
    expect(pressureTrendOf(null), isNull);
    expect(pressureTrendOf(-1.2), PressureTrend.falling);
    expect(pressureTrendOf(0.9), PressureTrend.steady);
    expect(pressureTrendOf(1.1), PressureTrend.rising);
  });
}
