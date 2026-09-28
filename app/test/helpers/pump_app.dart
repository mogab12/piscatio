import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:piscatio/app.dart';
import 'package:piscatio/core/clock.dart';
import 'package:piscatio/core/device.dart';
import 'package:piscatio/core/ids.dart';
import 'package:piscatio/core/location/location_service.dart';
import 'package:piscatio/core/providers.dart';
import 'package:piscatio/core/theme/app_theme.dart';
import 'package:piscatio/data/db/app_database.dart';
import 'package:piscatio/data/media/photo_storage.dart';
import 'package:piscatio/l10n/generated/app_localizations.dart';

import 'fakes.dart';
import 'test_db.dart';

/// Wraps the pumped tree; screenshots capture this boundary.
const screenKey = ValueKey('screen');

/// Everything a widget test needs: seeded in-memory database, fixed clock,
/// predictable ids and a chosen device locale.
class TestApp {
  TestApp._(
    this.db,
    this.clock,
    this.ids,
    this.container,
    this.location,
    this.photoRoot,
  );

  final AppDatabase db;
  final FakeLocationService location;

  /// Temporary folder standing in for the app documents directory.
  final Directory photoRoot;
  final FixedClock clock;
  final SequentialIdGenerator ids;
  final ProviderContainer container;

  /// Creates the app state with real async I/O (outside the fake clock of
  /// widget tests, where database futures would never complete).
  static Future<TestApp> start(
    WidgetTester tester, {
    Locale deviceLocale = const Locale('pt', 'BR'),
    FakeLocationService? location,
    List<Override> overrides = const [],
  }) async => (await tester.runAsync(
    () => create(
      deviceLocale: deviceLocale,
      location: location,
      overrides: overrides,
    ),
  ))!;

  static Future<TestApp> create({
    Locale deviceLocale = const Locale('pt', 'BR'),
    FakeLocationService? location,
    List<Override> overrides = const [],
  }) async {
    final db = await newSeededDatabase();
    final clock = FixedClock(DateTime.utc(2026, 9, 12, 9));
    final ids = SequentialIdGenerator();
    location ??= FakeLocationService(fix: pantanal);
    final photoRoot = Directory.systemTemp.createTempSync('piscatio_photos');
    final container = ProviderContainer(
      overrides: [
        locationServiceProvider.overrideWithValue(location),
        deviceTimezoneProvider.overrideWith((ref) => 'America/Sao_Paulo'),
        nowTickerProvider.overrideWith((ref) => Stream.value(clock.now())),
        photoRootProvider.overrideWith((ref) => photoRoot),
        appDatabaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(clock),
        idGeneratorProvider.overrideWithValue(ids),
        deviceLocaleProvider.overrideWithValue(deviceLocale),
        deviceLocalesProvider.overrideWithValue([deviceLocale]),
        ...overrides,
      ],
    );
    return TestApp._(db, clock, ids, container, location, photoRoot);
  }

  T read<T>(ProviderListenable<T> provider) => container.read(provider);

  /// Runs real async work (database writes) from a widget test.
  ///
  /// Only call this before [pumpApp]/[pumpScreen]: once the UI watches the
  /// database, its stream re-queries run in the fake-async zone and hold
  /// Drift's lock, so writes from the real zone would deadlock. After the
  /// UI is mounted, change data through the UI instead.
  Future<T> run<T>(WidgetTester tester, Future<T> Function() body) async =>
      (await tester.runAsync(body)) as T;

  /// Pumps the whole app (router, onboarding redirect…).
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const RepaintBoundary(key: screenKey, child: PiscatioApp()),
      ),
    );
    await settle(tester);
  }

  /// Pumps a single screen inside a localized MaterialApp.
  Future<void> pumpScreen(
    WidgetTester tester,
    Widget screen, {
    Locale locale = const Locale('pt'),
  }) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: RepaintBoundary(
          key: screenKey,
          child: MaterialApp(
            locale: locale,
            theme: AppTheme.light(),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: screen,
          ),
        ),
      ),
    );
    await settle(tester);
  }

  /// Lets database streams deliver and animations finish.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();
  }

  /// Unmounts the tree and closes the database (avoids pending timers).
  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    // Drift cancels stream queries with zero-duration timers.
    await tester.pump(const Duration(milliseconds: 10));
    await db.close();
    if (photoRoot.existsSync()) photoRoot.deleteSync(recursive: true);
  }
}
