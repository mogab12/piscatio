import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// The Meta app id Instagram asks for when an app shares to Stories
/// (`--dart-define=FACEBOOK_APP_ID=...`). Without it the direct share is
/// off and the system share sheet is used.
const facebookAppId = String.fromEnvironment('FACEBOOK_APP_ID');

/// Sends a card straight to Instagram's story composer.
abstract interface class StoriesSharer {
  /// Whether it can be offered (app id set, Instagram installed).
  Future<bool> available();

  /// A 9:16 card fills the story; a square one goes as a sticker over
  /// [top]→[bottom] colors. False if Instagram did not open.
  Future<bool> share(
    Uint8List png, {
    required bool sticker,
    required Color top,
    required Color bottom,
  });
}

String _hex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

class PlatformStoriesSharer implements StoriesSharer {
  static const _channel = MethodChannel('piscatio/stories');

  @override
  Future<bool> available() async {
    if (facebookAppId.isEmpty) return false;
    try {
      return await _channel.invokeMethod<bool>('available') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Future<bool> share(
    Uint8List png, {
    required bool sticker,
    required Color top,
    required Color bottom,
  }) async {
    // The folder the Android file provider exposes (res/xml/stories_paths).
    final dir = Directory(
      p.join((await getTemporaryDirectory()).path, 'stories'),
    );
    await dir.create(recursive: true);
    final file = File(p.join(dir.path, 'piscatio-story.png'));
    await file.writeAsBytes(png, flush: true);
    try {
      return await _channel.invokeMethod<bool>('share', {
            'path': file.path,
            'appId': facebookAppId,
            'sticker': sticker,
            'top': _hex(top),
            'bottom': _hex(bottom),
          }) ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}

final storiesSharerProvider = Provider<StoriesSharer>(
  (ref) => PlatformStoriesSharer(),
);
