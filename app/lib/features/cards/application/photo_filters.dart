import 'dart:math' as math;
import 'dart:typed_data';

/// Ways to show the catch photo on a card, drawn in the card's colors.
enum CardPhotoFilter {
  /// The photo as taken.
  none,

  /// Pen and ink: contour lines and cross-hatching in the shadows.
  ink,

  /// Engraved lines that follow the shapes, like an old field guide.
  engraving,

  /// Three flat inks, slightly out of register.
  screenprint,

  /// Printed dots, like a fishing magazine.
  halftone,

  /// Two colors of the theme, from shadow to light.
  duotone,
}

/// Turns RGBA pixels into a *separation*: the amount of each ink, not the
/// final colors. The card tints it with its palette ([filterTint]), so the
/// theme can change without filtering the photo again.
///
/// Red holds the main mask (tone for [CardPhotoFilter.duotone], ink for the
/// others); green holds the second ink of [CardPhotoFilter.screenprint].
/// Pure Dart, meant to run in an isolate.
Uint8List applyPhotoFilter(
  CardPhotoFilter filter,
  Uint8List rgba,
  int width,
  int height,
) {
  assert(rgba.length == width * height * 4);
  // Parameters were tuned on 720 px wide photos.
  final s = math.max(math.min(width, height) / 720, 0.25);
  final y = _luminance(rgba, width * height);
  final out = Uint8List(width * height * 4);
  void put(int i, double r, [double g = 0]) {
    out[i * 4] = (r.clamp(0, 1) * 255).round();
    out[i * 4 + 1] = (g.clamp(0, 1) * 255).round();
    out[i * 4 + 3] = 255;
  }

  switch (filter) {
    case CardPhotoFilter.none:
      return Uint8List.fromList(rgba);
    case CardPhotoFilter.duotone:
      final t = _tone(blur(y, width, height, 0.6 * s));
      for (var i = 0; i < t.length; i++) {
        put(i, t[i]);
      }
    case CardPhotoFilter.ink:
      final t = _tone(y);
      final lines = xdog(
        t,
        width,
        height,
        sigma: 1.0 * s,
        p: 26,
        eps: 0.62,
        phi: 14,
      );
      final shade = blur(t, width, height, 2.5 * s);
      final step = math.max(8 * s, 4).round();
      final nib = math.max(2 * s, 1).round();
      for (var i = 0; i < t.length; i++) {
        final x = i % width;
        final row = i ~/ width;
        final hatch =
            ((x + row) % step < nib && shade[i] < 0.33) ||
            ((x - row) % step < nib && shade[i] < 0.16);
        final paper = math.min(lines[i], hatch ? 0.1 : 1.0);
        put(i, 1 - paper);
      }
    case CardPhotoFilter.engraving:
      final t = _tone(blur(y, width, height, 1.0 * s));
      final period = 8 * s;
      final bend = blur(t, width, height, 10 * s);
      final edges = xdog(
        t,
        width,
        height,
        sigma: 1.3 * s,
        p: 20,
        eps: 0.75,
        phi: 10,
      );
      for (var i = 0; i < t.length; i++) {
        final x = i % width;
        final row = i ~/ width;
        final phase =
            (row + bend[i] * period * 2.5 + math.sin(x / (40 * s)) * 1.5 * s) /
            period;
        final f = (phase - phase.roundToDouble()).abs() * 2;
        final thick = math.pow(1 - t[i], 1.2);
        final line = ((thick - f) * period * 0.9 + 0.5).clamp(0.0, 1.0);
        put(i, math.max(line, (1 - edges[i]) * 0.95));
      }
    case CardPhotoFilter.screenprint:
      final t = _tone(y);
      final down = math.max((3 * s).round(), 2);
      final smooth = _smoothShapes(t, width, height, down);
      // The second ink is printed a few pixels off, like a hand pull.
      final dx = -(3 * s).round();
      final dy = (4 * s).round();
      for (var i = 0; i < t.length; i++) {
        final x = i % width;
        final row = i ~/ width;
        final sx = (x - dx).clamp(0, width - 1);
        final sy = (row - dy).clamp(0, height - 1);
        final mid = smooth[sy * width + sx] < 0.58 ? 1.0 : 0.0;
        final dark = smooth[i] < 0.30 ? 1.0 : 0.0;
        put(i, dark, math.max(mid, dark));
      }
    case CardPhotoFilter.halftone:
      final t = _tone(blur(y, width, height, 1.5 * s));
      final cell = 10 * s;
      const angle = math.pi / 4;
      final ca = math.cos(angle) / cell;
      final sa = math.sin(angle) / cell;
      for (var i = 0; i < t.length; i++) {
        final x = i % width;
        final row = i ~/ width;
        final u = x * ca + row * sa;
        final v = -x * sa + row * ca;
        final fu = u - u.roundToDouble();
        final fv = v - v.roundToDouble();
        final dist = math.sqrt(fu * fu + fv * fv);
        final radius = math.sqrt((1 - t[i]) / math.pi) * 1.08;
        put(i, (radius - dist) * cell * 1.2 + 0.5);
      }
  }
  return out;
}

