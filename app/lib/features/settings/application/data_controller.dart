import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/background.dart';
import '../../../core/providers.dart';
import '../../../data/export/logbook_exporter.dart';
import '../../../data/media/photo_importer.dart';
import '../../../data/media/photo_storage.dart';
import '../../cards/application/photo_filter_service.dart';

/// Hands a file to the system share sheet.
abstract interface class FileSharer {
  Future<void> share(Uint8List bytes, String fileName, String mimeType);
}

class PlatformFileSharer implements FileSharer {
  @override
  Future<void> share(Uint8List bytes, String fileName, String mimeType) async {
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, fileName));
    await file.writeAsBytes(bytes, flush: true);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path, mimeType: mimeType)]),
    );
  }
}

final fileSharerProvider = Provider<FileSharer>((ref) => PlatformFileSharer());

/// "Your data": export everything as JSON, or delete everything.
class DataController {
  DataController(this._ref);

  final Ref _ref;

  Future<void> exportAndShare() async {
    final now = _ref.read(clockProvider).now();
    final json = await LogbookExporter(_ref.read(appDatabaseProvider))
        .toJson(now);
    final day = DateFormat('yyyy-MM-dd').format(now.toLocal());
    await _ref
        .read(fileSharerProvider)
        .share(
          Uint8List.fromList(utf8.encode(json)),
          'piscatio-$day.json',
          'application/json',
        );
  }

  /// The only physical deletion in the app: every record and every photo
  /// (with their filtered copies). Settings go too, so the app starts over
  /// at onboarding.
  Future<void> wipeAll() async {
    await _ref.read(appDatabaseProvider).wipeUserData();
    final root = await _ref.read(photoRootProvider.future);
    final photos = Directory(p.join(root.path, PhotoImporter.folder));
    if (photos.existsSync()) await photos.delete(recursive: true);
    await _ref.read(photoFilterServiceProvider).clear();
    // A new install secret will be made: forget the old one.
    _ref.invalidate(privacySecretProvider);
  }
}

final dataControllerProvider = Provider(DataController.new);
