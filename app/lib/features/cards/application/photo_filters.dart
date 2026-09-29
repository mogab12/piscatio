import 'dart:math' as math;
import 'dart:typed_data';

/// Ways to show the catch photo on a card, drawn in the card's colors.
/// The order is the order of the choices in the editor.
enum CardPhotoFilter {
  /// The photo as taken.
  none,

  /// A cave painting: the catch in ochre with a charcoal outline on the
  /// theme's stone, the rest sketched around it.
  rupestre,

  /// Engraved lines that bend around the shapes, like a banknote or an old
  /// field guide.
  engraving,

  /// Printed dots, like a fishing magazine.
  halftone,

  /// Two colors of the theme, from shadow to light.
  duotone,
}

/// Turns RGBA pixels into a *separation*: the amount of each ink, not the
/// final colors. The card inks it with its palette, so the theme can change
/// without filtering the photo again.
///
/// Red holds the main mask (tone for [CardPhotoFilter.duotone], ink for
/// the others). [CardPhotoFilter.rupestre] uses three: red for outlines,
/// green for the paint level, blue for the rock's shade.
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
  void put(int i, double r) {
    out[i * 4] = (r.clamp(0, 1) * 255).round();
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
    case CardPhotoFilter.engraving:
      _engraving(y, width, height, s, put);
    case CardPhotoFilter.rupestre:
      _rupestre(y, width, height, s, out);
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

/// Banknote engraving: regular lines that bend around the big shapes,
/// thicker in the shadows, crossed by a second set in the deep shadows,
/// with the real edges drawn. Local contrast keeps detail in dark areas.
void _engraving(
  Float32List y,
  int width,
  int height,
  double s,
  void Function(int i, double ink) put,
) {
  var t = _localTone(_tone(y), width, height, 50 * s, 0.45);
  t = _median3(t, width, height);
  final light = blur(t, width, height, 1.2 * s);
  final bend = blur(t, width, height, 18 * s);
  final fine = blur(t, width, height, 1.1 * s);
  final coarse = blur(t, width, height, 1.8 * s);
  final period = 7.5 * s;
  // Main lines slightly tilted, crossing lines steeper.
  const a1 = -18 * math.pi / 180;
  const a2 = 52 * math.pi / 180;
  final c1 = math.cos(a1), s1 = math.sin(a1);
  final c2 = math.cos(a2), s2 = math.sin(a2);
  final wave = 55 * s;
  double distance(
    double x,
    double row,
    double b,
    double ca,
    double sa,
    double p,
    double warp,
  ) {
    final along = x * ca + row * sa;
    final across = -x * sa + row * ca;
    final phase =
        (across + b * p * warp + math.sin(along / wave) * 1.2 * s) / p;
    return (phase - phase.roundToDouble()).abs() * 2;
  }

  for (var i = 0; i < t.length; i++) {
    final x = (i % width).toDouble();
    final row = (i ~/ width).toDouble();
    final dark = 1 - light[i];
    // Hairlines even in the light parts, paper only in highlights.
    final w1 = light[i] > 0.95
        ? 0.0
        : math.pow(dark.clamp(0.0, 1.0), 1.1) * 0.92 + 0.06;
    final f1 = distance(x, row, bend[i], c1, s1, period, 5);
    final line1 = ((w1 - f1) * period * 0.8 + 0.5).clamp(0.0, 1.0);
    final w2 = ((dark - 0.5) * 1.6).clamp(0.0, 0.9);
    final f2 = distance(x, row, bend[i], c2, s2, period * 0.9, 3);
    final line2 = w2 == 0
        ? 0.0
        : ((w2 - f2) * period * 0.8 + 0.5).clamp(0.0, 1.0);
    final edge = _smoothstep(0.012, 0.035, coarse[i] - fine[i]);
    put(i, math.max(math.max(line1, line2), edge * 0.95));
  }
}

/// Cave painting, like a scene on a lit rock wall: the photo smoothed
/// into painted patches (Kuwahara), their edges wobbling like a hand
/// brush, split by tone into four pigments (charcoal, dark ochre, light
/// ochre, bare stone), outlined in charcoal with the finer details drawn,
/// over limestone with grain, pits, stains and torchlight fading at the
/// edges.
///
/// Writes the outlines to red, the paint level to green (1 bare stone, 0.7
/// light ochre, 0.4 dark ochre, 0.1 charcoal, soaked unevenly) and the
/// rock's shade to blue.
void _rupestre(Float32List y, int width, int height, double s, Uint8List out) {
  final n = width * height;
  final t = _localTone(_tone(y), width, height, 50 * s, 0.35);
  final k = math.max((7 * s).round(), 2);
  var painted = kuwahara(t, width, height, k);
  painted = kuwahara(painted, width, height, math.max(k ~/ 2, 2));
  painted = _warp(painted, width, height, 3.5 * s, 18 * s, 40);

  // The rock.
  final n1 = valueNoise(width, height, 200 * s, seed: 3);
  final n2 = valueNoise(width, height, 60 * s, seed: 5, octaves: 2);
  final g1 = valueNoise(width, height, 1.6 * s, seed: 9, octaves: 1);
  final g2 = valueNoise(width, height, 4 * s, seed: 10, octaves: 2);
  final bumps = Float32List(n);
  for (var i = 0; i < n; i++) {
    bumps[i] = n1[i] + 0.2 * n2[i];
  }
  final relief = blur(bumps, width, height, 3 * s);
  final pitSeeds = Float32List(n);
  final rng = math.Random(17);
  final pitChance = 0.0015 / math.pow(math.max(s, 0.5), 2);
  for (var i = 0; i < n; i++) {
    if (rng.nextDouble() < pitChance) pitSeeds[i] = 1;
  }
  final pits = blur(pitSeeds, width, height, 1.3 * s);

  // Pigment levels by tone, with a little noise so borders are uneven.
  final sample = [for (var i = 0; i < n; i += 7) painted[i]]..sort();
  double quantile(double f) =>
      sample[(f * (sample.length - 1)).round().clamp(0, sample.length - 1)];
  final q0 = quantile(0.16), q1 = quantile(0.46), q2 = quantile(0.88);
  final level = Uint8List(n);
  for (var i = 0; i < n; i++) {
    final v = painted[i] + (n2[i] - 0.5) * 0.04;
    level[i] = v < q0
        ? 0
        : v < q1
        ? 1
        : v < q2
        ? 2
        : 3;
  }
  _majority4(level, width, height, math.max((5 * s).round(), 3));
  const plateaus = [0.1, 0.4, 0.7, 1.0];
  final paint = Float32List(n);
  final levels = Float32List(n);
  for (var i = 0; i < n; i++) {
    paint[i] = plateaus[level[i]];
    levels[i] = level[i].toDouble();
  }
  final paintSoft = blur(paint, width, height, 1.0 * s);
  final levelSoft = blur(levels, width, height, 1.8 * s);
  final widthNoise = valueNoise(width, height, 50 * s, seed: 21, octaves: 2);

  // Finer lines from the photo itself: eye, fins, spots.
  final fine = blur(t, width, height, 0.9 * s);
  final coarse = blur(t, width, height, 1.8 * s);
  final detail = Float32List(n);
  for (var i = 0; i < n; i++) {
    detail[i] = _smoothstep(0.025, 0.07, coarse[i] - fine[i]);
  }
  final detailWobbly = _warp(detail, width, height, 1.5 * s, 12 * s, 50);

  final cx = width / 2, cy = height / 2;
  for (var i = 0; i < n; i++) {
    final x = i % width;
    final row = i ~/ width;
    final holes = _smoothstep(0.62, 0.9, g2[i]) * 0.7;
    final level = paintSoft[i];
    final soaked = level < 0.97 ? math.min(level + holes * 0.3, 1.0) : level;
    final gx =
        (levelSoft[row * width + math.min(x + 1, width - 1)] -
            levelSoft[row * width + math.max(x - 1, 0)]) /
        2;
    final gy =
        (levelSoft[math.min(row + 1, height - 1) * width + x] -
            levelSoft[math.max(row - 1, 0) * width + x]) /
        2;
    final edge = math.sqrt(gx * gx + gy * gy) * 2.4 * s;
    final w = widthNoise[i];
    final contour = _smoothstep(
      0.25 - 0.12 * w,
      0.5 - 0.1 * w,
      edge + (g2[i] - 0.5) * 0.3,
    );
    final lines =
        math.max(contour * 0.95, detailWobbly[i] * 0.7) * (1 - holes * 0.45);
    // Rock shade: light from the top left on the bumps, grain, pits,
    // stains and the torch's reach.
    final rx =
        (relief[row * width + math.min(x + 1, width - 1)] -
            relief[row * width + math.max(x - 1, 0)]) /
        2;
    final ry =
        (relief[math.min(row + 1, height - 1) * width + x] -
            relief[math.max(row - 1, 0) * width + x]) /
        2;
    final lit = (-0.6 * rx - 0.8 * ry) * 100 * s;
    final dx = (x - cx) / cx, dy = (row - cy) / cy;
    final reach = math.sqrt(dx * dx + dy * dy) / math.sqrt2;
    final shade =
        (0.16 - lit * 0.4).clamp(0.0, 0.4) * 0.35 +
        ((g1[i] - 0.45) * 0.30 + (g2[i] - 0.45) * 0.22).clamp(0.0, 1.0) +
        _smoothstep(0.02, 0.12, pits[i]) * 0.5 +
        _smoothstep(0.45, 0.95, 1 - n2[i]) * 0.10 +
        _smoothstep(0.55, 0.95, 1 - n1[i]) * 0.08 +
        _smoothstep(0.5, 1.05, reach + (n2[i] - 0.5) * 0.12) * 0.45;
    out[i * 4] = (lines.clamp(0.0, 1.0) * 255).round();
    out[i * 4 + 1] = (soaked.clamp(0.0, 1.0) * 255).round();
    out[i * 4 + 2] = (shade.clamp(0.0, 0.85) * 255).round();
    out[i * 4 + 3] = 255;
  }
}

/// Generalized Kuwahara filter of radius [r]: each pixel takes the mean of
/// the calmest of its four overlapping quadrants. Flat, painted patches
/// with the edges kept. Constant time per pixel (summed-area tables).
Float32List kuwahara(Float32List src, int width, int height, int r) {
  final w1 = width + 1;
  final sum = Float64List(w1 * (height + 1));
  final sq = Float64List(w1 * (height + 1));
  for (var y = 0; y < height; y++) {
    var rowSum = 0.0, rowSq = 0.0;
    for (var x = 0; x < width; x++) {
      final v = src[y * width + x];
      rowSum += v;
      rowSq += v * v;
      sum[(y + 1) * w1 + x + 1] = sum[y * w1 + x + 1] + rowSum;
      sq[(y + 1) * w1 + x + 1] = sq[y * w1 + x + 1] + rowSq;
    }
  }
  final out = Float32List(src.length);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      var bestMean = 0.0;
      var bestVar = double.infinity;
      for (var q = 0; q < 4; q++) {
        final x0 = (q.isEven ? x - r : x).clamp(0, width - 1);
        final y0 = (q < 2 ? y - r : y).clamp(0, height - 1);
        final x1 = (q.isEven ? x : x + r).clamp(0, width - 1) + 1;
        final y1 = (q < 2 ? y : y + r).clamp(0, height - 1) + 1;
        final count = (x1 - x0) * (y1 - y0);
        final s =
            sum[y1 * w1 + x1] -
            sum[y0 * w1 + x1] -
            sum[y1 * w1 + x0] +
            sum[y0 * w1 + x0];
        final s2 =
            sq[y1 * w1 + x1] -
            sq[y0 * w1 + x1] -
            sq[y1 * w1 + x0] +
            sq[y0 * w1 + x0];
        final mean = s / count;
        final variance = s2 / count - mean * mean;
        if (variance < bestVar) {
          bestVar = variance;
          bestMean = mean;
        }
      }
      out[y * width + x] = bestMean;
    }
  }
  return out;
}

