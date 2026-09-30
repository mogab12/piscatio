import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:piscatio/core/background.dart';
import 'package:piscatio/core/providers.dart';
import 'package:piscatio/core/router/app_router.dart';
import 'package:piscatio/core/router/app_routes.dart';
import 'package:piscatio/data/remote/piscatio_api.dart';
import 'package:piscatio/domain/models/catch.dart';
import 'package:piscatio/domain/models/enums.dart';
import 'package:piscatio/domain/models/geo_point.dart';
import 'package:piscatio/domain/models/social.dart';
import 'package:piscatio/features/cards/application/card_data.dart';
import 'package:piscatio/features/cards/application/card_exporter.dart';
import 'package:piscatio/features/cards/application/stories_sharer.dart';
import 'package:piscatio/features/cards/presentation/card_view.dart';
import 'package:piscatio/features/community/application/community.dart';

import '../../helpers/fake_server.dart';
import '../../helpers/pump_app.dart';
import 'community_test.dart' show pixel;

class _Sharer implements CardSharer {
  final shared = <Uint8List>[];

  @override
  Future<void> sharePng(Uint8List png, String fileName) async =>
      shared.add(png);
}

class _Stories implements StoriesSharer {
  _Stories({this.installed = true});

  final bool installed;
  final shared = <(Uint8List, bool, Color, Color)>[];

  @override
  Future<bool> available() async => installed;

  @override
  Future<bool> share(
    Uint8List png, {
    required bool sticker,
    required Color top,
    required Color bottom,
  }) async {
    shared.add((png, sticker, top, bottom));
    return true;
  }
}

Future<(TestApp, FakeServer, String, String)> _setup(
  WidgetTester tester, {
  bool signedIn = true,
  bool profile = true,
  _Stories? stories,
  _Sharer? sharer,
}) async {
  final server = FakeServer();
  if (profile) server.profile = FakeServer.person('ana');
  final app = await TestApp.start(
    tester,
    overrides: [
      apiFactoryProvider.overrideWithValue(
        (base, token) => PiscatioApi(server.client(), base: base, token: token),
      ),
      socialImageProvider.overrideWithValue((_) => MemoryImage(pixel)),
      storiesSharerProvider.overrideWithValue(
        stories ?? _Stories(installed: false),
      ),
      cardSharerProvider.overrideWithValue(sharer ?? _Sharer()),
    ],
  );
  final (tripId, catchId) = await app.run(tester, () async {
    await app.read(settingsRepositoryProvider).completeOnboarding();
    if (signedIn) {
      await app
          .read(accountRepositoryProvider)
          .signedIn(
            const ApiSession(token: FakeServer.token, email: FakeServer.email),
          );
    }
    final start = app.clock.now().subtract(const Duration(hours: 4));
    final trip = await app
        .read(tripRepositoryProvider)
        .createPastTrip(
          startedAt: start,
          endedAt: start.add(const Duration(hours: 3)),
          timezone: 'UTC',
          privacy: PrivacyLevel.friends,
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
      ),
    );
    return (trip.id, c.id);
  });
  return (app, server, tripId, catchId);
}

Future<void> _openCard(TestApp app, WidgetTester tester, String catchId) async {
  await app.pumpApp(tester);
  unawaited(app.read(routerProvider).push(AppRoutes.catchCard(catchId)));
  await app.settle(tester);
}

