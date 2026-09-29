import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:piscatio/features/cards/application/photo_filter_service.dart';
import 'package:piscatio/features/cards/application/photo_filters.dart';

void main() {
  late Directory root;
  late PlatformPhotoFilterService service;
  final photo = File('test/fixtures/card_photo.jpg').absolute.path;

  setUp(() {
    root = Directory.systemTemp.createTempSync('piscatio_filters');
    service = PlatformPhotoFilterService(() async => root);
  });

  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  testWidgets('makes a separation once, then reuses it', (tester) async {
    await tester.runAsync(() async {
      final path = await service.separation(photo, CardPhotoFilter.engraving);
      expect(path, isNotNull);
      expect(path, isNot(photo));
      final codec = await ui.instantiateImageCodec(
        File(path!).readAsBytesSync(),
      );
      final frame = await codec.getNextFrame();
      // The 1200×1600 fixture is scaled to the processing size.
      expect((frame.image.width, frame.image.height), (1080, 1440));
      frame.image.dispose();
      codec.dispose();

      final modified = File(path).lastModifiedSync();
      expect(await service.separation(photo, CardPhotoFilter.engraving), path);
      expect(File(path).lastModifiedSync(), modified);
      final other = await service.separation(photo, CardPhotoFilter.halftone);
      expect(other, isNot(path));
    });
  });

  testWidgets('no filter is the photo; a missing photo is null', (
    tester,
  ) async {
    await tester.runAsync(() async {
      expect(await service.separation(photo, CardPhotoFilter.none), photo);
      expect(
        await service.separation(
          '${root.path}/gone.jpg',
          CardPhotoFilter.engraving,
        ),
        isNull,
      );
    });
  });

  testWidgets('clear forgets every filtered photo', (tester) async {
    await tester.runAsync(() async {
      final path = await service.separation(photo, CardPhotoFilter.duotone);
      expect(File(path!).existsSync(), isTrue);
      await service.clear();
      expect(File(path).existsSync(), isFalse);
    });
  });
}
