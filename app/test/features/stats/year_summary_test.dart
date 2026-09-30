import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:piscatio/core/providers.dart';
import 'package:piscatio/features/cards/application/card_data.dart';
import 'package:piscatio/features/cards/application/card_exporter.dart';
import 'package:piscatio/features/cards/presentation/card_view.dart';

import '../../helpers/pump_app.dart';
import '../summary/trip_summary_test.dart' show seedSummaryTrip;

class _Sharer implements CardSharer {
  final shared = <Uint8List>[];

  @override
  Future<void> sharePng(Uint8List png, String fileName) async =>
      shared.add(png);
}

void main() {
  testWidgets('from Stats to the year in review and its card', (tester) async {
    final sharer = _Sharer();
    final app = await TestApp.start(
      tester,
      overrides: [cardSharerProvider.overrideWithValue(sharer)],
    );
    await app.run(
      tester,
      () => app.read(settingsRepositoryProvider).completeOnboarding(),
    );
    await seedSummaryTrip(app, tester);
    await app.pumpApp(tester);
    await tester.tap(find.text('Números'));
    await app.settle(tester);
    expect(find.text('Resumo de 2026'), findsOneWidget);
    await tester.tap(find.text('Resumo de 2026'));
    await app.settle(tester);

    // Two trips, three catches, two species in 2026.
    expect(find.text('pescarias'), findsOneWidget);
    expect(find.text('capturas'), findsOneWidget);
    expect(find.text('espécies'), findsOneWidget);
    expect(find.text('2 dias na água'), findsOneWidget);
    expect(find.text('Mais pescada: Traíra (2)'), findsOneWidget);
    expect(find.text('Maior: Dourado, 72\u00a0cm'), findsOneWidget);
    expect(find.text('Melhor mês: Setembro'), findsOneWidget);
    expect(find.text('Capturas por mês'), findsOneWidget);

    await tester.tap(find.text('Criar card do ano'));
    await app.settle(tester);
    final view = tester.widget<YearCardView>(find.byType(YearCardView));
    expect(view.data.year, 2026);
    expect(view.data.catchCount, 3);
    // The older trip was in August.
    expect(view.data.byMonth[7], 1);
    expect(view.data.byMonth[8], 2);
    // One layout: no style chips, no details tab.
    expect(find.text('Capa'), findsNothing);
    expect(find.text('Detalhes'), findsNothing);
    await tester.tap(find.text('Quadrado'));
    await app.settle(tester);
    expect(tester.getSize(find.byType(YearCardView)), CardFormat.square.size);

    await tester.tap(find.text('Compartilhar'));
    await app.settleUntil(tester, () => sharer.shared.isNotEmpty);
    await app.settle(tester);
    expect(sharer.shared, hasLength(1));
    await app.dispose(tester);
  });
}
