/// Unit conversion between the SI values stored in the database and the
/// quantities shown to the user.
///
/// Storage is always SI: grams, millimeters, °C, hPa, km/h and mm of rain.
/// Nothing here formats text; `core/formatting` turns a [Quantity] into a
/// localized string.
library;

enum UnitSystem { metric, imperial }

/// Countries that use imperial units for everyday measurements.
const _imperialCountries = {'US', 'LR', 'MM'};

/// Default unit system for a device region (ISO 3166 alpha-2 country code).
UnitSystem defaultUnitSystemFor(String? countryCode) =>
    _imperialCountries.contains(countryCode?.toUpperCase())
    ? UnitSystem.imperial
    : UnitSystem.metric;

enum DisplayUnit {
  gram,
  kilogram,
  ounce,
  pound,
  centimeter,
  inch,
  meter,
  foot,
  celsius,
  fahrenheit,
  hectopascal,
  inchOfMercury,
  kilometerPerHour,
  milePerHour,
  millimeter,
}

/// A value in a display unit plus how many decimals it deserves.
class Quantity {
  const Quantity(this.value, this.unit, {this.maxFractionDigits = 0});

  final double value;
  final DisplayUnit unit;
  final int maxFractionDigits;

  @override
  bool operator ==(Object other) =>
      other is Quantity &&
      other.value == value &&
      other.unit == unit &&
      other.maxFractionDigits == maxFractionDigits;

  @override
  int get hashCode => Object.hash(value, unit, maxFractionDigits);

  @override
  String toString() => 'Quantity($value ${unit.name})';
}

abstract final class Units {
  static const gramsPerPound = 453.59237;
  static const gramsPerOunce = gramsPerPound / 16;
  static const mmPerInch = 25.4;
  static const mmPerFoot = 304.8;
  static const hpaPerInHg = 33.8638866667;
  static const kmPerMile = 1.609344;

  // Input: display unit -> SI (rounded to the stored integer precision).
  static int gramsFromKilograms(double kg) => (kg * 1000).round();
  static int gramsFromPounds(double pounds, [double ounces = 0]) =>
      ((pounds * 16 + ounces) * gramsPerOunce).round();
  static int millimetersFromCentimeters(double cm) => (cm * 10).round();
  static int millimetersFromInches(double inches) =>
      (inches * mmPerInch).round();
  static int millimetersFromMeters(double m) => (m * 1000).round();
  static int millimetersFromFeet(double ft) => (ft * mmPerFoot).round();

  // Output: SI -> display unit.
  static double inchesFromMillimeters(num mm) => mm / mmPerInch;
  static double feetFromMillimeters(num mm) => mm / mmPerFoot;
  static double fahrenheitFromCelsius(num c) => c * 9 / 5 + 32;
  static double inHgFromHpa(num hpa) => hpa / hpaPerInHg;
  static double mphFromKmh(num kmh) => kmh / kmPerMile;
}

/// Weight split into the parts an angler reads: `850 g`, `2.35 kg`,
/// `12 oz` or `5 lb 3 oz`.
List<Quantity> weightParts(int grams, UnitSystem system) {
  switch (system) {
    case UnitSystem.metric:
      if (grams < 1000) return [Quantity(grams.toDouble(), DisplayUnit.gram)];
      return [
        Quantity(grams / 1000, DisplayUnit.kilogram, maxFractionDigits: 2),
      ];
    case UnitSystem.imperial:
      final totalOunces = (grams / Units.gramsPerOunce).round();
      final pounds = totalOunces ~/ 16;
      final ounces = totalOunces % 16;
      if (pounds == 0) {
        return [Quantity(ounces.toDouble(), DisplayUnit.ounce)];
      }
      return [
        Quantity(pounds.toDouble(), DisplayUnit.pound),
        if (ounces > 0) Quantity(ounces.toDouble(), DisplayUnit.ounce),
      ];
  }
}

/// Fish length: centimeters or inches, one decimal at most.
Quantity lengthQuantity(int millimeters, UnitSystem system) => switch (system) {
  UnitSystem.metric => Quantity(
    millimeters / 10,
    DisplayUnit.centimeter,
    maxFractionDigits: 1,
  ),
  UnitSystem.imperial => Quantity(
    Units.inchesFromMillimeters(millimeters),
    DisplayUnit.inch,
    maxFractionDigits: 1,
  ),
};

/// Water depth: meters or feet, one decimal at most.
Quantity depthQuantity(int millimeters, UnitSystem system) => switch (system) {
  UnitSystem.metric => Quantity(
    millimeters / 1000,
    DisplayUnit.meter,
    maxFractionDigits: 1,
  ),
  UnitSystem.imperial => Quantity(
    Units.feetFromMillimeters(millimeters),
    DisplayUnit.foot,
    maxFractionDigits: 1,
  ),
};

Quantity temperatureQuantity(double celsius, UnitSystem system) =>
    switch (system) {
      UnitSystem.metric => Quantity(celsius, DisplayUnit.celsius),
      UnitSystem.imperial => Quantity(
        Units.fahrenheitFromCelsius(celsius),
        DisplayUnit.fahrenheit,
      ),
    };

Quantity pressureQuantity(double hpa, UnitSystem system) => switch (system) {
  UnitSystem.metric => Quantity(hpa, DisplayUnit.hectopascal),
  UnitSystem.imperial => Quantity(
    Units.inHgFromHpa(hpa),
    DisplayUnit.inchOfMercury,
    maxFractionDigits: 2,
  ),
};

Quantity windSpeedQuantity(double kmh, UnitSystem system) => switch (system) {
  UnitSystem.metric => Quantity(kmh, DisplayUnit.kilometerPerHour),
  UnitSystem.imperial => Quantity(
    Units.mphFromKmh(kmh),
    DisplayUnit.milePerHour,
  ),
};

Quantity precipitationQuantity(double mm, UnitSystem system) =>
    switch (system) {
      UnitSystem.metric => Quantity(
        mm,
        DisplayUnit.millimeter,
        maxFractionDigits: 1,
      ),
      UnitSystem.imperial => Quantity(
        Units.inchesFromMillimeters(mm),
        DisplayUnit.inch,
        maxFractionDigits: 2,
      ),
    };
