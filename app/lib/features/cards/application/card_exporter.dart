import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Renders the card's boundary to PNG bytes at its canvas size (the
/// boundary is laid out at [CardFormat.size], whatever the preview scale).
Future<Uint8List> captureCard(RenderRepaintBoundary boundary) async {
  final image = await boundary.toImage();
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}

/// Hands a finished card image to the system share sheet.
abstract interface class CardSharer {
  Future<void> sharePng(Uint8List png, String fileName);
}

class PlatformCardSharer implements CardSharer {
  @override
  Future<void> sharePng(Uint8List png, String fileName) async {
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, fileName));
    await file.writeAsBytes(png, flush: true);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path, mimeType: 'image/png')]),
    );
  }
}

final cardSharerProvider = Provider<CardSharer>((ref) => PlatformCardSharer());
