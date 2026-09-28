import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../models/geo_point.dart';

/// Hides a fishing spot for the "approximate" privacy level.
///
/// A plain random offset per point is not enough: nearby points (the same
/// spot on different days) would get different offsets and averaging them
/// reveals the real place. So the point is first snapped to a grid cell
/// (~1 km) and the cell — not the point — gets a deterministic offset derived
/// from an HMAC keyed with a per-install secret. Every point in the same
/// cell maps to the same public point, and without the secret the offset
/// cannot be reversed.
class PrivacyOffset {
  PrivacyOffset({
    required List<int> secret,
    this.cellSizeMeters = 1000,
    this.minOffsetMeters = 1000,
    this.maxOffsetMeters = 3000,
  }) : _hmac = Hmac(sha256, secret),
       assert(secret.isNotEmpty),
       assert(minOffsetMeters <= maxOffsetMeters);

  final Hmac _hmac;
  final double cellSizeMeters;
  final double minOffsetMeters;
  final double maxOffsetMeters;

  static const _metersPerDegreeLat = 111320.0;

  GeoPoint approximate(GeoPoint point) {
    final latStep = cellSizeMeters / _metersPerDegreeLat;
    final row = (point.latitude / latStep).floor();
    final rowCenterLat = (row + 0.5) * latStep;
    final lonStep = cellSizeMeters / _metersPerDegreeLon(rowCenterLat);
    final col = (point.longitude / lonStep).floor();
    final cellCenterLon = (col + 0.5) * lonStep;

    final digest = _hmac.convert(utf8.encode('$row:$col')).bytes;
    final data = ByteData.sublistView(Uint8List.fromList(digest));
    final u1 = data.getUint32(0) / 0xFFFFFFFF;
    final u2 = data.getUint32(4) / 0xFFFFFFFF;

    final angle = u1 * 2 * math.pi;
    // sqrt keeps the offsets uniform over the ring's area.
    final minSq = minOffsetMeters * minOffsetMeters;
    final maxSq = maxOffsetMeters * maxOffsetMeters;
    final distance = math.sqrt(minSq + (maxSq - minSq) * u2);

    final lat = rowCenterLat + distance * math.cos(angle) / _metersPerDegreeLat;
    final lon =
        cellCenterLon + distance * math.sin(angle) / _metersPerDegreeLon(lat);
    return GeoPoint(lat.clamp(-90.0, 90.0), _wrapLongitude(lon));
  }

  static double _metersPerDegreeLon(double latitude) =>
      _metersPerDegreeLat *
      math.max(math.cos(latitude * math.pi / 180).abs(), 0.01);

  static double _wrapLongitude(double lon) {
    final wrapped = (lon + 180) % 360;
    return (wrapped < 0 ? wrapped + 360 : wrapped) - 180;
  }
}

/// Great-circle distance in meters (haversine).
double distanceMeters(GeoPoint a, GeoPoint b) {
  const r = 6371008.8;
  final dLat = (b.latitude - a.latitude) * math.pi / 180;
  final dLon = (b.longitude - a.longitude) * math.pi / 180;
  final h =
      math.pow(math.sin(dLat / 2), 2) +
      math.cos(a.latitude * math.pi / 180) *
          math.cos(b.latitude * math.pi / 180) *
          math.pow(math.sin(dLon / 2), 2);
  return 2 * r * math.asin(math.sqrt(h));
}
