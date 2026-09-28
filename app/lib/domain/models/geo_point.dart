import 'package:freezed_annotation/freezed_annotation.dart';

part 'geo_point.freezed.dart';
part 'geo_point.g.dart';

/// A WGS84 coordinate. Never passed to card rendering.
@freezed
abstract class GeoPoint with _$GeoPoint {
  const factory GeoPoint(double latitude, double longitude) = _GeoPoint;

  factory GeoPoint.fromJson(Map<String, dynamic> json) =>
      _$GeoPointFromJson(json);
}
