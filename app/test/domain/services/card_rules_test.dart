import 'package:flutter_test/flutter_test.dart';
import 'package:piscatio/domain/models/enums.dart';
import 'package:piscatio/domain/services/card_privacy.dart';
import 'package:piscatio/domain/services/roman_date.dart';
import 'package:piscatio/domain/services/ruler_scale.dart';
import 'package:piscatio/domain/services/units.dart';

void main() {
  group('cardPlace', () {
    const name = 'Pesqueiro do Zé';
    const region = 'Cuiabá, MT';

    test('private and friends never show a place to everyone', () {
      for (final level in [PrivacyLevel.private, PrivacyLevel.friends]) {
        expect(cardPlace(level, name: name, region: region), isNull);
      }
    });

    test('friends shows the region, never the name, only to friends', () {
      expect(
        cardPlace(
          PrivacyLevel.friends,
          name: name,
          region: region,
          audience: CardAudience.friends,
        ),
        region,
      );
      expect(
        cardPlace(
          PrivacyLevel.private,
          name: name,
          region: region,
          audience: CardAudience.friends,
        ),
        isNull,
      );
      expect(
        cardPlace(
          PrivacyLevel.exact,
          name: name,
          region: region,
          audience: CardAudience.friends,
        ),
        name,
      );
    });

    test('approximate shows only the region, never the name', () {
      expect(
        cardPlace(PrivacyLevel.approximate, name: name, region: region),
        region,
      );
      expect(cardPlace(PrivacyLevel.approximate, name: name), isNull);
    });

    test('exact shows the name, falling back to the region', () {
      expect(cardPlace(PrivacyLevel.exact, name: name, region: region), name);
      expect(cardPlace(PrivacyLevel.exact, name: ' ', region: region), region);
      expect(cardPlace(PrivacyLevel.exact), isNull);
    });
  });

  group('lengthScale', () {
    test('metric board ends a bit past the fish, numbers every 10 cm', () {
      final s = lengthScale(525, UnitSystem.metric, previousMm: 460);
      expect(s.unit, RulerUnit.centimeter);
      expect(s.max, 60);
      expect(s.major, 10);
      expect(s.minor, 1);
      expect(s.value, 52.5);
      expect(s.previous, 46);
      expect(s.fraction(30), 0.5);
    });

    test('big fish use a coarser scale', () {
      final s = lengthScale(1350, UnitSystem.metric);
      expect(s.max, 140);
      expect(s.major, 20);
    });

    test('small fish get at least a 20 cm board', () {
      expect(lengthScale(90, UnitSystem.metric).max, 20);
    });

    test('imperial board in inches', () {
      final s = lengthScale(521, UnitSystem.imperial);
      expect(s.unit, RulerUnit.inch);
      expect(s.max, 25);
      expect(s.value, closeTo(20.5, 0.02));
    });
  });

  test('weight and day scales', () {
    final kg = weightScale(2350, UnitSystem.metric, previousGrams: 2000);
    expect(kg.unit, RulerUnit.kilogram);
    expect(kg.max, 3);
    expect(kg.previous, 2);
    final lb = weightScale(2353, UnitSystem.imperial);
    expect(lb.unit, RulerUnit.pound);
    expect(lb.max, 6);
    final day = dayScale(DateTime(2026, 9, 12, 6, 30));
    expect(day.max, 24);
    expect(day.value, 6.5);
  });

  test('romanDate uses Roman months like collection labels', () {
    expect(romanDate(DateTime(2026, 9, 12)), '12.IX.2026');
    expect(romanDate(DateTime(2026, 1, 3)), '3.I.2026');
    expect(romanDate(DateTime(2025, 12, 31)), '31.XII.2025');
  });
}
