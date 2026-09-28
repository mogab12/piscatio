import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Root folder for photos. The database stores paths relative to it because
/// the absolute app directory changes between iOS updates.
final photoRootProvider = FutureProvider<Directory>((ref) async {
  final docs = await getApplicationDocumentsDirectory();
  return Directory(docs.path);
});

/// Absolute file for a stored relative path.
File resolvePhoto(Directory root, String relativePath) =>
    File(p.join(root.path, relativePath));
