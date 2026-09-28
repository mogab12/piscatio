// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Piscatio';

  @override
  String get navFish => 'Fishing';

  @override
  String get navLogbook => 'Logbook';

  @override
  String get navSettings => 'Settings';

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
  String get unitInch => 'in';

  @override
  String get unitMeter => 'm';

  @override
  String get unitFoot => 'ft';

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
  String get moonNew => 'New moon';

  @override
  String get moonWaxingCrescent => 'Waxing crescent';

  @override
  String get moonFirstQuarter => 'First quarter';

  @override
  String get moonWaxingGibbous => 'Waxing gibbous';

  @override
  String get moonFull => 'Full moon';

  @override
  String get moonWaningGibbous => 'Waning gibbous';

  @override
  String get moonLastQuarter => 'Last quarter';

  @override
  String get moonWaningCrescent => 'Waning crescent';

  @override
  String get privacyPrivate => 'Only me';

  @override
  String get privacyFriends => 'Friends';

  @override
  String get privacyApproximate => 'Approximate area';

  @override
  String get privacyExact => 'Exact spot';

  @override
  String get privacyPrivateDescription => 'Cards never show where you fished.';

  @override
  String get privacyFriendsDescription =>
      'For now, works like “Only me”. Friends arrive in a future version.';

  @override
  String get privacyApproximateDescription =>
      'Cards show only the region, like the city. The spot is shifted a few kilometers.';

  @override
  String get privacyExactDescription =>
      'Cards show the name of the place. Coordinates are never shown.';

  @override
  String get unitsMetric => 'Metric';

  @override
  String get unitsImperial => 'Imperial';

  @override
  String get unitsMetricExample => 'kg, cm, m, °C';

  @override
  String get unitsImperialExample => 'lb, in, ft, °F';

  @override
  String get baitTypeNatural => 'Natural bait';

  @override
  String get baitTypeArtificial => 'Lure';

  @override
  String get baitTypeFly => 'Fly';

  @override
  String get gearTypeCombo => 'Rod and reel';

  @override
  String get gearTypeRod => 'Rod';

  @override
  String get gearTypeReel => 'Reel';

  @override
  String get gearTypeLine => 'Line';

  @override
  String get tackleTypeOther => 'Other';

  @override
  String get actionContinue => 'Continue';

  @override
  String get actionBack => 'Back';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionSave => 'Save';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionUndo => 'Undo';

  @override
  String onboardingStepOf(int step, int total) {
    return 'Step $step of $total';
  }

  @override
  String get onboardingTagline => 'Every fishing trip becomes a story.';

  @override
  String get onboardingLanguageTitle => 'Language';

  @override
  String get onboardingUnitsTitle => 'How do you measure your fish?';

  @override
  String get onboardingUnitsHint => 'You can change this later in Settings.';

  @override
  String get onboardingLocationTitle => 'Where are you fishing?';

  @override
  String get onboardingLocationWhy =>
      'Your location saves where each trip happened and lets us look up that day’s weather.';

  @override
  String get onboardingLocationPrivacy =>
      'The spot stays on your phone. Cards never show coordinates, and you decide how much to reveal.';

  @override
  String get onboardingLocationOffline =>
      'Works without signal. The weather is fetched when you are back online.';

  @override
  String get onboardingLocationAllow => 'Allow location';

  @override
  String get onboardingLocationSkip => 'Not now';

  @override
  String get settingsSectionPreferences => 'Preferences';

  @override
  String get settingsSectionAbout => 'About';

  @override
  String get settingsLanguage => 'Language';

  @override
  String settingsLanguageDevice(String language) {
    return 'Device language: $language';
  }

  @override
  String get settingsUnits => 'Units';

  @override
  String settingsUnitsValue(String system, String examples) {
    return '$system ($examples)';
  }

  @override
  String get settingsDefaultPrivacy => 'Default location privacy';

  @override
  String get settingsLicenses => 'Open source licenses';
}
