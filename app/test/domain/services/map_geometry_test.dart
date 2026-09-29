import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:piscatio/domain/models/geo_point.dart';
import 'package:piscatio/domain/models/place_map.dart';
import 'package:piscatio/domain/services/map_geometry.dart';
import 'package:piscatio/domain/services/privacy_offset.dart';

void main() {
  test('local projection round-trips and measures like haversine', () {
    const c = GeoPoint(-16.52, -56.41);
    final proj = LocalProjection(c);
    const p = GeoPoint(-16.45, -56.33);
    final xy = proj.of(p);
    final back = proj.toGeo(xy);
    expect(back.latitude, closeTo(p.latitude, 1e-9));
    expect(back.longitude, closeTo(p.longitude, 1e-9));
    final flat = math.sqrt(xy.x * xy.x + xy.y * xy.y);
    expect(flat, closeTo(distanceMeters(c, p), distanceMeters(c, p) * 0.005));
  });

  test('simplify keeps corners and drops points on a straight line', () {
    final line = <MapXY>[
      for (var i = 0; i <= 10; i++) (x: i * 10.0, y: 0.0),
      (x: 100, y: 50),
    ];
    final s = simplify(line, 1);
    expect(s, [(x: 0.0, y: 0.0), (x: 100.0, y: 0.0), (x: 100.0, y: 50.0)]);
  });

  test('simplifyRing drops rings too small to see', () {
    final tiny = <MapXY>[
      (x: 0, y: 0),
      (x: 1, y: 0),
      (x: 1, y: 1),
      (x: 0, y: 0),
    ];
    expect(simplifyRing(tiny, 5), isNull);
    final square = <MapXY>[
      (x: 0, y: 0),
      (x: 50, y: 0),
      (x: 100, y: 0),
      (x: 100, y: 100),
      (x: 0, y: 100),
      (x: 0, y: 0),
    ];
    expect(simplifyRing(square, 1), hasLength(4));
  });

  test('clipRing cuts a polygon to the box', () {
    final big = <MapXY>[
      (x: -200, y: -200),
      (x: 200, y: -200),
      (x: 200, y: 200),
      (x: -200, y: 200),
    ];
    final clipped = clipRing(big, squareBox(100));
    final b = boundsOf(clipped)!;
    expect((b.minX, b.minY, b.maxX, b.maxY), (-100.0, -100.0, 100.0, 100.0));
    expect(
      clipRing(
        big.map((p) => (x: p.x + 1000, y: p.y)).toList(),
        squareBox(100),
      ),
      isEmpty,
    );
  });

  test('clipLine splits a line that leaves and comes back', () {
    final line = <MapXY>[
      (x: -50, y: 0),
      (x: 150, y: 0),
      (x: 150, y: 50),
      (x: 50, y: 50),
      (x: 50, y: 150),
    ];
    final pieces = clipLine(line, squareBox(100));
    expect(pieces, hasLength(2));
    expect(pieces.first, [(x: -50.0, y: 0.0), (x: 100.0, y: 0.0)]);
    expect(pieces.last.first, (x: 100.0, y: 50.0));
    expect(pieces.last.last, (x: 50.0, y: 100.0));
  });

  test('assembleRings joins pieces in any direction', () {
    final a = <MapXY>[(x: 0, y: 0), (x: 10, y: 0), (x: 10, y: 10)];
    final b = <MapXY>[(x: 0, y: 0), (x: 0, y: 10), (x: 10, y: 10)];
    final rings = assembleRings([a, b]);
    expect(rings, hasLength(1));
    expect(rings.single.first, rings.single.last);
    expect(rings.single, hasLength(5));
    // An open chain with a wide gap is dropped.
    expect(
      assembleRings([
        [(x: 0, y: 0), (x: 500, y: 0), (x: 500, y: 500)],
      ]),
      isEmpty,
    );
  });

  group('sea from the coastline (land on the left)', () {
    final box = squareBox(100);
    double area(List<MapXY> ring) {
      var a = 0.0;
      for (var i = 0; i < ring.length; i++) {
        final p = ring[i];
        final q = ring[(i + 1) % ring.length];
        a += p.x * q.y - q.x * p.y;
      }
      return a.abs() / 2;
    }

    test('coast running east: the sea is to the south', () {
      final sea = seaRings([
        [(x: -100, y: 0), (x: 100, y: 0)],
      ], box);
      expect(sea, hasLength(1));
      expect(area(sea.single), closeTo(20000, 1e-6));
      expect(boundsOf(sea.single)!.maxY, 0);
    });

    test('coast running west: the sea is to the north', () {
      final sea = seaRings([
        [(x: 100, y: 0), (x: -100, y: 0)],
      ], box);
      expect(boundsOf(sea.single)!.minY, 0);
    });

    test('a corner of land: everything else is sea', () {
      final sea = seaRings([
        [(x: 0, y: 100), (x: 100, y: 0)],
      ], box);
      expect(area(sea.single), closeTo(40000 - 5000, 1e-6));
    });

    test('a loop of coast: the water inside it', () {
      // The coast comes in from the west, loops east and goes back out
      // to the west.
      final sea = seaRings([
        [(x: -100, y: 50), (x: 0, y: 50), (x: 0, y: -50), (x: -100, y: -50)],
      ], box);
      // Water on the right of that loop: the western pocket.
      expect(area(sea.single), closeTo(100 * 100, 1e-6));
    });

    test('only islands: sea everywhere, islands as holes', () {
      final island = <MapXY>[
        (x: 0, y: 0),
        (x: 10, y: 0),
        (x: 10, y: 10),
        (x: 0, y: 0),
      ];
      final sea = seaRings([island], box);
      expect(sea, hasLength(2));
      expect(area(sea.first), 40000);
      expect(seaRings(const [], box), isEmpty);
    });

    test('joinChains keeps the direction of oriented ways', () {
      final chains = joinChains([
        [(x: 10, y: 0), (x: 20, y: 0)],
        [(x: 0, y: 0), (x: 10, y: 0)],
      ]);
      expect(chains.single, [
        (x: 0.0, y: 0.0),
        (x: 10.0, y: 0.0),
        (x: 20.0, y: 0.0),
      ]);
      // Opposite directions do not join.
      expect(
        joinChains([
          [(x: 0, y: 0), (x: 10, y: 0)],
          [(x: 20, y: 0), (x: 10, y: 0)],
        ]),
        hasLength(2),
      );
    });
  });
}
