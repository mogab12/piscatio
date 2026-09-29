import 'package:flutter_test/flutter_test.dart';
import 'package:piscatio/core/background.dart';
import 'package:piscatio/core/providers.dart';
import 'package:piscatio/data/remote/piscatio_api.dart';
import 'package:piscatio/domain/models/enums.dart';
import 'package:piscatio/domain/models/geo_point.dart';
import 'package:piscatio/domain/services/privacy_offset.dart';
import 'package:piscatio/features/active_trip/presentation/active_trip_screen.dart';

import '../../helpers/fake_server.dart';
import '../../helpers/pump_app.dart';

void main() {
  late FakeServer server;
  const spot = GeoPoint(-16.52, -56.41);

  Future<TestApp> start(WidgetTester tester, {required bool signedIn}) async {
    server = FakeServer();
    final app = await TestApp.start(
      tester,
      overrides: [
        apiFactoryProvider.overrideWithValue(
          (base, token) =>
              PiscatioApi(server.client(), base: base, token: token),
        ),
      ],
    );
    await app.run(tester, () async {
      await app.read(settingsRepositoryProvider).completeOnboarding();
      if (signedIn) {
        await app
            .read(accountRepositoryProvider)
            .signedIn(
              const ApiSession(
                token: FakeServer.token,
                email: FakeServer.email,
              ),
            );
      }
      final trip = await app
          .read(tripRepositoryProvider)
          .startTrip(timezone: 'America/Cuiaba', privacy: PrivacyLevel.private);
      await app.read(tripRepositoryProvider).setLocation(trip.id, spot);
    });
    return app;
  }

  testWidgets('the trip in progress shows the weather now, credited', (
    tester,
  ) async {
    final app = await start(tester, signedIn: true);
    await app.pumpScreen(tester, const ActiveTripScreen());
    expect(find.text('Tempo agora'), findsOneWidget);
    expect(find.text('27 °C'), findsOneWidget);
    expect(find.text('1.012 hPa'), findsOneWidget);
    expect(find.text('11 km/h NE'), findsOneWidget);
    expect(find.bySemanticsLabel('Chuva na próxima hora: 0,4 mm'), findsOne);
    expect(find.text('Dados: MET Norway'), findsOneWidget);

    // The server gets a nearby point, never the spot itself.
    final asked = server.requests
        .singleWhere((r) => r.url.path == '/api/conditions/weather')
        .url
        .queryParameters;
    final sent = GeoPoint(
      double.parse(asked['lat']!),
      double.parse(asked['lon']!),
    );
    expect(sent, isNot(spot));
    expect(distanceMeters(sent, spot), lessThan(700));
    await app.dispose(tester);
  });

  testWidgets('signed out, the screen stays as it was', (tester) async {
    final app = await start(tester, signedIn: false);
    await app.pumpScreen(tester, const ActiveTripScreen());
    expect(find.text('Tempo agora'), findsNothing);
    expect(server.requests, isEmpty);
    await app.dispose(tester);
  });

  testWidgets('when the weather service is down nothing shows', (tester) async {
    final app = await start(tester, signedIn: true);
    server.weather = null;
    await app.pumpScreen(tester, const ActiveTripScreen());
    expect(find.text('Tempo agora'), findsNothing);
    await app.dispose(tester);
  });
}
