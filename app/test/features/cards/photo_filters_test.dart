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

    test('paints what differs from the borders, not the background', () {
      final out = applyPhotoFilter(CardPhotoFilter.rupestre, fish, w, h);
      // Ochre inside the figure, bare stone far outside.
      expect(green(out, w, cx.round(), cy.round()), greaterThan(60));
      expect(green(out, w, 12, 12), lessThan(10));
      // A charcoal outline runs around the figure.
      final across = [for (var x = 20; x < 40; x++) red(out, w, x, 60)];
      expect(across.reduce((a, b) => a > b ? a : b), greaterThan(150));
      expect(red(out, w, cx.round(), cy.round()), lessThan(60));
    });

    test('the stone has relief, and it is the same every time', () {
      final a = applyPhotoFilter(CardPhotoFilter.rupestre, fish, w, h);
      final b = applyPhotoFilter(CardPhotoFilter.rupestre, fish, w, h);
      expect(a, b);
      final relief = {for (var i = 2; i < a.length; i += 4) a[i]};
      expect(relief.length, greaterThan(20));
    });

    test('nothing is drawn right at the edges', () {
      final out = applyPhotoFilter(CardPhotoFilter.rupestre, fish, w, h);
      for (var x = 0; x < w; x++) {
        expect(red(out, w, x, 0), 0);
        expect(red(out, w, x, h - 1), 0);
      }
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
    final m = channelInk(color: 0xFFE4262C, channel: 1);
    List<double> apply(int r, int g, int b) => [
      for (var row = 0; row < 4; row++)
        m[row * 5] * r +
            m[row * 5 + 1] * g +
            m[row * 5 + 2] * b +
            m[row * 5 + 3] * 255 +
            m[row * 5 + 4],
    ];
    expect(apply(200, 80, 10), [0xE4, 0x26, 0x2C, 80]);
    expect(apply(0, 255, 0), [0xE4, 0x26, 0x2C, 255]);
  });
}
