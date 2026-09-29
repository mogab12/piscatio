import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:piscatio/core/background.dart';
import 'package:piscatio/core/providers.dart';
import 'package:piscatio/data/db/tables.dart';
import 'package:piscatio/data/repositories/catch_repository.dart';
import 'package:piscatio/domain/models/catch.dart';
import 'package:piscatio/domain/models/enums.dart';
import 'package:piscatio/domain/models/geo_point.dart';
import 'package:piscatio/domain/services/map_sketch.dart';
import 'package:piscatio/domain/services/overpass_map.dart';
import 'package:piscatio/features/cards/application/card_data.dart';
import 'package:piscatio/features/cards/application/card_exporter.dart';
import 'package:piscatio/features/cards/application/photo_filters.dart';
import 'package:piscatio/features/cards/presentation/card_canvas.dart';
import 'package:piscatio/features/cards/presentation/card_editor_screen.dart';
import 'package:piscatio/features/cards/presentation/card_view.dart';

import '../../helpers/pump_app.dart';

class _FakeSharer implements CardSharer {
  final shared = <(Uint8List, String)>[];

  @override
  Future<void> sharePng(Uint8List png, String fileName) async =>
      shared.add((png, fileName));
}

/// Width and height from a PNG's IHDR chunk.
(int, int) pngSize(Uint8List png) {
  final data = ByteData.sublistView(png);
  return (data.getUint32(16), data.getUint32(20));
}

Future<(TestApp, String, String, _FakeSharer)> _setup(
  WidgetTester tester, {
  PrivacyLevel privacy = PrivacyLevel.exact,
  bool photo = false,
}) async {
  final sharer = _FakeSharer();
  final app = await TestApp.start(
    tester,
    overrides: [cardSharerProvider.overrideWithValue(sharer)],
  );
  final (tripId, catchId) = await app.run(tester, () async {
    final start = app.clock.now().subtract(const Duration(hours: 4));
    final trip = await app
        .read(tripRepositoryProvider)
        .createPastTrip(
          startedAt: start,
          endedAt: start.add(const Duration(hours: 3)),
          timezone: 'UTC',
          privacy: privacy,
          location: const GeoPoint(-16.52, -56.41),
          locationName: 'Poço do Dourado',
        );
    await app.read(tripRepositoryProvider).fillRegion(trip.id, 'Cuiabá, MT');
    final repo = app.read(catchRepositoryProvider);
    final c = await repo.addCatch(
      tripId: trip.id,
      speciesId: 'hoplias-malabaricus',
      caughtAt: start.add(const Duration(hours: 1)),
    );
    await repo.updateDetails(
      c.id,
      const CatchDetails(
        speciesId: 'hoplias-malabaricus',
        lengthMillimeters: 480,
        weightGrams: 1300,
        released: true,
      ),
    );
    if (photo) {
      final file = File(p.join(app.photoRoot.path, 'photos', 'p1.jpg'))
        ..createSync(recursive: true);
      File('test/fixtures/card_photo.jpg').copySync(file.path);
      await repo.addPhoto(
        c.id,
        const StoredPhoto(
          relativePath: 'photos/p1.jpg',
          width: 1200,
          height: 1600,
        ),
      );
    }
    return (trip.id, c.id);
  });
  return (app, tripId, catchId, sharer);
}

