import 'package:flutter_test/flutter_test.dart';
import 'package:piscatio/core/background.dart';
import 'package:piscatio/core/providers.dart';
import 'package:piscatio/data/db/tables.dart';
import 'package:piscatio/domain/models/enums.dart';
import 'package:piscatio/domain/models/geo_point.dart';
import 'package:piscatio/features/active_trip/presentation/active_trip_screen.dart';
import 'package:piscatio/features/active_trip/presentation/time_ruler.dart';
import 'package:piscatio/features/history/presentation/trip_detail_screen.dart';
import 'package:piscatio/features/shell/presentation/app_shell.dart';

import '../../helpers/pump_app.dart';

Future<TestApp> _onboarded(WidgetTester tester) async {
  final app = await TestApp.start(tester);
  await app.run(tester, () async {
    await app.read(settingsRepositoryProvider).completeOnboarding();
    await app
        .read(settingsRepositoryProvider)
        .setDefaultPrivacy(PrivacyLevel.approximate);
  });
  return app;
}

void main() {
  testWidgets('home shows the first-trip empty state and start button', (
    tester,
  ) async {
    final app = await _onboarded(tester);
    await app.pumpApp(tester);
    expect(find.text('Sua primeira pescaria começa aqui.'), findsOneWidget);
    expect(find.text('Iniciar pescaria'), findsOneWidget);
    await app.dispose(tester);
  });

  testWidgets('starting a trip opens the active trip with defaults', (
    tester,
  ) async {
    final app = await _onboarded(tester);
    await app.pumpApp(tester);
    await tester.tap(find.text('Iniciar pescaria'));
    await app.settle(tester);

    expect(find.byType(ActiveTripScreen), findsOneWidget);
    expect(find.text('0:00:00'), findsOneWidget);
    expect(find.text('+ Captura'), findsOneWidget);
    expect(find.byType(TimeRuler), findsOneWidget);

    final trip = (await app.run(
      tester,
      app.read(tripRepositoryProvider).activeTrip,
    ))!;
    expect(trip.privacyLevel, PrivacyLevel.approximate);
    expect(trip.timezone, 'America/Sao_Paulo');
    // GPS answered after the trip started and was attached, then the
    // region was looked up (with a rounded point).
    expect(trip.location, const GeoPoint(-16.52, -56.41));
    expect(trip.locationRegion, 'Cuiabá, MT');
    expect(app.places.asked, isNotEmpty);
    expect(find.text('Local salvo'), findsOneWidget);
    await app.dispose(tester);
  });

  testWidgets('timer and ruler follow the clock; catches are listed', (
    tester,
  ) async {
    final app = await _onboarded(tester);
    final trip = await app.run(
      tester,
      () => app
          .read(tripRepositoryProvider)
          .startTrip(timezone: 'UTC', privacy: PrivacyLevel.private),
    );
    app.clock.advance(const Duration(hours: 1, minutes: 5, seconds: 9));
    await app.run(
      tester,
      () => app
          .read(catchRepositoryProvider)
          .addCatch(tripId: trip.id, speciesId: 'hoplias-malabaricus'),
    );
    await app.pumpScreen(tester, const ActiveTripScreen());
    expect(find.text('1:05:09'), findsOneWidget);
    expect(find.text('Traíra'), findsOneWidget);
    expect(find.text('capturas'), findsNothing);
    expect(find.text('captura'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Régua do tempo com 1 captura marcada'),
      findsOneWidget,
    );
    await app.dispose(tester);
  });

  testWidgets('home shows the running trip and resumes it', (tester) async {
    final app = await _onboarded(tester);
    await app.run(
      tester,
      () => app
          .read(tripRepositoryProvider)
          .startTrip(timezone: 'UTC', privacy: PrivacyLevel.private),
    );
    await app.pumpApp(tester);
    expect(find.text('Pescaria em andamento'), findsOneWidget);
    await tester.tap(find.text('Voltar à pescaria'));
    await app.settle(tester);
    expect(find.byType(ActiveTripScreen), findsOneWidget);
    await app.dispose(tester);
  });

  testWidgets('finishing asks for confirmation, then opens the trip', (
    tester,
  ) async {
    final app = await _onboarded(tester);
    await app.pumpApp(tester);
    await tester.tap(find.text('Iniciar pescaria'));
    await app.settle(tester);

    await tester.tap(find.text('Finalizar'));
    await app.settle(tester);
    expect(find.text('Finalizar a pescaria?'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await app.settle(tester);
    expect(find.byType(ActiveTripScreen), findsOneWidget);

    await tester.tap(find.text('Finalizar'));
    await app.settle(tester);
    await tester.tap(find.text('Finalizar pescaria'));
    await app.settle(tester);
    expect(find.byType(TripDetailScreen), findsOneWidget);
    expect(
      await app.run(tester, app.read(tripRepositoryProvider).activeTrip),
      isNull,
    );

    // Weather is queued and the detail says when it will arrive.
    final jobs = await app.run(tester, app.read(jobQueueProvider).all);
    expect(jobs.map((j) => j.kind), contains(JobKind.weather));
    expect(
      find.text('O clima desta pescaria fica pronto 2 a 3 dias depois.'),
      findsOneWidget,
    );

    // Regression: finishing must leave a way back, not a dead-end screen.
    expect(find.byTooltip('Voltar'), findsOneWidget);
    await tester.tap(find.byTooltip('Voltar'));
    await app.settle(tester);
    expect(find.byType(AppShell), findsOneWidget);
    expect(find.text('Pescar'), findsOneWidget);
    await app.dispose(tester);
  });

  test('ruler span is at least an hour and rounds to half hours', () {
    expect(TimeRuler.spanFor(Duration.zero), const Duration(hours: 1));
    expect(
      TimeRuler.spanFor(const Duration(minutes: 55)),
      const Duration(minutes: 90),
    );
    expect(
      TimeRuler.spanFor(const Duration(hours: 3, minutes: 2)),
      const Duration(hours: 3, minutes: 30),
    );
  });
}
