import 'dart:math' as math;

import '../models/weather.dart';

/// Reduces station (surface) pressure to sea level with the hypsometric
/// formula, so a trip in the Pantanal and one at a 900 m reservoir compare.
double seaLevelPressureHpa({
  required double surfaceHpa,
  required double elevationMeters,
  required double temperatureC,
}) {
  const lapse = 0.0065;
  final ratio =
      1 -
      lapse *
          elevationMeters /
          (temperatureC + lapse * elevationMeters + 273.15);
  return surfaceHpa * math.pow(ratio, -5.257);
}

DateTime _hourOf(DateTime t) {
  final u = t.toUtc();
  return DateTime.utc(u.year, u.month, u.day, u.hour);
}

/// Builds the trip's weather from an hourly series, or returns null when
/// the series does not cover the trip's start yet (data still publishing).
///
/// - Summary values are those of the hour the trip started.
/// - Pressure trend: start hour minus three hours earlier.
/// - Rain: total over the trip's hours.
/// - The stored series spans three hours before the start to the end.
TripWeather? summarizeWeather({
  required String tripId,
  required DateTime start,
  required DateTime end,
  required List<HourlyWeather> hourly,
  required DateTime fetchedAt,
  required String source,
}) {
  final startHour = _hourOf(start);
  final endHour = _hourOf(end.isBefore(start) ? start : end);
  final byHour = {for (final h in hourly) _hourOf(h.time): h};

  final atStart = byHour[startHour];
  if (atStart == null ||
      atStart.temperatureC == null ||
      atStart.pressureHpa == null) {
    return null;
  }

  final before = byHour[startHour.subtract(const Duration(hours: 3))];
  final trend = before?.pressureHpa == null
      ? null
      : atStart.pressureHpa! - before!.pressureHpa!;

  final windowStart = startHour.subtract(const Duration(hours: 3));
  final series = [
    for (final h in hourly)
      if (!_hourOf(h.time).isBefore(windowStart) &&
          !_hourOf(h.time).isAfter(endHour))
        h,
  ]..sort((a, b) => a.time.compareTo(b.time));

  double? rain;
  for (final h in series) {
    final t = _hourOf(h.time);
    if (t.isBefore(startHour) || h.precipitationMm == null) continue;
    rain = (rain ?? 0) + h.precipitationMm!;
  }

  return TripWeather(
    tripId: tripId,
    status: WeatherStatus.ok,
    source: source,
    fetchedAt: fetchedAt.toUtc(),
    temperatureC: atStart.temperatureC,
    pressureHpa: atStart.pressureHpa,
    pressureTrend3hHpa: trend,
    windSpeedKmh: atStart.windSpeedKmh,
    windDirectionDeg: atStart.windDirectionDeg,
    precipitationMm: rain,
    humidityPct: atStart.humidityPct,
    hourly: series,
  );
}

/// Compass point for a wind direction: 0 = N, 1 = NE … 7 = NW.
int compassOctant(double degrees) => ((degrees % 360 + 22.5) ~/ 45) % 8;