/// Each pixel takes the most common of the four levels around it (a
/// [size]-pixel box): tiny islands of paint disappear.
void _majority4(Uint8List level, int width, int height, int size) {
  final r = size ~/ 2;
  final counts = [
    for (var l = 0; l < 4; l++)
      blur(
        Float32List.fromList([for (final v in level) v == l ? 1.0 : 0.0]),
        width,
        height,
        r / 1.5,
      ),
  ];
  for (var i = 0; i < level.length; i++) {
    var best = 0;
    for (var l = 1; l < 4; l++) {
      if (counts[l][i] > counts[best][i]) best = l;
    }
    level[i] = best;
  }
}

/// [src] pushed around by a smooth random field up to [amount] pixels:
/// straight edges wobble like a hand brush.
Float32List _warp(
  Float32List src,
  int width,
  int height,
  double amount,
  double scale,
  int seed,
) {
  final ox = valueNoise(width, height, scale, seed: seed, octaves: 2);
  final oy = valueNoise(width, height, scale, seed: seed + 1, octaves: 2);
  final out = Float32List(src.length);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final i = y * width + x;
      final fx = (x + (ox[i] - 0.5) * 2 * amount).clamp(0.0, width - 1.0);
      final fy = (y + (oy[i] - 0.5) * 2 * amount).clamp(0.0, height - 1.0);
      final x0 = fx.floor(), y0 = fy.floor();
      final x1 = math.min(x0 + 1, width - 1), y1 = math.min(y0 + 1, height - 1);
      final wx = fx - x0, wy = fy - y0;
      final top = src[y0 * width + x0] * (1 - wx) + src[y0 * width + x1] * wx;
      final bottom =
          src[y1 * width + x0] * (1 - wx) + src[y1 * width + x1] * wx;
      out[i] = top + (bottom - top) * wy;
    }
  }
  return out;
}

