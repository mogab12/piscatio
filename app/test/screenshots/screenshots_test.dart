import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piscatio/core/media/photo_source.dart';
import 'package:piscatio/core/providers.dart';
import 'package:piscatio/data/media/photo_importer.dart';
import 'package:piscatio/domain/models/catch.dart';
import 'package:piscatio/domain/models/enums.dart';

import '../helpers/fakes.dart';
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

  testWidgets('quick catch', (tester) async {
    usePhoneSurface(tester);
    final app = await TestApp.start(
      tester,
      overrides: [
        photoSourceProvider.overrideWithValue(FakePhotoSource()),
        imageProcessorProvider.overrideWithValue(PassThroughImageProcessor()),
      ],
    );
    await app.run(tester, () async {
      await app.read(settingsRepositoryProvider).completeOnboarding();
      final trip = await app
          .read(tripRepositoryProvider)
          .startTrip(timezone: 'UTC', privacy: PrivacyLevel.private);
      final catches = app.read(catchRepositoryProvider);
      for (final sp in [
        'cichla-kelberi',
        'cichla-kelberi',
        'hoplias-malabaricus',
        'salminus-brasiliensis',
        'pseudoplatystoma-corruscans',
      ]) {
        await catches.addCatch(tripId: trip.id, speciesId: sp);
      }
    });
    await app.pumpApp(tester);
    await tester.tap(find.text('Voltar à pescaria'));
    await app.settle(tester);
    await tester.tap(find.text('+ Captura'));
    await app.settle(tester);
    await saveScreenshot(tester, 'capture_1_photo');
    await tester.tap(find.text('Sem foto'));
    await app.settle(tester);
    await saveScreenshot(tester, 'capture_2_species');
    await tester.enterText(find.byType(TextField), 'surubi');
    await app.settle(tester);
    await saveScreenshot(tester, 'capture_3_search');
    await tester.tap(find.text('Pintado'));
    await app.settle(tester);
    await tester.tap(find.text('Mais detalhes'));
    await app.settle(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Peso'), '8,4');
    await tester.enterText(find.widgetWithText(TextField, 'Comprimento'), '92');
    await app.settle(tester);
    await saveScreenshot(tester, 'capture_4_confirm');
    await app.dispose(tester);
  }, skip: !screenshotsEnabled);
}
