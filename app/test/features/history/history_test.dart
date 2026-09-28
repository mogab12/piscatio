import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piscatio/core/providers.dart';
import 'package:piscatio/domain/models/catch.dart';
import 'package:piscatio/domain/models/enums.dart';
import 'package:piscatio/features/common/species_picker.dart';
import 'package:piscatio/features/history/presentation/catch_detail_screen.dart';
import 'package:piscatio/features/history/presentation/history_screen.dart';
import 'package:piscatio/features/history/presentation/trip_detail_screen.dart';

import '../../helpers/pump_app.dart';

/// Two finished trips (August and September) and the ids of the second.
Future<(TestApp, String, String)> _seeded(WidgetTester tester) async {
  final app = await TestApp.start(tester);
  final ids = await app.run(tester, () async {
    await app.read(settingsRepositoryProvider).completeOnboarding();
    final trips = app.read(tripRepositoryProvider);
    final catches = app.read(catchRepositoryProvider);

    app.clock.set(DateTime.utc(2026, 8, 20, 10));
    final august = await trips.startTrip(
      timezone: 'UTC',
      privacy: PrivacyLevel.private,
    );
    await catches.addCatch(tripId: august.id, speciesId: 'cichla-kelberi');
    app.clock.advance(const Duration(hours: 2));
    await trips.finishTrip(august.id);

    app.clock.set(DateTime.utc(2026, 9, 10, 10));
    final sept = await trips.startTrip(
      timezone: 'UTC',
      privacy: PrivacyLevel.private,
    );
    await trips.updateTrip(sept.copyWith(locationName: 'Rio Cuiabá'));
    final small = await catches.addCatch(
      tripId: sept.id,
      speciesId: 'hoplias-malabaricus',
    );
    await catches.updateDetails(
      small.id,
      const CatchDetails(speciesId: 'hoplias-malabaricus', weightGrams: 900),
    );
    app.clock.advance(const Duration(minutes: 30));
    final big = await catches.addCatch(
      tripId: sept.id,
      speciesId: 'pseudoplatystoma-corruscans',
    );
    await catches.updateDetails(
      big.id,
      const CatchDetails(
        speciesId: 'pseudoplatystoma-corruscans',
        weightGrams: 8400,
      ),
    );
    app.clock.set(DateTime.utc(2026, 9, 10, 13, 20));
    await trips.finishTrip(sept.id);
    app.clock.set(DateTime.utc(2026, 9, 12, 9));
    return (sept.id, small.id);
  });
  return (app, ids.$1, ids.$2);
}

Future<void> _openLogbook(TestApp app, WidgetTester tester) async {
  await app.pumpApp(tester);
  await tester.tap(find.text('Diário'));
  await app.settle(tester);
  expect(find.byType(HistoryScreen), findsOneWidget);
}

