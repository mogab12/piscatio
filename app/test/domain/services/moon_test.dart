import 'package:flutter_test/flutter_test.dart';
import 'package:piscatio/domain/services/moon.dart';

void main() {
  // Published phase instants (UTC), from USNO/NASA tables.
  final cases = <(String, DateTime, double, MoonPhase)>[
    ('new moon', DateTime.utc(2000, 1, 6, 18, 14), 0, MoonPhase.newMoon),
    ('full moon', DateTime.utc(2022, 11, 8, 11, 2), 180, MoonPhase.fullMoon),
    ('new moon', DateTime.utc(2024, 1, 11, 11, 57), 0, MoonPhase.newMoon),
    (
      'first quarter',
      DateTime.utc(2024, 1, 18, 3, 53),
      90,
      MoonPhase.firstQuarter,
    ),
    ('full moon', DateTime.utc(2024, 1, 25, 17, 54), 180, MoonPhase.fullMoon),
    (
      'last quarter',
      DateTime.utc(2024, 2, 2, 23, 18),
      270,
      MoonPhase.lastQuarter,
    ),
    ('new moon', DateTime.utc(2024, 4, 8, 18, 21), 0, MoonPhase.newMoon),
  ];

  for (final (name, instant, expected, phase) in cases) {
    test('$name at $instant', () {
      final moon = moonAt(instant);
      final diff = ((moon.elongation - expected + 540) % 360) - 180;
      expect(
        diff.abs(),
        lessThan(2.0),
        reason: 'elongation ${moon.elongation}',
      );
      expect(moon.phase, phase);
    });
  }

  test('illumination is ~0 at new moon, ~1 at full, ~0.5 at quarters', () {
    expect(
      moonAt(DateTime.utc(2024, 1, 11, 11, 57)).illumination,
      lessThan(0.01),
    );
    expect(
      moonAt(DateTime.utc(2024, 1, 25, 17, 54)).illumination,
      greaterThan(0.99),
    );
    expect(
      moonAt(DateTime.utc(2024, 1, 18, 3, 53)).illumination,
      closeTo(0.5, 0.03),
    );
  });

  test('waxing between new and full, waning after', () {
    expect(moonAt(DateTime.utc(2024, 1, 15)).isWaxing, isTrue);
    expect(moonAt(DateTime.utc(2024, 1, 15)).phase, MoonPhase.waxingCrescent);
    expect(moonAt(DateTime.utc(2024, 1, 29)).isWaxing, isFalse);
    expect(moonAt(DateTime.utc(2024, 1, 29)).phase, MoonPhase.waningGibbous);
  });

  test('local time and UTC of the same instant give the same result', () {
    final utc = DateTime.utc(2024, 1, 25, 17, 54);
    expect(moonAt(utc.toLocal()).elongation, moonAt(utc).elongation);
  });

  test('age grows monotonically from new moon to the next one', () {
    // The true Moon speeds up and slows down (perigee/apogee), so age derived
    // from elongation is not linear in time; it must still only grow.
    var previous = -1.0;
    for (var h = 1; h < 29 * 24; h += 6) {
      final instant = DateTime.utc(2024, 1, 11, 12).add(Duration(hours: h));
      final age = moonAt(instant).ageDays;
      expect(age, greaterThan(previous), reason: '$instant');
      expect(age, lessThan(MoonInfo.synodicMonthDays));
      previous = age;
    }
  });

  test('phaseForElongation boundaries', () {
    expect(phaseForElongation(0), MoonPhase.newMoon);
    expect(phaseForElongation(359), MoonPhase.newMoon);
    expect(phaseForElongation(22.4), MoonPhase.newMoon);
    expect(phaseForElongation(22.6), MoonPhase.waxingCrescent);
    expect(phaseForElongation(200), MoonPhase.fullMoon);
    expect(phaseForElongation(300), MoonPhase.waningCrescent);
  });
}
