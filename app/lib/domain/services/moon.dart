import 'dart:math' as math;

/// Moon phase computed locally (no network), following the low-precision
/// method in Jean Meeus, *Astronomical Algorithms*, ch. 47–48. Accurate to
/// well under a degree of elongation, i.e. within an hour or two of the
/// published phase instants.
enum MoonPhase {
  newMoon,
  waxingCrescent,
  firstQuarter,
  waxingGibbous,
  fullMoon,
  waningGibbous,
  lastQuarter,
  waningCrescent,
}

class MoonInfo {
  const MoonInfo({
    required this.elongation,
    required this.illumination,
    required this.phase,
  });

  /// Sun–Moon elongation in degrees, 0–360 (0 new, 90 first quarter,
  /// 180 full, 270 last quarter).
  final double elongation;

  /// Illuminated fraction of the disc, 0–1.
  final double illumination;

  final MoonPhase phase;

  static const synodicMonthDays = 29.530588853;

  /// Days since the last new moon.
  double get ageDays => elongation / 360 * synodicMonthDays;

  bool get isWaxing => elongation < 180;
}

MoonInfo moonAt(DateTime instant) {
  final jd = instant.toUtc().millisecondsSinceEpoch / 86400000 + 2440587.5;
  final t = (jd - 2451545.0) / 36525;
  final t2 = t * t;
  final t3 = t2 * t;
  final t4 = t3 * t;

  // Mean elongation, Sun's and Moon's mean anomalies (degrees).
  final d =
      297.8501921 +
      445267.1114034 * t -
      0.0018819 * t2 +
      t3 / 545868 -
      t4 / 113065000;
  final m = 357.5291092 + 35999.0502909 * t - 0.0001536 * t2 + t3 / 24490000;
  final mp =
      134.9633964 +
      477198.8675055 * t +
      0.0087414 * t2 +
      t3 / 69699 -
      t4 / 14712000;

  // Phase angle (Meeus 48.4).
  final i =
      180 -
      d -
      6.289 * _sin(mp) +
      2.100 * _sin(m) -
      1.274 * _sin(2 * d - mp) -
      0.658 * _sin(2 * d) -
      0.214 * _sin(2 * mp) -
      0.110 * _sin(d);

  final elongation = _normalize(180 - i);
  final illumination = (1 - math.cos(elongation * math.pi / 180)) / 2;
  return MoonInfo(
    elongation: elongation,
    illumination: illumination,
    phase: phaseForElongation(elongation),
  );
}

/// Eight named phases, each centered on its principal instant (±22.5°,
/// roughly ±1.8 days).
MoonPhase phaseForElongation(double elongation) {
  final index = ((_normalize(elongation) + 22.5) ~/ 45) % 8;
  return MoonPhase.values[index];
}

double _sin(double degrees) => math.sin(degrees * math.pi / 180);

double _normalize(double degrees) {
  final r = degrees % 360;
  return r < 0 ? r + 360 : r;
}
