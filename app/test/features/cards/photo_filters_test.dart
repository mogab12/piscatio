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

  test('ink draws a line along an edge and leaves flat areas even', () {
    final out = applyPhotoFilter(CardPhotoFilter.ink, edge, w, h);
    final atEdge = [for (var x = 76; x < 84; x++) red(out, w, x, 60)];
    final farLight = red(out, w, 150, 60);
    expect(atEdge.reduce((a, b) => a > b ? a : b), greaterThan(farLight + 100));
    final flat = image(w, h, (_, _) => 128);
    final plain = applyPhotoFilter(CardPhotoFilter.ink, flat, w, h);
    final values = {for (var i = 0; i < plain.length; i += 4) plain[i]};
    expect(values, hasLength(1));
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

  test('screen print: the dark ink only prints over the second one', () {
    final out = applyPhotoFilter(CardPhotoFilter.screenprint, gradient, w, h);
    for (var i = 0; i < out.length; i += 4) {
      expect(out[i + 1], greaterThanOrEqualTo(out[i]));
    }
    // Shadows get both inks, highlights neither.
    expect(red(out, w, 2, 60), 255);
    expect(green(out, w, w - 3, 60), 0);
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

    test('two inks: second where only green, first where both', () {
      final m = filterTint(
        base: 0xFFFFFFFF,
        first: 0xFF0B2A33,
        second: 0xFFE4262C,
      );
      expect(apply(m, 0, 255, 0).map((v) => v.round()), [0xE4, 0x26, 0x2C]);
      expect(apply(m, 255, 255, 0).map((v) => v.round()), [0x0B, 0x2A, 0x33]);
      // Alpha is kept, so nothing around the photo gets tinted.
      expect(m.sublist(15), [0, 0, 0, 1, 0]);
    });
  });
}
