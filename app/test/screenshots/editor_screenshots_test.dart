import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:piscatio/core/background.dart';
import 'package:piscatio/core/providers.dart';
import 'package:piscatio/core/theme/app_theme.dart';
import 'package:piscatio/data/repositories/catch_repository.dart';
import 'package:piscatio/domain/models/enums.dart';
import 'package:piscatio/domain/models/geo_point.dart';
import 'package:piscatio/domain/services/map_sketch.dart';
import 'package:piscatio/domain/services/overpass_map.dart';
import 'package:piscatio/features/cards/presentation/card_editor_screen.dart';

import '../features/summary/trip_summary_test.dart' show seedSummaryTrip;
import '../helpers/pump_app.dart';
import '../helpers/screenshots.dart';

/// A catch with a photo on a trip whose map is stored.
Future<(String, String)> _seed(
  TestApp app,
  WidgetTester tester,
) => app.run(tester, () async {
  final start = app.clock.now().subtract(const Duration(hours: 4));
  final trip = await app
      .read(tripRepositoryProvider)
      .createPastTrip(
        startedAt: start,
        endedAt: start.add(const Duration(hours: 3)),
        timezone: 'UTC',
        privacy: PrivacyLevel.approximate,
        location: const GeoPoint(-16.52, -56.41),
        locationName: 'Poço do Dourado',
      );
  final repo = app.read(catchRepositoryProvider);
  final c = await repo.addCatch(
    tripId: trip.id,
    speciesId: 'salminus-brasiliensis',
    caughtAt: start.add(const Duration(hours: 1)),
  );
  final file = File(p.join(app.photoRoot.path, 'photos', 'p1.jpg'))
    ..createSync(recursive: true);
  File(Platform.environment['PREVIEW_PHOTO'] ?? 'test/fixtures/card_photo.jpg')
      .copySync(file.path);
  await repo.addPhoto(
    c.id,
    const StoredPhoto(relativePath: 'photos/p1.jpg', width: 1200, height: 1600),
  );
  final secret = await app.read(settingsRepositoryProvider).privacySecret();
  final area = mapAreaFor(const GeoPoint(-16.52, -56.41), secret);
  final json = jsonDecode(
    File('test/fixtures/overpass_reservoir.json').readAsStringSync(),
  ) as Map<String, Object?>;
  await app
      .read(placeMapRepositoryProvider)
      .save(area.key, OverpassMap.parse(json, area.center));
  return (trip.id, c.id);
});

void main() {
  setUpAll(loadRealFonts);

  for (final (name, theme) in [
    ('light', AppTheme.light()),
    ('dark', AppTheme.dark()),
  ]) {
    testWidgets('card editor details, $name', (tester) async {
      usePhoneSurface(tester);
      final app = await TestApp.start(tester);
      final tripId = await seedSummaryTrip(app, tester);
      await app.pumpScreen(
        tester,
        CardEditorScreen(subject: CardSubject.trip, id: tripId),
        theme: theme,
      );
      await tester.tap(find.text('Detalhes'));
      await app.settle(tester);
      await saveScreenshot(tester, 'editor_details_$name');
      await tester.tap(find.text('Estilo'));
      await app.settle(tester);
      await saveScreenshot(tester, 'editor_style_$name');
      await app.dispose(tester);
    }, skip: !screenshotsEnabled);
  }

  testWidgets('card editor framing', (tester) async {
    usePhoneSurface(tester);
    final app = await TestApp.start(tester);
    final (_, catchId) = await _seed(app, tester);
    await app.pumpScreen(
      tester,
      CardEditorScreen(subject: CardSubject.catchItem, id: catchId),
    );
    await tester.tap(find.text('Enquadrar'));
    await app.settle(tester);
    tester.widget<Slider>(find.byType(Slider).first).onChanged!(1.8);
    await app.settle(tester);
    await tester.dragFrom(const Offset(180, 260), const Offset(30, -20));
    await app.settle(tester);
    await saveScreenshot(tester, 'editor_frame_photo');

    await tester.tap(find.text('Estilo'));
    await app.settle(tester);
    await tester.ensureVisible(find.text('Mapa'));
    await tester.tap(find.text('Mapa'));
    await app.settle(tester);
    await tester.tap(find.text('Enquadrar'));
    await app.settle(tester);
    await saveScreenshot(tester, 'editor_frame_map_before');
    tester.widget<Slider>(find.byType(Slider).last).onChanged!(2.2);
    await app.settle(tester);
    await tester.dragFrom(const Offset(160, 200), const Offset(25, 15));
    await app.settle(tester);
    await saveScreenshot(tester, 'editor_frame_map');
    await app.dispose(tester);
  }, skip: !screenshotsEnabled);
}
