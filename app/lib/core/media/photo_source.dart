import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

enum PhotoOrigin { camera, gallery }

/// Camera and gallery behind an interface so the capture flow is testable.
abstract interface class PhotoSource {
  /// Path of the picked photo, or null if the user cancelled.
  Future<String?> pick(PhotoOrigin origin);

  /// A photo taken while Android killed the app (it can do that while the
  /// camera is open), delivered on the next launch; null otherwise.
  Future<String?> recoverLost();
}

class ImagePickerPhotoSource implements PhotoSource {
  ImagePickerPhotoSource();

  final _picker = ImagePicker();

  @override
  Future<String?> pick(PhotoOrigin origin) async {
    final file = await _picker.pickImage(
      source: origin == PhotoOrigin.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      // requestFullMetadata stays on (default) so we can read date and
      // place from EXIF; it is stripped when the photo is imported.
    );
    return file?.path;
  }

  @override
  Future<String?> recoverLost() async {
    // Only Android can lose the app to the camera.
    if (!Platform.isAndroid) return null;
    final lost = await _picker.retrieveLostData();
    if (lost.isEmpty) return null;
    return lost.file?.path ?? lost.files?.firstOrNull?.path;
  }
}

final photoSourceProvider = Provider<PhotoSource>(
  (ref) => ImagePickerPhotoSource(),
);
