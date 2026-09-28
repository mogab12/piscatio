import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'tackle.freezed.dart';
part 'tackle.g.dart';

@freezed
abstract class Bait with _$Bait {
  const factory Bait({
    required String id,
    required String name,
    required BaitType type,
    String? notes,
    @Default(false) bool archived,
  }) = _Bait;

  factory Bait.fromJson(Map<String, dynamic> json) => _$BaitFromJson(json);
}

@freezed
abstract class Gear with _$Gear {
  const factory Gear({
    required String id,
    required String name,
    required GearType type,
    String? notes,
    @Default(false) bool archived,
  }) = _Gear;

  factory Gear.fromJson(Map<String, dynamic> json) => _$GearFromJson(json);
}
