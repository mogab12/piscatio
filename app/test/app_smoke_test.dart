import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piscatio/core/providers.dart';
import 'package:piscatio/features/onboarding/presentation/onboarding_screen.dart';
import 'package:piscatio/features/shell/presentation/app_shell.dart';

import 'helpers/pump_app.dart';

void main() {
  testWidgets('first launch opens onboarding', (tester) async {
    final app = await TestApp.start(tester);
    await app.pumpApp(tester);
    expect(find.byType(OnboardingScreen), findsOneWidget);
    await app.dispose(tester);
  });

  testWidgets('after onboarding the app opens on the tabs', (tester) async {
    final app = await TestApp.start(tester);
    await tester.runAsync(
      () => app.read(settingsRepositoryProvider).completeOnboarding(),
    );
    await app.pumpApp(tester);
    expect(find.byType(AppShell), findsOneWidget);
    expect(find.text('Pescar'), findsOneWidget);
    expect(find.text('Diário'), findsOneWidget);
    await app.dispose(tester);
  });

  testWidgets('unsupported device language falls back to English', (
    tester,
  ) async {
    final app = await TestApp.start(
      tester,
      deviceLocale: const Locale('fr', 'FR'),
    );
    await tester.runAsync(
      () => app.read(settingsRepositoryProvider).completeOnboarding(),
    );
    await app.pumpApp(tester);
    expect(find.text('Logbook'), findsOneWidget);
    await app.dispose(tester);
  });

  testWidgets('choosing a language in settings switches the app', (
    tester,
  ) async {
    final app = await TestApp.start(tester);
    await tester.runAsync(() async {
      await app.read(settingsRepositoryProvider).completeOnboarding();
      await app.read(settingsRepositoryProvider).setLanguage('es');
    });
    await app.pumpApp(tester);
    expect(find.text('Diario'), findsOneWidget);
    await app.dispose(tester);
  });
}
