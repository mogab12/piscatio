import 'package:freezed_annotation/freezed_annotation.dart';

import 'geo_point.dart';

part 'catch.freezed.dart';
part 'catch.g.dart';

@freezed
abstract class CatchPhoto with _$CatchPhoto {
  const factory CatchPhoto({
    required String id,
    required String catchId,

    /// Relative to the app's photo directory (absolute paths change on iOS).
    required String relativePath,
    required int width,
    required int height,

    /// Original capture time read from EXIF before it was stripped.
    DateTime? takenAt,
  }) = _CatchPhoto;

  factory CatchPhoto.fromJson(Map<String, dynamic> json) =>
      _$CatchPhotoFromJson(json);
}

@freezed
abstract class Catch with _$Catch {
  const factory Catch({
    required String id,
    required String tripId,

    /// Null when the species was not identified.
    String? speciesId,

    /// UTC.
    required DateTime caughtAt,
    int? weightGrams,
    int? lengthMillimeters,

    /// Null means "not informed", which is different from "kept".
    bool? released,
    String? baitId,
    String? gearId,
    int? depthMillimeters,
    GeoPoint? location,
    String? notes,
    @Default(<CatchPhoto>[]) List<CatchPhoto> photos,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Catch;

  const Catch._();

  factory Catch.fromJson(Map<String, dynamic> json) => _$CatchFromJson(json);

  CatchPhoto? get coverPhoto => photos.firstOrNull;
}

/// Optional fields of a catch, edited in the details form.
@freezed
abstract class CatchDetails with _$CatchDetails {
  const factory CatchDetails({
    String? speciesId,
    DateTime? caughtAt,
    int? weightGrams,
    int? lengthMillimeters,
    bool? released,
    String? baitId,
    String? gearId,
    int? depthMillimeters,
    String? notes,
  }) = _CatchDetails;
}
