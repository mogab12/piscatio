import 'package:intl/intl.dart';

import '../../domain/models/enums.dart';
import '../../domain/services/moon.dart';
import '../../domain/services/units.dart';
import '../../domain/services/weather_summary.dart';
import '../../l10n/generated/app_localizations.dart';

/// Turns SI values into localized text: numbers by `intl` in the active
/// locale, unit symbols from the ARB files.
class Formatters {
  Formatters(this.l10n, this.units) : _locale = l10n.localeName;

  final AppLocalizations l10n;
  final UnitSystem units;
  final String _locale;

  static const _nbsp = ' ';

  String number(double value, {int maxFractionDigits = 0}) {
    final f = NumberFormat.decimalPattern(_locale)
      ..minimumFractionDigits = 0
      ..maximumFractionDigits = maxFractionDigits;
    return f.format(value);
  }

  /// Gain as a signed percentage in the active locale: "+14%".
  String percentGain(double fraction) {
    final f = NumberFormat.percentPattern(_locale)..maximumFractionDigits = 0;
    return '+${f.format(fraction)}';
  }

  /// Number part of a quantity, without the unit.
  String quantityValue(Quantity q) =>
      number(q.value, maxFractionDigits: q.maxFractionDigits);

  String unitSymbol(DisplayUnit unit) => switch (unit) {
    DisplayUnit.gram => l10n.unitGram,
    DisplayUnit.kilogram => l10n.unitKilogram,
    DisplayUnit.ounce => l10n.unitOunce,
    DisplayUnit.pound => l10n.unitPound,
    DisplayUnit.centimeter => l10n.unitCentimeter,
    DisplayUnit.inch => l10n.unitInch,
    DisplayUnit.meter => l10n.unitMeter,
    DisplayUnit.foot => l10n.unitFoot,
    DisplayUnit.celsius => l10n.unitCelsius,
    DisplayUnit.fahrenheit => l10n.unitFahrenheit,
    DisplayUnit.hectopascal => l10n.unitHectopascal,
    DisplayUnit.inchOfMercury => l10n.unitInchOfMercury,
    DisplayUnit.kilometerPerHour => l10n.unitKilometerPerHour,
    DisplayUnit.milePerHour => l10n.unitMilePerHour,
    DisplayUnit.millimeter => l10n.unitMillimeter,
  };

  String quantity(Quantity q) =>
      '${quantityValue(q)}$_nbsp${unitSymbol(q.unit)}';

  String weight(int grams) => weightParts(grams, units).map(quantity).join(' ');

  String length(int millimeters) =>
      quantity(lengthQuantity(millimeters, units));

  String depth(int millimeters) => quantity(depthQuantity(millimeters, units));

  String temperature(double celsius) =>
      quantity(temperatureQuantity(celsius, units));

  String pressure(double hpa) => quantity(pressureQuantity(hpa, units));

  String windSpeed(double kmh) => quantity(windSpeedQuantity(kmh, units));

  /// A distance on the map: "12,3 km" or "7,6 mi".
  String distanceKm(double km) => units == UnitSystem.imperial
      ? '${number(km / 1.609344, maxFractionDigits: 1)} ${l10n.unitMile}'
      : '${number(km, maxFractionDigits: 1)} ${l10n.unitKilometer}';

  String precipitation(double mm) => quantity(precipitationQuantity(mm, units));

  /// Where the wind comes from: N, NE, E… in the active language.
  String compass(double degrees) => switch (compassOctant(degrees)) {
    0 => l10n.compassN,
    1 => l10n.compassNE,
    2 => l10n.compassE,
    3 => l10n.compassSE,
    4 => l10n.compassS,
    5 => l10n.compassSW,
    6 => l10n.compassW,
    _ => l10n.compassNW,
  };

  /// Clock time in the device's local zone, e.g. `06:42` or `6:42 AM`.
  String time(DateTime utc) => DateFormat.jm(_locale).format(utc.toLocal());

