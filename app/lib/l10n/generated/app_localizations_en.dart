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

  @override
  String get errorGeneric => 'Something went wrong. Try again.';

  @override
  String get startTripAction => 'Start trip';

  @override
  String get resumeTripAction => 'Back to trip';

  @override
  String get homeRecentTrips => 'Recent trips';

  @override
  String get homeEmptyTitle => 'Your first trip starts here.';

  @override
  String get homeEmptyBody =>
      'Tap Start trip when you reach the water. Each catch takes three taps, even with wet hands.';

  @override
  String get activeTripLabel => 'Trip in progress';

  @override
  String activeTripElapsed(String duration) {
    return 'Fishing for $duration';
  }

  @override
  String activeTripStartedAt(String time) {
    return 'Started at $time';
  }

  @override
  String get activeTripNoLocation => 'No location';

  @override
  String get activeTripLocationSaved => 'Location saved';

  @override
  String get activeTripEmpty =>
      'No catches yet. Tap + Catch as soon as the fish is out of the water.';

  @override
  String get activeTripMinimize => 'Minimize';

  @override
  String get addCatchAction => '+ Catch';

  @override
  String get finishTripAction => 'Finish';

  @override
  String get finishTripTitle => 'Finish this trip?';

  @override
  String get finishTripBody =>
      'The timer stops now. You can still edit times and catches later.';

  @override
  String get finishTripConfirm => 'Finish trip';

  @override
  String catchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count catches',
      one: '1 catch',
      zero: 'No catches',
    );
    return '$_temp0';
  }

  @override
  String catchCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'catches',
      one: 'catch',
    );
    return '$_temp0';
  }

  @override
  String get catchReleased => 'Released';

  @override
  String get speciesUnknown => 'Unidentified species';

  @override
  String rulerHour(int hours) {
    return '$hours h';
  }

  @override
  String rulerSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Time ruler with $count catches marked',
      one: 'Time ruler with 1 catch marked',
      zero: 'Time ruler, no catches yet',
    );
    return '$_temp0';
  }

  @override
  String get quickCatchTitle => 'New catch';

  @override
  String get quickCatchPhotoTitle => 'Photo first';

  @override
  String get quickCatchPhotoHint =>
      'Location data is removed from the photo before it is saved.';

  @override
  String get quickCatchTakePhoto => 'Take photo';

  @override
  String get quickCatchGallery => 'Gallery';

  @override
  String get quickCatchNoPhoto => 'No photo';

  @override
  String get quickCatchSpeciesTitle => 'Which fish?';

  @override
  String get quickCatchChangeSpecies => 'Change';

  @override
  String get quickCatchMoreDetails => 'More details';

  @override
  String get quickCatchMoreDetailsHint => 'Weight, length, bait, gear, depth';

  @override
  String get quickCatchSave => 'Save catch';

  @override
  String get catchSaved => 'Catch saved';

  @override
  String get photoImportFailed =>
      'Could not use this photo. The catch was saved without it.';

  @override
  String get speciesSearchHint => 'Search: traíra, tararira, bass…';

  @override
  String get speciesSearchClear => 'Clear search';

  @override
  String get speciesMostUsed => 'Your most caught';

  @override
  String get speciesAll => 'All species';

  @override
  String get speciesUnknownAction => 'I don’t know the species';

  @override
  String speciesAlsoKnownAs(String name) {
    return 'Also: $name';
  }

  @override
  String get speciesNoResults => 'No species found with that name.';

  @override
  String speciesAddCustom(String name) {
    return 'Add “$name” as a species';
  }

  @override
  String get catchWeight => 'Weight';

  @override
  String get catchWeightOunces => 'Ounces';

  @override
  String get catchLength => 'Length';

  @override
  String get catchDepth => 'Depth';

  @override
  String get catchReleasedQuestion => 'Released?';

  @override
  String get catchReleasedYes => 'Released';

  @override
  String get catchReleasedNo => 'Kept';

  @override
  String get catchBait => 'Bait';

  @override
  String get catchGear => 'Gear';

  @override
  String get catchChooseBait => 'Choose bait';

  @override
  String get catchChooseGear => 'Choose gear';

  @override
  String get catchNone => 'None';

  @override
  String get catchNotes => 'Notes';

  @override
  String get tackleNewBait => 'New bait';

  @override
  String get tackleNewGear => 'New gear';

  @override
  String get tackleName => 'Name';

  @override
  String get errorInvalidNumber => 'Enter a number, like 2.5';
}
