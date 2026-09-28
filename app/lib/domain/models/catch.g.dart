// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catch.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CatchPhoto _$CatchPhotoFromJson(Map<String, dynamic> json) => _CatchPhoto(
  id: json['id'] as String,
  catchId: json['catchId'] as String,
  relativePath: json['relativePath'] as String,
  width: (json['width'] as num).toInt(),
  height: (json['height'] as num).toInt(),
  takenAt: json['takenAt'] == null
      ? null
      : DateTime.parse(json['takenAt'] as String),
);

Map<String, dynamic> _$CatchPhotoToJson(_CatchPhoto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'catchId': instance.catchId,
      'relativePath': instance.relativePath,
      'width': instance.width,
      'height': instance.height,
      'takenAt': instance.takenAt?.toIso8601String(),
    };

_Catch _$CatchFromJson(Map<String, dynamic> json) => _Catch(
  id: json['id'] as String,
  tripId: json['tripId'] as String,
  speciesId: json['speciesId'] as String?,
  caughtAt: DateTime.parse(json['caughtAt'] as String),
  weightGrams: (json['weightGrams'] as num?)?.toInt(),
  lengthMillimeters: (json['lengthMillimeters'] as num?)?.toInt(),
  released: json['released'] as bool?,
  baitId: json['baitId'] as String?,
  gearId: json['gearId'] as String?,
  depthMillimeters: (json['depthMillimeters'] as num?)?.toInt(),
  location: json['location'] == null
      ? null
      : GeoPoint.fromJson(json['location'] as Map<String, dynamic>),
  notes: json['notes'] as String?,
  photos:
      (json['photos'] as List<dynamic>?)
          ?.map((e) => CatchPhoto.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <CatchPhoto>[],
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$CatchToJson(_Catch instance) => <String, dynamic>{
  'id': instance.id,
  'tripId': instance.tripId,
  'speciesId': instance.speciesId,
  'caughtAt': instance.caughtAt.toIso8601String(),
  'weightGrams': instance.weightGrams,
  'lengthMillimeters': instance.lengthMillimeters,
  'released': instance.released,
  'baitId': instance.baitId,
  'gearId': instance.gearId,
  'depthMillimeters': instance.depthMillimeters,
  'location': instance.location?.toJson(),
  'notes': instance.notes,
  'photos': instance.photos.map((e) => e.toJson()).toList(),
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};
