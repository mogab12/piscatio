// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'species.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SpeciesName _$SpeciesNameFromJson(Map<String, dynamic> json) => _SpeciesName(
  lang: json['lang'] as String,
  name: json['name'] as String,
  isPrimary: json['isPrimary'] as bool? ?? false,
  region: json['region'] as String?,
  needsReview: json['needsReview'] as bool? ?? false,
);

Map<String, dynamic> _$SpeciesNameToJson(_SpeciesName instance) =>
    <String, dynamic>{
      'lang': instance.lang,
      'name': instance.name,
      'isPrimary': instance.isPrimary,
      'region': instance.region,
      'needsReview': instance.needsReview,
    };

_Species _$SpeciesFromJson(Map<String, dynamic> json) => _Species(
  id: json['id'] as String,
  scientificName: json['scientificName'] as String,
  habitats:
      (json['habitats'] as List<dynamic>?)
          ?.map((e) => $enumDecode(_$HabitatEnumMap, e))
          .toList() ??
      const <Habitat>[],
  regionTags:
      (json['regionTags'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  names:
      (json['names'] as List<dynamic>?)
          ?.map((e) => SpeciesName.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <SpeciesName>[],
  isCustom: json['isCustom'] as bool? ?? false,
);

Map<String, dynamic> _$SpeciesToJson(_Species instance) => <String, dynamic>{
  'id': instance.id,
  'scientificName': instance.scientificName,
  'habitats': instance.habitats.map((e) => _$HabitatEnumMap[e]!).toList(),
  'regionTags': instance.regionTags,
  'names': instance.names,
  'isCustom': instance.isCustom,
};

const _$HabitatEnumMap = {
  Habitat.freshwater: 'freshwater',
  Habitat.brackish: 'brackish',
  Habitat.saltwater: 'saltwater',
};
