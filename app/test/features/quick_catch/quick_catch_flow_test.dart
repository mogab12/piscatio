import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piscatio/core/media/photo_source.dart';
import 'package:piscatio/core/providers.dart';
import 'package:piscatio/data/media/exif_summary.dart';
import 'package:piscatio/data/media/photo_importer.dart';
import 'package:piscatio/domain/models/catch.dart';
import 'package:piscatio/domain/models/enums.dart';
import 'package:piscatio/domain/services/units.dart';
import 'package:piscatio/features/active_trip/presentation/active_trip_screen.dart';
import 'package:piscatio/features/quick_catch/presentation/quick_catch_screen.dart';

import '../../helpers/fakes.dart';
import '../../helpers/pump_app.dart';

class _Flow {
  _Flow(this.app, this.tripId, this.photos);

  final TestApp app;
  final String tripId;
  final FakePhotoSource photos;

  Future<List<Catch>> catches(WidgetTester tester) => app.run(
    tester,
    () => app.read(catchRepositoryProvider).watchCatchesForTrip(tripId).first,
  );
}

/// Onboarded app with a running trip, opened on the active trip screen.
Future<_Flow> _openActiveTrip(
  WidgetTester tester, {
  UnitSystem units = UnitSystem.metric,
}) async {
  final photos = FakePhotoSource();
  final app = await TestApp.start(
    tester,
    overrides: [
      photoSourceProvider.overrideWithValue(photos),
      imageProcessorProvider.overrideWithValue(PassThroughImageProcessor()),
    ],
  );
  final trip = await app.run(tester, () async {
    final settings = app.read(settingsRepositoryProvider);
    await settings.completeOnboarding();
    await settings.setUnitSystem(units);
    return app
        .read(tripRepositoryProvider)
        .startTrip(timezone: 'UTC', privacy: PrivacyLevel.private);
  });
  await app.pumpApp(tester);
  await tester.tap(find.text('Voltar à pescaria'));
  await app.settle(tester);
  expect(find.byType(ActiveTripScreen), findsOneWidget);
  return _Flow(app, trip.id, photos);
}

