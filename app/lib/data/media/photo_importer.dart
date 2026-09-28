import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../core/ids.dart';
import '../../core/providers.dart';
import '../../domain/models/geo_point.dart';
import '../repositories/catch_repository.dart';
import 'exif_summary.dart';
import 'jpeg_metadata.dart';
import 'photo_storage.dart';

class ProcessedImage {
  const ProcessedImage(this.bytes, this.width, this.height);

  final Uint8List bytes;
  final int width;
  final int height;
}

/// Re-encodes a photo: upright, at most ~2048 px on the short side, JPEG,
/// no metadata.
abstract interface class ImageProcessor {
  Future<ProcessedImage?> process(String sourcePath);
}

class NativeImageProcessor implements ImageProcessor {
  const NativeImageProcessor();

  @override
  Future<ProcessedImage?> process(String sourcePath) async {
    final bytes = await FlutterImageCompress.compressWithFile(
      sourcePath,
      minWidth: 2048,
      minHeight: 2048,
      quality: 85,
    );
    if (bytes == null) return null;
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    final descriptor = await ui.ImageDescriptor.encoded(buffer);
    final result = ProcessedImage(bytes, descriptor.width, descriptor.height);
    descriptor.dispose();
    buffer.dispose();
    return result;
  }
}

/// A photo saved in the app folder, plus where the original was taken
/// (never stored in the image itself).
class ImportedPhoto {
  const ImportedPhoto(this.stored, this.exifLocation);

  final StoredPhoto stored;
  final GeoPoint? exifLocation;
}

class PhotoImportException implements Exception {
  const PhotoImportException();
}

class PhotoImporter {
  PhotoImporter(this._processor, this._root, this._ids);

  final ImageProcessor _processor;
  final Future<Directory> Function() _root;
  final IdGenerator _ids;

  static const folder = 'photos';

  Future<ImportedPhoto> import(String sourcePath) async {
    final original = await File(sourcePath).readAsBytes();
    final exif = await readExifSummary(original);
    final processed = await _processor.process(sourcePath);
    if (processed == null) throw const PhotoImportException();
    final clean = stripJpegMetadata(processed.bytes);
    final relative = '$folder/${_ids.newId()}.jpg';
    final file = resolvePhoto(await _root(), relative);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(clean, flush: true);
    return ImportedPhoto(
      StoredPhoto(
        relativePath: relative,
        width: processed.width,
        height: processed.height,
        takenAt: exif.takenAt,
      ),
      exif.location,
    );
  }

  /// Deletes a photo that was imported but never saved with a catch.
  Future<void> discard(StoredPhoto photo) async {
    final file = resolvePhoto(await _root(), photo.relativePath);
    if (p.isWithin(p.join((await _root()).path, folder), file.path) &&
        await file.exists()) {
      await file.delete();
    }
  }
}

final imageProcessorProvider = Provider<ImageProcessor>(
  (ref) => const NativeImageProcessor(),
);

final photoImporterProvider = Provider(
  (ref) => PhotoImporter(
    ref.watch(imageProcessorProvider),
    () => ref.read(photoRootProvider.future),
    ref.watch(idGeneratorProvider),
  ),
);
