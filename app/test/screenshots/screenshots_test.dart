import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piscatio/core/background.dart';
import 'package:piscatio/core/media/photo_source.dart';
import 'package:piscatio/core/providers.dart';
import 'package:piscatio/core/router/app_router.dart';
import 'package:piscatio/core/router/app_routes.dart';
import 'package:piscatio/data/media/photo_importer.dart';
import 'package:piscatio/data/remote/piscatio_api.dart';
import 'package:piscatio/domain/models/catch.dart';
import 'package:piscatio/domain/models/enums.dart';
import 'package:piscatio/domain/models/geo_point.dart';
import 'package:piscatio/features/account/presentation/account_screen.dart';
import 'package:piscatio/features/active_trip/presentation/active_trip_screen.dart';
import 'package:piscatio/features/cards/presentation/card_editor_screen.dart';
import 'package:piscatio/features/community/application/community.dart';
import 'package:piscatio/features/stats/presentation/stats_screen.dart';
import 'package:piscatio/features/summary/presentation/trip_summary_screen.dart';

import '../features/community/community_test.dart' show pixel;
import '../features/summary/trip_summary_test.dart' show seedSummaryTrip;
import '../helpers/fake_server.dart';
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

  testWidgets('phase 2 screens', (tester) async {
    usePhoneSurface(tester);
    final server = FakeServer();
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
      final tuvira = await app
          .read(tackleRepositoryProvider)
          .addBait('Tuvira', BaitType.natural);
      final trips = app.read(tripRepositoryProvider);
      final catches = app.read(catchRepositoryProvider);
      final now = app.clock.now();
      for (final day in [3, 10, 17]) {
        final start = now.subtract(Duration(days: day, hours: 3));
        final trip = await trips.createPastTrip(
          startedAt: start,
          endedAt: start.add(const Duration(hours: 6)),
          timezone: 'UTC',
          privacy: PrivacyLevel.private,
        );
        for (final minutes in [20, 70, day == 3 ? 300 : 110]) {
          final c = await catches.addCatch(
            tripId: trip.id,
            speciesId: 'salminus-brasiliensis',
            caughtAt: start.add(Duration(minutes: minutes)),
          );
          await catches.updateDetails(
            c.id,
            CatchDetails(speciesId: 'salminus-brasiliensis', baitId: tuvira.id),
          );
        }
      }
      final active = await trips.startTrip(
        timezone: 'America/Cuiaba',
        privacy: PrivacyLevel.approximate,
      );
      await trips.setLocation(active.id, const GeoPoint(-16.52, -56.41));
    });
    await app.pumpScreen(tester, const AccountScreen());
    await saveScreenshot(tester, 'account_sign_in');
    await tester.enterText(find.byType(TextField).first, FakeServer.email);
    await tester.pump();
    await tester.tap(find.text('Enviar código'));
    await app.settle(tester);
    await tester.enterText(find.byType(TextField).first, FakeServer.code);
    await tester.pump();
    await saveScreenshot(tester, 'account_code');
    await tester.tap(find.text('Entrar'));
    await app.settle(tester);
    await app.settleUntil(tester, () => server.secret != null);
    await app.settle(tester);
    await saveScreenshot(tester, 'account_signed_in');
    await app.pumpScreen(tester, const ActiveTripScreen());
    await saveScreenshot(tester, 'active_trip_weather_now');
    await app.pumpScreen(tester, const StatsScreen());
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -260));
    await app.settle(tester);
    await saveScreenshot(tester, 'stats_what_worked');
    await app.dispose(tester);
  }, skip: !screenshotsEnabled);

  // Needs the card screenshots first (test/screenshots/cards_*): the feed
  // shows real cards.
  testWidgets('phase 3 screens', (tester) async {
    usePhoneSurface(tester);
    final cards = {
      for (final name in [
        'card_catch_cover_story_photo',
        'card_trip_chart_square_plain',
        'card_year_story_plain',
      ])
        name: File('build/screenshots/$name.png'),
    };
    final server = FakeServer()
      ..profile = {
        ...FakeServer.person('ana.pesca', name: 'Ana'),
        'bio': 'Dourado no Cuiabá, tucunaré no Araguaia',
        'is_private': true,
        'followers': 38,
        'following': 41,
        'posts': 12,
      }
      ..people['bia'] = {
        ...FakeServer.person('bia', name: 'Bia Ribeiro'),
        'bio': 'Pesca esportiva, sempre soltando',
        'followers': 210,
        'following': 95,
        'posts': 3,
      }
      ..followRequests.addAll(['cid', 'dani'])
      ..feedPosts.addAll([
        {
          ...FakeServer.post('card_catch_cover_story_photo', likes: 14),
          'author': {
            'handle': 'bia',
            'display_name': 'Bia Ribeiro',
            'avatar_url': null,
          },
          'caption': 'Primeiro dourado do ano, voltou pra água',
          'liked': true,
        },
        {
          ...FakeServer.post(
            'card_trip_chart_square_plain',
            handle: 'joao',
            caption: 'Manhã boa na represa',
            likes: 3,
            audience: 'friends',
          ),
          'width': 1080,
          'height': 1080,
        },
      ]);
    final app = await TestApp.start(
      tester,
      overrides: [
        apiFactoryProvider.overrideWithValue(
          (base, token) =>
              PiscatioApi(server.client(), base: base, token: token),
        ),
        socialImageProvider.overrideWithValue((url) {
          final id = Uri.parse(url).pathSegments.last.replaceAll('.png', '');
          final file = cards[id];
          return file != null && file.existsSync()
              ? FileImage(file)
              : MemoryImage(pixel);
        }),
      ],
    );
    await app.run(tester, () async {
      await app.read(settingsRepositoryProvider).completeOnboarding();
      await app
          .read(accountRepositoryProvider)
          .signedIn(
            const ApiSession(token: FakeServer.token, email: FakeServer.email),
          );
    });
    await seedSummaryTrip(app, tester);
    await app.pumpApp(tester);
    // Card images decode on the real event loop.
    final context = tester.element(find.byType(Scaffold).first);
    for (final f in cards.values.where((f) => f.existsSync())) {
      await tester.runAsync(() => precacheImage(FileImage(f), context));
    }
    await tester.tap(find.text('Comunidade'));
    await app.settle(tester);
    await saveScreenshot(tester, 'community_feed');
    await tester.drag(find.byType(ListView).first, const Offset(0, -560));
    await app.settle(tester);
    await saveScreenshot(tester, 'community_feed_scrolled');

    server.people['bia']!['can_see'] = true;
    unawaited(app.read(routerProvider).push(AppRoutes.person('bia')));
    await app.settle(tester);
    await saveScreenshot(tester, 'community_person');
    app.read(routerProvider).pop();
    await app.settle(tester);
    await tester.tap(find.byTooltip('Pedidos para seguir'));
    await app.settle(tester);
    await saveScreenshot(tester, 'community_requests');
    app.read(routerProvider).pop();
    await app.settle(tester);

    unawaited(app.read(routerProvider).push(AppRoutes.communityProfile));
    await app.settle(tester);
    await saveScreenshot(tester, 'community_profile_edit');
    app.read(routerProvider).pop();
    await app.settle(tester);

    unawaited(app.read(routerProvider).push(AppRoutes.yearSummary(2026)));
    await app.settle(tester);
    await saveScreenshot(tester, 'year_summary');
    await app.dispose(tester);
  }, skip: !screenshotsEnabled);
}