void main() {
  testWidgets('trip card: styles, formats, place, share a PNG', (tester) async {
    final (app, tripId, _, sharer) = await _setup(tester);
    await app.pumpScreen(
      tester,
      CardEditorScreen(subject: CardSubject.trip, id: tripId),
    );

    TripCardView view() => tester.widget(find.byType(TripCardView));
    expect(view().style, CardStyle.board);
    expect(view().format, CardFormat.story);
    // Exact privacy: the place name shows, and can be hidden.
    expect(view().shown.place, 'Poço do Dourado');
    expect(find.text('Poço do Dourado'), findsWidgets);
    // The brand is on the card, with its tagline.
    expect(find.text('Diário de pesca'), findsOneWidget);

    await tester.tap(find.text('Carta'));
    await app.settle(tester);
    expect(view().style, CardStyle.chart);
    await tester.tap(find.text('Quadrado'));
    await app.settle(tester);
    expect(view().format, CardFormat.square);
    expect(tester.getSize(find.byType(TripCardView)), CardFormat.square.size);

    await tester.tap(find.text('Detalhes'));
    await app.settle(tester);
    await tester.tap(find.text('Mostrar local'));
    await app.settle(tester);
    expect(view().shown.place, isNull);
    expect(find.text('Poço do Dourado'), findsNothing);

    await tester.tap(find.text('Compartilhar'));
    // Rendering and PNG encoding run on the real event loop.
    await app.settleUntil(tester, () => sharer.shared.isNotEmpty);
    await app.settle(tester);
    expect(sharer.shared, hasLength(1));
    final (png, name) = sharer.shared.single;
    expect(pngSize(png), (1080, 1080));
    expect(name, 'piscatio-chart-square.png');
    await app.dispose(tester);
  });

  testWidgets('theme, details and caption make the card yours', (tester) async {
    final (app, _, catchId, _) = await _setup(tester);
    await app.pumpScreen(
      tester,
      CardEditorScreen(subject: CardSubject.catchItem, id: catchId),
    );
    CatchCardView view() => tester.widget(find.byType(CatchCardView));

    await tester.tap(find.text('Tema'));
    await app.settle(tester);
    await tester.ensureVisible(find.bySemanticsLabel('Tucunaré'));
    await app.settle(tester);
    await tester.tap(find.bySemanticsLabel('Tucunaré'));
    await app.settle(tester);
    expect(view().options.palette, CardPalette.tucunare);
    // The whole card follows: its ground is the theme's.
    final canvas = tester.widget<CardCanvas>(find.byType(CardCanvas));
    expect(canvas.palette, CardPalette.tucunare);

    await tester.tap(find.text('Detalhes'));
    await app.settle(tester);
    await tester.tap(find.text('Clima e lua'));
    await app.settle(tester);
    expect(view().shown.moon, isNull);

    await tester.tap(find.text('Legenda'));
    await app.settle(tester);
    await tester.enterText(find.byType(TextField), 'Primeira traíra do ano');
    await app.settle(tester);
    expect(view().shown.caption, 'Primeira traíra do ano');
    // Shown on the card itself (and typed in the field).
    expect(find.text('Primeira traíra do ano'), findsNWidgets(2));

    // No photos on this catch: the photo tab says so.
    await tester.tap(find.text('Foto'));
    await app.settle(tester);
    expect(find.text('Sem fotos para usar no card.'), findsOneWidget);
    await app.dispose(tester);
  });

  testWidgets('catch card renders at 1080×1920 in every style', (tester) async {
    final (app, _, catchId, _) = await _setup(tester);
    await app.pumpScreen(
      tester,
      CardEditorScreen(subject: CardSubject.catchItem, id: catchId),
    );
    for (final style in ['Régua', 'Carta', 'Etiqueta']) {
      await tester.ensureVisible(find.text(style));
      await app.settle(tester);
      await tester.tap(find.text(style));
      await app.settle(tester);
      expect(tester.takeException(), isNull);
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find
            .ancestor(
              of: find.byType(CatchCardView),
              matching: find.byType(RepaintBoundary),
            )
            .first,
      );
      final png = (await tester.runAsync(() => captureCard(boundary)))!;
      expect(pngSize(png), (1080, 1920));
    }
    final card = tester.widget<CatchCardView>(find.byType(CatchCardView));
    expect(card.data.speciesName, 'Traíra');
    expect(card.data.lengthLabel, '48 cm');
    await app.dispose(tester);
  });

  testWidgets('private trip: the card never shows the place', (tester) async {
    final (app, tripId, _, _) = await _setup(
      tester,
      privacy: PrivacyLevel.private,
    );
    await app.pumpScreen(
      tester,
      CardEditorScreen(subject: CardSubject.trip, id: tripId),
    );
    final view = tester.widget<TripCardView>(find.byType(TripCardView));
    expect(view.data.place, isNull);
    await tester.tap(find.text('Detalhes'));
    await app.settle(tester);
    expect(
      find.text('Esta pescaria é privada: o card não mostra onde foi.'),
      findsOneWidget,
    );
    final chip = tester.widget<FilterChip>(
      find.widgetWithText(FilterChip, 'Mostrar local'),
    );
    expect(chip.onSelected, isNull);
    expect(find.text('Cuiabá, MT'), findsNothing);
    await app.dispose(tester);
  });

  testWidgets('approximate trip: only the region, with a note', (tester) async {
    final (app, tripId, _, _) = await _setup(
      tester,
      privacy: PrivacyLevel.approximate,
    );
    await app.pumpScreen(
      tester,
      CardEditorScreen(subject: CardSubject.trip, id: tripId),
    );
    final view = tester.widget<TripCardView>(find.byType(TripCardView));
    expect(view.shown.place, 'Cuiabá, MT');
    await tester.tap(find.text('Detalhes'));
    await app.settle(tester);
    expect(find.text('Mostra só a região, nunca o ponto.'), findsOneWidget);
    expect(find.text('Poço do Dourado'), findsNothing);
    await app.dispose(tester);
  });

  testWidgets('a filter redraws the photo in the theme colors', (tester) async {
    final (app, _, catchId, _) = await _setup(tester, photo: true);
    await app.pumpScreen(
      tester,
      CardEditorScreen(subject: CardSubject.catchItem, id: catchId),
    );
    CatchCardView view() => tester.widget(find.byType(CatchCardView));
    CardCanvas canvas() => tester.widget(find.byType(CardCanvas));
    final photo = view().data.photoPath!;

    await tester.tap(find.text('Foto'));
    await app.settle(tester);
    await tester.ensureVisible(find.text('Nanquim'));
    await tester.tap(find.text('Nanquim'));
    await app.settle(tester);
    expect(app.filters.requests.single, (photo, CardPhotoFilter.ink));
    expect(view().options.activeFilter, CardPhotoFilter.ink);
    expect(canvas().photoFilter, CardPhotoFilter.ink);

    // Without a photo there is nothing to filter.
    await tester.tap(find.text('Sem foto'));
    await app.settle(tester);
    expect(view().shown.photoPath, isNull);
    expect(canvas().photoFilter, CardPhotoFilter.none);

    // Back to the photo: the filter is made for it again. When that fails,
    // the card keeps the plain photo and says so.
    app.filters.fail = true;
    await tester.tap(find.bySemanticsLabel('Foto 1'));
    await app.settle(tester);
    expect(app.filters.requests.last, (photo, CardPhotoFilter.ink));
    expect(
      find.text('Não deu para aplicar o filtro nesta foto.'),
      findsOneWidget,
    );
    expect(view().options.photoFilter, CardPhotoFilter.none);
    expect(view().shown.photoPath, photo);

    app.filters.fail = false;
    await tester.ensureVisible(find.text('Original'));
    await app.settle(tester);
    await tester.tap(find.text('Original'));
    await app.settle(tester);
    expect(canvas().photoFilter, CardPhotoFilter.none);
    await app.dispose(tester);
  });

  group('map', () {
    Future<void> storeMap(TestApp app, WidgetTester tester) =>
        app.run(tester, () async {
          final secret = await app
              .read(settingsRepositoryProvider)
              .privacySecret();
          final area = mapAreaFor(const GeoPoint(-16.52, -56.41), secret);
          final json = jsonDecode(
            File('test/fixtures/overpass_reservoir.json').readAsStringSync(),
          ) as Map<String, Object?>;
          await app
              .read(placeMapRepositoryProvider)
              .save(area.key, OverpassMap.parse(json, area.center));
        });

    testWidgets('a trip with its map offers the map style', (tester) async {
      final (app, tripId, _, _) = await _setup(tester);
      await storeMap(app, tester);
      await app.pumpScreen(
        tester,
        CardEditorScreen(subject: CardSubject.trip, id: tripId),
      );
      TripCardView view() => tester.widget(find.byType(TripCardView));
      expect(view().data.map, isNotNull);

      await tester.ensureVisible(find.text('Mapa'));
      await app.settle(tester);
      await tester.tap(find.text('Mapa'));
      await app.settle(tester);
      expect(view().style, CardStyle.map);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Detalhes'));
      await app.settle(tester);
      expect(
        find.text('O círculo marca a região, nunca o ponto exato.'),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Mapa do local'));
      await tester.tap(find.text('Mapa do local'));
      await app.settle(tester);
      expect(view().shown.map, isNull);
      await app.dispose(tester);
    });

    testWidgets('private trips: no map, and none is asked for', (tester) async {
      final (app, tripId, _, _) = await _setup(
        tester,
        privacy: PrivacyLevel.private,
      );
      await app.pumpScreen(
        tester,
        CardEditorScreen(subject: CardSubject.trip, id: tripId),
      );
      TripCardView view() => tester.widget(find.byType(TripCardView));
      expect(view().data.map, isNull);
      final chip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'Mapa'),
      );
      expect(chip.onSelected, isNull);
      await tester.tap(find.text('Detalhes'));
      await app.settle(tester);
      expect(find.text('Pescarias privadas não mostram mapa.'), findsOneWidget);
      final jobs = await app.run(
        tester,
        () => app.read(jobQueueProvider).all(),
      );
      expect(jobs.where((j) => j.kind == JobKind.placeMap), isEmpty);
      await app.dispose(tester);
    });

    testWidgets('a missing map is queued and explained', (tester) async {
      final (app, tripId, _, _) = await _setup(tester);
      await app.pumpScreen(
        tester,
        CardEditorScreen(subject: CardSubject.trip, id: tripId),
      );
      await tester.tap(find.text('Detalhes'));
      await app.settle(tester);
      expect(
        find.text('O mapa chega quando o celular estiver online.'),
        findsOneWidget,
      );
      final jobs = await app.run(
        tester,
        () => app.read(jobQueueProvider).all(),
      );
      // Tried at once; offline in tests, so it waits for a retry.
      final map = jobs.singleWhere((j) => j.kind == JobKind.placeMap);
      expect(map.subjectId, tripId);
      expect(map.lastError, contains('503'));
      await app.dispose(tester);
    });
  });
}
