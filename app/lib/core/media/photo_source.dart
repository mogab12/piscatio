import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

enum PhotoOrigin { camera, gallery }

/// Camera and gallery behind an interface so the capture flow is testable.
abstract interface class PhotoSource {
  /// Path of the picked photo, or null if the user cancelled.
  Future<String?> pick(PhotoOrigin origin);
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
}

final photoSourceProvider = Provider<PhotoSource>(
  (ref) => ImagePickerPhotoSource(),
);