/// Local contrast: each tone against its neighborhood ([sigma]), mixed
/// with the global tone by [amount]. Detail survives in dark and light
/// areas alike.
Float32List _localTone(
  Float32List t,
  int width,
  int height,
  double sigma,
  double amount,
) {
  final mean = blur(t, width, height, sigma);
  final sq = Float32List(t.length);
  for (var i = 0; i < t.length; i++) {
    sq[i] = t[i] * t[i];
  }
  final meanSq = blur(sq, width, height, sigma);
  final out = Float32List(t.length);
  for (var i = 0; i < t.length; i++) {
    final sd = math.sqrt(math.max(meanSq[i] - mean[i] * mean[i], 1e-4));
    final local = (0.5 + (t[i] - mean[i]) / (4 * sd + 0.05)).clamp(0.0, 1.0);
    out[i] = t[i] * (1 - amount) + local * amount;
  }
  return out;
}

/// Smooth random field in 0–1 with features about [scale] pixels wide:
/// [octaves] layers of value noise, each half the size and weight.
/// Deterministic for a given [seed].
Float32List valueNoise(
  int width,
  int height,
  double scale, {
  required int seed,
  int octaves = 4,
}) {
  final rng = math.Random(seed);
  final out = Float32List(width * height);
  var amp = 1.0;
  for (var o = 0; o < octaves; o++) {
    final cell = scale / (1 << o);
    // Finer than a pixel and a half adds only aliasing.
    if (cell < 1.5) break;
    final gw = (width / cell).ceil() + 2;
    final gh = (height / cell).ceil() + 2;
    final grid = Float32List(gw * gh);
    for (var i = 0; i < grid.length; i++) {
      grid[i] = rng.nextDouble();
    }
    final x0s = Int32List(width);
    final wxs = Float32List(width);
    for (var x = 0; x < width; x++) {
      final fx = x / cell;
      final x0 = fx.floor();
      final tx = fx - x0;
      x0s[x] = x0;
      wxs[x] = tx * tx * (3 - 2 * tx);
    }
    for (var row = 0; row < height; row++) {
      final fy = row / cell;
      final y0 = fy.floor();
      final ty = fy - y0;
      final wy = ty * ty * (3 - 2 * ty);
      final top = y0 * gw;
      final bottom = top + gw;
      final base = row * width;
      for (var x = 0; x < width; x++) {
        final x0 = x0s[x];
        final wx = wxs[x];
        final a = grid[top + x0];
        final t = a + (grid[top + x0 + 1] - a) * wx;
        final c = grid[bottom + x0];
        final b = c + (grid[bottom + x0 + 1] - c) * wx;
        out[base + x] += (t + (b - t) * wy) * amp;
      }
    }
    amp *= 0.5;
  }
  var lo = double.infinity, hi = -double.infinity;
  for (final v in out) {
    lo = math.min(lo, v);
    hi = math.max(hi, v);
  }
  final span = math.max(hi - lo, 1e-6);
  for (var i = 0; i < out.length; i++) {
    out[i] = (out[i] - lo) / span;
  }
  return out;
}

