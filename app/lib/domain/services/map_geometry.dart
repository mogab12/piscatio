import 'dart:math' as math;

import '../models/geo_point.dart';
import '../models/place_map.dart';

/// Flat projection around a center (equirectangular): a few meters off at
/// 20 km, plenty for a sketch map.
class LocalProjection {
  LocalProjection(this.center)
    : _kx = 111320 * math.cos(center.latitude * math.pi / 180),
      _ky = 110574;

  final GeoPoint center;
  final double _kx;
  final double _ky;

  MapXY toXY(double latitude, double longitude) {
    var dLon = longitude - center.longitude;
    if (dLon > 180) dLon -= 360;
    if (dLon < -180) dLon += 360;
    return (x: dLon * _kx, y: (latitude - center.latitude) * _ky);
  }

  MapXY of(GeoPoint p) => toXY(p.latitude, p.longitude);

  GeoPoint toGeo(MapXY p) =>
      GeoPoint(center.latitude + p.y / _ky, center.longitude + p.x / _kx);
}

/// Axis-aligned box.
typedef MapBox = ({double minX, double minY, double maxX, double maxY});

MapBox squareBox(double half) =>
    (minX: -half, minY: -half, maxX: half, maxY: half);

MapBox? boundsOf(Iterable<MapXY> points) {
  double? minX, minY, maxX, maxY;
  for (final p in points) {
    minX = minX == null ? p.x : math.min(minX, p.x);
    minY = minY == null ? p.y : math.min(minY, p.y);
    maxX = maxX == null ? p.x : math.max(maxX, p.x);
    maxY = maxY == null ? p.y : math.max(maxY, p.y);
  }
  if (minX == null) return null;
  return (minX: minX, minY: minY!, maxX: maxX!, maxY: maxY!);
}

bool overlaps(MapBox a, MapBox b) =>
    a.minX <= b.maxX &&
    b.minX <= a.maxX &&
    a.minY <= b.maxY &&
    b.minY <= a.maxY;

double _segmentDistance(MapXY p, MapXY a, MapXY b) {
  final dx = b.x - a.x;
  final dy = b.y - a.y;
  final len2 = dx * dx + dy * dy;
  if (len2 == 0) {
    return math.sqrt(math.pow(p.x - a.x, 2) + math.pow(p.y - a.y, 2));
  }
  final t = (((p.x - a.x) * dx + (p.y - a.y) * dy) / len2).clamp(0.0, 1.0);
  final qx = a.x + t * dx;
  final qy = a.y + t * dy;
  return math.sqrt(math.pow(p.x - qx, 2) + math.pow(p.y - qy, 2));
}

/// Douglas–Peucker: drops points closer than [tolerance] to the simplified
/// line. Iterative, so long rivers cannot overflow the stack.
List<MapXY> simplify(List<MapXY> points, double tolerance) {
  if (points.length <= 2 || tolerance <= 0) return points;
  final keep = List<bool>.filled(points.length, false)
    ..[0] = true
    ..[points.length - 1] = true;
  final stack = <(int, int)>[(0, points.length - 1)];
  while (stack.isNotEmpty) {
    final (first, last) = stack.removeLast();
    var index = -1;
    var maxDistance = tolerance;
    for (var i = first + 1; i < last; i++) {
      final d = _segmentDistance(points[i], points[first], points[last]);
      if (d > maxDistance) {
        maxDistance = d;
        index = i;
      }
    }
    if (index != -1) {
      keep[index] = true;
      stack
        ..add((first, index))
        ..add((index, last));
    }
  }
  return [
    for (var i = 0; i < points.length; i++)
      if (keep[i]) points[i],
  ];
}

/// Simplifies a closed ring (first point repeated at the end or not);
/// null when too little is left to enclose anything.
List<MapXY>? simplifyRing(List<MapXY> ring, double tolerance) {
  if (ring.length < 3) return null;
  final open = _same(ring.first, ring.last)
      ? ring.sublist(0, ring.length - 1)
      : ring;
  if (open.length < 3) return null;
  // Split at the point farthest from the start so both halves have ends.
  var far = 1;
  var best = -1.0;
  for (var i = 1; i < open.length; i++) {
    final d =
        math.pow(open[i].x - open[0].x, 2) + math.pow(open[i].y - open[0].y, 2);
    if (d > best) {
      best = d.toDouble();
      far = i;
    }
  }
  final a = simplify(open.sublist(0, far + 1), tolerance);
  final b = simplify([...open.sublist(far), open[0]], tolerance);
  final out = [...a, ...b.sublist(1, b.length - 1)];
  return out.length < 3 ? null : out;
}

