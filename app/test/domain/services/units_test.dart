import 'package:flutter_test/flutter_test.dart';
import 'package:piscatio/domain/services/units.dart';

void main() {
  group('defaultUnitSystemFor', () {
    test('US, Liberia and Myanmar are imperial', () {
      for (final c in ['US', 'us', 'LR', 'MM']) {
        expect(defaultUnitSystemFor(c), UnitSystem.imperial, reason: c);
      }
    });

    test('everything else, including unknown, is metric', () {
      for (final c in ['BR', 'AR', 'GB', 'CA', 'ES', null, '']) {
        expect(defaultUnitSystemFor(c), UnitSystem.metric, reason: '$c');
      }
    });
  });

  group('input conversion to SI', () {
    test('weight', () {
      expect(Units.gramsFromKilograms(2.35), 2350);
      expect(Units.gramsFromPounds(1), 454);
      expect(Units.gramsFromPounds(5, 3), 2353);
      expect(Units.gramsFromPounds(0, 12), 340);
    });

    test('length and depth', () {
      expect(Units.millimetersFromCentimeters(52.5), 525);
      expect(Units.millimetersFromInches(20.5), 521);
      expect(Units.millimetersFromMeters(3.2), 3200);
      expect(Units.millimetersFromFeet(10), 3048);
    });

    test('weather', () {
      expect(Units.fahrenheitFromCelsius(0), 32);
      expect(Units.fahrenheitFromCelsius(100), 212);
      expect(Units.fahrenheitFromCelsius(-40), -40);
      expect(Units.inHgFromHpa(1013.25), closeTo(29.92, 0.005));
      expect(Units.mphFromKmh(100), closeTo(62.137, 0.001));
    });
  });

  group('weightParts', () {
    test('metric uses grams below 1 kg and kilograms above', () {
      expect(weightParts(850, UnitSystem.metric), [
        const Quantity(850, DisplayUnit.gram),
      ]);
      expect(weightParts(2350, UnitSystem.metric), [
        const Quantity(2.35, DisplayUnit.kilogram, maxFractionDigits: 2),
      ]);
    });

    test('imperial splits pounds and ounces', () {
      expect(weightParts(2353, UnitSystem.imperial), [
        const Quantity(5, DisplayUnit.pound),
        const Quantity(3, DisplayUnit.ounce),
      ]);
      expect(weightParts(340, UnitSystem.imperial), [
        const Quantity(12, DisplayUnit.ounce),
      ]);
      expect(weightParts(Units.gramsFromPounds(4), UnitSystem.imperial), [
        const Quantity(4, DisplayUnit.pound),
      ]);
    });

    test('rounding up to 16 oz carries into a pound', () {
      // 15.9 oz rounds to 16 oz = 1 lb 0 oz.
      expect(weightParts(451, UnitSystem.imperial), [
        const Quantity(1, DisplayUnit.pound),
      ]);
    });
  });

  test('imperial input survives a round trip through SI storage', () {
    for (var tenths = 10; tenths <= 600; tenths++) {
      final inches = tenths / 10;
      final stored = Units.millimetersFromInches(inches);
      final shown = lengthQuantity(stored, UnitSystem.imperial).value;
      expect(shown, closeTo(inches, 0.05), reason: '$inches in');
    }
  });

  test('length, depth and weather quantities', () {
    expect(
      lengthQuantity(525, UnitSystem.metric),
      const Quantity(52.5, DisplayUnit.centimeter, maxFractionDigits: 1),
    );
    expect(lengthQuantity(254, UnitSystem.imperial).value, 10);
    expect(depthQuantity(3048, UnitSystem.imperial).value, closeTo(10, 1e-9));
    expect(depthQuantity(3200, UnitSystem.metric).unit, DisplayUnit.meter);
    expect(temperatureQuantity(25, UnitSystem.imperial).value, 77);
    expect(
      pressureQuantity(1013.25, UnitSystem.imperial).unit,
      DisplayUnit.inchOfMercury,
    );
    expect(windSpeedQuantity(16.09344, UnitSystem.imperial).value, 10);
    expect(precipitationQuantity(25.4, UnitSystem.imperial).value, 1);
    expect(precipitationQuantity(2, UnitSystem.metric).value, 2);
  });
}