void main() {
  testWidgets('logbook groups trips by month, newest first', (tester) async {
    final (app, _, _) = await _seeded(tester);
    await _openLogbook(app, tester);
    final sept = tester.getTopLeft(find.text('Setembro de 2026'));
    final aug = tester.getTopLeft(find.text('Agosto de 2026'));
    expect(sept.dy, lessThan(aug.dy));
    expect(find.text('Rio Cuiabá'), findsOneWidget);
    await app.dispose(tester);
  });

  testWidgets('trip detail shows duration, counts and the biggest catch', (
    tester,
  ) async {
    final (app, _, _) = await _seeded(tester);
    await _openLogbook(app, tester);
    await tester.tap(find.text('Rio Cuiabá'));
    await app.settle(tester);
    expect(find.byType(TripDetailScreen), findsOneWidget);
    expect(find.text('3 h 20 min'), findsOneWidget);
    expect(find.text('Maior: Pintado, 8,4 kg'), findsOneWidget);
    expect(find.text('2 capturas'), findsOneWidget);
    expect(find.text('Traíra'), findsOneWidget);
    await app.dispose(tester);
  });

  testWidgets('editing a trip saves place, region and privacy', (tester) async {
    final (app, tripId, _) = await _seeded(tester);
    await _openLogbook(app, tester);
    await tester.tap(find.text('Rio Cuiabá'));
    await app.settle(tester);
    await tester.tap(find.byTooltip('Editar'));
    await app.settle(tester);

    await tester.enterText(
      find.widgetWithText(TextField, 'Nome do local'),
      'Rio Paraguai',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Região'),
      'Cáceres, MT',
    );
    await tester.tap(find.text('Privacidade do local'));
    await app.settle(tester);
    await tester.tap(find.text('Região aproximada'));
    await app.settle(tester);
    await tester.tap(find.text('Salvar'));
    await app.settle(tester);

    final trip = (await app.run(
      tester,
      () => app.read(tripRepositoryProvider).getTrip(tripId),
    ))!;
    expect(trip.locationName, 'Rio Paraguai');
    expect(trip.locationRegion, 'Cáceres, MT');
    expect(trip.privacyLevel, PrivacyLevel.approximate);
    expect(find.text('Rio Paraguai'), findsOneWidget);
    await app.dispose(tester);
  });

  testWidgets('deleting a trip asks first and removes it', (tester) async {
    final (app, tripId, _) = await _seeded(tester);
    await _openLogbook(app, tester);
    await tester.tap(find.text('Rio Cuiabá'));
    await app.settle(tester);
    await tester.tap(find.byTooltip('Excluir pescaria'));
    await app.settle(tester);
    expect(find.textContaining('As capturas e fotos'), findsOneWidget);
    await tester.tap(find.text('Excluir'));
    await app.settle(tester);

    expect(find.byType(HistoryScreen), findsOneWidget);
    expect(find.text('Rio Cuiabá'), findsNothing);
    expect(
      await app.run(
        tester,
        () => app.read(tripRepositoryProvider).getTrip(tripId),
      ),
      isNull,
    );
    await app.dispose(tester);
  });

  testWidgets('editing a catch: species via search and weight', (tester) async {
    final (app, _, catchId) = await _seeded(tester);
    await _openLogbook(app, tester);
    await tester.tap(find.text('Rio Cuiabá'));
    await app.settle(tester);
    await tester.tap(find.text('Traíra'));
    await app.settle(tester);
    expect(find.byType(CatchDetailScreen), findsOneWidget);
    expect(find.text('Hoplias malabaricus'), findsOneWidget);

    await tester.tap(find.text('Trocar'));
    await app.settle(tester);
    await tester.enterText(
      find.descendant(
        of: find.byType(SpeciesPicker),
        matching: find.byType(TextField),
      ),
      'pacu',
    );
    await app.settle(tester);
    await tester.tap(find.text('Pacu').first);
    await app.settle(tester);
    expect(find.text('Piaractus mesopotamicus'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Peso'), '1,2');
    await app.settle(tester);
    await tester.tap(find.text('Salvar'));
    await app.settle(tester);

    final c = (await app.run(
      tester,
      () => app.read(catchRepositoryProvider).getCatch(catchId),
    ))!;
    expect(c.speciesId, 'piaractus-mesopotamicus');
    expect(c.weightGrams, 1200);
    await app.dispose(tester);
  });

  testWidgets('deleting a catch removes it from the trip', (tester) async {
    final (app, _, catchId) = await _seeded(tester);
    await _openLogbook(app, tester);
    await tester.tap(find.text('Rio Cuiabá'));
    await app.settle(tester);
    await tester.tap(find.text('Traíra'));
    await app.settle(tester);
    await tester.tap(find.byTooltip('Excluir captura'));
    await app.settle(tester);
    await tester.tap(find.text('Excluir'));
    await app.settle(tester);
    expect(find.byType(TripDetailScreen), findsOneWidget);
    expect(find.text('Traíra'), findsNothing);
    expect(find.text('1 captura'), findsOneWidget);
    expect(
      await app.run(
        tester,
        () => app.read(catchRepositoryProvider).getCatch(catchId),
      ),
      isNull,
    );
    await app.dispose(tester);
  });
}
