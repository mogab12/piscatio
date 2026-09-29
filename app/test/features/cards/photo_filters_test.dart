import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:piscatio/features/cards/application/photo_filters.dart';

/// Grey pixels from a function of (x, y) returning 0–255.
Uint8List image(int w, int h, int Function(int x, int y) grey) {
  final rgba = Uint8List(w * h * 4);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final i = (y * w + x) * 4;
      final v = grey(x, y);
      rgba
        ..[i] = v
        ..[i + 1] = v
        ..[i + 2] = v
        ..[i + 3] = 255;
    }
  }
  return rgba;
}

int red(Uint8List out, int w, int x, int y) => out[(y * w + x) * 4];
int green(Uint8List out, int w, int x, int y) => out[(y * w + x) * 4 + 1];

double meanRed(Uint8List out, int w, int x0, int x1, int h) {
  var sum = 0;
  for (var y = 0; y < h; y++) {
    for (var x = x0; x < x1; x++) {
      sum += red(out, w, x, y);
    }
  }
  return sum / ((x1 - x0) * h);
}

void main() {
  const w = 160;
  const h = 120;
  final gradient = image(w, h, (x, _) => (x * 255 / (w - 1)).round());
  final edge = image(w, h, (x, _) => x < w / 2 ? 40 : 220);

  test('every filter keeps the size and is opaque', () {
    for (final f in CardPhotoFilter.values) {
      final out = applyPhotoFilter(f, gradient, w, h);
      expect(out.length, w * h * 4, reason: f.name);
      expect(out[3], 255, reason: f.name);
    }
  });

  test('duotone follows the light: darker left, lighter right', () {
    final out = applyPhotoFilter(CardPhotoFilter.duotone, gradient, w, h);
    expect(red(out, w, 5, 60), lessThan(red(out, w, 80, 60)));
    expect(red(out, w, 80, 60), lessThan(red(out, w, 154, 60)));
  });

  test('engraving draws a line along an edge', () {
    final out = applyPhotoFilter(CardPhotoFilter.engraving, edge, w, h);
    // Across the edge, on its dark side, the ink is solid for a moment.
    final column = [for (var x = 70; x < 80; x++) red(out, w, x, 60)];
    expect(column.reduce((a, b) => a > b ? a : b), greaterThan(230));
  });

  test('halftone and engraving put more ink in the shadows', () {
    for (final f in [CardPhotoFilter.halftone, CardPhotoFilter.engraving]) {
      final out = applyPhotoFilter(f, gradient, w, h);
      expect(
        meanRed(out, w, 0, 40, h),
        greaterThan(meanRed(out, w, 120, 160, h) + 60),
        reason: f.name,
      );
    }
  });

  group('rupestre', () {
    // A bright fish-shaped blob on a dark, even background.
    const cx = w / 2, cy = h / 2;
    final fish = image(w, h, (x, y) {
      final dx = (x - cx) / 48, dy = (y - cy) / 22;
      return dx * dx + dy * dy < 1 ? 215 : 35;
    });

    test('darker parts get darker pigment, with an outline between', () {
      final out = applyPhotoFilter(CardPhotoFilter.rupestre, fish, w, h);
      // Paint level (green): high on the bright fish, low on the dark.
      expect(green(out, w, cx.round(), cy.round()), greaterThan(170));
      expect(green(out, w, 12, 60), lessThan(120));
      // An outline (red) runs around the fish, not through its middle.
      final across = [for (var x = 20; x < 40; x++) red(out, w, x, 60)];
      expect(across.reduce((a, b) => a > b ? a : b), greaterThan(150));
      expect(red(out, w, cx.round(), cy.round()), lessThan(60));
    });

    test('the rock has relief, and it is the same every time', () {
      final a = applyPhotoFilter(CardPhotoFilter.rupestre, fish, w, h);
      final b = applyPhotoFilter(CardPhotoFilter.rupestre, fish, w, h);
      expect(a, b);
      final shade = {for (var i = 2; i < a.length; i += 4) a[i]};
      expect(shade.length, greaterThan(20));
      // Torchlight: the corners are darker than the middle.
      int blue(int x, int y) => a[(y * w + x) * 4 + 2];
      expect(blue(1, 1), greaterThan(blue(cx.round(), cy.round())));
    });
  });

  group('kuwahara', () {
    test('keeps flat areas flat and edges sharp', () {
      final step = Float32List.fromList([
        for (var y = 0; y < 20; y++)
          for (var x = 0; x < 20; x++) x < 10 ? 0.2 : 0.8,
      ]);
      final out = kuwahara(step, 20, 20, 3);
      expect(out[5 * 20 + 2], closeTo(0.2, 1e-6));
      expect(out[5 * 20 + 17], closeTo(0.8, 1e-6));
      // Right next to the edge each side keeps its own value.
      expect(out[5 * 20 + 9], closeTo(0.2, 1e-6));
      expect(out[5 * 20 + 10], closeTo(0.8, 1e-6));
    });
  });

  test('median9 is the middle of nine values', () {
    final rng = Random(4);
    for (var n = 0; n < 2000; n++) {
      final v = [for (var i = 0; i < 9; i++) rng.nextInt(6).toDouble()];
      final sorted = [...v]..sort();
      expect(
        median9(v[0], v[1], v[2], v[3], v[4], v[5], v[6], v[7], v[8]),
        sorted[4],
        reason: '$v',
      );
    }
  });

  group('filterTint', () {
    // Applies a Flutter color matrix to one RGB pixel (offsets in 0–255).
    List<double> apply(List<double> m, int r, int g, int b) => [
      for (var row = 0; row < 3; row++)
        m[row * 5] * r +
            m[row * 5 + 1] * g +
            m[row * 5 + 2] * b +
            m[row * 5 + 3] * 255 +
            m[row * 5 + 4],
    ];

    test('one ink: no ink is the base, full ink is the ink', () {
      final m = filterTint(base: 0xFFF7F9F8, first: 0xFF0B2A33);
      expect(apply(m, 0, 0, 0), [0xF7, 0xF9, 0xF8]);
      final full = apply(m, 255, 0, 0);
      expect(full.map((v) => v.round()), [0x0B, 0x2A, 0x33]);
    });

    test('alpha passes through', () {
      final m = filterTint(base: 0xFFFFFFFF, first: 0xFF0B2A33);
      // Nothing around the photo gets tinted.
      expect(m.sublist(15), [0, 0, 0, 1, 0]);
    });
  });

  test('channelInk paints one color with one channel as its opacity', () {
    List<double> apply(List<double> m, int r, int g, int b) => [
      for (var row = 0; row < 4; row++)
        (m[row * 5] * r +
                m[row * 5 + 1] * g +
                m[row * 5 + 2] * b +
                m[row * 5 + 3] * 255 +
                m[row * 5 + 4])
            .clamp(0, 255)
            .toDouble(),
    ];
    final m = channelInk(color: 0xFFE4262C, channel: 1);
    expect(apply(m, 200, 80, 10), [0xE4, 0x26, 0x2C, 80]);
    // A ramp: fully opaque below the level, clear above it.
    final ramp = channelInk(
      color: 0xFF000000,
      channel: 1,
      scale: -1 / 0.3,
      offset: 0.7 / 0.3,
    );
    expect(apply(ramp, 0, (0.4 * 255).round(), 0)[3], 255);
    expect(apply(ramp, 0, (0.7 * 255).round(), 0)[3], closeTo(0, 1));
    expect(apply(ramp, 0, (0.55 * 255).round(), 0)[3], closeTo(127.5, 1));
  });

  test('photoGrade keeps half the photo and maps its light', () {
    final m = photoGrade(shadow: 0xFF000000, light: 0xFFFFFFFF, amount: 0);
    // No grading: the identity.
    expect(m.sublist(0, 5), [1, 0, 0, 0, 0]);
    final g = photoGrade(shadow: 0xFF102030, light: 0xFFF0E0D0);
    // Black goes halfway to the shadow color.
    expect(g[4], closeTo(0x10 / 2, 1e-9));
    expect(g[9], closeTo(0x20 / 2, 1e-9));
    // White comes out between white and the light color.
    final r = (g[0] + g[1] + g[2]) * 255 + g[4];
    expect(r, closeTo((255 + 0xF0) / 2, 1e-6));
  });
}