double _smoothstep(double e0, double e1, double x) {
  final t = ((x - e0) / (e1 - e0)).clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}

/// Color matrix (Flutter's 5×4 layout, offsets in 0–255) that tints a
/// one-ink separation: `out = base + red·(ink − base)`.
List<double> filterTint({required int base, required int first}) {
  List<double> row(int shift) {
    final b = (base >> shift) & 0xFF;
    final f = (first >> shift) & 0xFF;
    return [(f - b) / 255, 0, 0, 0, b.toDouble()];
  }

  // Alpha passes through: forcing it opaque would tint everything around
  // the photo too.
  return [...row(16), ...row(8), ...row(0), 0, 0, 0, 1, 0];
}

/// Color matrix that grades a photo toward two colors: half the photo,
/// half its brightness mapped from [shadow] to [light]. Keeps the photo
/// readable while it takes the theme's hues.
List<double> photoGrade({
  required int shadow,
  required int light,
  double amount = 0.5,
}) {
  List<double> row(int shift, int channel) {
    final s = ((shadow >> shift) & 0xFF).toDouble();
    final l = ((light >> shift) & 0xFF).toDouble();
    final k = amount * (l - s) / 255;
    return [
      (channel == 0 ? 1 - amount : 0) + k * 0.299,
      (channel == 1 ? 1 - amount : 0) + k * 0.587,
      (channel == 2 ? 1 - amount : 0) + k * 0.114,
      0,
      amount * s,
    ];
  }

  return [...row(16, 0), ...row(8, 1), ...row(0, 2), 0, 0, 0, 1, 0];
}

