import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piscatio/core/media/photo_source.dart';
import 'package:piscatio/core/providers.dart';
import 'package:piscatio/data/media/photo_importer.dart';
import 'package:piscatio/domain/models/catch.dart';
import 'package:piscatio/domain/models/enums.dart';
import 'package:piscatio/features/cards/presentation/card_editor_screen.dart';
import 'package:piscatio/features/summary/presentation/trip_summary_screen.dart';

import '../features/summary/trip_summary_test.dart' show seedSummaryTrip;
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

  testWidgets('logbook', (tester) async {
    usePhoneSurface(tester);
    final app = await TestApp.start(tester);
    await app.run(tester, () async {
      await app.read(settingsRepositoryProvider).completeOnboarding();
      final trips = app.read(tripRepositoryProvider);
      final catches = app.read(catchRepositoryProvider);
      final plan = [
        (
          DateTime.utc(2026, 8, 16, 9),
          'Represa de Furnas',
          150,
          [('cichla-kelberi', 2100, 480), ('cichla-kelberi', 1650, 440)],
        ),
        (
          DateTime.utc(2026, 8, 30, 8),
          'Rio Paraná',
          240,
          [('salminus-brasiliensis', 5200, 780)],
        ),
        (
          DateTime.utc(2026, 9, 10, 6),
          'Rio Cuiabá',
          200,
          [
            ('hoplias-malabaricus', 900, 390),
            ('pseudoplatystoma-corruscans', 8400, 920),
            ('piaractus-mesopotamicus', 3100, 520),
          ],
        ),
      ];
      for (final (start, name, minutes, list) in plan) {
        app.clock.set(start);
        final t = await trips.startTrip(
          timezone: 'UTC',
          privacy: PrivacyLevel.private,
        );
        for (final (sp, g, mm) in list) {
          app.clock.advance(const Duration(minutes: 35));
          final c = await catches.addCatch(tripId: t.id, speciesId: sp);
          await catches.updateDetails(
            c.id,
            CatchDetails(speciesId: sp, weightGrams: g, lengthMillimeters: mm),
          );
        }
        await trips.updateTrip(t.copyWith(locationName: name));
        app.clock.set(start.add(Duration(minutes: minutes)));
        await trips.finishTrip(t.id);
      }
      app.clock.set(DateTime.utc(2026, 9, 12, 9));
    });
    await app.pumpApp(tester);
    await tester.tap(find.text('Diário'));
    await app.settle(tester);
    await saveScreenshot(tester, 'logbook');
    await tester.tap(find.text('Rio Cuiabá'));
    await app.settle(tester);
    await saveScreenshot(tester, 'trip_detail');
    await tester.tap(find.text('Pintado'));
    await app.settle(tester);
    await saveScreenshot(tester, 'catch_detail');
    await app.dispose(tester);
  }, skip: !screenshotsEnabled);

  testWidgets('dark theme and large text', (tester) async {
    usePhoneSurface(tester);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    final app = await TestApp.start(tester);
    await app.run(tester, () async {
      await app.read(settingsRepositoryProvider).completeOnboarding();
      final trips = app.read(tripRepositoryProvider);
      final catches = app.read(catchRepositoryProvider);
      final start = DateTime.utc(2026, 9, 12, 9);
      app.clock.set(start);
      final t = await trips.startTrip(
        timezone: 'UTC',
        privacy: PrivacyLevel.private,
      );
      for (final (min, sp, g) in [
        (20, 'cichla-kelberi', 2350),
        (64, 'hoplias-malabaricus', 1450),
      ]) {
        app.clock.set(start.add(Duration(minutes: min)));
        final c = await catches.addCatch(tripId: t.id, speciesId: sp);
        await catches.updateDetails(
          c.id,
          CatchDetails(speciesId: sp, weightGrams: g),
        );
      }
      app.clock.set(start.add(const Duration(minutes: 83, seconds: 4)));
    });
    await app.pumpApp(tester);
    await tester.tap(find.text('Voltar à pescaria'));
    await app.settle(tester);
    await saveScreenshot(tester, 'dark_active_trip');

    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await app.settle(tester);
    await saveScreenshot(tester, 'dark_active_trip_large_text');
    await tester.tap(find.byTooltip('Minimizar'));
    await app.settle(tester);
    await saveScreenshot(tester, 'dark_home_large_text');
    await app.dispose(tester);
  }, skip: !screenshotsEnabled);

  testWidgets('trip summary and card editor', (tester) async {
    usePhoneSurface(tester);
    final app = await TestApp.start(tester);
    final tripId = await seedSummaryTrip(app, tester);
    await app.pumpScreen(tester, TripSummaryScreen(tripId: tripId));
    await saveScreenshot(tester, 'trip_summary');
    await app.pumpScreen(
      tester,
      CardEditorScreen(subject: CardSubject.trip, id: tripId),
    );
    await saveScreenshot(tester, 'card_editor');
    await app.dispose(tester);
  }, skip: !screenshotsEnabled);

  testWidgets('phase 1C screens', (tester) async {
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
      await app
          .read(tackleRepositoryProvider)
          .addBait('Tuvira', BaitType.natural);
      await app
          .read(tackleRepositoryProvider)
          .addBait('Jig de pena', BaitType.artificial);
    });
    await seedSummaryTrip(app, tester);
    await app.pumpApp(tester);
    await tester.tap(find.text('Números'));
    await app.settle(tester);
    await saveScreenshot(tester, 'stats');
    await tester.drag(
      find.byType(CustomScrollView).last,
      const Offset(0, -500),
    );
    await app.settle(tester);
    await saveScreenshot(tester, 'stats_scrolled');
    await tester.tap(find.text('Ajustes'));
    await app.settle(tester);
    await tester.drag(find.byType(ListView).last, const Offset(0, -400));
    await app.settle(tester);
    await saveScreenshot(tester, 'settings_1c');
    await tester.tap(find.text('Iscas'));
    await app.settle(tester);
    await saveScreenshot(tester, 'tackle_baits');
    await tester.tap(find.byTooltip('Voltar'));
    await app.settle(tester);
    await tester.tap(find.text('Diário'));
    await app.settle(tester);
    await tester.tap(find.text('Registrar pescaria passada'));
    await app.settle(tester);
    await saveScreenshot(tester, 'past_trip');

    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await app.settle(tester);
    await saveScreenshot(tester, 'past_trip_large_text');
    await tester.tap(find.byTooltip('Voltar'));
    await app.settle(tester);
    await tester.tap(find.text('Números'));
    await app.settle(tester);
    await saveScreenshot(tester, 'stats_large_text');
    await app.dispose(tester);
  }, skip: !screenshotsEnabled);
}