/// Sutherland–Hodgman against a box. Concave rings may gain edges along
/// the box border; filled, they look right.
List<MapXY> clipRing(List<MapXY> ring, MapBox box) {
  var out = ring;
  for (var edge = 0; edge < 4; edge++) {
    if (out.isEmpty) break;
    bool inside(MapXY p) => switch (edge) {
      0 => p.x >= box.minX,
      1 => p.x <= box.maxX,
      2 => p.y >= box.minY,
      _ => p.y <= box.maxY,
    };
    MapXY cross(MapXY a, MapXY b) {
      final double t;
      switch (edge) {
        case 0:
          t = (box.minX - a.x) / (b.x - a.x);
        case 1:
          t = (box.maxX - a.x) / (b.x - a.x);
        case 2:
          t = (box.minY - a.y) / (b.y - a.y);
        default:
          t = (box.maxY - a.y) / (b.y - a.y);
      }
      return (x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t);
    }

    final input = out;
    out = [];
    for (var i = 0; i < input.length; i++) {
      final cur = input[i];
      final prev = input[(i + input.length - 1) % input.length];
      final curIn = inside(cur);
      final prevIn = inside(prev);
      if (curIn) {
        if (!prevIn) out.add(cross(prev, cur));
        out.add(cur);
      } else if (prevIn) {
        out.add(cross(prev, cur));
      }
    }
  }
  return out;
}

/// Liang–Barsky per segment: the pieces of [line] inside [box].
List<List<MapXY>> clipLine(List<MapXY> line, MapBox box) {
  final pieces = <List<MapXY>>[];
  List<MapXY>? current;
  for (var i = 0; i + 1 < line.length; i++) {
    final a = line[i];
    final b = line[i + 1];
    final dx = b.x - a.x;
    final dy = b.y - a.y;
    var t0 = 0.0;
    var t1 = 1.0;
    var visible = true;
    for (final (p, q) in [
      (-dx, a.x - box.minX),
      (dx, box.maxX - a.x),
      (-dy, a.y - box.minY),
      (dy, box.maxY - a.y),
    ]) {
      if (p == 0) {
        if (q < 0) visible = false;
      } else {
        final r = q / p;
        if (p < 0) {
          if (r > t1) visible = false;
          if (r > t0) t0 = r;
        } else {
          if (r < t0) visible = false;
          if (r < t1) t1 = r;
        }
      }
      if (!visible) break;
    }
    if (!visible) {
      current = null;
      continue;
    }
    final start = t0 == 0 ? a : (x: a.x + dx * t0, y: a.y + dy * t0);
    final end = t1 == 1 ? b : (x: a.x + dx * t1, y: a.y + dy * t1);
    if (current == null || t0 > 0) {
      current = [start];
      pieces.add(current);
    }
    current.add(end);
    if (t1 < 1) current = null;
  }
  return [
    for (final p in pieces)
      if (p.length >= 2) p,
  ];
}

bool _same(MapXY a, MapXY b, [double eps = 0.01]) =>
    (a.x - b.x).abs() <= eps && (a.y - b.y).abs() <= eps;

/// Joins the ways of a multipolygon into closed rings, matching ends (a
/// ring may be split over many ways, in any direction). A chain that
/// cannot be closed is kept only if its gap is small.
List<List<MapXY>> assembleRings(
  List<List<MapXY>> ways, {
  double maxGapMeters = 50,
}) {
  final pool = [
    for (final w in ways)
      if (w.length >= 2) [...w],
  ];
  final rings = <List<MapXY>>[];
  while (pool.isNotEmpty) {
    final ring = pool.removeLast();
    var extended = true;
    while (!_same(ring.first, ring.last) && extended) {
      extended = false;
      for (var i = 0; i < pool.length; i++) {
        final w = pool[i];
        if (_same(ring.last, w.first)) {
          ring.addAll(w.skip(1));
        } else if (_same(ring.last, w.last)) {
          ring.addAll(w.reversed.skip(1));
        } else if (_same(ring.first, w.last)) {
          ring.insertAll(0, w.take(w.length - 1));
        } else if (_same(ring.first, w.first)) {
          ring.insertAll(0, w.reversed.take(w.length - 1));
        } else {
          continue;
        }
        pool.removeAt(i);
        extended = true;
        break;
      }
    }
    final gap = math.sqrt(
      math.pow(ring.first.x - ring.last.x, 2) +
          math.pow(ring.first.y - ring.last.y, 2),
    );
    if (gap <= maxGapMeters && ring.length >= 3) rings.add(ring);
  }
  return rings;
}

