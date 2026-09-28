import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piscatio/core/background.dart';
import 'package:piscatio/core/providers.dart';
import 'package:piscatio/domain/models/enums.dart';
import 'package:piscatio/domain/models/weather.dart';
import 'package:piscatio/domain/services/units.dart';
import 'package:piscatio/features/weather/presentation/weather_panel.dart';

import '../../helpers/pump_app.dart';

Future<(TestApp, String)> _tripWith(
  WidgetTester tester,
  TripWeather Function(String tripId)? weather, {
  UnitSystem units = UnitSystem.metric,
}) async {
  final app = await TestApp.start(tester);
  final id = await app.run(tester, () async {
    await app.read(settingsRepositoryProvider).setUnitSystem(units);
    final trip = await app
        .read(tripRepositoryProvider)
        .createPastTrip(
          startedAt: DateTime.utc(2026, 9, 10, 6, 40),
          endedAt: DateTime.utc(2026, 9, 10, 10),
          timezone: 'UTC',
          privacy: PrivacyLevel.private,
        );
    final repo = app.read(weatherRepositoryProvider);
    if (weather == null) {
      await repo.markPending(trip.id);
    } else {
      await repo.save(weather(trip.id));
    }
    return trip.id;
  });
  return (app, id);
}

TripWeather _ok(String id) => TripWeather(
  tripId: id,
  status: WeatherStatus.ok,
  temperatureC: 27,
  pressureHpa: 1011.4,
  pressureTrend3hHpa: -1.8,
  windSpeedKmh: 9,
  windDirectionDeg: 135,
  precipitationMm: 0.8,
);

void main() {
  testWidgets('pending weather explains the 2–3 day delay', (tester) async {
    final (app, id) = await _tripWith(tester, null);
    await app.pumpScreen(tester, Scaffold(body: WeatherPanel(tripId: id)));
    expect(
      find.text('O clima desta pescaria fica pronto 2 a 3 dias depois.'),
      findsOneWidget,
    );
    await app.dispose(tester);
  });

  testWidgets('shows values, pressure trend, wind direction and source', (
    tester,
  ) async {
    final (app, id) = await _tripWith(tester, _ok);
    await app.pumpScreen(tester, Scaffold(body: WeatherPanel(tripId: id)));
    expect(find.text('27 °C'), findsOneWidget);
    expect(find.text('1.011 hPa'), findsOneWidget);
    expect(find.text('Pressão caindo'), findsOneWidget);
    expect(find.text('9 km/h SE'), findsOneWidget);
    expect(find.text('0,8 mm'), findsOneWidget);
    expect(find.text('Clima: NASA POWER'), findsOneWidget);
    await app.dispose(tester);
  });

  testWidgets('imperial units convert the weather too', (tester) async {
    final (app, id) = await _tripWith(tester, _ok, units: UnitSystem.imperial);
    await app.pumpScreen(
      tester,
      Scaffold(body: WeatherPanel(tripId: id)),
      locale: const Locale('en'),
    );
    expect(find.text('81 °F'), findsOneWidget);
    expect(find.text('29.87 inHg'), findsOneWidget);
    expect(find.text('6 mph SE'), findsOneWidget);
    await app.dispose(tester);
  });
}