void main() {
  testWidgets('no photo, search by a regional synonym, save, undo', (
    tester,
  ) async {
    final flow = await _openActiveTrip(tester);
    final app = flow.app;

    await tester.tap(find.text('+ Captura'));
    await app.settle(tester);
    expect(find.byType(QuickCatchScreen), findsOneWidget);

    await tester.tap(find.text('Sem foto'));
    await app.settle(tester);
    expect(find.text('Qual é o peixe?'), findsOneWidget);

    // Argentine name, no accents: still finds the traíra.
    await tester.enterText(find.byType(TextField), 'tararira');
    await app.settle(tester);
    expect(find.text('Também: Tararira'), findsOneWidget);
    await tester.tap(find.text('Traíra'));
    await app.settle(tester);

    expect(find.text('Hoplias malabaricus'), findsOneWidget);
    await tester.tap(find.text('Salvar captura'));
    await app.settle(tester);

    expect(find.byType(ActiveTripScreen), findsOneWidget);
    expect(find.text('Captura salva'), findsOneWidget);
    final saved = await flow.catches(tester);
    expect(saved.single.speciesId, 'hoplias-malabaricus');
    expect(saved.single.photos, isEmpty);
    expect(find.text('Traíra'), findsOneWidget);

    await tester.tap(find.text('Desfazer'));
    await app.settle(tester);
    expect(await flow.catches(tester), isEmpty);
    await app.dispose(tester);
  });

  testWidgets('the undo bar goes away by itself, catch after catch', (
    tester,
  ) async {
    final flow = await _openActiveTrip(tester);
    final app = flow.app;
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text('+ Captura'));
      await app.settle(tester);
      await tester.tap(find.text('Sem foto'));
      await app.settle(tester);
      await tester.enterText(find.byType(TextField), 'dourado');
      await app.settle(tester);
      await tester.tap(find.text('Dourado').first);
      await app.settle(tester);
      await tester.tap(find.text('Salvar captura'));
      await app.settle(tester);
      expect(find.text('Captura salva'), findsOneWidget);
      await tester.pump(undoWindow + const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text('Captura salva'), findsNothing);
    }
    expect(await flow.catches(tester), hasLength(2));
    await app.dispose(tester);
  });

  testWidgets('gallery photo is stored without EXIF and details in SI', (
    tester,
  ) async {
    final flow = await _openActiveTrip(tester);
    final app = flow.app;

    await tester.tap(find.text('+ Captura'));
    await app.settle(tester);
    await tester.tap(find.text('Galeria'));
    await app.settle(tester);
    expect(flow.photos.picks, [PhotoOrigin.gallery]);

    await tester.enterText(find.byType(TextField), 'dourado');
    await app.settle(tester);
    await tester.tap(find.text('Dourado').first);
    await app.settle(tester);

    await tester.tap(find.text('Mais detalhes'));
    await app.settle(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Peso'), '4,25');
    await tester.enterText(
      find.widgetWithText(TextField, 'Comprimento'),
      '68,5',
    );
    final released = find.widgetWithText(ChoiceChip, 'Soltei');
    await tester.ensureVisible(released);
    await app.settle(tester);
    await tester.tap(released);
    await app.settle(tester);
    await tester.tap(find.text('Salvar captura'));
    await app.settle(tester);

    final c = (await flow.catches(tester)).single;
    expect(c.speciesId, 'salminus-brasiliensis');
    expect(c.weightGrams, 4250);
    expect(c.lengthMillimeters, 685);
    expect(c.released, isTrue);
    final photo = c.coverPhoto!;
    expect(photo.relativePath, startsWith('photos/'));
    expect(photo.takenAt, DateTime.utc(2026, 9, 12, 10, 41));

    final file = File('${app.photoRoot.path}/${photo.relativePath}');
    final bytes = await app.run(tester, file.readAsBytes);
    final exif = await app.run(tester, () => readExifSummary(bytes));
    expect(exif.location, isNull);
    await app.dispose(tester);
  });

  testWidgets('imperial units: pounds and ounces become grams', (tester) async {
    final flow = await _openActiveTrip(tester, units: UnitSystem.imperial);
    final app = flow.app;
    await tester.tap(find.text('+ Captura'));
    await app.settle(tester);
    await tester.tap(find.text('Sem foto'));
    await app.settle(tester);
    await tester.tap(find.text('Não sei a espécie'));
    await app.settle(tester);
    expect(find.text('Espécie não identificada'), findsOneWidget);

    await tester.tap(find.text('Mais detalhes'));
    await app.settle(tester);
    expect(find.text('lb'), findsOneWidget);
    expect(find.text('pol'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Peso'), '5');
    await tester.enterText(find.widgetWithText(TextField, 'Onças'), '3');
    await tester.enterText(
      find.widgetWithText(TextField, 'Comprimento'),
      '20,5',
    );
    await app.settle(tester);
    await tester.tap(find.text('Salvar captura'));
    await app.settle(tester);

    final c = (await flow.catches(tester)).single;
    expect(c.speciesId, isNull);
    expect(c.weightGrams, 2353);
    expect(c.lengthMillimeters, 521);
    await app.dispose(tester);
  });

  testWidgets('an invalid number blocks saving until fixed', (tester) async {
    final flow = await _openActiveTrip(tester);
    final app = flow.app;
    await tester.tap(find.text('+ Captura'));
    await app.settle(tester);
    await tester.tap(find.text('Sem foto'));
    await app.settle(tester);
    await tester.tap(find.text('Não sei a espécie'));
    await app.settle(tester);
    await tester.tap(find.text('Mais detalhes'));
    await app.settle(tester);

    await tester.enterText(find.widgetWithText(TextField, 'Peso'), 'dois');
    await app.settle(tester);
    expect(find.text('Digite um número, como 2,5'), findsOneWidget);
    await tester.tap(find.text('Salvar captura'));
    await app.settle(tester);
    expect(find.byType(QuickCatchScreen), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Peso'), '2');
    await app.settle(tester);
    await tester.tap(find.text('Salvar captura'));
    await app.settle(tester);
    expect((await flow.catches(tester)).single.weightGrams, 2000);
    await app.dispose(tester);
  });

  testWidgets('cancelling discards the imported photo', (tester) async {
    final flow = await _openActiveTrip(tester);
    final app = flow.app;
    await tester.tap(find.text('+ Captura'));
    await app.settle(tester);
    await tester.tap(find.text('Galeria'));
    await app.settle(tester);
    final photosDir = Directory('${app.photoRoot.path}/photos');
    expect(photosDir.listSync(), hasLength(1));

    await tester.tap(find.byTooltip('Cancelar'));
    await app.settle(tester);
    expect(find.byType(ActiveTripScreen), findsOneWidget);
    expect(await flow.catches(tester), isEmpty);
    // The copy is deleted in the background after the screen closes.
    await app.settleUntil(tester, () => photosDir.listSync().isEmpty);
    await app.dispose(tester);
  });

  testWidgets('most caught species appear first as tiles', (tester) async {
    final flow = await _openActiveTrip(tester);
    final app = flow.app;
    // One quick catch of a peacock bass to build usage.
    await tester.tap(find.text('+ Captura'));
    await app.settle(tester);
    await tester.tap(find.text('Sem foto'));
    await app.settle(tester);
    await tester.enterText(find.byType(TextField), 'tucunare amarelo');
    await app.settle(tester);
    await tester.tap(find.text('Tucunaré-amarelo'));
    await app.settle(tester);
    await tester.tap(find.text('Salvar captura'));
    await app.settle(tester);

    await tester.tap(find.text('+ Captura'));
    await app.settle(tester);
    await tester.tap(find.text('Sem foto'));
    await app.settle(tester);
    expect(find.text('Suas mais pescadas'), findsOneWidget);
    // The tile appears before the full list.
    final tile = tester.getTopLeft(find.text('Tucunaré-amarelo').first);
    final all = tester.getTopLeft(find.text('Todas as espécies'));
    expect(tile.dy, lessThan(all.dy));
    await app.dispose(tester);
  });
}