/// Color matrix (Flutter's 5×4 layout, offsets in 0–255) that tints a
/// separation: `out = base + red·(first − base) + green·(second − first)`.
///
/// For the one-ink filters [second] is unused.
List<double> filterTint({required int base, required int first, int? second}) {
  List<double> row(int shift) {
    final b = (base >> shift) & 0xFF;
    final f = (first >> shift) & 0xFF;
    if (second == null) return [(f - b) / 255, 0, 0, 0, b.toDouble()];
    final c = (second >> shift) & 0xFF;
    // Green covers both inks, red only the darkest one.
    return [(f - c) / 255, (c - b) / 255, 0, 0, b.toDouble()];
  }

  // Alpha passes through: forcing it opaque would tint everything around
  // the photo too.
  return [...row(16), ...row(8), ...row(0), 0, 0, 0, 1, 0];
}

Float32List _luminance(Uint8List rgba, int n) {
  final y = Float32List(n);
  for (var i = 0; i < n; i++) {
    y[i] =
        (rgba[i * 4] * 0.299 +
            rgba[i * 4 + 1] * 0.587 +
            rgba[i * 4 + 2] * 0.114) /
        255;
  }
  return y;
}

/// Contrast for any light: part histogram equalization (lifts night
/// photos), part plain levels (keeps daylight photos natural).
Float32List _tone(Float32List y, {double amount = 0.6}) {
  final hist = Int32List(256);
  for (final v in y) {
    hist[(v * 255).round().clamp(0, 255)]++;
  }
  final cdf = Float32List(256);
  var acc = 0;
  for (var i = 0; i < 256; i++) {
    acc += hist[i];
    cdf[i] = acc / y.length;
  }
  var lo = 0;
  while (lo < 255 && cdf[lo] < 0.01) {
    lo++;
  }
  var hi = 255;
  while (hi > 0 && cdf[hi - 1] >= 0.99) {
    hi--;
  }
  final span = math.max(hi - lo, 1) / 255;
  final base = lo / 255;
  final out = Float32List(y.length);
  for (var i = 0; i < y.length; i++) {
    final v = y[i];
    final eq = cdf[(v * 255).round().clamp(0, 255)];
    final lv = ((v - base) / span).clamp(0.0, 1.0);
    out[i] = eq * amount + lv * (1 - amount);
  }
  return out;
}

/// Extended difference of Gaussians: 1 on paper, falling to 0 on lines.
Float32List xdog(
  Float32List y,
  int width,
  int height, {
  required double sigma,
  double k = 1.6,
  required double p,
  required double eps,
  required double phi,
}) {
  final g1 = blur(y, width, height, sigma);
  final g2 = blur(y, width, height, sigma * k);
  final out = Float32List(y.length);
  for (var i = 0; i < y.length; i++) {
    final d = (1 + p) * g1[i] - p * g2[i];
    out[i] = d >= eps ? 1 : (1 + _tanh(phi * (d - eps))).clamp(0.0, 1.0);
  }
  return out;
}

double _tanh(double x) {
  if (x > 10) return 1;
  if (x < -10) return -1;
  final e = math.exp(2 * x);
  return (e - 1) / (e + 1);
}

