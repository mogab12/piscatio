import 'package:flutter_test/flutter_test.dart';
import 'package:piscatio/core/providers.dart';
import 'package:piscatio/domain/models/catch.dart';
import 'package:piscatio/domain/models/enums.dart';

import '../helpers/pump_app.dart';
import '../helpers/screenshots.dart';

void main() {
  setUpAll(loadRealFonts);

  testWidgets('onboarding', (tester) async {
    usePhoneSurface(tester);
    final app = await TestApp.start(tester);
    await app.pumpApp(tester);
    await saveScreenshot(tester, 'onboarding_1_language');
    await tester.tap(find.text('Continuar'));
    await app.settle(tester);
    await saveScreenshot(tester, 'onboarding_2_units');
    await tester.tap(find.text('Continuar'));
    await app.settle(tester);
    await saveScreenshot(tester, 'onboarding_3_location');
    await app.dispose(tester);
  }, skip: !screenshotsEnabled);

  testWidgets('settings', (tester) async {
    usePhoneSurface(tester);
    final app = await TestApp.start(tester);
    await app.run(
      tester,
      () => app.read(settingsRepositoryProvider).completeOnboarding(),
    );
    await app.pumpApp(tester);
    await tester.tap(find.text('Ajustes'));
    await app.settle(tester);
    await saveScreenshot(tester, 'settings');
    await tester.tap(find.text('Privacidade padrão do local'));
    await app.settle(tester);
    await saveScreenshot(tester, 'settings_privacy_sheet');
    await app.dispose(tester);
  }, skip: !screenshotsEnabled);

  testWidgets('home empty', (tester) async {
    usePhoneSurface(tester);
    final app = await TestApp.start(tester);
    await app.run(
      tester,
      () => app.read(settingsRepositoryProvider).completeOnboarding(),
    );
    await app.pumpApp(tester);
    await saveScreenshot(tester, 'home_empty');
    await app.dispose(tester);
  }, skip: !screenshotsEnabled);

  testWidgets('home and active trip', (tester) async {
    usePhoneSurface(tester);
    final app = await TestApp.start(tester);
    // All data is written before the UI is mounted (see TestApp.run).
    await app.run(tester, () async {
      await app.read(settingsRepositoryProvider).completeOnboarding();
      final trips = app.read(tripRepositoryProvider);
      final catches = app.read(catchRepositoryProvider);
      for (final (days, name, species) in [
        (9, 'Represa de Furnas', ['cichla-kelberi', 'cichla-kelberi']),
        (
          3,
          'Rio Cuiabá',
          [
            'pseudoplatystoma-corruscans',
            'salminus-brasiliensis',
            'piaractus-mesopotamicus',
            'hoplias-malabaricus',
          ],
        ),
      ]) {
        app.clock.set(DateTime.utc(2026, 9, 12 - days, 9, 30));
        final t = await trips.startTrip(
          timezone: 'UTC',
          privacy: PrivacyLevel.private,
        );
        for (final sp in species) {
          app.clock.advance(const Duration(minutes: 40));
          await catches.addCatch(tripId: t.id, speciesId: sp);
        }
        await trips.updateTrip(t.copyWith(locationName: name));
        app.clock.advance(const Duration(minutes: 50));
        await trips.finishTrip(t.id);
      }
      // Trip running now, 1h47 in, three catches.
      final start = DateTime.utc(2026, 9, 12, 9);
      app.clock.set(start);
      final active = await trips.startTrip(
        timezone: 'UTC',
        privacy: PrivacyLevel.private,
      );
      for (final (min, sp, g, mm) in [
        (18, 'hoplias-malabaricus', 1450, 480),
        (52, 'cichla-kelberi', 2350, 525),
        (95, null, null, null),
      ]) {
        app.clock.set(start.add(Duration(minutes: min)));
        final c = await catches.addCatch(tripId: active.id, speciesId: sp);
        if (g != null) {
          await catches.updateDetails(
            c.id,
            CatchDetails(
              speciesId: sp,
              weightGrams: g,
              lengthMillimeters: mm,
              released: true,
            ),
          );
        }
      }
      app.clock.set(DateTime.utc(2026, 9, 12, 10, 47, 12));
    });
    await app.pumpApp(tester);
    await saveScreenshot(tester, 'home_active');
    await tester.tap(find.text('Voltar à pescaria'));
    await app.settle(tester);
    await saveScreenshot(tester, 'active_trip');
    await app.dispose(tester);
  }, skip: !screenshotsEnabled);
}
