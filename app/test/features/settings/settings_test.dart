import 'package:flutter_test/flutter_test.dart';
import 'package:piscatio/core/providers.dart';
import 'package:piscatio/domain/models/enums.dart';
import 'package:piscatio/domain/services/units.dart';

import '../../helpers/pump_app.dart';

void main() {
  Future<TestApp> openSettings(WidgetTester tester) async {
    final app = await TestApp.start(tester);
    await app.run(
      tester,
      () => app.read(settingsRepositoryProvider).completeOnboarding(),
    );
    await app.pumpApp(tester);
    await tester.tap(find.text('Ajustes'));
    await app.settle(tester);
    return app;
  }

  testWidgets('changing units updates settings and the row', (tester) async {
    final app = await openSettings(tester);
    expect(find.text('Métrico (kg, cm, m, °C)'), findsOneWidget);
    await tester.tap(find.text('Unidades'));
    await app.settle(tester);
    await tester.tap(find.text('Imperial'));
    await app.settle(tester);
    expect(app.read(unitSystemProvider), UnitSystem.imperial);
    expect(find.text('Imperial (lb, pol, pés, °F)'), findsOneWidget);
    await app.dispose(tester);
  });

  testWidgets('changing language re-renders the app in that language', (
    tester,
  ) async {
    final app = await openSettings(tester);
    expect(find.text('Idioma do aparelho: Português (Brasil)'), findsOneWidget);
    await tester.tap(find.text('Idioma'));
    await app.settle(tester);
    await tester.tap(find.text('Español'));
    await app.settle(tester);
    expect(find.text('Idioma'), findsOneWidget);
    expect(find.text('Unidades'), findsOneWidget);
    expect(find.text('Privacidad predeterminada del lugar'), findsOneWidget);
    expect(find.text('Diario'), findsOneWidget);
    await app.dispose(tester);
  });

  testWidgets('default privacy shows descriptions and saves', (tester) async {
    final app = await openSettings(tester);
    await tester.tap(find.text('Privacidade padrão do local'));
    await app.settle(tester);
    expect(find.textContaining('Os cards mostram só a região'), findsOneWidget);
    await tester.tap(find.text('Região aproximada'));
    await app.settle(tester);
    final s = await app.run(tester, app.read(settingsRepositoryProvider).read);
    expect(s.defaultPrivacy, PrivacyLevel.approximate);
    await app.dispose(tester);
  });
}
