import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piscatio/core/background.dart';
import 'package:piscatio/core/providers.dart';
import 'package:piscatio/core/router/app_router.dart';
import 'package:piscatio/core/router/app_routes.dart';
import 'package:piscatio/data/remote/piscatio_api.dart';
import 'package:piscatio/features/community/application/community.dart';

import '../../helpers/fake_server.dart';
import '../../helpers/pump_app.dart';

/// A 1×1 transparent PNG: every community picture in tests.
final pixel = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
);

Future<(TestApp, FakeServer)> startCommunity(
  WidgetTester tester, {
  bool signedIn = true,
  bool withProfile = true,
  FakeServer? server,
}) async {
  server ??= FakeServer();
  if (withProfile) {
    server.profile = {
      ...FakeServer.person('ana', name: 'Ana'),
      'is_private': true,
    };
  }
  final app = await TestApp.start(
    tester,
    overrides: [
      apiFactoryProvider.overrideWithValue(
        (base, token) =>
            PiscatioApi(server!.client(), base: base, token: token),
      ),
      socialImageProvider.overrideWithValue((_) => MemoryImage(pixel)),
    ],
  );
  await app.run(tester, () async {
    await app.read(settingsRepositoryProvider).completeOnboarding();
    if (signedIn) {
      await app
          .read(accountRepositoryProvider)
          .signedIn(
            const ApiSession(token: FakeServer.token, email: FakeServer.email),
          );
    }
  });
  return (app, server);
}

Future<void> openCommunity(TestApp app, WidgetTester tester) async {
  await app.pumpApp(tester);
  await tester.tap(find.text('Comunidade'));
  await app.settle(tester);
}

