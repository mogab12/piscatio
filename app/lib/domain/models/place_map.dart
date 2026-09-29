import 'geo_point.dart';

/// What a map shape is. Areas are filled, the rest are drawn as lines.
enum MapFeatureKind {
  /// Lakes, reservoirs, wide rivers mapped as areas.
  water,
  river,
  canal,
  stream,

  /// The shore of the sea (land on the left of the line).
  coast,

  /// Main roads, for orientation only.
  road;

  bool get isArea => this == MapFeatureKind.water;
}

/// A point in meters east (x) and north (y) of a map's center.
typedef MapXY = ({double x, double y});

/// One shape: rings for an area (drawn even-odd, so inner rings are holes),
/// polylines for the rest.
class MapFeature {
  const MapFeature(this.kind, this.parts);

  final MapFeatureKind kind;
  final List<List<MapXY>> parts;
}

/// The water (and main roads) around a fishing area, from OpenStreetMap.
///
/// Kept on the device only. The center is the *approximate* point of the
/// trip (never the real spot) and the shapes are in meters around it.
class PlaceMap {
  const PlaceMap({
    required this.center,
    required this.halfSizeMeters,
    required this.features,
  });

  factory PlaceMap.fromJson(
    Map<String, Object?> json, {
    required GeoPoint center,
    required double halfSizeMeters,
  }) {
    final features = <MapFeature>[];
    for (final raw in (json['f'] as List? ?? const [])) {
      final f = raw as Map<String, Object?>;
      final kind = MapFeatureKind.values.asNameMap()[f['k']];
      if (kind == null) continue;
      features.add(
        MapFeature(kind, [
          for (final part in (f['p'] as List? ?? const []))
            [
              for (var i = 0; i + 1 < (part as List).length; i += 2)
                (
                  x: (part[i] as num).toDouble(),
                  y: (part[i + 1] as num).toDouble(),
                ),
            ],
        ]),
      );
    }
    return PlaceMap(
      center: center,
      halfSizeMeters: halfSizeMeters,
      features: features,
    );
  }

  final GeoPoint center;

  /// The square covered: [center] ± this many meters on each axis.
  final double halfSizeMeters;
  final List<MapFeature> features;

  bool get isEmpty => features.isEmpty;

  static const _version = 1;

  /// Compact JSON: whole meters, flat coordinate lists.
  Map<String, Object?> toJson() => {
    'v': _version,
    'f': [
      for (final f in features)
        {
          'k': f.kind.name,
          'p': [
            for (final part in f.parts)
              [
                for (final p in part) ...[p.x.round(), p.y.round()],
              ],
          ],
        },
    ],
  };
}
