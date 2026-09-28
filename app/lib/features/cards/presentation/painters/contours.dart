import 'dart:math' as math;
import 'dart:ui';

/// Seeded 2D gradient noise (Perlin style), -1..1. Deterministic per seed,
/// so a trip's chart always looks the same.
class GradientNoise {
  GradientNoise(int seed) {
    final rnd = math.Random(seed);
    final p = List<int>.generate(256, (i) => i)..shuffle(rnd);
    _perm = [...p, ...p];
  }

  late final List<int> _perm;

  static double _fade(double t) => t * t * t * (t * (t * 6 - 15) + 10);

  static double _grad(int hash, double x, double y) {
    switch (hash & 7) {
      case 0:
        return x + y;
      case 1:
        return -x + y;
      case 2:
        return x - y;
      case 3:
        return -x - y;
      case 4:
        return x;
      case 5:
        return -x;
      case 6:
        return y;
      default:
        return -y;
    }
  }

  double noise(double x, double y) {
    final xi = x.floor() & 255;
    final yi = y.floor() & 255;
    final xf = x - x.floor();
    final yf = y - y.floor();
    final u = _fade(xf);
    final v = _fade(yf);
    final aa = _perm[_perm[xi] + yi];
    final ab = _perm[_perm[xi] + yi + 1];
    final ba = _perm[_perm[xi + 1] + yi];
    final bb = _perm[_perm[xi + 1] + yi + 1];
    double lerp(double a, double b, double t) => a + (b - a) * t;
    final x1 = lerp(_grad(aa, xf, yf), _grad(ba, xf - 1, yf), u);
    final x2 = lerp(_grad(ab, xf, yf - 1), _grad(bb, xf - 1, yf - 1), u);
    return lerp(x1, x2, v).clamp(-1.0, 1.0);
  }

  /// Fractal sum of octaves, normalized to 0..1.
  double fbm(double x, double y, {int octaves = 4}) {
    var sum = 0.0;
    var amp = 1.0;
    var freq = 1.0;
    var norm = 0.0;
    for (var i = 0; i < octaves; i++) {
      sum += noise(x * freq, y * freq) * amp;
      norm += amp;
      amp *= 0.5;
      freq *= 2;
    }
    return (sum / norm + 1) / 2;
  }
}

/// Sampled scalar field on a regular grid.
class ScalarGrid {
  ScalarGrid(this.columns, this.rows, this.cell, this.values);

  /// Samples [f] at every grid node over [size].
  factory ScalarGrid.sample(
    Size size,
    double cell,
    double Function(double x, double y) f,
  ) {
    final cols = (size.width / cell).ceil() + 1;
    final rows = (size.height / cell).ceil() + 1;
    return ScalarGrid(cols, rows, cell, [
      for (var r = 0; r < rows; r++)
        for (var c = 0; c < cols; c++) f(c * cell, r * cell),
    ]);
  }

  final int columns;
  final int rows;
  final double cell;
  final List<double> values;

  double at(int c, int r) => values[r * columns + c];
}

/// Line segments where the field crosses [level] (marching squares).
List<(Offset, Offset)> isoSegments(ScalarGrid g, double level) {
  final out = <(Offset, Offset)>[];
  double t(double a, double b) => (level - a) / (b - a);
  for (var r = 0; r < g.rows - 1; r++) {
    for (var c = 0; c < g.columns - 1; c++) {
      final tl = g.at(c, r);
      final tr = g.at(c + 1, r);
      final br = g.at(c + 1, r + 1);
      final bl = g.at(c, r + 1);
      final index =
          (tl > level ? 8 : 0) |
          (tr > level ? 4 : 0) |
          (br > level ? 2 : 0) |
          (bl > level ? 1 : 0);
      if (index == 0 || index == 15) continue;
      final x = c * g.cell;
      final y = r * g.cell;
      final s = g.cell;
      final top = Offset(x + s * t(tl, tr), y);
      final right = Offset(x + s, y + s * t(tr, br));
      final bottom = Offset(x + s * t(bl, br), y + s);
      final left = Offset(x, y + s * t(tl, bl));
      switch (index) {
        case 1 || 14:
          out.add((left, bottom));
        case 2 || 13:
          out.add((bottom, right));
        case 3 || 12:
          out.add((left, right));
        case 4 || 11:
          out.add((top, right));
        case 5:
          out
            ..add((left, top))
            ..add((bottom, right));
        case 6 || 9:
          out.add((top, bottom));
        case 7 || 8:
          out.add((left, top));
        case 10:
          out
            ..add((top, right))
            ..add((left, bottom));
      }
    }
  }
  return out;
}
