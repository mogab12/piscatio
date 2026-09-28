// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Piscatio';

  @override
  String get navFish => 'Pescar';

  @override
  String get navLogbook => 'Diario';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get unitGram => 'g';

  @override
  String get unitKilogram => 'kg';

  @override
  String get unitOunce => 'oz';

  @override
  String get unitPound => 'lb';

  @override
  String get unitCentimeter => 'cm';

  @override
  String get unitInch => 'pulg';

  @override
  String get unitMeter => 'm';

  @override
  String get unitFoot => 'pies';

  @override
  String get unitCelsius => '°C';

  @override
  String get unitFahrenheit => '°F';

  @override
  String get unitHectopascal => 'hPa';

  @override
  String get unitInchOfMercury => 'inHg';

  @override
  String get unitKilometerPerHour => 'km/h';

  @override
  String get unitMilePerHour => 'mph';

  @override
  String get unitMillimeter => 'mm';

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get moonNew => 'Luna nueva';

  @override
  String get moonWaxingCrescent => 'Luna creciente';

  @override
  String get moonFirstQuarter => 'Cuarto creciente';

  @override
  String get moonWaxingGibbous => 'Gibosa creciente';

  @override
  String get moonFull => 'Luna llena';

  @override
  String get moonWaningGibbous => 'Gibosa menguante';

  @override
  String get moonLastQuarter => 'Cuarto menguante';

  @override
  String get moonWaningCrescent => 'Luna menguante';

  @override
  String get privacyPrivate => 'Solo yo';

  @override
  String get privacyFriends => 'Amigos';

  @override
  String get privacyApproximate => 'Zona aproximada';

  @override
  String get privacyExact => 'Lugar exacto';

  @override
  String get privacyPrivateDescription =>
      'Las tarjetas nunca muestran dónde pescaste.';

  @override
  String get privacyFriendsDescription =>
      'Por ahora funciona como “Solo yo”. Los amigos llegan en una próxima versión.';

  @override
  String get privacyApproximateDescription =>
      'Las tarjetas muestran solo la región, como la ciudad. El punto se desplaza algunos kilómetros.';

  @override
  String get privacyExactDescription =>
      'Las tarjetas muestran el nombre del lugar. Las coordenadas nunca aparecen.';

  @override
  String get unitsMetric => 'Métrico';

  @override
  String get unitsImperial => 'Imperial';

  @override
  String get unitsMetricExample => 'kg, cm, m, °C';

  @override
  String get unitsImperialExample => 'lb, pulg, pies, °F';

  @override
  String get baitTypeNatural => 'Carnada natural';

  @override
  String get baitTypeArtificial => 'Señuelo';

  @override
  String get baitTypeFly => 'Mosca';

  @override
  String get gearTypeCombo => 'Caña y reel';

  @override
  String get gearTypeRod => 'Caña';

  @override
  String get gearTypeReel => 'Reel';

  @override
  String get gearTypeLine => 'Línea';

  @override
  String get tackleTypeOther => 'Otro';
}
