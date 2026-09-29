import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piscatio/features/cards/application/card_data.dart';
import 'package:piscatio/features/cards/application/photo_filters.dart';
import 'package:piscatio/features/cards/presentation/card_theme.dart';

void main() {
  test('natural colors are the same on every theme', () {
    for (final f in CardPhotoFilter.values) {
      final a = photoPaint(CardPalette.redHead, f, false);
      final b = photoPaint(CardPalette.tucunare, f, false);
      expect(a.tint, b.tint, reason: f.name);
      expect(a.base, b.base, reason: f.name);
      expect(a.layers, b.layers, reason: f.name);
    }
    // The plain photo stays untouched.
    expect(
      photoPaint(CardPalette.moon, CardPhotoFilter.none, false).tint,
      isNull,
    );
  });

  test('theme colors change with the theme', () {
    for (final f in CardPhotoFilter.values) {
      final a = photoPaint(CardPalette.redHead, f, true);
      final b = photoPaint(CardPalette.tucunare, f, true);
      final differs =
          a.tint != b.tint || a.base != b.base || a.layers != b.layers;
      expect(differs, isTrue, reason: f.name);
    }
  });

  test('a themed print stays a positive on dark themes', () {
    for (final p in CardPalette.values) {
      final (:light, :dark) = themeInks(p);
      expect(
        light.computeLuminance(),
        greaterThan(dark.computeLuminance()),
        reason: p.name,
      );
    }
  });

  test('duotone in theme colors is three tones', () {
    final paint = photoPaint(CardPalette.paper, CardPhotoFilter.duotone, true);
    expect(paint.base, CardPalette.paper.shadow);
    expect(paint.layers, hasLength(2));
  });

  test('the cave painting uses the theme materials only when asked', () {
    final natural = rupestreInks(CardPalette.moon, themed: false);
    final themed = rupestreInks(CardPalette.moon, themed: true);
    expect(natural.stone, NaturalInks.stone);
    expect(themed.stone, isNot(NaturalInks.stone));
    expect(themed.charcoal, CardPalette.moon.typed);
    final paint = photoPaint(CardPalette.moon, CardPhotoFilter.rupestre, true);
    expect(paint.base, themed.stone);
    // Three pigments, the outlines and the rock's shade.
    expect(paint.layers, hasLength(5));
    expect(paint.layers.first, isA<ColorFilter>());
  });
}
