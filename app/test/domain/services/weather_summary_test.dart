import 'package:flutter_test/flutter_test.dart';
import 'package:piscatio/domain/models/weather.dart';
import 'package:piscatio/domain/services/weather_summary.dart';

HourlyWeather _h(int hour, {double? t, double? p, double? rain}) =>
    HourlyWeather(
      time: DateTime.utc(2026, 9, 10, hour),
      temperatureC: t,
      pressureHpa: p,
      precipitationMm: rain,
      windSpeedKmh: 9,
      windDirectionDeg: 135,
      humidityPct: 70,
    );

void main() {
  final series = [
    for (var h = 0; h < 24; h++)
      _h(h, t: 20.0 + h, p: 1015.0 - h * 0.5, rain: h == 8 ? 1.2 : 0.2),
  ];

  test('uses the start hour and the 3 h pressure trend', () {
    final w = summarizeWeather(
      tripId: 't',
      start: DateTime.utc(2026, 9, 10, 6, 40),
      end: DateTime.utc(2026, 9, 10, 10, 5),
      hourly: series,
      fetchedAt: DateTime.utc(2026, 9, 13),
      source: 'nasa_power',
    )!;
    expect(w.status, WeatherStatus.ok);
    expect(w.temperatureC, 26);
    expect(w.pressureHpa, 1012);
    // 06h (1012) minus 03h (1013.5): falling.
    expect(w.pressureTrend3hHpa, -1.5);
    // Rain 06h..10h: 0.2 + 0.2 + 1.2 + 0.2 + 0.2.
    expect(w.precipitationMm, closeTo(2.0, 1e-9));
    expect(w.hourly.first.time, DateTime.utc(2026, 9, 10, 3));
    expect(w.hourly.last.time, DateTime.utc(2026, 9, 10, 10));
  });

  test('returns null until the start hour is published', () {
    final unpublished = [
      for (final h in series)
        h.time.hour >= 6
            ? h.copyWith(temperatureC: null, pressureHpa: null)
            : h,
    ];
    expect(
      summarizeWeather(
        tripId: 't',
        start: DateTime.utc(2026, 9, 10, 6),
        end: DateTime.utc(2026, 9, 10, 9),
        hourly: unpublished,
        fetchedAt: DateTime.utc(2026, 9, 13),
        source: 'nasa_power',
      ),
      isNull,
    );
  });

  test('catch conditions: the closest hour within 90 minutes', () {
    final w = TripWeather(
      tripId: 't',
      status: WeatherStatus.ok,
      hourly: series,
    );
    expect(w.at(DateTime.utc(2026, 9, 10, 7, 50))!.time.hour, 7);
    expect(
      const TripWeather(
        tripId: 't',
        status: WeatherStatus.ok,
      ).at(DateTime.utc(2026)),
      isNull,
    );
  });

  test('sea-level pressure from surface pressure and elevation', () {
    expect(
      seaLevelPressureHpa(
        surfaceHpa: 1000,
        elevationMeters: 500,
        temperatureC: 15,
      ),
      closeTo(1060.7, 0.3),
    );
    expect(
      seaLevelPressureHpa(
        surfaceHpa: 1013,
        elevationMeters: 0,
        temperatureC: 20,
      ),
      1013,
    );
  });

  test('compass octants', () {
    expect(compassOctant(0), 0);
    expect(compassOctant(350), 0);
    expect(compassOctant(135), 3);
    expect(compassOctant(270), 6);
    expect(compassOctant(-45), 7);
  });
}
