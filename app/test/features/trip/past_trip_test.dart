import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piscatio/core/background.dart';
import 'package:piscatio/core/media/photo_source.dart';
import 'package:piscatio/core/providers.dart';
import 'package:piscatio/data/db/tables.dart';
import 'package:piscatio/data/media/photo_importer.dart';
import 'package:piscatio/data/remote/place_name_service.dart';
import 'package:piscatio/domain/models/geo_point.dart';
import 'package:piscatio/features/history/presentation/trip_detail_screen.dart';
import 'package:piscatio/features/trip/presentation/past_trip_screen.dart';

import '../../helpers/fakes.dart';
import '../../helpers/pump_app.dart';

Future<TestApp> _start(WidgetTester tester) async {
  final app = await TestApp.start(
    tester,
    overrides: [
      photoSourceProvider.overrideWithValue(FakePhotoSource()),
      imageProcessorProvider.overrideWithValue(PassThroughImageProcessor()),
    ],
  );
  await app.run(
    tester,
    () => app.read(settingsRepositoryProvider).completeOnboarding(),
  );
  return app;
}

Future<void> _openForm(TestApp app, WidgetTester tester) async {
  await app.pumpApp(tester);
  await tester.tap(find.text('Diário'));
  await app.settle(tester);
  await tester.tap(find.text('Registrar pescaria passada'));
  await app.settle(tester);
  expect(find.byType(PastTripScreen), findsOneWidget);
}

void main() {
  testWidgets('a past trip with a place found by name', (tester) async {
    final app = await _start(tester);
    app.places.results = const [
      PlaceResult(
        point: GeoPoint(-21.1, -45.9),
        name: 'Represa de Furnas',
        region: 'Alfenas, MG',
      ),
    ];
    await _openForm(app, tester);

    await tester.tap(find.text('Buscar local por nome'));
    await app.settle(tester);
    await tester.enterText(find.byType(TextField).last, 'Furnas');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await app.settle(tester);
    expect(app.places.searched, ['Furnas']);
    await tester.tap(find.text('Represa de Furnas'));
    await app.settle(tester);
    expect(find.text('Ponto do local marcado'), findsOneWidget);

    await tester.tap(find.text('Salvar pescaria'));
    await app.settle(tester);
    expect(find.byType(TripDetailScreen), findsOneWidget);

    // One-shot reads with get(), never watch().first.
    final trip = (await app.run(
      tester,
      () => app.db.select(app.db.trips).get(),
    )).single;
    expect(trip.isRetroactive, isTrue);
    expect(trip.endedAt, isNotNull);
    expect(trip.locationName, 'Represa de Furnas');
    expect(trip.locationRegion, 'Alfenas, MG');
    expect(trip.latitude, -21.1);
    expect(trip.longitude, -45.9);
    final jobs = await app.run(tester, app.read(jobQueueProvider).all);
    expect(jobs.map((j) => j.kind), [JobKind.weather]);
    await app.dispose(tester);
  });

  testWidgets('photos become catches and suggest date and place', (
    tester,
  ) async {
    final app = await _start(tester);
    // The fixture photo was taken on 12 Sep 2026 at 10:41 UTC.
    app.clock.set(DateTime.utc(2026, 9, 13, 12));
    await _openForm(app, tester);

    await tester.tap(find.text('Adicionar foto'));
    await app.settle(tester);
    await tester.tap(find.text('Galeria'));
    await app.settleUntil(
      tester,
      () => find
          .text('Data e local sugeridos pelas fotos.')
          .evaluate()
          .isNotEmpty,
    );
    expect(find.text('Ponto do local marcado'), findsOneWidget);

    await tester.tap(find.text('Salvar pescaria'));
    await app.settle(tester);
    expect(find.byType(TripDetailScreen), findsOneWidget);

    final trip = (await app.run(
      tester,
      () => app.db.select(app.db.trips).get(),
    )).single;
    expect(trip.startedAt, DateTime.utc(2026, 9, 12, 10, 26));
    expect(trip.endedAt, DateTime.utc(2026, 9, 12, 11, 26));
    expect(trip.latitude, closeTo(-16.52, 0.0001));
    final catches = await app.run(
      tester,
      () => app.db.select(app.db.catches).get(),
    );
    expect(catches.single.caughtAt, DateTime.utc(2026, 9, 12, 10, 41));
    final photos = await app.run(
      tester,
      () => app.db.select(app.db.catchPhotos).get(),
    );
    expect(photos.single.catchId, catches.single.id);
    await app.dispose(tester);
  });
}
