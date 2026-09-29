import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piscatio/core/background.dart';
import 'package:piscatio/core/providers.dart';
import 'package:piscatio/domain/models/enums.dart';
import 'package:piscatio/features/onboarding/presentation/onboarding_screen.dart';
import 'package:piscatio/features/settings/application/data_controller.dart';
import 'package:piscatio/features/settings/presentation/tackle_screen.dart';

import '../../helpers/pump_app.dart';

class _FakeFileSharer implements FileSharer {
  final shared = <(Uint8List, String, String)>[];

  @override
  Future<void> share(Uint8List bytes, String fileName, String mimeType) async =>
      shared.add((bytes, fileName, mimeType));
}

Future<void> _openSettings(TestApp app, WidgetTester tester) async {
  await app.pumpApp(tester);
  await tester.tap(find.text('Ajustes'));
  await app.settle(tester);
}

void main() {
  testWidgets('baits: add, edit, archive and restore', (tester) async {
    final app = await TestApp.start(tester);
    await app.pumpScreen(tester, const TackleScreen(kind: TackleKind.bait));
    expect(
      find.text('Nenhuma isca ainda. Adicione as que você mais usa.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Nova isca'));
    await app.settle(tester);
    await tester.enterText(find.byType(TextField), 'Tuvira');
    await tester.tap(find.text('Isca natural'));
    await tester.tap(find.text('Salvar'));
    await app.settle(tester);
    expect(find.text('Tuvira'), findsOneWidget);

    await tester.tap(find.text('Tuvira'));
    await app.settle(tester);
    await tester.enterText(find.byType(TextField), 'Tuvira viva');
    await tester.tap(find.text('Salvar'));
    await app.settle(tester);
    expect(find.text('Tuvira viva'), findsOneWidget);

    await tester.tap(find.text('Tuvira viva'));
    await app.settle(tester);
    await tester.tap(find.text('Arquivar'));
    await app.settle(tester);
    expect(find.text('Arquivados'), findsOneWidget);
    expect(
      find.text(
        'Continuam nas capturas antigas, mas saem das listas de escolha.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Restaurar'));
    await app.settle(tester);
    expect(find.text('Arquivados'), findsNothing);
    expect(find.text('Tuvira viva'), findsOneWidget);
    await app.dispose(tester);
  });

  testWidgets('export shares a JSON file with the logbook', (tester) async {
    final sharer = _FakeFileSharer();
    final app = await TestApp.start(
      tester,
      overrides: [fileSharerProvider.overrideWithValue(sharer)],
    );
    await app.run(tester, () async {
      await app.read(settingsRepositoryProvider).completeOnboarding();
      await app
          .read(tripRepositoryProvider)
          .createPastTrip(
            startedAt: DateTime.utc(2026, 9, 1, 6),
            endedAt: DateTime.utc(2026, 9, 1, 9),
            timezone: 'UTC',
            privacy: PrivacyLevel.private,
          );
    });
    await _openSettings(app, tester);
    await tester.scrollUntilVisible(find.text('Exportar dados'), 200);
    await tester.tap(find.text('Exportar dados'));
    await app.settleUntil(tester, () => sharer.shared.isNotEmpty);
    final (bytes, name, mime) = sharer.shared.single;
    expect(name, startsWith('piscatio-'));
    expect(name, endsWith('.json'));
    expect(mime, 'application/json');
    final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    expect(json['app'], 'piscatio');
    expect(json['trips'], hasLength(1));
    await app.dispose(tester);
  });

  testWidgets('delete all asks first, then starts over at onboarding', (
    tester,
  ) async {
    final app = await TestApp.start(tester);
    await app.run(
      tester,
      () => app.read(settingsRepositoryProvider).completeOnboarding(),
    );
    final secret = await app.run(
      tester,
      () => app.read(privacySecretProvider.future),
    );
    await _openSettings(app, tester);
    await tester.scrollUntilVisible(find.text('Apagar todos os dados'), 200);
    await tester.tap(find.text('Apagar todos os dados'));
    await app.settle(tester);
    expect(find.text('Apagar todos os dados?'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await app.settle(tester);
    expect(find.byType(OnboardingScreen), findsNothing);

    await tester.tap(find.text('Apagar todos os dados'));
    await app.settle(tester);
    await tester.tap(find.text('Apagar tudo'));
    await app.settle(tester);
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(app.filters.cleared, isTrue);
    // The install secret starts over too, and nothing keeps the old one.
    final fresh = await app.run(
      tester,
      () => app.read(privacySecretProvider.future),
    );
    expect(fresh, isNot(secret));
    final stored = await app.run(
      tester,
      () => app.read(settingsRepositoryProvider).privacySecret(),
    );
    expect(stored, fresh);
    await app.dispose(tester);
  });
}
