import 'dart:typed_data';

import '../models/enums.dart';
import '../models/geo_point.dart';
import '../models/place_map.dart';
import 'map_geometry.dart';
import 'privacy_offset.dart';

/// The part of the map a card may show, decided by the trip's privacy.
///
/// The ring never sits on the real spot: its center is the privacy offset
/// point (deterministic per ~1 km cell, see [PrivacyOffset]), and its
/// radius is wide enough to contain the spot.
class MapView {
  const MapView({
    required this.center,
    required this.halfWidthMeters,
    required this.ringRadiusMeters,
  });

  final GeoPoint center;
  final double halfWidthMeters;
  final double ringRadiusMeters;

  /// The region: a ~19 km wide map with a ring of 4 km.
  static const regionalHalfWidth = 9500.0;
  static const regionalRing = 4000.0;

  /// The place: a ~6 km wide map with a ring of 650 m.
  static const localHalfWidth = 3000.0;
  static const localRing = 650.0;

  /// Null for private trips ("friends" behaves as private for now).
  static MapView? forPrivacy(
    PrivacyLevel level,
    GeoPoint spot,
    List<int> secret,
  ) => switch (level) {
    PrivacyLevel.private || PrivacyLevel.friends => null,
    PrivacyLevel.approximate => MapView(
      center: coarseOffset(secret).approximate(spot),
      halfWidthMeters: regionalHalfWidth,
      ringRadiusMeters: regionalRing,
    ),
    PrivacyLevel.exact => MapView(
      center: fineOffset(secret).approximate(spot),
      halfWidthMeters: localHalfWidth,
      ringRadiusMeters: localRing,
    ),
  };

  /// The spot is at most ~3.7 km from this point (cell half-diagonal plus
  /// the largest offset), inside the 4 km ring.
  static PrivacyOffset coarseOffset(List<int> secret) =>
      PrivacyOffset(secret: secret);

  /// For exact trips: at most ~0.58 km away, inside the 650 m ring.
  static PrivacyOffset fineOffset(List<int> secret) => PrivacyOffset(
    secret: secret,
    cellSizeMeters: 250,
    minOffsetMeters: 150,
    maxOffsetMeters: 400,
  );
}

/// Where map data is fetched and stored for a spot: always around the
/// approximate point, so the service never learns the real spot, and trips
/// in the same cell share it.
({GeoPoint center, String key}) mapAreaFor(GeoPoint spot, List<int> secret) {
  final c = MapView.coarseOffset(secret).approximate(spot);
  return (
    center: c,
    key: '${c.latitude.toStringAsFixed(5)},${c.longitude.toStringAsFixed(5)}',
  );
}

/// One shape of a sketch, in view units: x right, y down, the view center
/// at (0, 0) and its half-width = 1. Flat x, y pairs.
class SketchShape {
  const SketchShape(this.kind, this.parts);

  final MapFeatureKind kind;
  final List<Float32List> parts;
}

/// What a card draws: shapes relative to the view's center, a ring and a
/// scale. It holds **no coordinates**, like the rest of the card data.
class MapSketch {
  const MapSketch({
    required this.shapes,
    required this.ringRadius,
    required this.metersPerUnit,
  });

  final List<SketchShape> shapes;

  /// In view units.
  final double ringRadius;

  /// For the scale bar.
  final double metersPerUnit;

  /// Shapes cover [-extent, extent] on both axes, so frames up to this
  /// aspect ratio are filled.
  static const extent = 1.45;

  /// Shape detail: about one pixel on a 1080 px wide map.
  static const _tolerance = 2 / 1080;

  /// Null when there is nothing watery to show there (the map would only
  /// be roads).
  static MapSketch? of(PlaceMap map, MapView view) {
    final proj = LocalProjection(map.center);
    final c = proj.of(view.center);
    final h = view.halfWidthMeters;
    final box = squareBox(extent * h);
    final viewBox = (
      minX: c.x - extent * h,
      minY: c.y - extent * h,
      maxX: c.x + extent * h,
      maxY: c.y + extent * h,
    );
    // Streams clutter a regional map.
    final streams = h <= MapView.localHalfWidth * 1.5;
    final shapes = <SketchShape>[];
    for (final f in map.features) {
      if (f.kind == MapFeatureKind.stream && !streams) continue;
      final parts = <Float32List>[];
      for (final part in f.parts) {
        final b = boundsOf(part);
        if (b == null || !overlaps(b, viewBox)) continue;
        final local = [for (final p in part) (x: p.x - c.x, y: p.y - c.y)];
        final pieces = f.kind.isArea
            ? [?simplifyRing(clipRing(local, box), _tolerance * h)]
            : clipLine(simplify(local, _tolerance * h), box);
        for (final piece in pieces) {
          final flat = Float32List(piece.length * 2);
          for (var i = 0; i < piece.length; i++) {
            flat[i * 2] = piece[i].x / h;
            flat[i * 2 + 1] = -piece[i].y / h;
          }
          parts.add(flat);
        }
      }
      if (parts.isNotEmpty) shapes.add(SketchShape(f.kind, parts));
    }
    if (!shapes.any((s) => s.kind != MapFeatureKind.road)) return null;
    // Areas first, then lines, roads under the water lines.
    int order(MapFeatureKind k) => switch (k) {
      MapFeatureKind.water => 0,
      MapFeatureKind.road => 1,
      MapFeatureKind.coast => 2,
      MapFeatureKind.stream => 3,
      MapFeatureKind.canal => 4,
      MapFeatureKind.river => 5,
    };
    shapes.sort((a, b) => order(a.kind).compareTo(order(b.kind)));
    return MapSketch(
      shapes: shapes,
      ringRadius: view.ringRadiusMeters / h,
      metersPerUnit: h,
    );
  }
}
