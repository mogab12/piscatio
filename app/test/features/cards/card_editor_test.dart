import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piscatio/core/providers.dart';
import 'package:piscatio/domain/models/catch.dart';
import 'package:piscatio/domain/models/enums.dart';
import 'package:piscatio/domain/models/geo_point.dart';
import 'package:piscatio/features/cards/application/card_data.dart';
import 'package:piscatio/features/cards/application/card_exporter.dart';
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
    return (trip.id, c.id);
  });
  return (app, tripId, catchId, sharer);
}

void main() {
  testWidgets('trip card: styles, formats, place switch, share a PNG', (
    tester,
  ) async {
    final (app, tripId, _, sharer) = await _setup(tester);
    await app.pumpScreen(
      tester,
      CardEditorScreen(subject: CardSubject.trip, id: tripId),
    );

    TripCardView view() => tester.widget(find.byType(TripCardView));
    expect(view().style, CardStyle.board);
    expect(view().format, CardFormat.story);
    // Exact privacy: the place name shows, and can be hidden.
    expect(view().data.place, 'Poço do Dourado');
    expect(find.text('Poço do Dourado'), findsWidgets);

    await tester.tap(find.text('Carta'));
    await app.settle(tester);
    expect(view().style, CardStyle.chart);
    await tester.tap(find.text('Quadrado'));
    await app.settle(tester);
    expect(view().format, CardFormat.square);
    expect(tester.getSize(find.byType(TripCardView)), CardFormat.square.size);

    await tester.tap(find.text('Mostrar local'));
    await app.settle(tester);
    expect(view().data.place, isNull);
    expect(find.text('Poço do Dourado'), findsNothing);

    await tester.tap(find.text('Compartilhar'));
    await app.settle(tester);
    expect(sharer.shared, hasLength(1));
    final (png, name) = sharer.shared.single;
    expect(pngSize(png), (1080, 1080));
    expect(name, 'piscatio-chart-square.png');
    await app.dispose(tester);
  });

  testWidgets('catch card renders at 1080×1920 in every style', (tester) async {
    final (app, _, catchId, _) = await _setup(tester);
    await app.pumpScreen(
      tester,
      CardEditorScreen(subject: CardSubject.catchItem, id: catchId),
    );
    for (final style in ['Régua', 'Carta', 'Etiqueta']) {
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
    expect(
      find.text('Esta pescaria é privada: o card não mostra onde foi.'),
      findsOneWidget,
    );
    final toggle = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
    expect(toggle.onChanged, isNull);
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
    expect(view.data.place, 'Cuiabá, MT');
    expect(find.text('Mostra só a região, nunca o ponto.'), findsOneWidget);
    expect(find.text('Poço do Dourado'), findsNothing);
    await app.dispose(tester);
  });
}