/// Joins ways head to tail, keeping their direction (coastlines are
/// oriented). Chains whose ends meet become closed rings.
List<List<MapXY>> joinChains(List<List<MapXY>> ways) {
  final pool = [
    for (final w in ways)
      if (w.length >= 2) [...w],
  ];
  final chains = <List<MapXY>>[];
  while (pool.isNotEmpty) {
    final chain = pool.removeLast();
    var extended = true;
    while (extended && !_same(chain.first, chain.last)) {
      extended = false;
      for (var i = 0; i < pool.length; i++) {
        final w = pool[i];
        if (_same(chain.last, w.first)) {
          chain.addAll(w.skip(1));
        } else if (_same(w.last, chain.first)) {
          chain.insertAll(0, w.take(w.length - 1));
        } else {
          continue;
        }
        pool.removeAt(i);
        extended = true;
        break;
      }
    }
    chains.add(chain);
  }
  return chains;
}

/// Position along the box's edge, clockwise from the top left corner
/// (0–4, one unit per side); negative when [p] is not on the edge.
double _perimeter(MapXY p, MapBox b, double eps) {
  final w = b.maxX - b.minX;
  final h = b.maxY - b.minY;
  if ((p.y - b.maxY).abs() <= eps) return ((p.x - b.minX) / w).clamp(0, 1);
  if ((p.x - b.maxX).abs() <= eps) return 1 + ((b.maxY - p.y) / h).clamp(0, 1);
  if ((p.y - b.minY).abs() <= eps) return 2 + ((b.maxX - p.x) / w).clamp(0, 1);
  if ((p.x - b.minX).abs() <= eps) return 3 + ((p.y - b.minY) / h).clamp(0, 1);
  return -1;
}

MapXY _corner(int k, MapBox b) => switch (k % 4) {
  0 => (x: b.minX, y: b.maxY),
  1 => (x: b.maxX, y: b.maxY),
  2 => (x: b.maxX, y: b.minY),
  _ => (x: b.minX, y: b.minY),
};

/// The sea inside [box] (y pointing north), from coastline [pieces]
/// already clipped to it. OpenStreetMap draws coastlines with the land on
/// the left, so the water is on the right: each piece is closed by walking
/// the box's edge clockwise to the next piece. Closed rings are islands
/// and come back as holes (fill even-odd).
List<List<MapXY>> seaRings(List<List<MapXY>> pieces, MapBox box) {
  final eps = (box.maxX - box.minX) * 1e-6;
  final open = <List<MapXY>>[];
  final islands = <List<MapXY>>[];
  for (final p in pieces) {
    if (p.length < 2) continue;
    if (p.length >= 4 && _same(p.first, p.last, eps)) {
      islands.add(p);
    } else if (_perimeter(p.first, box, eps) >= 0 &&
        _perimeter(p.last, box, eps) >= 0) {
      open.add(p);
    }
  }
  if (open.isEmpty) {
    if (islands.isEmpty) return const [];
    return [
      [for (var k = 0; k < 4; k++) _corner(k, box)],
      ...islands,
    ];
  }
  final used = List<bool>.filled(open.length, false);
  final rings = <List<MapXY>>[];
  for (var first = 0; first < open.length; first++) {
    if (used[first]) continue;
    final ring = <MapXY>[];
    var current = first;
    for (var guard = 0; guard <= open.length; guard++) {
      used[current] = true;
      ring.addAll(open[current]);
      final end = _perimeter(open[current].last, box, eps);
      var next = first;
      var best = double.infinity;
      for (var j = 0; j < open.length; j++) {
        if (used[j] && j != first) continue;
        final d = (_perimeter(open[j].first, box, eps) - end) % 4;
        if (d < best) {
          best = d;
          next = j;
        }
      }
      for (var k = end.floor() + 1; k < end + best; k++) {
        ring.add(_corner(k, box));
      }
      if (next == first) break;
      current = next;
    }
    if (ring.length >= 3) rings.add(ring);
  }
  return [...rings, ...islands];
}
