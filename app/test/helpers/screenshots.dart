import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Screenshots are for design review only: `SCREENSHOTS=1 flutter test
/// test/screenshots`. PNGs land in build/screenshots/.
bool get screenshotsEnabled => Platform.environment['SCREENSHOTS'] == '1';

/// Loads the bundled fonts and Material icons (tests use a box font
/// otherwise).
Future<void> loadRealFonts() async {
  final families = <String, List<String>>{};
  for (final f in Directory('assets/fonts').listSync().whereType<File>()) {
    final name = f.uri.pathSegments.last;
    if (!name.endsWith('.ttf')) continue;
    families.putIfAbsent(name.split('-').first, () => []).add(f.path);
  }
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot != null) {
    families['MaterialIcons'] = [
      '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    ];
  }
  for (final entry in families.entries) {
    final loader = FontLoader(entry.key);
    for (final path in entry.value) {
      final bytes = File(path).readAsBytesSync();
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
    await loader.load();
  }
}

/// Phone-sized surface: 1080×2340 px at 3x.
void usePhoneSurface(
  WidgetTester tester, {
  Size logical = const Size(360, 780),
}) {
  tester.view.physicalSize = logical * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Future<void> saveScreenshot(WidgetTester tester, String name) async {
  final element = tester.binding.rootElement!;
  RenderRepaintBoundary? boundary;
  void visit(Element e) {
    if (boundary != null) return;
    final r = e.renderObject;
    if (r is RenderRepaintBoundary) {
      boundary = r;
      return;
    }
    e.visitChildren(visit);
  }

  element.visitChildren(visit);
  final image = await tester.runAsync(() async {
    final img = await boundary!.toImage(
      pixelRatio: tester.view.devicePixelRatio,
    );
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  });
  final out = File('build/screenshots/$name.png');
  out.parent.createSync(recursive: true);
  out.writeAsBytesSync(image!);
}