void main() {
  testWidgets('a card published for friends shows the region and goes up', (
    tester,
  ) async {
    final (app, server, tripId, catchId) = await _setup(tester);
    await _openCard(app, tester, catchId);
    CatchCardView view() => tester.widget(find.byType(CatchCardView));
    // Friends privacy: shared out of the app, the card shows no place.
    expect(view().shown.place, isNull);

    await tester.tap(find.text('Compartilhar'));
    await app.settle(tester);
    expect(find.text('Compartilhar em'), findsOneWidget);
    expect(find.text('Outros apps'), findsOneWidget);
    // Instagram is not there: no Stories option.
    expect(find.text('Stories do Instagram'), findsNothing);
    await tester.tap(find.text('Publicar na Comunidade'));
    await app.settle(tester);

    await tester.tap(find.text('Só amigos'));
    await tester.enterText(
      find.byType(TextField).last,
      'Traíra no fim da tarde',
    );
    await tester.pump();
    await tester.tap(find.text('Publicar'));
    await app.settleUntil(tester, () => server.postImages.isNotEmpty);
    await app.settle(tester);

    final body = server.posts.values.single;
    expect(body['audience'], 'friends');
    expect(body['kind'], 'catch');
    expect(body['catch_id'], catchId);
    expect(body['trip_id'], tripId);
    expect(body['species_id'], 'hoplias-malabaricus');
    expect(body['caption'], 'Traíra no fim da tarde');
    expect((body['width'], body['height']), (1080, 1920));
    expect(find.text('Publicando na Comunidade.'), findsOneWidget);
    // Nothing left waiting, and the editor is back to everyone.
    final outbox = Directory(p.join(app.photoRoot.path, 'outbox'));
    expect(outbox.listSync(), isEmpty);
    expect(view().options.audience, CardAudience.everyone);
    await app.dispose(tester);
  });

  testWidgets('the card for friends is drawn with the region', (tester) async {
    final (app, _, _, catchId) = await _setup(tester);
    await _openCard(app, tester, catchId);
    final view = tester.widget<CatchCardView>(find.byType(CatchCardView));
    final forFriends = view.data.customized(
      view.options.copyWith(audience: CardAudience.friends),
    );
    expect(forFriends.place, 'Cuiabá, MT');
    await app.dispose(tester);
  });

  testWidgets('without a profile, publishing says to create one', (
    tester,
  ) async {
    final (app, server, _, catchId) = await _setup(tester, profile: false);
    await _openCard(app, tester, catchId);
    await tester.tap(find.text('Compartilhar'));
    await app.settle(tester);
    await tester.tap(find.text('Publicar na Comunidade'));
    await app.settle(tester);
    expect(find.text('Crie seu perfil na Comunidade para publicar.'), findsOne);
    expect(find.text('Só amigos'), findsNothing);
    expect(server.posts, isEmpty);
    await app.dispose(tester);
  });

  testWidgets('signed out and without Instagram, sharing goes straight out', (
    tester,
  ) async {
    final sharer = _Sharer();
    final (app, _, _, catchId) = await _setup(
      tester,
      signedIn: false,
      sharer: sharer,
    );
    await _openCard(app, tester, catchId);
    await tester.tap(find.text('Compartilhar'));
    await app.settleUntil(tester, () => sharer.shared.isNotEmpty);
    await app.settle(tester);
    expect(find.text('Compartilhar em'), findsNothing);
    await app.dispose(tester);
  });

  testWidgets('straight to Instagram Stories when it is there', (tester) async {
    final stories = _Stories();
    final (app, _, _, catchId) = await _setup(
      tester,
      signedIn: false,
      stories: stories,
    );
    await _openCard(app, tester, catchId);
    await tester.tap(find.text('Compartilhar'));
    await app.settle(tester);
    expect(find.text('Publicar na Comunidade'), findsNothing);
    await tester.tap(find.text('Stories do Instagram'));
    await app.settleUntil(tester, () => stories.shared.isNotEmpty);
    await app.settle(tester);
    final (_, sticker, top, bottom) = stories.shared.single;
    // A 9:16 card fills the story; the background matches the card.
    expect(sticker, isFalse);
    expect(top, CardPalette.redHead.ground);
    expect(bottom, CardPalette.redHead.ground);
    await app.dispose(tester);
  });

  testWidgets('a card that did not go up can be tried again or discarded', (
    tester,
  ) async {
    final (app, server, _, _) = await _setup(tester);
    server.feedPosts.add(FakeServer.post('p1'));
    await app.run(tester, () async {
      final social = app.read(socialRepositoryProvider);
      final id = await social.queue(
        png: pixel,
        width: 1080,
        height: 1080,
        kind: PostKind.values.first,
        audience: CardAudience.everyone,
      );
      await social.fail(id, 'profile_required');
    });
    await app.pumpApp(tester);
    await tester.tap(find.text('Comunidade'));
    await app.settle(tester);
    expect(
      find.text('O card não subiu. Crie seu perfil primeiro.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Descartar'));
    await app.settle(tester);
    expect(find.textContaining('O card não subiu'), findsNothing);
    expect(server.posts, isEmpty);
    await app.dispose(tester);
  });
}