/// Color matrix that paints [color] with the separation's [channel] (0 red,
/// 1 green, 2 blue) as its opacity, `scale · channel + offset` (clamped to
/// 0–1): one layer of a multi-ink filter, drawn over the layers below it.
List<double> channelInk({
  required int color,
  required int channel,
  double scale = 1,
  double offset = 0,
}) {
  double c(int shift) => ((color >> shift) & 0xFF).toDouble();
  return [
    0, 0, 0, 0, c(16), //
    0, 0, 0, 0, c(8),
    0, 0, 0, 0, c(0),
    for (var i = 0; i < 3; i++) i == channel ? scale : 0.0, 0, offset * 255,
  ];
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

/// 3×3 median (edges clamped): removes speckle, keeps edges.
Float32List _median3(Float32List src, int width, int height) {
  final out = Float32List(src.length);
  for (var y = 0; y < height; y++) {
    final up = math.max(y - 1, 0) * width;
    final mid = y * width;
    final down = math.min(y + 1, height - 1) * width;
    for (var x = 0; x < width; x++) {
      final l = math.max(x - 1, 0);
      final r = math.min(x + 1, width - 1);
      out[mid + x] = median9(
        src[up + l],
        src[up + x],
        src[up + r],
        src[mid + l],
        src[mid + x],
        src[mid + r],
        src[down + l],
        src[down + x],
        src[down + r],
      );
    }
  }
  return out;
}

/// Median of nine values with a fixed compare-exchange network (no
/// allocation, no sort).
double median9(
  double p0,
  double p1,
  double p2,
  double p3,
  double p4,
  double p5,
  double p6,
  double p7,
  double p8,
) {
  double t;
  if (p1 > p2) {
    t = p1;
    p1 = p2;
    p2 = t;
  }
  if (p4 > p5) {
    t = p4;
    p4 = p5;
    p5 = t;
  }
  if (p7 > p8) {
    t = p7;
    p7 = p8;
    p8 = t;
  }
  if (p0 > p1) {
    t = p0;
    p0 = p1;
    p1 = t;
  }
  if (p3 > p4) {
    t = p3;
    p3 = p4;
    p4 = t;
  }
  if (p6 > p7) {
    t = p6;
    p6 = p7;
    p7 = t;
  }
  if (p1 > p2) {
    t = p1;
    p1 = p2;
    p2 = t;
  }
  if (p4 > p5) {
    t = p4;
    p4 = p5;
    p5 = t;
  }
  if (p7 > p8) {
    t = p7;
    p7 = p8;
    p8 = t;
  }
  // Largest of the minimums, smallest of the maximums, median of medians.
  final lo = math.max(math.max(p0, p3), p6);
  final hi = math.min(math.min(p2, p5), p8);
  if (p4 > p7) {
    t = p4;
    p4 = p7;
    p7 = t;
  }
  final m = math.min(math.max(p1, p4), p7);
  // Median of (lo, m, hi).
  return math.max(math.min(lo, m), math.min(math.max(lo, m), hi));
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
  final inv = 1 / (2 * r + 1);
  if (horizontal) {
    for (var row = 0; row < height; row++) {
      final start = row * width;
      double at(int k) => src[start + k.clamp(0, width - 1)];
      var acc = 0.0;
      for (var k = -r; k <= r; k++) {
        acc += at(k);
      }
      for (var k = 0; k < width; k++) {
        dst[start + k] = acc * inv;
        final add = k + r + 1;
        final drop = k - r;
        acc +=
            (add < width ? src[start + add] : src[start + width - 1]) -
            (drop >= 0 ? src[start + drop] : src[start]);
      }
    }
    return;
  }
  // Vertical: sweep rows with one running sum per column (row-major
  // memory access, much faster than walking each column).
  final acc = Float64List(width);
  for (var k = -r; k <= r; k++) {
    final row = k.clamp(0, height - 1) * width;
    for (var x = 0; x < width; x++) {
      acc[x] += src[row + x];
    }
  }
  for (var y = 0; y < height; y++) {
    final out = y * width;
    final add = math.min(y + r + 1, height - 1) * width;
    final drop = math.max(y - r, 0) * width;
    for (var x = 0; x < width; x++) {
      dst[out + x] = acc[x] * inv;
      acc[x] += src[add + x] - src[drop + x];
    }
  }
}
