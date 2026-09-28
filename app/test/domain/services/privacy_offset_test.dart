import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:piscatio/domain/models/geo_point.dart';
import 'package:piscatio/domain/services/privacy_offset.dart';

void main() {
  final secret = List<int>.generate(32, (i) => i * 7);
  final offset = PrivacyOffset(secret: secret);
  const spot = GeoPoint(-22.9068, -43.1729);

  test('same point always gets the same public point', () {
    expect(offset.approximate(spot), offset.approximate(spot));
    expect(
      PrivacyOffset(secret: secret).approximate(spot),
      offset.approximate(spot),
    );
  });

  test('points in the same grid cell share one public point', () {
    // ~20 m apart: the same spot on different days.
    const nearby = GeoPoint(-22.90665, -43.17275);
    expect(offset.approximate(nearby), offset.approximate(spot));
  });

  test('averaging many trips at one spot does not reveal it', () {
    final rnd = math.Random(1);
    final publics = <GeoPoint>{};
    for (var i = 0; i < 50; i++) {
      final jitter = GeoPoint(
        spot.latitude + (rnd.nextDouble() - 0.5) * 0.0002,
        spot.longitude + (rnd.nextDouble() - 0.5) * 0.0002,
      );
      publics.add(offset.approximate(jitter));
    }
    // At most the cells touched by the jitter, never a cloud around the spot.
    expect(publics.length, lessThanOrEqualTo(4));
    for (final p in publics) {
      expect(distanceMeters(p, spot), greaterThan(250));
    }
  });

  test('offset stays within the configured ring (plus half a cell)', () {
    final rnd = math.Random(42);
    for (var i = 0; i < 500; i++) {
      final p = GeoPoint(
        rnd.nextDouble() * 140 - 70,
        rnd.nextDouble() * 360 - 180,
      );
      final d = distanceMeters(offset.approximate(p), p);
      expect(d, greaterThan(1000 - 750), reason: '$p');
      expect(d, lessThan(3000 + 750), reason: '$p');
    }
  });

  test('a different secret gives a different public point', () {
    final other = PrivacyOffset(secret: List<int>.filled(32, 1));
    expect(other.approximate(spot), isNot(offset.approximate(spot)));
  });

  test('offset directions vary between cells', () {
    final bearings = <int>{};
    for (var i = 0; i < 40; i++) {
      final p = GeoPoint(-20 + i * 0.05, -45);
      final q = offset.approximate(p);
      final bearing = math.atan2(
        q.longitude - p.longitude,
        q.latitude - p.latitude,
      );
      bearings.add(((bearing + math.pi) / (math.pi / 4)).floor());
    }
    expect(bearings.length, greaterThanOrEqualTo(5));
  });

  test('handles the antimeridian and poles', () {
    final east = offset.approximate(const GeoPoint(10, 179.9999));
    expect(east.longitude, inInclusiveRange(-180, 180));
    final pole = offset.approximate(const GeoPoint(89.999, 0));
    expect(pole.latitude, inInclusiveRange(-90, 90));
  });
}
