import '../models/geo_point.dart';
import '../models/place_map.dart';
import 'map_geometry.dart';

/// Map data comes from OpenStreetMap (ODbL: attribution on every map)
/// through the Overpass API. Only what a fishing sketch needs: water, the
/// shore and the main roads.
abstract final class OverpassMap {
  /// Area fetched around the approximate point, big enough for the
  /// regional and the local views (see `map_sketch.dart`).
  static const halfSizeMeters = 14000.0;

  /// Streams are only drawn on local maps, which stay closer to the point.
  static const streamHalfSizeMeters = 9000.0;

  /// Detail kept: about a pixel on the most zoomed-in card map.
  static const toleranceMeters = 6.0;

  static String query(GeoPoint center) {
    String bbox(double half) {
      final proj = LocalProjection(center);
      final sw = proj.toGeo((x: -half, y: -half));
      final ne = proj.toGeo((x: half, y: half));
      String f(double v) => v.toStringAsFixed(5);
      return '${f(sw.latitude)},${f(sw.longitude)},'
          '${f(ne.latitude)},${f(ne.longitude)}';
    }

    final b = bbox(halfSizeMeters);
    final s = bbox(streamHalfSizeMeters);
    return '[out:json][timeout:25][maxsize:67108864];'
        '('
        'way["natural"="water"]($b);'
        'relation["natural"="water"]($b);'
        'way["waterway"="riverbank"]($b);'
        'relation["waterway"="riverbank"]($b);'
        'way["landuse"="reservoir"]($b);'
        'relation["landuse"="reservoir"]($b);'
        'way["waterway"~"^(river|canal)\$"]($b);'
        'way["waterway"="stream"]($s);'
        'way["natural"="coastline"]($b);'
        'way["highway"~"^(motorway|trunk|primary|secondary)\$"]($b);'
        ');'
        'out geom qt;';
  }

  static MapFeatureKind? classify(Map<String, Object?> tags) {
    final waterway = tags['waterway'];
    if (tags['natural'] == 'water' ||
        waterway == 'riverbank' ||
        tags['landuse'] == 'reservoir') {
      return MapFeatureKind.water;
    }
    switch (waterway) {
      case 'river':
        return MapFeatureKind.river;
      case 'canal':
        return MapFeatureKind.canal;
      case 'stream':
        return MapFeatureKind.stream;
    }
    if (tags['natural'] == 'coastline') return MapFeatureKind.coast;
    if (const {
      'motorway',
      'trunk',
      'primary',
      'secondary',
    }.contains(tags['highway'])) {
      return MapFeatureKind.road;
    }
    return null;
  }

  /// Turns an Overpass `out geom` answer into a [PlaceMap] around
  /// [center]: projected, cropped to the area and simplified.
  static PlaceMap parse(Map<String, Object?> json, GeoPoint center) {
    final proj = LocalProjection(center);
    final box = squareBox(halfSizeMeters * 1.02);

    // A missing node (null) breaks a way into separate runs.
    List<List<MapXY>> runs(Object? geometry) {
      final out = <List<MapXY>>[];
      var run = <MapXY>[];
      for (final g in (geometry as List? ?? const [])) {
        if (g is Map && g['lat'] is num && g['lon'] is num) {
          run.add(
            proj.toXY(
              (g['lat']! as num).toDouble(),
              (g['lon']! as num).toDouble(),
            ),
          );
        } else if (run.isNotEmpty) {
          out.add(run);
          run = <MapXY>[];
        }
      }
      if (run.isNotEmpty) out.add(run);
      return out;
    }

    List<List<MapXY>> area(List<List<MapXY>> rings) => [
      for (final ring in rings)
        if (boundsOf(ring) case final b? when overlaps(b, box))
          if (simplifyRing(clipRing(ring, box), toleranceMeters) case final r?
              when r.length >= 3)
            r,
    ];

    List<List<MapXY>> lines(List<List<MapXY>> parts) => [
      for (final part in parts)
        for (final piece in clipLine(simplify(part, toleranceMeters), box))
          piece,
    ];

    final features = <MapFeature>[];
    for (final raw in (json['elements'] as List? ?? const [])) {
      if (raw is! Map) continue;
      final element = raw.cast<String, Object?>();
      final tags = (element['tags'] as Map?)?.cast<String, Object?>() ?? {};
      final kind = classify(tags);
      if (kind == null) continue;
      final List<List<MapXY>> parts;
      if (element['type'] == 'way') {
        final geometry = runs(element['geometry']);
        if (kind.isArea) {
          final closed =
              geometry.length == 1 &&
              geometry.single.length >= 4 &&
              geometry.single.first == geometry.single.last;
          // An open "area" is a multipolygon piece: its relation draws it.
          parts = closed ? area(geometry) : const [];
        } else {
          parts = lines(geometry);
        }
      } else if (element['type'] == 'relation' && kind.isArea) {
        final outer = <List<MapXY>>[];
        final inner = <List<MapXY>>[];
        for (final m in (element['members'] as List? ?? const [])) {
          if (m is! Map || m['type'] != 'way') continue;
          (m['role'] == 'inner' ? inner : outer).addAll(runs(m['geometry']));
        }
        parts = [...area(assembleRings(outer)), ...area(assembleRings(inner))];
      } else {
        continue;
      }
      if (parts.isNotEmpty) features.add(MapFeature(kind, parts));
    }
    return PlaceMap(
      center: center,
      halfSizeMeters: halfSizeMeters,
      features: features,
    );
  }
}
