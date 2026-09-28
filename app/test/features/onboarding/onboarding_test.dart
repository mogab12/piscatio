import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piscatio/core/location/location_service.dart';
import 'package:piscatio/core/providers.dart';
import 'package:piscatio/domain/services/units.dart';
import 'package:piscatio/features/shell/presentation/app_shell.dart';

import '../../helpers/fakes.dart';
import '../../helpers/pump_app.dart';

void main() {
  testWidgets('language choice switches the onboarding immediately', (
    tester,
  ) async {
    final app = await TestApp.start(tester);
    await app.pumpApp(tester);
    expect(find.text('Cada pescaria vira uma história.'), findsOneWidget);

    await tester.tap(find.text('English'));
    await app.settle(tester);
    expect(find.text('Every fishing trip becomes a story.'), findsOneWidget);
    expect(
      (await app.run(
        tester,
        app.read(settingsRepositoryProvider).read,
      )).languageCode,
      'en',
    );

    // Choosing the device language again goes back to following the device.
    await tester.tap(find.text('Português (Brasil)'));
    await app.settle(tester);
    expect(
      (await app.run(
        tester,
        app.read(settingsRepositoryProvider).read,
      )).languageCode,
      isNull,
    );
    await app.dispose(tester);
  });

  testWidgets('units default from region, are saved, then location asked', (
    tester,
  ) async {
    final location = FakeLocationService();
    final app = await TestApp.start(
      tester,
      deviceLocale: const Locale('en', 'US'),
      overrides: [locationServiceProvider.overrideWithValue(location)],
    );
    await app.pumpApp(tester);
    await tester.tap(find.text('Continue'));
    await app.settle(tester);

    expect(find.text('How do you measure your fish?'), findsOneWidget);
    // US device: imperial preselected and shown with the sample fish.
    expect(find.text('5 lb 3 oz'), findsOneWidget);
    expect(find.text('2.35 kg'), findsOneWidget);
    await tester.tap(find.text('Metric'));
    await app.settle(tester);
    await tester.tap(find.text('Continue'));
    await app.settle(tester);
    expect(app.read(unitSystemProvider), UnitSystem.metric);

    expect(find.text('Where are you fishing?'), findsOneWidget);
    await tester.tap(find.text('Allow location'));
    await app.settle(tester);
    expect(location.requests, 1);
    expect(find.byType(AppShell), findsOneWidget);
    await app.dispose(tester);
  });

  testWidgets('location can be skipped', (tester) async {
    final location = FakeLocationService(accessResult: LocationAccess.denied);
    final app = await TestApp.start(
      tester,
      overrides: [locationServiceProvider.overrideWithValue(location)],
    );
    await app.pumpApp(tester);
    await tester.tap(find.text('Continuar'));
    await app.settle(tester);
    await tester.tap(find.text('Continuar'));
    await app.settle(tester);
    await tester.tap(find.text('Agora não'));
    await app.settle(tester);
    expect(location.requests, 0);
    expect(find.byType(AppShell), findsOneWidget);
    await app.dispose(tester);
  });

  testWidgets('back returns to the previous step', (tester) async {
    final app = await TestApp.start(tester);
    await app.pumpApp(tester);
    await tester.tap(find.text('Continuar'));
    await app.settle(tester);
    await tester.tap(find.byTooltip('Voltar'));
    await app.settle(tester);
    expect(find.text('Idioma'), findsOneWidget);
    await app.dispose(tester);
  });
}
