import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('pt'),
  ];

  /// App name. Brand, do not translate.
  ///
  /// In en, this message translates to:
  /// **'Piscatio'**
  String get appTitle;

  /// Bottom tab with the start-trip button.
  ///
  /// In en, this message translates to:
  /// **'Fishing'**
  String get navFish;

  /// Bottom tab with past trips.
  ///
  /// In en, this message translates to:
  /// **'Logbook'**
  String get navLogbook;

  /// Bottom tab with settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// Unit symbol: grams.
  ///
  /// In en, this message translates to:
  /// **'g'**
  String get unitGram;

  /// Unit symbol: kilograms.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get unitKilogram;

  /// Unit symbol: ounces.
  ///
  /// In en, this message translates to:
  /// **'oz'**
  String get unitOunce;

  /// Unit symbol: pounds.
  ///
  /// In en, this message translates to:
  /// **'lb'**
  String get unitPound;

  /// Unit symbol: centimeters.
  ///
  /// In en, this message translates to:
  /// **'cm'**
  String get unitCentimeter;

  /// Unit symbol: inches.
  ///
  /// In en, this message translates to:
  /// **'in'**
  String get unitInch;

  /// Unit symbol: meters.
  ///
  /// In en, this message translates to:
  /// **'m'**
  String get unitMeter;

  /// Unit symbol: feet.
  ///
  /// In en, this message translates to:
  /// **'ft'**
  String get unitFoot;

  /// Unit symbol: degrees Celsius.
  ///
  /// In en, this message translates to:
  /// **'°C'**
  String get unitCelsius;

  /// Unit symbol: degrees Fahrenheit.
  ///
  /// In en, this message translates to:
  /// **'°F'**
  String get unitFahrenheit;

  /// Unit symbol: hectopascals.
  ///
  /// In en, this message translates to:
  /// **'hPa'**
  String get unitHectopascal;

  /// Unit symbol: inches of mercury.
  ///
  /// In en, this message translates to:
  /// **'inHg'**
  String get unitInchOfMercury;

  /// Unit symbol: kilometers per hour.
  ///
  /// In en, this message translates to:
  /// **'km/h'**
  String get unitKilometerPerHour;

  /// Unit symbol: miles per hour.
  ///
  /// In en, this message translates to:
  /// **'mph'**
  String get unitMilePerHour;

  /// Unit symbol: millimeters.
  ///
  /// In en, this message translates to:
  /// **'mm'**
  String get unitMillimeter;

  /// A duration with hours and minutes.
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} min'**
  String durationHoursMinutes(int hours, int minutes);

  /// A duration shorter than one hour.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String durationMinutes(int minutes);

  /// Moon phase.
  ///
  /// In en, this message translates to:
  /// **'New moon'**
  String get moonNew;

  /// Moon phase.
  ///
  /// In en, this message translates to:
  /// **'Waxing crescent'**
  String get moonWaxingCrescent;

  /// Moon phase.
  ///
  /// In en, this message translates to:
  /// **'First quarter'**
  String get moonFirstQuarter;

  /// Moon phase.
  ///
  /// In en, this message translates to:
  /// **'Waxing gibbous'**
  String get moonWaxingGibbous;

  /// Moon phase.
  ///
  /// In en, this message translates to:
  /// **'Full moon'**
  String get moonFull;

  /// Moon phase.
  ///
  /// In en, this message translates to:
  /// **'Waning gibbous'**
  String get moonWaningGibbous;

  /// Moon phase.
  ///
  /// In en, this message translates to:
  /// **'Last quarter'**
  String get moonLastQuarter;

  /// Moon phase.
  ///
  /// In en, this message translates to:
  /// **'Waning crescent'**
  String get moonWaningCrescent;

  /// Location privacy level: nobody else sees the place.
  ///
  /// In en, this message translates to:
  /// **'Only me'**
  String get privacyPrivate;

  /// Location privacy level: friends only (social features come later).
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get privacyFriends;

  /// Location privacy level: shifted a few km.
  ///
  /// In en, this message translates to:
  /// **'Approximate area'**
  String get privacyApproximate;

  /// Location privacy level: the real place name.
  ///
  /// In en, this message translates to:
  /// **'Exact spot'**
  String get privacyExact;

  /// Explains the private level.
  ///
  /// In en, this message translates to:
  /// **'Cards never show where you fished.'**
  String get privacyPrivateDescription;

  /// Explains the friends level in the MVP.
  ///
  /// In en, this message translates to:
  /// **'For now, works like “Only me”. Friends arrive in a future version.'**
  String get privacyFriendsDescription;

  /// Explains the approximate level.
  ///
  /// In en, this message translates to:
  /// **'Cards show only the region, like the city. The spot is shifted a few kilometers.'**
  String get privacyApproximateDescription;

  /// Explains the exact level.
  ///
  /// In en, this message translates to:
  /// **'Cards show the name of the place. Coordinates are never shown.'**
  String get privacyExactDescription;

  /// Metric unit system.
  ///
  /// In en, this message translates to:
  /// **'Metric'**
  String get unitsMetric;

  /// Imperial unit system.
  ///
  /// In en, this message translates to:
  /// **'Imperial'**
  String get unitsImperial;

  /// Examples of metric units.
  ///
  /// In en, this message translates to:
  /// **'kg, cm, m, °C'**
  String get unitsMetricExample;

  /// Examples of imperial units.
  ///
  /// In en, this message translates to:
  /// **'lb, in, ft, °F'**
  String get unitsImperialExample;

  /// Bait type.
  ///
  /// In en, this message translates to:
  /// **'Natural bait'**
  String get baitTypeNatural;

  /// Bait type.
  ///
  /// In en, this message translates to:
  /// **'Lure'**
  String get baitTypeArtificial;

  /// Bait type (fly fishing).
  ///
  /// In en, this message translates to:
  /// **'Fly'**
  String get baitTypeFly;

  /// Gear type.
  ///
  /// In en, this message translates to:
  /// **'Rod and reel'**
  String get gearTypeCombo;

  /// Gear type.
  ///
  /// In en, this message translates to:
  /// **'Rod'**
  String get gearTypeRod;

  /// Gear type.
  ///
  /// In en, this message translates to:
  /// **'Reel'**
  String get gearTypeReel;

  /// Gear type.
  ///
  /// In en, this message translates to:
  /// **'Line'**
  String get gearTypeLine;

  /// Bait or gear type: other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get tackleTypeOther;

  /// Button to go to the next step.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get actionContinue;

  /// Tooltip of the back button.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get actionBack;

  /// Cancel button.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// Save button.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// Delete button.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// Edit button.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get actionEdit;

  /// Undo action in a snackbar.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get actionUndo;

  /// Screen reader label of the onboarding progress bar.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total}'**
  String onboardingStepOf(int step, int total);

  /// Tagline on the first onboarding screen.
  ///
  /// In en, this message translates to:
  /// **'Every fishing trip becomes a story.'**
  String get onboardingTagline;

  /// Label above the language options in onboarding.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get onboardingLanguageTitle;

  /// Title of the units step.
  ///
  /// In en, this message translates to:
  /// **'How do you measure your fish?'**
  String get onboardingUnitsTitle;

  /// Hint under the units title.
  ///
  /// In en, this message translates to:
  /// **'You can change this later in Settings.'**
  String get onboardingUnitsHint;

  /// Title of the location permission step.
  ///
  /// In en, this message translates to:
  /// **'Where are you fishing?'**
  String get onboardingLocationTitle;

  /// Why the app asks for location.
  ///
  /// In en, this message translates to:
  /// **'Your location saves where each trip happened and lets us look up that day’s weather.'**
  String get onboardingLocationWhy;

  /// Privacy promise in the location step.
  ///
  /// In en, this message translates to:
  /// **'The spot stays on your phone. Cards never show coordinates, and you decide how much to reveal.'**
  String get onboardingLocationPrivacy;

  /// Offline note in the location step.
  ///
  /// In en, this message translates to:
  /// **'Works without signal. The weather is fetched when you are back online.'**
  String get onboardingLocationOffline;

  /// Button that asks for location permission.
  ///
  /// In en, this message translates to:
  /// **'Allow location'**
  String get onboardingLocationAllow;

  /// Skip the location permission.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get onboardingLocationSkip;

  /// Settings section heading.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get settingsSectionPreferences;

  /// Settings section heading.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsSectionAbout;

  /// Settings row: app language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// Option to follow the device language.
  ///
  /// In en, this message translates to:
  /// **'Device language: {language}'**
  String settingsLanguageDevice(String language);

  /// Settings row: unit system.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get settingsUnits;

  /// Current unit system with examples.
  ///
  /// In en, this message translates to:
  /// **'{system} ({examples})'**
  String settingsUnitsValue(String system, String examples);

  /// Settings row: privacy level for new trips.
  ///
  /// In en, this message translates to:
  /// **'Default location privacy'**
  String get settingsDefaultPrivacy;

  /// Settings row: licenses page.
  ///
  /// In en, this message translates to:
  /// **'Open source licenses'**
  String get settingsLicenses;

  /// Generic error message.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get errorGeneric;

  /// Main button on the home screen.
  ///
  /// In en, this message translates to:
  /// **'Start trip'**
  String get startTripAction;

  /// Main button when a trip is running.
  ///
  /// In en, this message translates to:
  /// **'Back to trip'**
  String get resumeTripAction;

  /// Heading of the recent trips list.
  ///
  /// In en, this message translates to:
  /// **'Recent trips'**
  String get homeRecentTrips;

  /// Home empty state title.
  ///
  /// In en, this message translates to:
  /// **'Your first trip starts here.'**
  String get homeEmptyTitle;

  /// Home empty state body.
  ///
  /// In en, this message translates to:
  /// **'Tap Start trip when you reach the water. Each catch takes three taps, even with wet hands.'**
  String get homeEmptyBody;

  /// Label above the running timer.
  ///
  /// In en, this message translates to:
  /// **'Trip in progress'**
  String get activeTripLabel;

  /// Screen reader text for the timer.
  ///
  /// In en, this message translates to:
  /// **'Fishing for {duration}'**
  String activeTripElapsed(String duration);

  /// Start time of the trip.
  ///
  /// In en, this message translates to:
  /// **'Started at {time}'**
  String activeTripStartedAt(String time);

  /// Trip has no GPS location.
  ///
  /// In en, this message translates to:
  /// **'No location'**
  String get activeTripNoLocation;

  /// Trip has a GPS location.
  ///
  /// In en, this message translates to:
  /// **'Location saved'**
  String get activeTripLocationSaved;

  /// Active trip with no catches.
  ///
  /// In en, this message translates to:
  /// **'No catches yet. Tap + Catch as soon as the fish is out of the water.'**
  String get activeTripEmpty;

  /// Tooltip: leave the active trip screen, the trip keeps running.
  ///
  /// In en, this message translates to:
  /// **'Minimize'**
  String get activeTripMinimize;

  /// Big button to register a catch.
  ///
  /// In en, this message translates to:
  /// **'+ Catch'**
  String get addCatchAction;

  /// Button to end the trip.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finishTripAction;

  /// Confirmation dialog title.
  ///
  /// In en, this message translates to:
  /// **'Finish this trip?'**
  String get finishTripTitle;

  /// Confirmation dialog body.
  ///
  /// In en, this message translates to:
  /// **'The timer stops now. You can still edit times and catches later.'**
  String get finishTripBody;

  /// Confirm finishing the trip.
  ///
  /// In en, this message translates to:
  /// **'Finish trip'**
  String get finishTripConfirm;

  /// Number of catches as a sentence.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No catches} =1{1 catch} other{{count} catches}}'**
  String catchCount(int count);

  /// Word shown next to a big catch number.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{catch} other{catches}}'**
  String catchCountLabel(int count);

  /// The fish was released.
  ///
  /// In en, this message translates to:
  /// **'Released'**
  String get catchReleased;

  /// Catch without species.
  ///
  /// In en, this message translates to:
  /// **'Unidentified species'**
  String get speciesUnknown;

  /// Hour label on the trip time ruler.
  ///
  /// In en, this message translates to:
  /// **'{hours} h'**
  String rulerHour(int hours);

  /// Screen reader label of the time ruler.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Time ruler, no catches yet} =1{Time ruler with 1 catch marked} other{Time ruler with {count} catches marked}}'**
  String rulerSemantics(int count);

  /// Title of the quick capture screen.
  ///
  /// In en, this message translates to:
  /// **'New catch'**
  String get quickCatchTitle;

  /// Photo step title.
  ///
  /// In en, this message translates to:
  /// **'Photo first'**
  String get quickCatchPhotoTitle;

  /// Photo step hint about EXIF removal.
  ///
  /// In en, this message translates to:
  /// **'Location data is removed from the photo before it is saved.'**
  String get quickCatchPhotoHint;

  /// Open the camera.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get quickCatchTakePhoto;

  /// Pick a photo from the gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get quickCatchGallery;

  /// Continue without a photo.
  ///
  /// In en, this message translates to:
  /// **'No photo'**
  String get quickCatchNoPhoto;

  /// Species step title.
  ///
  /// In en, this message translates to:
  /// **'Which fish?'**
  String get quickCatchSpeciesTitle;

  /// Change the chosen species.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get quickCatchChangeSpecies;

  /// Expandable optional fields.
  ///
  /// In en, this message translates to:
  /// **'More details'**
  String get quickCatchMoreDetails;

  /// What the optional area contains.
  ///
  /// In en, this message translates to:
  /// **'Weight, length, bait, gear, depth'**
  String get quickCatchMoreDetailsHint;

  /// Save the catch.
  ///
  /// In en, this message translates to:
  /// **'Save catch'**
  String get quickCatchSave;

  /// Snackbar after saving a catch.
  ///
  /// In en, this message translates to:
  /// **'Catch saved'**
  String get catchSaved;

  /// Photo processing failed.
  ///
  /// In en, this message translates to:
  /// **'Could not use this photo. The catch was saved without it.'**
  String get photoImportFailed;

  /// Hint of the species search field.
  ///
  /// In en, this message translates to:
  /// **'Search: traíra, tararira, bass…'**
  String get speciesSearchHint;

  /// Tooltip to clear the search.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get speciesSearchClear;

  /// Heading: species the user catches most.
  ///
  /// In en, this message translates to:
  /// **'Your most caught'**
  String get speciesMostUsed;

  /// Heading: full species list.
  ///
  /// In en, this message translates to:
  /// **'All species'**
  String get speciesAll;

  /// Save without species.
  ///
  /// In en, this message translates to:
  /// **'I don’t know the species'**
  String get speciesUnknownAction;

  /// Synonym that matched the search.
  ///
  /// In en, this message translates to:
  /// **'Also: {name}'**
  String speciesAlsoKnownAs(String name);

  /// Empty search result.
  ///
  /// In en, this message translates to:
  /// **'No species found with that name.'**
  String get speciesNoResults;

  /// Create a custom species.
  ///
  /// In en, this message translates to:
  /// **'Add “{name}” as a species'**
  String speciesAddCustom(String name);

  /// Weight field label.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get catchWeight;

  /// Ounces field label (imperial).
  ///
  /// In en, this message translates to:
  /// **'Ounces'**
  String get catchWeightOunces;

  /// Fish length field label.
  ///
  /// In en, this message translates to:
  /// **'Length'**
  String get catchLength;

  /// Water depth field label.
  ///
  /// In en, this message translates to:
  /// **'Depth'**
  String get catchDepth;

  /// Question: was the fish released.
  ///
  /// In en, this message translates to:
  /// **'Released?'**
  String get catchReleasedQuestion;

  /// The fish was released.
  ///
  /// In en, this message translates to:
  /// **'Released'**
  String get catchReleasedYes;

  /// The fish was kept.
  ///
  /// In en, this message translates to:
  /// **'Kept'**
  String get catchReleasedNo;

  /// Bait field label.
  ///
  /// In en, this message translates to:
  /// **'Bait'**
  String get catchBait;

  /// Gear field label.
  ///
  /// In en, this message translates to:
  /// **'Gear'**
  String get catchGear;

  /// Placeholder for bait.
  ///
  /// In en, this message translates to:
  /// **'Choose bait'**
  String get catchChooseBait;

  /// Placeholder for gear.
  ///
  /// In en, this message translates to:
  /// **'Choose gear'**
  String get catchChooseGear;

  /// No bait/gear selected.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get catchNone;

  /// Notes field label.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get catchNotes;

  /// Create a bait.
  ///
  /// In en, this message translates to:
  /// **'New bait'**
  String get tackleNewBait;

  /// Create a gear item.
  ///
  /// In en, this message translates to:
  /// **'New gear'**
  String get tackleNewGear;

  /// Name field for bait/gear.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get tackleName;

  /// Invalid number in a field.
  ///
  /// In en, this message translates to:
  /// **'Enter a number, like 2.5'**
  String get errorInvalidNumber;

  /// Empty logbook.
  ///
  /// In en, this message translates to:
  /// **'Finished trips show up here, month by month.'**
  String get historyEmpty;

  /// Trip was deleted.
  ///
  /// In en, this message translates to:
  /// **'This trip no longer exists.'**
  String get tripNotFound;

  /// Catch was deleted.
  ///
  /// In en, this message translates to:
  /// **'This catch no longer exists.'**
  String get catchNotFound;

  /// Trip without catches.
  ///
  /// In en, this message translates to:
  /// **'No catches on this trip.'**
  String get tripNoCatches;

  /// Add a catch to a finished trip.
  ///
  /// In en, this message translates to:
  /// **'Add a catch'**
  String get tripAddCatch;

  /// Trip start and end times.
  ///
  /// In en, this message translates to:
  /// **'{start} to {end}'**
  String tripTimeRange(String start, String end);

  /// Label under the trip duration.
  ///
  /// In en, this message translates to:
  /// **'fishing'**
  String get tripStatDuration;

  /// Word next to a big species count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{species} other{species}}'**
  String speciesCountLabel(int count);

  /// Biggest catch of the trip.
  ///
  /// In en, this message translates to:
  /// **'Biggest: {species}, {measure}'**
  String tripBiggestCatch(String species, String measure);

  /// Delete trip action and dialog title.
  ///
  /// In en, this message translates to:
  /// **'Delete trip'**
  String get deleteTripTitle;

  /// Delete trip confirmation.
  ///
  /// In en, this message translates to:
  /// **'Its catches and photos will be deleted too. This cannot be undone.'**
  String get deleteTripBody;

  /// Delete catch action and dialog title.
  ///
  /// In en, this message translates to:
  /// **'Delete catch'**
  String get deleteCatchTitle;

  /// Delete catch confirmation.
  ///
  /// In en, this message translates to:
  /// **'The catch and its photo will be deleted.'**
  String get deleteCatchBody;

  /// Edit trip screen title.
  ///
  /// In en, this message translates to:
  /// **'Edit trip'**
  String get editTripTitle;

  /// Trip date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get editTripDate;

  /// Trip start time.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get editTripStart;

  /// Trip end time.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get editTripEnd;

  /// Validation error.
  ///
  /// In en, this message translates to:
  /// **'The end must be after the start.'**
  String get editTripEndBeforeStart;

  /// Location name field.
  ///
  /// In en, this message translates to:
  /// **'Place name'**
  String get editTripPlace;

  /// When the place name is shown.
  ///
  /// In en, this message translates to:
  /// **'Shown on cards only with “Exact spot”.'**
  String get editTripPlaceHelp;

  /// Region field (city, state).
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get editTripRegion;

  /// What the region is and when it is shown.
  ///
  /// In en, this message translates to:
  /// **'City or state, e.g. Cuiabá, MT. Shown with “Approximate area”.'**
  String get editTripRegionHelp;

  /// Privacy level of this trip.
  ///
  /// In en, this message translates to:
  /// **'Location privacy'**
  String get editTripPrivacy;

  /// Photo source sheet title.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get catchPhoto;

  /// Add a photo to a catch.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get catchAddPhoto;

  /// Replace the catch photo.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get catchReplacePhoto;

  /// Remove the catch photo.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get catchRemovePhoto;

  /// Catch time field.
  ///
  /// In en, this message translates to:
  /// **'Time caught'**
  String get catchTime;

  /// A duration of whole hours.
  ///
  /// In en, this message translates to:
  /// **'{hours} h'**
  String durationHours(int hours);

  /// Weather not published yet (NASA POWER delay).
  ///
  /// In en, this message translates to:
  /// **'This trip’s weather is ready 2 to 3 days later.'**
  String get weatherPending;

  /// Weather could not be obtained.
  ///
  /// In en, this message translates to:
  /// **'No weather for this trip (no location or no data).'**
  String get weatherUnavailable;

  /// Weather label.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get weatherTemperature;

  /// Weather label (no trend known).
  ///
  /// In en, this message translates to:
  /// **'Pressure'**
  String get weatherPressure;

  /// Pressure dropped over the 3 hours before the trip.
  ///
  /// In en, this message translates to:
  /// **'Pressure falling'**
  String get weatherPressureFalling;

  /// Pressure rose over the 3 hours before the trip.
  ///
  /// In en, this message translates to:
  /// **'Pressure rising'**
  String get weatherPressureRising;

  /// Pressure barely changed before the trip.
  ///
  /// In en, this message translates to:
  /// **'Pressure steady'**
  String get weatherPressureSteady;

  /// Weather label.
  ///
  /// In en, this message translates to:
  /// **'Wind'**
  String get weatherWind;

  /// Weather label: total rain during the trip.
  ///
  /// In en, this message translates to:
  /// **'Rain'**
  String get weatherRain;

  /// Weather data credit.
  ///
  /// In en, this message translates to:
  /// **'Weather: NASA POWER'**
  String get weatherSource;

  /// Compass point: north.
  ///
  /// In en, this message translates to:
  /// **'N'**
  String get compassN;

  /// Compass point: northeast.
  ///
  /// In en, this message translates to:
  /// **'NE'**
  String get compassNE;

  /// Compass point: east.
  ///
  /// In en, this message translates to:
  /// **'E'**
  String get compassE;

  /// Compass point: southeast.
  ///
  /// In en, this message translates to:
  /// **'SE'**
  String get compassSE;

  /// Compass point: south.
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get compassS;

  /// Compass point: southwest.
  ///
  /// In en, this message translates to:
  /// **'SW'**
  String get compassSW;

  /// Compass point: west.
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get compassW;

  /// Compass point: northwest.
  ///
  /// In en, this message translates to:
  /// **'NW'**
  String get compassNW;

  /// Settings row crediting the weather source.
  ///
  /// In en, this message translates to:
  /// **'Weather data'**
  String get settingsWeatherData;

  /// Weather data attribution.
  ///
  /// In en, this message translates to:
  /// **'NASA POWER Project, NASA Langley Research Center. CC BY 4.0.'**
  String get settingsWeatherDataCredit;

  /// App name printed on cards as the maker's mark.
  ///
  /// In en, this message translates to:
  /// **'Piscatio'**
  String get brandName;

  /// Value of the 'Biggest' row on a trip card, e.g. 'Dourado, 4.2 kg'.
  ///
  /// In en, this message translates to:
  /// **'{species}, {measure}'**
  String cardBiggestValue(String species, String measure);

  /// Specimen number on the tag card: the catch's position in the user's logbook.
  ///
  /// In en, this message translates to:
  /// **'No. {number}'**
  String cardCatchNumber(String number);

  /// Field label on a card (scientific name).
  ///
  /// In en, this message translates to:
  /// **'Species'**
  String get cardFieldSpecies;

  /// Field label on a card.
  ///
  /// In en, this message translates to:
  /// **'Common name'**
  String get cardFieldCommonName;

  /// Field label on a card.
  ///
  /// In en, this message translates to:
  /// **'Locality'**
  String get cardFieldPlace;

  /// Field label on a card.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get cardFieldDate;

  /// Field label on a card (time of day).
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get cardFieldTime;

  /// Field label on a card.
  ///
  /// In en, this message translates to:
  /// **'Length'**
  String get cardFieldLength;

  /// Field label on a card.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get cardFieldWeight;

  /// Field label on a card.
  ///
  /// In en, this message translates to:
  /// **'Bait'**
  String get cardFieldBait;

  /// Field label on a card.
  ///
  /// In en, this message translates to:
  /// **'Wind'**
  String get cardFieldWind;

  /// Field label on a card: air temperature.
  ///
  /// In en, this message translates to:
  /// **'Air'**
  String get cardFieldAir;

  /// Field label on a card: air pressure.
  ///
  /// In en, this message translates to:
  /// **'Pressure'**
  String get cardFieldPressure;

  /// Field label on a card.
  ///
  /// In en, this message translates to:
  /// **'Moon'**
  String get cardFieldMoon;

  /// Field label on a trip card: how long the trip lasted.
  ///
  /// In en, this message translates to:
  /// **'Time out'**
  String get cardFieldDuration;

  /// Field label on a trip card: the biggest catch.
  ///
  /// In en, this message translates to:
  /// **'Biggest'**
  String get cardFieldBiggest;

  /// Value on a card when the fish was released.
  ///
  /// In en, this message translates to:
  /// **'Released'**
  String get cardFieldReleased;

  /// Value on a card when the fish was kept.
  ///
  /// In en, this message translates to:
  /// **'Kept'**
  String get cardFieldKept;

  /// Field label on a card: released or kept.
  ///
  /// In en, this message translates to:
  /// **'Fate'**
  String get cardFieldFate;

  /// Title of the trip version of the tag card: a field register listing the catches.
  ///
  /// In en, this message translates to:
  /// **'Field log'**
  String get cardFieldLog;

  /// Label next to the gold mark of the previous personal best on the ruler card.
  ///
  /// In en, this message translates to:
  /// **'previous best {measure}'**
  String cardPreviousRecord(String measure);

  /// A new personal record with how much it beat the previous one, e.g. '+14%'.
  ///
  /// In en, this message translates to:
  /// **'Personal best, {improvement}'**
  String cardRecordImprovement(String improvement);

  /// A new personal record without an earlier measure to compare.
  ///
  /// In en, this message translates to:
  /// **'Personal best'**
  String get cardRecord;

  /// The user's first catch of this species.
  ///
  /// In en, this message translates to:
  /// **'First of the species'**
  String get cardFirstOfSpecies;

  /// How many catches of a trip were personal records.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 personal best} other{{count} personal bests}}'**
  String cardRecordCount(int count);

  /// Unit printed at the end of the trip's time board (hours).
  ///
  /// In en, this message translates to:
  /// **'h'**
  String get cardHoursUnit;

  /// Last line of a trip card when not all catches fit.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{and 1 more} other{and {count} more}}'**
  String cardMoreCatches(int count);

  /// Button/tooltip that opens the card editor.
  ///
  /// In en, this message translates to:
  /// **'Create card'**
  String get cardCreate;

  /// Card style: a fish measuring board.
  ///
  /// In en, this message translates to:
  /// **'Board'**
  String get cardStyleBoard;

  /// Card style: a nautical chart.
  ///
  /// In en, this message translates to:
  /// **'Chart'**
  String get cardStyleChart;

  /// Card style: a museum specimen tag.
  ///
  /// In en, this message translates to:
  /// **'Tag'**
  String get cardStyleTag;

  /// Card format 9:16 (stories).
  ///
  /// In en, this message translates to:
  /// **'Story'**
  String get cardFormatStory;

  /// Card format 1:1 (feed post).
  ///
  /// In en, this message translates to:
  /// **'Square'**
  String get cardFormatSquare;

  /// Switch in the card editor.
  ///
  /// In en, this message translates to:
  /// **'Show place'**
  String get cardShowPlace;

  /// Card editor note when the trip's privacy hides the place.
  ///
  /// In en, this message translates to:
  /// **'This trip is private: cards never show where it was.'**
  String get cardPlacePrivate;

  /// Card editor note for approximate privacy.
  ///
  /// In en, this message translates to:
  /// **'Only the region is shown, never the spot.'**
  String get cardPlaceRegion;

  /// Card editor note when there is no place text to show.
  ///
  /// In en, this message translates to:
  /// **'No place name saved for this trip.'**
  String get cardPlaceUnknown;

  /// Button that exports the card image and opens the share sheet.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get cardShare;

  /// Error when exporting a card fails.
  ///
  /// In en, this message translates to:
  /// **'Could not create the image. Try again.'**
  String get cardShareFailed;

  /// Screen reader label for the card preview.
  ///
  /// In en, this message translates to:
  /// **'Card preview: {style}, {format}'**
  String cardPreviewLabel(String style, String format);

  /// Generic close button tooltip.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get actionClose;

  /// Title of the summary shown right after finishing a trip.
  ///
  /// In en, this message translates to:
  /// **'Trip finished'**
  String get summaryTitle;

  /// Section with the personal records set on this trip.
  ///
  /// In en, this message translates to:
  /// **'Personal bests'**
  String get summaryRecords;

  /// The bait with the most catches on this trip.
  ///
  /// In en, this message translates to:
  /// **'Best bait: {bait}'**
  String summaryTopBait(String bait);

  /// A record catch in the trip summary, e.g. 'Dourado, 72 cm'.
  ///
  /// In en, this message translates to:
  /// **'{species}, {measure}'**
  String summaryRecordLine(String species, String measure);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
