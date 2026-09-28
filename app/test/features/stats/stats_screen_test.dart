import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
