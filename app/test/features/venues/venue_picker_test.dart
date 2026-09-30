import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piscatio/core/background.dart';
import 'package:piscatio/core/providers.dart';
import 'package:piscatio/core/router/app_router.dart';
import 'package:piscatio/core/router/app_routes.dart';
import 'package:piscatio/data/remote/piscatio_api.dart';
import 'package:piscatio/domain/models/enums.dart';
import 'package:piscatio/domain/models/geo_point.dart';
import 'package:piscatio/features/account/presentation/account_screen.dart';
import 'package:piscatio/features/history/presentation/edit_trip_screen.dart';
import 'package:piscatio/features/history/presentation/trip_detail_screen.dart';

import '../../helpers/fake_server.dart';
import '../../helpers/pump_app.dart';

const _spot = GeoPoint(-16.52, -56.41);

Future<(TestApp, FakeServer, String)> _start(
  WidgetTester tester, {
  required bool venuesOn,
}) async {
  final server = FakeServer()
    ..venues.add({
      'id': 'v1',
      'name': 'Pesqueiro São José',
      'kind': 'pay_lake',
      'city': 'Cuiabá',
      'state': 'MT',
      'latitude': -16.5,
      'longitude': -56.4,
      'verified': true,
      'distance_km': 3.2,
    });
  final app = await TestApp.start(
    tester,
    overrides: [
      apiFactoryProvider.overrideWithValue(
        (base, token) => PiscatioApi(server.client(), base: base, token: token),
      ),
    ],
  );
  final tripId = await app.run(tester, () async {
    await app.read(settingsRepositoryProvider).completeOnboarding();
    final accounts = app.read(accountRepositoryProvider);
    await accounts.signedIn(
      const ApiSession(token: FakeServer.token, email: FakeServer.email),
    );
    await accounts.setRemoteConfig({
      'features': {'venues': venuesOn},
    });
    final now = app.clock.now();
    final trip = await app
        .read(tripRepositoryProvider)
        .createPastTrip(
          startedAt: now.subtract(const Duration(hours: 6)),
          endedAt: now.subtract(const Duration(hours: 2)),
          timezone: 'UTC',
          privacy: PrivacyLevel.private,
          location: _spot,
        );
    return trip.id;
  });
  return (app, server, tripId);
}

void main() {
  testWidgets('a trip can be linked to a venue found nearby', (tester) async {
    final (app, server, tripId) = await _start(tester, venuesOn: true);
    await app.pumpApp(tester);
    unawaited(app.read(routerProvider).push(AppRoutes.editTrip(tripId)));
    await app.settle(tester);
    expect(find.text('Pesqueiro'), findsOneWidget);
    expect(find.text('Nenhum'), findsOneWidget);
    await tester.ensureVisible(find.text('Pesqueiro'));
    await tester.tap(find.text('Pesqueiro'));
    await app.settle(tester);
    expect(find.text('Perto desta pescaria'), findsOneWidget);
    expect(find.text('Pesqueiro São José'), findsOneWidget);
    expect(find.text('Pesqueiro, Cuiabá, MT, 3,2 km'), findsOneWidget);
    // The server was asked around the trip's area, not its exact spot.
    final asked = server.venueSearches.single;
    final lat = double.parse(asked['lat']!);
    final lon = double.parse(asked['lon']!);
    expect(lat == _spot.latitude && lon == _spot.longitude, isFalse);
    expect((lat - _spot.latitude).abs(), lessThan(0.05));

    await tester.tap(find.text('Pesqueiro São José'));
    await app.settle(tester);
    expect(find.text('Pesqueiro São José'), findsOneWidget);
    await tester.tap(find.text('Salvar'));
    await app.settle(tester);
    final trip = app.read(tripProvider(tripId)).value!;
    expect(trip.venueId, 'v1');
    unawaited(app.read(routerProvider).push(AppRoutes.trip(tripId)));
    await app.settle(tester);
    expect(find.byType(TripDetailScreen), findsOneWidget);
    expect(find.text('Pesqueiro São José'), findsOneWidget);
    await app.dispose(tester);
  });

  testWidgets('until the server opens venues, nothing shows', (tester) async {
    final (app, _, tripId) = await _start(tester, venuesOn: false);
    await app.pumpScreen(tester, EditTripScreen(tripId: tripId));
    expect(find.text('Pesqueiro'), findsNothing);
    await app.pumpScreen(tester, const AccountScreen());
    expect(find.text('Ajudar pesqueiros com números anônimos'), findsNothing);
    await app.dispose(tester);
  });

  testWidgets('the insights consent is off until turned on', (tester) async {
    final (app, server, _) = await _start(tester, venuesOn: true);
    await app.pumpScreen(tester, const AccountScreen());
    final tile = find.widgetWithText(
      SwitchListTile,
      'Ajudar pesqueiros com números anônimos',
    );
    await tester.ensureVisible(tile);
    await app.settle(tester);
    expect(tester.widget<SwitchListTile>(tile).value, isFalse);
    await tester.tap(tile);
    await app.settle(tester);
    expect(server.shareInsights, isTrue);
    expect(tester.widget<SwitchListTile>(tile).value, isTrue);
    await app.dispose(tester);
  });
}
