import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:piscatio/domain/models/enums.dart';
import 'package:piscatio/domain/models/geo_point.dart';
import 'package:piscatio/domain/models/place_map.dart';
import 'package:piscatio/domain/services/map_geometry.dart';
import 'package:piscatio/domain/services/map_sketch.dart';
import 'package:piscatio/domain/services/overpass_map.dart';
import 'package:piscatio/domain/services/privacy_offset.dart';

void main() {
  final secret = List<int>.generate(32, (i) => i * 7 % 256);

  group('privacy', () {
    test('private and friends trips get no map', () {
      const spot = GeoPoint(-16.52, -56.41);
      expect(MapView.forPrivacy(PrivacyLevel.private, spot, secret), isNull);
      expect(MapView.forPrivacy(PrivacyLevel.friends, spot, secret), isNull);
    });

    test('the ring always contains the spot but is never centered on it', () {
      final rnd = math.Random(3);
      for (var i = 0; i < 400; i++) {
        final spot = GeoPoint(
          -30 + rnd.nextDouble() * 40,
          -70 + rnd.nextDouble() * 40,
        );
        for (final level in [PrivacyLevel.approximate, PrivacyLevel.exact]) {
          final view = MapView.forPrivacy(level, spot, secret)!;
          final d = distanceMeters(spot, view.center);
          expect(d, lessThan(view.ringRadiusMeters), reason: '$level $spot');
          if (level == PrivacyLevel.approximate) {
            expect(d, greaterThan(250), reason: '$spot');
          }
        }
      }
    });

    test('nearby spots share the same approximate map area', () {
      final a = mapAreaFor(const GeoPoint(-16.52001, -56.41001), secret);
      final b = mapAreaFor(const GeoPoint(-16.52003, -56.41004), secret);
      expect(a.key, b.key);
      // The data is fetched around the approximate point, not the spot.
      expect(
        distanceMeters(a.center, const GeoPoint(-16.52001, -56.41001)),
        greaterThan(250),
      );
    });

    test('the local view always fits in the fetched area', () {
      final rnd = math.Random(5);
      for (var i = 0; i < 300; i++) {
        final spot = GeoPoint(
          -30 + rnd.nextDouble() * 40,
          -70 + rnd.nextDouble() * 40,
        );
        final area = mapAreaFor(spot, secret);
        final proj = LocalProjection(area.center);
        for (final level in [PrivacyLevel.approximate, PrivacyLevel.exact]) {
          final view = MapView.forPrivacy(level, spot, secret)!;
          final c = proj.of(view.center);
          final reach = view.halfWidthMeters * MapSketch.extent;
          // Local maps show streams, fetched over a smaller area.
          final limit = level == PrivacyLevel.exact
              ? OverpassMap.streamHalfSizeMeters
              : OverpassMap.halfSizeMeters;
          expect(c.x.abs() + reach, lessThan(limit), reason: '$level $spot');
          expect(c.y.abs() + reach, lessThan(limit), reason: '$level $spot');
        }
      }
    });
  });

  group('sketch', () {
    const spot = GeoPoint(-16.5205, -56.4102);
    final area = mapAreaFor(spot, secret);
    final json = jsonDecode(
      File('test/fixtures/overpass_reservoir.json').readAsStringSync(),
    ) as Map<String, Object?>;
    final map = OverpassMap.parse(json, area.center);

    test('in view units around the view center, inside the extent', () {
      final view = MapView.forPrivacy(PrivacyLevel.exact, spot, secret)!;
      final sketch = MapSketch.of(map, view)!;
      expect(sketch.ringRadius, closeTo(650 / 3000, 1e-9));
      expect(sketch.metersPerUnit, 3000);
      for (final s in sketch.shapes) {
        for (final part in s.parts) {
          for (final v in part) {
            expect(v.abs(), lessThanOrEqualTo(MapSketch.extent + 1e-4));
          }
        }
      }
      expect(sketch.shapes.first.kind, MapFeatureKind.water);
    });

    test('regional maps leave out streams', () {
      final regional = MapSketch.of(
        map,
        MapView.forPrivacy(PrivacyLevel.approximate, spot, secret)!,
      )!;
      expect(
        regional.shapes.map((s) => s.kind),
        isNot(contains(MapFeatureKind.stream)),
      );
      final local = MapSketch.of(
        map,
        MapView.forPrivacy(PrivacyLevel.exact, spot, secret)!,
      )!;
      expect(local.shapes.map((s) => s.kind), contains(MapFeatureKind.stream));
    });

    test('no water around: no map', () {
      final roadsOnly = PlaceMap(
        center: area.center,
        halfSizeMeters: map.halfSizeMeters,
        features: map.features
            .where((f) => f.kind == MapFeatureKind.road)
            .toList(),
      );
      final view = MapView.forPrivacy(PrivacyLevel.exact, spot, secret)!;
      expect(MapSketch.of(roadsOnly, view), isNull);
    });
  });
}
