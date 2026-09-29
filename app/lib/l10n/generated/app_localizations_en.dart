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

  @override
  String get historyEmpty => 'Finished trips show up here, month by month.';

  @override
  String get tripNotFound => 'This trip no longer exists.';

  @override
  String get catchNotFound => 'This catch no longer exists.';

  @override
  String get tripNoCatches => 'No catches on this trip.';

  @override
  String get tripAddCatch => 'Add a catch';

  @override
  String tripTimeRange(String start, String end) {
    return '$start to $end';
  }

  @override
  String get tripStatDuration => 'fishing';

  @override
  String speciesCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'species',
      one: 'species',
    );
    return '$_temp0';
  }

  @override
  String tripBiggestCatch(String species, String measure) {
    return 'Biggest: $species, $measure';
  }

  @override
  String get deleteTripTitle => 'Delete trip';

  @override
  String get deleteTripBody =>
      'Its catches and photos will be deleted too. This cannot be undone.';

  @override
  String get deleteCatchTitle => 'Delete catch';

  @override
  String get deleteCatchBody => 'The catch and its photo will be deleted.';

  @override
  String get editTripTitle => 'Edit trip';

  @override
  String get editTripDate => 'Date';

  @override
  String get editTripStart => 'Start';

  @override
  String get editTripEnd => 'End';

  @override
  String get editTripEndBeforeStart => 'The end must be after the start.';

  @override
  String get editTripPlace => 'Place name';

  @override
  String get editTripPlaceHelp => 'Shown on cards only with “Exact spot”.';

  @override
  String get editTripRegion => 'Region';

  @override
  String get editTripRegionHelp =>
      'City or state, e.g. Cuiabá, MT. Shown with “Approximate area”.';

  @override
  String get editTripPrivacy => 'Location privacy';

  @override
  String get catchPhoto => 'Photo';

  @override
  String get catchAddPhoto => 'Add photo';

  @override
  String get catchReplacePhoto => 'Replace';

  @override
  String get catchRemovePhoto => 'Remove';

  @override
  String get catchTime => 'Time caught';

  @override
  String durationHours(int hours) {
    return '$hours h';
  }

  @override
  String get weatherPending =>
      'This trip’s weather is ready 2 to 3 days later.';

  @override
  String get weatherUnavailable =>
      'No weather for this trip (no location or no data).';

  @override
  String get weatherTemperature => 'Temperature';

  @override
  String get weatherPressure => 'Pressure';

  @override
  String get weatherPressureFalling => 'Pressure falling';

  @override
  String get weatherPressureRising => 'Pressure rising';

  @override
  String get weatherPressureSteady => 'Pressure steady';

  @override
  String get weatherWind => 'Wind';

  @override
  String get weatherRain => 'Rain';

  @override
  String get weatherSource => 'Weather: NASA POWER';

  @override
  String get compassN => 'N';

  @override
  String get compassNE => 'NE';

  @override
  String get compassE => 'E';

  @override
  String get compassSE => 'SE';

  @override
  String get compassS => 'S';

  @override
  String get compassSW => 'SW';

  @override
  String get compassW => 'W';

  @override
  String get compassNW => 'NW';

  @override
  String get settingsWeatherData => 'Weather data';

  @override
  String get settingsWeatherDataCredit =>
      'NASA POWER Project, NASA Langley Research Center. CC BY 4.0.';

  @override
  String get brandName => 'Piscatio';

  @override
  String cardBiggestValue(String species, String measure) {
    return '$species, $measure';
  }

  @override
  String cardCatchNumber(String number) {
    return 'No. $number';
  }

  @override
  String get cardFieldSpecies => 'Species';

  @override
  String get cardFieldCommonName => 'Common name';

  @override
  String get cardFieldPlace => 'Locality';

  @override
  String get cardFieldDate => 'Date';

  @override
  String get cardFieldTime => 'Time';

  @override
  String get cardFieldLength => 'Length';

  @override
  String get cardFieldWeight => 'Weight';

  @override
  String get cardFieldBait => 'Bait';

  @override
  String get cardFieldWind => 'Wind';

  @override
  String get cardFieldAir => 'Air';

  @override
  String get cardFieldPressure => 'Pressure';

  @override
  String get cardFieldMoon => 'Moon';

  @override
  String get cardFieldDuration => 'Time out';

  @override
  String get cardFieldBiggest => 'Biggest';

  @override
  String get cardFieldReleased => 'Released';

  @override
  String get cardFieldKept => 'Kept';

  @override
  String get cardFieldFate => 'Fate';

  @override
  String get cardFieldLog => 'Field log';

  @override
  String cardPreviousRecord(String measure) {
    return 'previous best $measure';
  }

  @override
  String cardRecordImprovement(String improvement) {
    return 'Personal best, $improvement';
  }

  @override
  String get cardRecord => 'Personal best';

  @override
  String get cardFirstOfSpecies => 'First of the species';

  @override
  String cardRecordCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personal bests',
      one: '1 personal best',
    );
    return '$_temp0';
  }

  @override
  String get cardHoursUnit => 'h';

  @override
  String cardMoreCatches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'and $count more',
      one: 'and 1 more',
    );
    return '$_temp0';
  }

  @override
  String get cardCreate => 'Create card';

  @override
  String get cardStyleBoard => 'Board';

  @override
  String get cardStyleChart => 'Chart';

  @override
  String get cardStyleTag => 'Tag';

  @override
  String get cardFormatStory => 'Story';

  @override
  String get cardFormatSquare => 'Square';

  @override
  String get cardShowPlace => 'Show place';

  @override
  String get cardPlacePrivate =>
      'This trip is private: cards never show where it was.';

  @override
  String get cardPlaceRegion => 'Only the region is shown, never the spot.';

  @override
  String get cardPlaceUnknown => 'No place name saved for this trip.';

  @override
  String get cardShare => 'Share';

  @override
  String get cardShareFailed => 'Could not create the image. Try again.';

  @override
  String cardPreviewLabel(String style, String format) {
    return 'Card preview: $style, $format';
  }

  @override
  String get actionClose => 'Close';

  @override
  String get summaryTitle => 'Trip finished';

  @override
  String get summaryRecords => 'Personal bests';

  @override
  String summaryTopBait(String bait) {
    return 'Best bait: $bait';
  }

  @override
  String summaryRecordLine(String species, String measure) {
    return '$species, $measure';
  }

  @override
  String get bootStepDatabase => 'Opening your logbook…';

  @override
  String get bootStepCatalog => 'Loading the species…';

  @override
  String get bootSlow => 'This is taking longer than usual.';

  @override
  String get bootFailedTitle => 'The app could not open';

  @override
  String get bootFailedBody =>
      'Take a screenshot of this screen and send it to us. Your data stays on the phone.';

  @override
  String get bootRetry => 'Try again';

  @override
  String get bootCopyDetails => 'Copy details';

  @override
  String get brandTagline => 'Fishing log';

  @override
  String get cardSectionStyle => 'Style';

  @override
  String get cardSectionPhoto => 'Photo';

  @override
  String get cardSectionDetails => 'Details';

  @override
  String get cardSectionCaption => 'Caption';

  @override
  String get cardNoPhoto => 'No photo';

  @override
  String get cardNoPhotos => 'No photos to use on the card.';

  @override
  String cardPhotoOption(String number) {
    return 'Photo $number';
  }

  @override
  String get cardShowWeather => 'Weather and moon';

  @override
  String get cardShowBait => 'Bait';

  @override
  String get cardCaptionHint => 'Write a caption (optional)';

  @override
  String get cardFieldNotes => 'Notes';

  @override
  String get navStats => 'Stats';

  @override
  String get statsTitle => 'Your numbers';

  @override
  String get statsEmpty => 'Your numbers show up after your first trip.';

  @override
  String statsTripsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'trips',
      one: 'trip',
    );
    return '$_temp0';
  }

  @override
  String statsReleased(String percent) {
    return '$percent released';
  }

  @override
  String statsPerHour(String rate) {
    return '$rate per hour fished';
  }

  @override
  String get statsByHourTitle => 'Catches by time of day';

  @override
  String statsPeakHour(String start, String end) {
    return 'Most catches between $start and $end';
  }

  @override
  String statsHourBar(String time, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count catches',
      one: '1 catch',
    );
    return '$time: $_temp0';
  }

  @override
  String get statsSpeciesTitle => 'Most caught species';

  @override
  String get statsBaitsTitle => 'Baits that catch the most';

  @override
  String get statsRecordsTitle => 'Personal bests';

  @override
  String get statsBestTrip => 'Best trip';

  @override
  String statsBestTripValue(String date, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count catches',
      one: '1 catch',
    );
    return '$date: $_temp0';
  }

  @override
  String statsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count catches',
      one: '1 catch',
    );
    return '$_temp0';
  }

  @override
  String get tackleBaits => 'Baits';

  @override
  String get tackleGear => 'Gear';

  @override
  String get tackleEditBait => 'Edit bait';

  @override
  String get tackleEditGear => 'Edit gear';

  @override
  String get tackleArchive => 'Archive';

  @override
  String get tackleRestore => 'Restore';

  @override
  String get tackleArchived => 'Archived';

  @override
  String get tackleArchivedNote =>
      'They stay on older catches, but leave the pickers.';

  @override
  String get tackleEmptyBaits => 'No baits yet. Add the ones you use most.';

  @override
  String get tackleEmptyGear => 'No gear yet. Add your rods, reels and lines.';

  @override
  String get settingsSectionTackle => 'Baits and gear';

  @override
  String settingsBaitsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count baits',
      one: '1 bait',
      zero: 'None yet',
    );
    return '$_temp0';
  }

  @override
  String settingsGearCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
      zero: 'None yet',
    );
    return '$_temp0';
  }

  @override
  String get settingsSectionData => 'Your data';

  @override
  String get settingsExport => 'Export data';

  @override
  String get settingsExportHint =>
      'A JSON file with your trips, catches and baits. Photos stay on the phone.';

  @override
  String get settingsExportFailed => 'Could not export. Try again.';

  @override
  String get settingsWipe => 'Delete all data';

  @override
  String get settingsWipeHint =>
      'Trips, catches, photos and baits. This can\'t be undone.';

  @override
  String get wipeTitle => 'Delete all data?';

  @override
  String get wipeBody =>
      'Everything you logged leaves this phone: trips, catches, photos, baits and settings. Export first if you want to keep a copy.';

  @override
  String get wipeConfirm => 'Delete everything';

  @override
  String get pastTripAction => 'Log a past trip';

  @override
  String get pastTripTitle => 'Past trip';

  @override
  String get pastTripPhotos => 'Trip photos';

  @override
  String get pastTripPhotosHint =>
      'Each photo becomes a catch. Their date and place suggest the trip\'s.';

  @override
  String get pastTripAddPhoto => 'Add photo';

  @override
  String get pastTripSuggested => 'Date and place suggested by the photos.';

  @override
  String get pastTripSave => 'Save trip';

  @override
  String get pastTripPhotoFailed =>
      'Could not read this photo. Try another one.';

  @override
  String get placeSearchAction => 'Search a place by name';

  @override
  String get placeSearchHint => 'Lake, river, town…';

  @override
  String get placeSearchEmpty => 'No place found with that name.';

  @override
  String get placeSearchFailed => 'No connection to search. Try again.';

  @override
  String get placeSearchPointSaved => 'Place marked on the map';

  @override
  String get cardSectionTheme => 'Theme';

  @override
  String get cardThemeRedHead => 'Red head';

  @override
  String get cardThemePaper => 'Paper';

  @override
  String get cardThemeTucunare => 'Peacock bass';

  @override
  String get cardThemeDawn => 'Dawn';

  @override
  String get cardThemeMoon => 'Moon';

  @override
  String get cardThemeRiver => 'River';

  @override
  String get cardFilterNone => 'Original';

  @override
  String get cardFilterDuotone => 'Duotone';

  @override
  String get cardFilterInk => 'Ink drawing';

  @override
  String get cardFilterEngraving => 'Engraving';

  @override
  String get cardFilterScreenprint => 'Screen print';

  @override
  String get cardFilterHalftone => 'Halftone';

  @override
  String get cardFilterWorking => 'Applying the filter';

  @override
  String get cardFilterFailed => 'Couldn\'t apply the filter to this photo.';
}
