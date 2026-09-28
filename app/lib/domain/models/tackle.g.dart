// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tackle.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Bait _$BaitFromJson(Map<String, dynamic> json) => _Bait(
  id: json['id'] as String,
  name: json['name'] as String,
  type: $enumDecode(_$BaitTypeEnumMap, json['type']),
  notes: json['notes'] as String?,
  archived: json['archived'] as bool? ?? false,
);

Map<String, dynamic> _$BaitToJson(_Bait instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'type': _$BaitTypeEnumMap[instance.type]!,
  'notes': instance.notes,
  'archived': instance.archived,
};

const _$BaitTypeEnumMap = {
  BaitType.natural: 'natural',
  BaitType.artificial: 'artificial',
  BaitType.fly: 'fly',
  BaitType.other: 'other',
};

_Gear _$GearFromJson(Map<String, dynamic> json) => _Gear(
  id: json['id'] as String,
  name: json['name'] as String,
  type: $enumDecode(_$GearTypeEnumMap, json['type']),
  notes: json['notes'] as String?,
  archived: json['archived'] as bool? ?? false,
);

Map<String, dynamic> _$GearToJson(_Gear instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'type': _$GearTypeEnumMap[instance.type]!,
  'notes': instance.notes,
  'archived': instance.archived,
};

const _$GearTypeEnumMap = {
  GearType.combo: 'combo',
  GearType.rod: 'rod',
  GearType.reel: 'reel',
  GearType.line: 'line',
  GearType.other: 'other',
};
