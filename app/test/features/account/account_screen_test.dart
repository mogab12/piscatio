import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piscatio/core/background.dart';
import 'package:piscatio/core/providers.dart';
import 'package:piscatio/data/remote/piscatio_api.dart';
import 'package:piscatio/features/account/presentation/account_screen.dart';

import '../../helpers/fake_server.dart';
import '../../helpers/pump_app.dart';

void main() {
  late FakeServer server;

  Future<TestApp> start(WidgetTester tester) async {
    server = FakeServer();
    final app = await TestApp.start(
      tester,
      overrides: [
        apiFactoryProvider.overrideWithValue(
          (base, token) =>
              PiscatioApi(server.client(), base: base, token: token),
        ),
      ],
    );
    return app;
  }

  Future<void> signIn(TestApp app, WidgetTester tester) async {
    await tester.enterText(find.byType(TextField).first, FakeServer.email);
    await tester.pump();
    await tester.tap(find.text('Enviar código'));
    await app.settle(tester);
    expect(
      find.text(
        'Enviamos um código de 6 dígitos para ${FakeServer.email}. '
        'Ele vale por 10 minutos.',
      ),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextField).first, FakeServer.code);
    await tester.pump();
    await tester.tap(find.text('Entrar'));
    await app.settle(tester);
  }

  testWidgets('signing in with the emailed code syncs right away', (
    tester,
  ) async {
    final app = await start(tester);
    await app.pumpScreen(tester, const AccountScreen());
    expect(find.textContaining('Sem conta, tudo continua'), findsOneWidget);
    // No action until the email looks like one.
    final slab = find.text('Enviar código');
    await tester.tap(slab);
    await app.settle(tester);
    expect(server.requests, isEmpty);

    await signIn(app, tester);
    expect(find.text(FakeServer.email), findsOneWidget);
    expect(app.tokens.token, FakeServer.token);
    await app.settleUntil(tester, () => server.secret != null);
    await app.settle(tester);
    expect(find.textContaining('Sincronizado hoje às'), findsOneWidget);
    expect(
      server.requests.map((r) => r.url.path),
      containsAll(['/api/auth/email/verify', '/api/sync/pull']),
    );
    await app.dispose(tester);
  });

  testWidgets('a wrong code says so and keeps the form', (tester) async {
    final app = await start(tester);
    await app.pumpScreen(tester, const AccountScreen());
    await tester.enterText(find.byType(TextField).first, FakeServer.email);
    await tester.pump();
    await tester.tap(find.text('Enviar código'));
    await app.settle(tester);
    await tester.enterText(find.byType(TextField).first, '000000');
    await tester.pump();
    await tester.tap(find.text('Entrar'));
    await app.settle(tester);
    expect(
      find.text('Código errado. Confira o e-mail e tente de novo.'),
      findsOneWidget,
    );
    expect(app.tokens.token, isNull);
    await app.dispose(tester);
  });

  testWidgets('with the server down it says so', (tester) async {
    final app = await start(tester);
    server.down = true;
    await app.pumpScreen(tester, const AccountScreen());
    await tester.enterText(find.byType(TextField).first, FakeServer.email);
    await tester.pump();
    await tester.tap(find.text('Enviar código'));
    await app.settle(tester);
    expect(find.textContaining('Não deu para falar com o servidor'), findsOne);
    await app.dispose(tester);
  });

  testWidgets('a server address must be a web address', (tester) async {
    final app = await start(tester);
    await app.pumpScreen(tester, const AccountScreen());
    await tester.tap(find.text('Servidor'));
    await app.settle(tester);
    await tester.enterText(find.byType(TextField).last, 'meu servidor');
    await tester.enterText(find.byType(TextField).first, FakeServer.email);
    await tester.pump();
    await tester.tap(find.text('Enviar código'));
    await app.settle(tester);
    expect(
      find.text('Digite um endereço que comece com https://'),
      findsOneWidget,
    );
    expect(server.requests, isEmpty);
    await app.dispose(tester);
  });

  testWidgets('signing out keeps the logbook and shows the form again', (
    tester,
  ) async {
    final app = await start(tester);
    await app.pumpScreen(tester, const AccountScreen());
    await signIn(app, tester);
    await tester.tap(find.text('Sair'));
    await app.settle(tester);
    expect(find.text('Enviar código'), findsOneWidget);
    expect(app.tokens.token, isNull);
    expect(
      server.requests.map((r) => r.url.path),
      contains('/api/auth/logout'),
    );
    await app.dispose(tester);
  });

  testWidgets('deleting the account asks first, then erases it', (
    tester,
  ) async {
    final app = await start(tester);
    await app.pumpScreen(tester, const AccountScreen());
    await signIn(app, tester);
    await tester.tap(find.text('Excluir conta'));
    await app.settle(tester);
    expect(find.text('Excluir sua conta?'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await app.settle(tester);
    expect(server.requests.where((r) => r.method == 'DELETE'), isEmpty);

    await tester.tap(find.text('Excluir conta'));
    await app.settle(tester);
    await tester.tap(find.text('Excluir conta').last);
    await app.settle(tester);
    expect(server.requests.where((r) => r.method == 'DELETE'), hasLength(1));
    expect(find.text('Conta excluída'), findsOneWidget);
    expect(find.text('Enviar código'), findsOneWidget);
    expect(app.read(accountProvider).value, isNull);
    await app.dispose(tester);
  });

  testWidgets('settings shows the account and its last sync', (tester) async {
    final app = await start(tester);
    await app.run(
      tester,
      () => app.read(settingsRepositoryProvider).completeOnboarding(),
    );
    await app.pumpApp(tester);
    await tester.tap(find.text('Ajustes'));
    await app.settle(tester);
    expect(find.text('Guarde o diário e use em outro aparelho'), findsOne);
    await tester.tap(find.text('Entrar'));
    await app.settle(tester);
    await signIn(app, tester);
    await app.settleUntil(tester, () => server.secret != null);
    await tester.tap(find.byType(BackButton));
    await app.settle(tester);
    expect(find.text(FakeServer.email), findsOneWidget);
    expect(find.textContaining('Sincronizado hoje às'), findsOneWidget);
    await app.dispose(tester);
  });
}