/// Posterize-ready tones with smooth, cut-paper edges: shrink, clean up,
/// grow back and soften.
Float32List _smoothShapes(Float32List t, int width, int height, int down) {
  final sw = math.max(width ~/ down, 1);
  final sh = math.max(height ~/ down, 1);
  final small = Float32List(sw * sh);
  for (var y = 0; y < sh; y++) {
    for (var x = 0; x < sw; x++) {
      var sum = 0.0;
      var n = 0;
      for (var j = 0; j < down; j++) {
        final yy = y * down + j;
        if (yy >= height) break;
        for (var i = 0; i < down; i++) {
          final xx = x * down + i;
          if (xx >= width) break;
          sum += t[yy * width + xx];
          n++;
        }
      }
      small[y * sw + x] = sum / math.max(n, 1);
    }
  }
  final cleaned = _median3(small, sw, sh);
  final big = Float32List(width * height);
  for (var y = 0; y < height; y++) {
    final fy = ((y + 0.5) / down - 0.5).clamp(0.0, sh - 1.0);
    final y0 = fy.floor();
    final y1 = math.min(y0 + 1, sh - 1);
    final wy = fy - y0;
    for (var x = 0; x < width; x++) {
      final fx = ((x + 0.5) / down - 0.5).clamp(0.0, sw - 1.0);
      final x0 = fx.floor();
      final x1 = math.min(x0 + 1, sw - 1);
      final wx = fx - x0;
      final top = cleaned[y0 * sw + x0] * (1 - wx) + cleaned[y0 * sw + x1] * wx;
      final bottom =
          cleaned[y1 * sw + x0] * (1 - wx) + cleaned[y1 * sw + x1] * wx;
      big[y * width + x] = top * (1 - wy) + bottom * wy;
    }
  }
  return blur(big, width, height, down * 0.6);
}

Float32List _median3(Float32List src, int width, int height) {
  final out = Float32List(src.length);
  final window = Float32List(9);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      var n = 0;
      for (var j = -1; j <= 1; j++) {
        final yy = (y + j).clamp(0, height - 1);
        for (var i = -1; i <= 1; i++) {
          final xx = (x + i).clamp(0, width - 1);
          window[n++] = src[yy * width + xx];
        }
      }
      window.sort();
      out[y * width + x] = window[4];
    }
  }
  return out;
}

/// Gaussian blur approximated by three box blurs (constant time per pixel
/// whatever the radius). Edges are clamped.
Float32List blur(Float32List src, int width, int height, double sigma) {
  if (sigma < 0.5) return Float32List.fromList(src);
  final a = Float32List.fromList(src);
  final b = Float32List(src.length);
  for (final size in _boxSizes(sigma, 3)) {
    final r = (size - 1) ~/ 2;
    _boxPass(a, b, width, height, r: r, horizontal: true);
    _boxPass(b, a, width, height, r: r, horizontal: false);
  }
  return a;
}

List<int> _boxSizes(double sigma, int n) {
  final ideal = math.sqrt(12 * sigma * sigma / n + 1);
  var wl = ideal.floor();
  if (wl.isEven) wl--;
  final wu = wl + 2;
  final m =
      ((12 * sigma * sigma - n * wl * wl - 4 * n * wl - 3 * n) / (-4 * wl - 4))
          .round();
  return [for (var i = 0; i < n; i++) i < m ? wl : wu];
}

void _boxPass(
  Float32List src,
  Float32List dst,
  int width,
  int height, {
  required int r,
  required bool horizontal,
}) {
  final lines = horizontal ? height : width;
  final len = horizontal ? width : height;
  final stride = horizontal ? 1 : width;
  final inv = 1 / (2 * r + 1);
  for (var l = 0; l < lines; l++) {
    final start = horizontal ? l * width : l;
    double at(int k) => src[start + k.clamp(0, len - 1) * stride];
    var acc = 0.0;
    for (var k = -r; k <= r; k++) {
      acc += at(k);
    }
    for (var k = 0; k < len; k++) {
      dst[start + k * stride] = acc * inv;
      acc += at(k + r + 1) - at(k - r);
    }
  }
}
