import 'dart:math' as math;

import 'units.dart';

enum RulerUnit { centimeter, inch, kilogram, pound, hour }

/// A measuring-board scale: from 0 to [max], ticks every [minor], numbers
/// every [major], a notch at [value] and (for a record) a mark at
/// [previous]. All in the display unit.
class RulerScale {
  const RulerScale({
    required this.unit,
    required this.max,
    required this.major,
    required this.minor,
    required this.value,
    this.previous,
  });

  final RulerUnit unit;
  final double max;
  final double major;
  final double minor;
  final double value;
  final double? previous;

  double fraction(double v) => (v / max).clamp(0.0, 1.0);
}

double _roundUp(double v, double step) => (v / step).ceil() * step;

/// Fish length: the board ends a little past the fish, like a real board
/// ends past the tail.
RulerScale lengthScale(int millimeters, UnitSystem units, {int? previousMm}) {
  if (units == UnitSystem.imperial) {
    final v = Units.inchesFromMillimeters(millimeters);
    final max = math.max(10.0, _roundUp(v + 2, 5));
    return RulerScale(
      unit: RulerUnit.inch,
      max: max,
      major: max > 40 ? 5 : 1,
      minor: max > 40 ? 1 : 0.5,
      value: v,
      previous: previousMm == null
          ? null
          : Units.inchesFromMillimeters(previousMm),
    );
  }
  final v = millimeters / 10;
  final max = math.max(20.0, _roundUp(v + 5, 10));
  return RulerScale(
    unit: RulerUnit.centimeter,
    max: max,
    major: max > 120 ? 20 : 10,
    minor: max > 120 ? 5 : 1,
    value: v,
    previous: previousMm == null ? null : previousMm / 10,
  );
}

/// Weight on a scale when there is no length.
RulerScale weightScale(int grams, UnitSystem units, {int? previousGrams}) {
  if (units == UnitSystem.imperial) {
    final v = grams / Units.gramsPerPound;
    final max = math.max(2.0, _roundUp(v * 1.15, v > 20 ? 10 : 2));
    return RulerScale(
      unit: RulerUnit.pound,
      max: max,
      major: max > 20 ? 5 : 1,
      minor: max > 20 ? 1 : 0.25,
      value: v,
      previous: previousGrams == null
          ? null
          : previousGrams / Units.gramsPerPound,
    );
  }
  final v = grams / 1000;
  final max = math.max(1.0, _roundUp(v * 1.15, v > 10 ? 5 : 1));
  return RulerScale(
    unit: RulerUnit.kilogram,
    max: max,
    major: max > 10 ? 5 : 1,
    minor: max > 10 ? 1 : 0.1,
    value: v,
    previous: previousGrams == null ? null : previousGrams / 1000,
  );
}

/// Nothing measured: the board marks the time of day it was caught.
RulerScale dayScale(DateTime local) => RulerScale(
  unit: RulerUnit.hour,
  max: 24,
  major: 6,
  minor: 1,
  value: local.hour + local.minute / 60,
);
