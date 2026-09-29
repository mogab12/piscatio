import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:piscatio/domain/models/geo_point.dart';
import 'package:piscatio/domain/models/place_map.dart';
import 'package:piscatio/domain/services/map_geometry.dart';
import 'package:piscatio/domain/services/overpass_map.dart';

void main() {
  const center = GeoPoint(-16.52, -56.41);
  final json = jsonDecode(
    File('test/fixtures/overpass_reservoir.json').readAsStringSync(),
  ) as Map<String, Object?>;

  test('the query asks only for water, shore and main roads', () {
    final q = OverpassMap.query(center);
    expect(q, startsWith('[out:json]'));
    expect(q, contains('"natural"="water"'));
    expect(q, contains('"waterway"="stream"'));
    expect(q, contains('out geom qt;'));
    expect(q, isNot(contains('building')));
    // The bounding box is the area around the point, ±14 km.
    expect(q, contains('-16.64661,-56.54118,-16.39339,-56.27882'));
  });

  test('classifies tags', () {
    expect(OverpassMap.classify({'natural': 'water'}), MapFeatureKind.water);
    expect(
      OverpassMap.classify({'landuse': 'reservoir'}),
      MapFeatureKind.water,
    );
    expect(OverpassMap.classify({'waterway': 'river'}), MapFeatureKind.river);
    expect(OverpassMap.classify({'waterway': 'stream'}), MapFeatureKind.stream);
    expect(
      OverpassMap.classify({'natural': 'coastline'}),
      MapFeatureKind.coast,
    );
    expect(OverpassMap.classify({'highway': 'trunk'}), MapFeatureKind.road);
    expect(OverpassMap.classify({'highway': 'residential'}), isNull);
    expect(OverpassMap.classify({'building': 'yes'}), isNull);
  });

  test('parses a reservoir split in pieces, with its island, and lines', () {
    final map = OverpassMap.parse(json, center);
    final kinds = map.features.map((f) => f.kind).toList();
    expect(kinds.where((k) => k == MapFeatureKind.water), hasLength(2));
    expect(kinds.where((k) => k == MapFeatureKind.river), hasLength(2));
    expect(kinds.where((k) => k == MapFeatureKind.stream), hasLength(10));
    expect(kinds.where((k) => k == MapFeatureKind.road), hasLength(2));
    // The relation's two outer pieces became one ring, plus the island.
    final reservoir = map.features.firstWhere(
      (f) => f.kind == MapFeatureKind.water && f.parts.length == 2,
    );
    for (final ring in reservoir.parts) {
      expect(ring.length, greaterThan(20));
    }
    // Everything is inside the area.
    const limit = OverpassMap.halfSizeMeters * 1.02 + 0.001;
    for (final f in map.features) {
      for (final part in f.parts) {
        final b = boundsOf(part)!;
        expect(b.minX, greaterThanOrEqualTo(-limit));
        expect(b.maxY, lessThanOrEqualTo(limit));
      }
    }
  });

  test('round-trips through its compact JSON', () {
    final map = OverpassMap.parse(json, center);
    final back = PlaceMap.fromJson(
      jsonDecode(jsonEncode(map.toJson())) as Map<String, Object?>,
      center: center,
      halfSizeMeters: map.halfSizeMeters,
    );
    expect(back.features.length, map.features.length);
    expect(
      back.features.first.parts.first.first.x,
      closeTo(map.features.first.parts.first.first.x, 0.5),
    );
    // Simplified and in whole meters, the stored map stays small.
    expect(jsonEncode(map.toJson()).length, lessThan(60000));
  });

  test('an empty answer is an empty map', () {
    expect(OverpassMap.parse({'elements': <Object>[]}, center).isEmpty, isTrue);
  });
}
