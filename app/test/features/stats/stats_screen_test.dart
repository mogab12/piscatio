import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piscatio/core/providers.dart';
import 'package:piscatio/domain/models/catch.dart';
import 'package:piscatio/domain/models/enums.dart';
import 'package:piscatio/features/stats/presentation/stats_screen.dart';

import '../../helpers/pump_app.dart';
import '../summary/trip_summary_test.dart' show seedSummaryTrip;

void main() {
  testWidgets('empty logbook invites the first trip', (tester) async {
    final app = await TestApp.start(tester);
    await app.pumpScreen(tester, const StatsScreen());
    expect(find.text('Seus números'), findsOneWidget);
    expect(
      find.text('Seus números aparecem depois da primeira pescaria.'),
      findsOneWidget,
    );
    await app.dispose(tester);
  });

  testWidgets('totals, hour chart, rankings, records and best trip', (
    tester,
  ) async {
    final app = await TestApp.start(tester);
    await seedSummaryTrip(app, tester);
    await app.pumpScreen(tester, const StatsScreen());

    expect(find.text('3'), findsOneWidget);
    expect(find.text('capturas'), findsOneWidget);
    expect(find.text('pescarias'), findsOneWidget);
    expect(find.text('Capturas por horário'), findsOneWidget);
    expect(find.byType(HourChart), findsOneWidget);
    expect(find.textContaining('Mais capturas entre'), findsOneWidget);
    // Three catches, no pattern yet.
    expect(find.text('O que funcionou'), findsOneWidget);
    expect(find.textContaining('Ainda sem padrões'), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
    await app.settle(tester);
    Finder built(String text) => find.text(text, skipOffstage: false);
    expect(built('Espécies mais pescadas'), findsOneWidget);
    // Traíra: two catches (one per trip); dourado: one.
    expect(built('2 capturas'), findsOneWidget);
    expect(built('Recordes pessoais'), findsOneWidget);
    expect(built('72 cm'), findsOneWidget);
    expect(built('Melhor pescaria'), findsOneWidget);
    await app.dispose(tester);
  });

  testWidgets('what worked names the bait behind most catches', (tester) async {
    final app = await TestApp.start(tester);
    await app.run(tester, () async {
      final trips = app.read(tripRepositoryProvider);
      final catches = app.read(catchRepositoryProvider);
      final tuvira = await app
          .read(tackleRepositoryProvider)
          .addBait('Tuvira', BaitType.natural);
      final now = app.clock.now();
      for (final day in [3, 10]) {
        final start = now.subtract(Duration(days: day));
        final trip = await trips.createPastTrip(
          startedAt: start,
          endedAt: start.add(const Duration(hours: 5)),
          timezone: 'UTC',
          privacy: PrivacyLevel.private,
        );
        for (final minutes in [30, 90]) {
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
    });
    await app.pumpScreen(tester, const StatsScreen());
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
    await app.settle(tester);
    expect(find.text('O que funcionou'), findsOneWidget);
    expect(find.text('Dourado com Tuvira'), findsOneWidget);
    expect(find.text('4 de 4 capturas com isca anotada'), findsOneWidget);
    await app.dispose(tester);
  });
}