  /// `12 de set. de 2026`, `Sep 12, 2026`.
  String date(DateTime utc) => DateFormat.yMMMd(_locale).format(utc.toLocal());

  /// `12 de set.`, `Sep 12` in the year of [now]; with the year otherwise.
  String shortDate(DateTime utc, {required DateTime now}) =>
      utc.toLocal().year == now.toLocal().year
      ? DateFormat.MMMd(_locale).format(utc.toLocal())
      : date(utc);

  /// `Sáb., 12 de set.`, `Sat, Sep 12` (capitalized: it starts a line).
  String weekdayDate(DateTime utc) =>
      _capitalize(DateFormat.MMMEd(_locale).format(utc.toLocal()));

  /// `Setembro de 2026`, for month headers.
  String monthYear(DateTime utc) =>
      _capitalize(DateFormat.yMMMM(_locale).format(utc.toLocal()));

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  /// `3 h 20 min`, `4 h` or `45 min`.
  String duration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    if (hours == 0) return l10n.durationMinutes(minutes);
    if (minutes == 0) return l10n.durationHours(hours);
    return l10n.durationHoursMinutes(hours, minutes);
  }

  /// Running timer: `1:05:09`, always with seconds.
  static String timer(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String moonPhase(MoonPhase phase) => switch (phase) {
    MoonPhase.newMoon => l10n.moonNew,
    MoonPhase.waxingCrescent => l10n.moonWaxingCrescent,
    MoonPhase.firstQuarter => l10n.moonFirstQuarter,
    MoonPhase.waxingGibbous => l10n.moonWaxingGibbous,
    MoonPhase.fullMoon => l10n.moonFull,
    MoonPhase.waningGibbous => l10n.moonWaningGibbous,
    MoonPhase.lastQuarter => l10n.moonLastQuarter,
    MoonPhase.waningCrescent => l10n.moonWaningCrescent,
  };

  String privacyLevel(PrivacyLevel level) => switch (level) {
    PrivacyLevel.private => l10n.privacyPrivate,
    PrivacyLevel.friends => l10n.privacyFriends,
    PrivacyLevel.approximate => l10n.privacyApproximate,
    PrivacyLevel.exact => l10n.privacyExact,
  };

  String privacyDescription(PrivacyLevel level) => switch (level) {
    PrivacyLevel.private => l10n.privacyPrivateDescription,
    PrivacyLevel.friends => l10n.privacyFriendsDescription,
    PrivacyLevel.approximate => l10n.privacyApproximateDescription,
    PrivacyLevel.exact => l10n.privacyExactDescription,
  };

  String unitSystemName(UnitSystem system) => switch (system) {
    UnitSystem.metric => l10n.unitsMetric,
    UnitSystem.imperial => l10n.unitsImperial,
  };

  String unitSystemExample(UnitSystem system) => switch (system) {
    UnitSystem.metric => l10n.unitsMetricExample,
    UnitSystem.imperial => l10n.unitsImperialExample,
  };

  String baitType(BaitType type) => switch (type) {
    BaitType.natural => l10n.baitTypeNatural,
    BaitType.artificial => l10n.baitTypeArtificial,
    BaitType.fly => l10n.baitTypeFly,
    BaitType.other => l10n.tackleTypeOther,
  };

  String gearType(GearType type) => switch (type) {
    GearType.combo => l10n.gearTypeCombo,
    GearType.rod => l10n.gearTypeRod,
    GearType.reel => l10n.gearTypeReel,
    GearType.line => l10n.gearTypeLine,
    GearType.other => l10n.tackleTypeOther,
  };
}

/// Parses a number typed with either decimal separator ("2,5" or "2.5").
double? parseDecimal(String input) {
  final cleaned = input.trim().replaceAll(' ', '').replaceAll(',', '.');
  if (cleaned.isEmpty) return null;
  final value = double.tryParse(cleaned);
  if (value == null || value.isNaN || value.isInfinite || value < 0) {
    return null;
  }
  return value;
}