void main() {
  testWidgets('without an account it explains and leads to sign in', (
    tester,
  ) async {
    final (app, server) = await startCommunity(tester, signedIn: false);
    await openCommunity(app, tester);
    expect(find.text('Pesque junto'), findsOneWidget);
    expect(find.textContaining('O diário continua só seu'), findsOneWidget);
    expect(server.requests, isEmpty);
    await tester.tap(find.text('Entrar'));
    await app.settle(tester);
    expect(find.text('Enviar código'), findsOneWidget);
    await app.dispose(tester);
  });

  testWidgets(
    'a profile is set up with a lowercase @name, private by default',
    (tester) async {
      final (app, server) = await startCommunity(tester, withProfile: false);
      server.people['bia'] = FakeServer.person('bia');
      await openCommunity(app, tester);
      expect(find.text('Crie seu perfil'), findsOneWidget);
      await tester.tap(find.text('Criar perfil'));
      await app.settle(tester);
      expect(find.text('Criar perfil'), findsOneWidget);
      final fields = find.byType(TextField);
      // Taken by someone else: said next to the field.
      await tester.enterText(fields.at(0), 'bia');
      await tester.enterText(fields.at(1), 'Ana');
      await tester.pump();
      await tester.tap(find.text('Salvar'));
      await app.settle(tester);
      expect(find.text('Esse @nome já tem dono.'), findsOneWidget);

      await tester.enterText(fields.at(0), 'Ana.Pesca');
      await tester.pump();
      await tester.tap(find.text('Salvar'));
      await app.settle(tester);
      expect(server.profile!['handle'], 'ana.pesca');
      expect(server.profile!['is_private'], true);
      // Back at the feed, with its tabs.
      expect(find.text('Descobrir'), findsOneWidget);
      expect(
        find.text('Siga pescadores ou publique um card para começar.'),
        findsOne,
      );
      await app.dispose(tester);
    },
  );

  testWidgets('the feed shows cards; like, report and block', (tester) async {
    final (app, server) = await startCommunity(tester);
    server
      ..people['bia'] = FakeServer.person('bia', name: 'Bia')
      ..feedPosts.addAll([
        FakeServer.post('p1', likes: 2),
        FakeServer.post('p2', handle: 'cid', caption: 'Traíra no fim da tarde'),
      ]);
    await openCommunity(app, tester);
    expect(find.text('Tucunaré de 3 kg'), findsOneWidget);
    expect(find.text('Traíra no fim da tarde'), findsOneWidget);
    expect(find.bySemanticsLabel('Card de @bia'), findsOneWidget);

    await tester.ensureVisible(find.byTooltip('Curtir').first);
    await app.settle(tester);
    await tester.tap(find.byTooltip('Curtir').first);
    await app.settle(tester);
    expect(find.text('3'), findsOneWidget);
    expect(find.byTooltip('Descurtir'), findsOneWidget);

    await tester.ensureVisible(find.byTooltip('Mais opções').first);
    await app.settle(tester);
    await tester.tap(find.byTooltip('Mais opções').first);
    await app.settle(tester);
    await tester.tap(find.text('Denunciar'));
    await app.settle(tester);
    await tester.tap(find.text('Mostra um ponto de pesca'));
    await app.settle(tester);
    expect(server.reports.single, {
      'post_id': 'p1',
      'reason': 'location',
      'note': '',
    });
    expect(find.text('Denúncia enviada. Obrigado.'), findsOneWidget);

    await tester.ensureVisible(find.byTooltip('Mais opções').first);
    await app.settle(tester);
    await tester.tap(find.byTooltip('Mais opções').first);
    await app.settle(tester);
    await tester.tap(find.text('Bloquear @bia'));
    await app.settle(tester);
    expect(find.text('Bloquear @bia?'), findsOneWidget);
    await tester.tap(find.text('Bloquear'));
    await app.settle(tester);
    expect(server.blocks, {'bia'});
    expect(find.text('Tucunaré de 3 kg'), findsNothing);
    expect(find.text('Traíra no fim da tarde'), findsOneWidget);
    await app.dispose(tester);
  });

  testWidgets('offline, the community says so and tries again', (tester) async {
    final (app, server) = await startCommunity(tester);
    server.down = true;
    await openCommunity(app, tester);
    expect(
      find.text('Sem conexão. A Comunidade precisa de internet.'),
      findsOneWidget,
    );
    server.down = false;
    await tester.tap(find.text('Tentar de novo'));
    await app.settle(tester);
    expect(find.text('Descobrir'), findsOneWidget);
    await app.dispose(tester);
  });

  testWidgets('following a public profile, asking a private one', (
    tester,
  ) async {
    final (app, server) = await startCommunity(tester);
    server
      ..people['bia'] = FakeServer.person('bia', name: 'Bia')
      ..people['cid'] = FakeServer.person('cid', name: 'Cid', private: true)
      ..feedPosts.add(FakeServer.post('p1'));
    await app.pumpApp(tester);
    unawaited(app.read(routerProvider).push(AppRoutes.person('bia')));
    await app.settle(tester);
    expect(find.text('Tucunaré de 3 kg'), findsOneWidget);
    await tester.tap(find.text('Seguir'));
    await app.settle(tester);
    expect(server.follows['bia'], 'accepted');
    expect(find.text('Seguindo'), findsOneWidget);

    unawaited(app.read(routerProvider).push(AppRoutes.person('cid')));
    await app.settle(tester);
    expect(
      find.text('Perfil fechado. Siga para ver as publicações.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Seguir'));
    await app.settle(tester);
    expect(server.follows['cid'], 'pending');
    expect(find.text('Solicitado'), findsOneWidget);
    await app.dispose(tester);
  });

  testWidgets('people are found by name and requests are answered', (
    tester,
  ) async {
    final (app, server) = await startCommunity(tester);
    server
      ..people['jpesca'] = FakeServer.person('jpesca', name: 'João Pescador')
      ..people['dani'] = FakeServer.person('dani', name: 'Dani')
      ..followRequests.add('dani');
    await openCommunity(app, tester);
    await tester.tap(find.byTooltip('Buscar pessoas'));
    await app.settle(tester);
    await tester.enterText(find.byType(TextField), 'joão');
    await tester.pump(const Duration(milliseconds: 400));
    await app.settle(tester);
    expect(find.text('@jpesca'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await app.settle(tester);

    await tester.tap(find.byTooltip('Pedidos para seguir'));
    await app.settle(tester);
    expect(find.text('@dani'), findsOneWidget);
    await tester.tap(find.text('Aceitar'));
    await app.settle(tester);
    expect(server.followRequests, isEmpty);
    expect(find.text('Nenhum pedido.'), findsOneWidget);
    await app.dispose(tester);
  });

  testWidgets('leaving the community asks first', (tester) async {
    final (app, server) = await startCommunity(tester);
    await app.pumpApp(tester);
    unawaited(app.read(routerProvider).push(AppRoutes.communityProfile));
    await app.settle(tester);
    expect(find.text('Editar perfil'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Sair da comunidade'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Sair da comunidade'));
    await app.settle(tester);
    expect(find.text('Sair da comunidade?'), findsOneWidget);
    await tester.tap(find.text('Sair da comunidade').last);
    await app.settle(tester);
    expect(server.profile, isNull);
    expect(find.text('Crie seu perfil'), findsOneWidget);
    await app.dispose(tester);
  });
}
