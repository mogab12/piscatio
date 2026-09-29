import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'photo_filters.dart';

/// Makes the filtered version of a card photo.
abstract interface class PhotoFilterService {
  /// The separation image (see [applyPhotoFilter]) of [photoPath] for
  /// [filter]: made once, then read from the cache. Null when the photo
  /// cannot be read.
  Future<String?> separation(String photoPath, CardPhotoFilter filter);

  /// Forget every filtered photo ("delete all data").
  Future<void> clear();
}

/// Where filtered photos are cached (the system may clear it any time).
final filterCacheRootProvider = FutureProvider<Directory>(
  (ref) => getTemporaryDirectory(),
);

class PlatformPhotoFilterService implements PhotoFilterService {
  PlatformPhotoFilterService(this._root);

  final Future<Directory> Function() _root;

  static const folder = 'card_filters';

  /// Longest side processed: sharp on a 1080 px card, quick on a phone.
  /// The cave painting is coarse by nature and the slowest: smaller.
  static int maxSideFor(CardPhotoFilter filter) =>
      filter == CardPhotoFilter.rupestre ? 1080 : 1440;

  /// Bump when the filters change so old results are not reused.
  static const version = 2;

  Future<Directory> get _dir async =>
      Directory(p.join((await _root()).path, folder));

  @override
  Future<String?> separation(String photoPath, CardPhotoFilter filter) async {
    final source = File(photoPath);
    if (!source.existsSync()) return null;
    if (filter == CardPhotoFilter.none) return photoPath;
    final stat = source.statSync();
    final key = sha1.convert(
      utf8.encode(
        '$version|$photoPath|${stat.modified.millisecondsSinceEpoch}|'
        '${stat.size}|${filter.name}',
      ),
    );
    final dir = await _dir;
    final out = File(p.join(dir.path, '$key.png'));
    if (out.existsSync()) return out.path;

    final (rgba, width, height) = await _decode(
      await source.readAsBytes(),
      maxSideFor(filter),
    );
    final result = await Isolate.run(
      () => applyPhotoFilter(filter, rgba, width, height),
    );
    final png = await _encodePng(result, width, height);
    await dir.create(recursive: true);
    // Written aside and renamed: a half-written file is never read back.
    final part = File('${out.path}.part');
    await part.writeAsBytes(png, flush: true);
    await part.rename(out.path);
    return out.path;
  }

  @override
  Future<void> clear() async {
    final dir = await _dir;
    if (dir.existsSync()) await dir.delete(recursive: true);
  }

  static Future<(Uint8List, int, int)> _decode(
    Uint8List bytes,
    int maxSide,
  ) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    final descriptor = await ui.ImageDescriptor.encoded(buffer);
    final scale = math.min(
      1.0,
      maxSide / math.max(descriptor.width, descriptor.height),
    );
    final width = math.max((descriptor.width * scale).round(), 1);
    final height = math.max((descriptor.height * scale).round(), 1);
    final codec = await descriptor.instantiateCodec(
      targetWidth: width,
      targetHeight: height,
    );
    try {
      final frame = await codec.getNextFrame();
      // Raw RGBA is the default format.
      final data = await frame.image.toByteData();
      frame.image.dispose();
      return (data!.buffer.asUint8List(), width, height);
    } finally {
      codec.dispose();
      descriptor.dispose();
      buffer.dispose();
    }
  }

  static Future<Uint8List> _encodePng(
    Uint8List rgba,
    int width,
    int height,
  ) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(rgba);
    final descriptor = ui.ImageDescriptor.raw(
      buffer,
      width: width,
      height: height,
      pixelFormat: ui.PixelFormat.rgba8888,
    );
    final codec = await descriptor.instantiateCodec();
    try {
      final frame = await codec.getNextFrame();
      final data = await frame.image.toByteData(format: ui.ImageByteFormat.png);
      frame.image.dispose();
      return data!.buffer.asUint8List();
    } finally {
      codec.dispose();
      descriptor.dispose();
      buffer.dispose();
    }
  }
}

final photoFilterServiceProvider = Provider<PhotoFilterService>(
  (ref) => PlatformPhotoFilterService(
    () => ref.read(filterCacheRootProvider.future),
  ),
);
