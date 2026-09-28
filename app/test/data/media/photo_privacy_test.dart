import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:piscatio/core/ids.dart';
import 'package:piscatio/data/media/exif_summary.dart';
import 'package:piscatio/data/media/jpeg_metadata.dart';
import 'package:piscatio/data/media/photo_importer.dart';

Uint8List _fixture(String name) =>
    File('test/fixtures/$name').readAsBytesSync();

bool _contains(Uint8List haystack, String needle) {
  final n = needle.codeUnits;
  outer:
  for (var i = 0; i + n.length <= haystack.length; i++) {
    for (var j = 0; j < n.length; j++) {
      if (haystack[i + j] != n[j]) continue outer;
    }
    return true;
  }
  return false;
}

/// Stands in for the native re-encoder: returns the file untouched, so the
/// test proves the Dart stripper alone removes the metadata.
class PassThroughProcessor implements ImageProcessor {
  @override
  Future<ProcessedImage?> process(String sourcePath) async =>
      ProcessedImage(File(sourcePath).readAsBytesSync(), 64, 48);
}

void main() {
  group('readExifSummary', () {
    test('reads capture time with its offset and GPS position', () async {
      final exif = await readExifSummary(_fixture('exif_gps.jpg'));
      expect(exif.takenAt, DateTime.utc(2026, 9, 12, 10, 41));
      expect(exif.location!.latitude, closeTo(-16.52, 0.0001));
      expect(exif.location!.longitude, closeTo(-56.41, 0.0001));
    });

    test('returns empty for photos without EXIF or garbage', () async {
      final plain = await readExifSummary(_fixture('plain.jpg'));
      expect(plain.takenAt, isNull);
      expect(plain.location, isNull);
      final junk = await readExifSummary([1, 2, 3]);
      expect(junk.location, isNull);
    });
  });

  group('stripJpegMetadata', () {
    test('removes EXIF, GPS, XMP and comments', () async {
      final original = _fixture('exif_gps.jpg');
      expect(_contains(original, 'Exif'), isTrue);
      expect(_contains(original, 'xmpmeta'), isTrue);
      expect(_contains(original, 'secret spot'), isTrue);

      final clean = stripJpegMetadata(original);
      expect(_contains(clean, 'Exif'), isFalse);
      expect(_contains(clean, 'xmpmeta'), isFalse);
      expect(_contains(clean, 'secret spot'), isFalse);
      final exif = await readExifSummary(clean);
      expect(exif.location, isNull);
      expect(exif.takenAt, isNull);
    });

    test('keeps a valid JPEG: same image data, starts and ends right', () {
      final original = _fixture('exif_gps.jpg');
      final clean = stripJpegMetadata(original);
      expect(clean.sublist(0, 2), [0xFF, 0xD8]);
      expect(clean.sublist(clean.length - 2), [0xFF, 0xD9]);
      expect(clean.length, lessThan(original.length));
      // The scan data (from SOS on) is byte-identical.
      int sos(Uint8List b) {
        for (var i = 0; i < b.length - 1; i++) {
          if (b[i] == 0xFF && b[i + 1] == 0xDA) return i;
        }
        return -1;
      }

      expect(clean.sublist(sos(clean)), original.sublist(sos(original)));
    });

    test('leaves non-JPEG input alone', () {
      final png = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 1, 2, 3]);
      expect(stripJpegMetadata(png), png);
    });
  });

  group('PhotoImporter', () {
    late Directory root;

    setUp(() => root = Directory.systemTemp.createTempSync('photos'));
    tearDown(() => root.deleteSync(recursive: true));

    test('saves a clean copy with a relative path and keeps EXIF data '
        'only in memory', () async {
      final importer = PhotoImporter(
        PassThroughProcessor(),
        () async => root,
        SequentialIdGenerator(),
      );
      final imported = await importer.import('test/fixtures/exif_gps.jpg');
      expect(imported.stored.relativePath, 'photos/id-1.jpg');
      expect(imported.stored.takenAt, DateTime.utc(2026, 9, 12, 10, 41));
      expect(imported.exifLocation!.latitude, closeTo(-16.52, 0.0001));

      final saved = File('${root.path}/photos/id-1.jpg').readAsBytesSync();
      expect(_contains(saved, 'Exif'), isFalse);
      expect((await readExifSummary(saved)).location, isNull);

      await importer.discard(imported.stored);
      expect(File('${root.path}/photos/id-1.jpg').existsSync(), isFalse);
    });

    test('fails clearly when the image cannot be processed', () async {
      final importer = PhotoImporter(
        _FailingProcessor(),
        () async => root,
        SequentialIdGenerator(),
      );
      expect(
        () => importer.import('test/fixtures/plain.jpg'),
        throwsA(isA<PhotoImportException>()),
      );
    });
  });
}

class _FailingProcessor implements ImageProcessor {
  @override
  Future<ProcessedImage?> process(String sourcePath) async => null;
}
