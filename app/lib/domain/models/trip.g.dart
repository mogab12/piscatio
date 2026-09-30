// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Trip _$TripFromJson(Map<String, dynamic> json) => _Trip(
  id: json['id'] as String,
  startedAt: DateTime.parse(json['startedAt'] as String),
  endedAt: json['endedAt'] == null
      ? null
      : DateTime.parse(json['endedAt'] as String),
  timezone: json['timezone'] as String,
  location: json['location'] == null
      ? null
      : GeoPoint.fromJson(json['location'] as Map<String, dynamic>),
  locationAccuracyMeters: (json['locationAccuracyMeters'] as num?)?.toDouble(),
  locationName: json['locationName'] as String?,
  locationRegion: json['locationRegion'] as String?,
  privacyLevel: $enumDecode(_$PrivacyLevelEnumMap, json['privacyLevel']),
  moonPhase: $enumDecode(_$MoonPhaseEnumMap, json['moonPhase']),
  moonIllumination: (json['moonIllumination'] as num).toDouble(),
  notes: json['notes'] as String?,
  isRetroactive: json['isRetroactive'] as bool? ?? false,
  venueId: json['venueId'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$TripToJson(_Trip instance) => <String, dynamic>{
  'id': instance.id,
  'startedAt': instance.startedAt.toIso8601String(),
  'endedAt': instance.endedAt?.toIso8601String(),
  'timezone': instance.timezone,
  'location': instance.location?.toJson(),
  'locationAccuracyMeters': instance.locationAccuracyMeters,
  'locationName': instance.locationName,
  'locationRegion': instance.locationRegion,
  'privacyLevel': _$PrivacyLevelEnumMap[instance.privacyLevel]!,
  'moonPhase': _$MoonPhaseEnumMap[instance.moonPhase]!,
  'moonIllumination': instance.moonIllumination,
  'notes': instance.notes,
  'isRetroactive': instance.isRetroactive,
  'venueId': instance.venueId,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};

const _$PrivacyLevelEnumMap = {
  PrivacyLevel.private: 'private',
  PrivacyLevel.friends: 'friends',
  PrivacyLevel.approximate: 'approximate',
  PrivacyLevel.exact: 'exact',
};

const _$MoonPhaseEnumMap = {
  MoonPhase.newMoon: 'newMoon',
  MoonPhase.waxingCrescent: 'waxingCrescent',
  MoonPhase.firstQuarter: 'firstQuarter',
  MoonPhase.waxingGibbous: 'waxingGibbous',
  MoonPhase.fullMoon: 'fullMoon',
  MoonPhase.waningGibbous: 'waningGibbous',
  MoonPhase.lastQuarter: 'lastQuarter',
  MoonPhase.waningCrescent: 'waningCrescent',
};
