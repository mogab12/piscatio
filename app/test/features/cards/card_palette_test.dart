import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:piscatio/features/cards/application/card_data.dart';

double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

double contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  for (final p in CardPalette.values) {
    group(p.name, () {
      test('text reads on the ground (AA)', () {
        expect(contrast(p.text, p.ground), greaterThanOrEqualTo(7));
        expect(contrast(p.muted, p.ground), greaterThanOrEqualTo(4.5));
      });

      test('accent and record stand out (large text, AA)', () {
        expect(contrast(p.accent, p.ground), greaterThanOrEqualTo(3));
        expect(contrast(p.record, p.ground), greaterThanOrEqualTo(4.5));
      });

      test('ink reads on the board and on the tag', () {
        expect(contrast(p.boardInk, p.board), greaterThanOrEqualTo(7));
        expect(contrast(p.typed, p.stock), greaterThanOrEqualTo(7));
        expect(contrast(p.accentInk, p.stock), greaterThanOrEqualTo(3));
      });

      test('dark flag matches the ground', () {
        expect(_luminance(p.ground) < _luminance(p.text), p.dark);
      });
    });
  }
}
