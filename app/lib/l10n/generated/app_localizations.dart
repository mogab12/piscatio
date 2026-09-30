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

  /// Settings > About: credit for the weather data sources.
  ///
  /// In en, this message translates to:
  /// **'Past trips: NASA POWER Project, NASA Langley Research Center. Weather now: MET Norway. Both CC BY 4.0.'**
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

  /// Boot screen: the database is being opened.
  ///
  /// In en, this message translates to:
  /// **'Opening your logbook…'**
  String get bootStepDatabase;

  /// Boot screen: the species catalog is being loaded.
  ///
  /// In en, this message translates to:
  /// **'Loading the species…'**
  String get bootStepCatalog;

  /// Boot screen: shown when startup takes too long.
  ///
  /// In en, this message translates to:
  /// **'This is taking longer than usual.'**
  String get bootSlow;

  /// Boot screen title when startup fails.
  ///
  /// In en, this message translates to:
  /// **'The app could not open'**
  String get bootFailedTitle;

  /// Boot screen text when startup fails, above the error details.
  ///
  /// In en, this message translates to:
  /// **'Take a screenshot of this screen and send it to us. Your data stays on the phone.'**
  String get bootFailedBody;

  /// Boot screen button to retry startup.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get bootRetry;

  /// Boot screen button that copies the error details.
  ///
  /// In en, this message translates to:
  /// **'Copy details'**
  String get bootCopyDetails;

  /// Tagline under the app name on cards and in the brand lockup.
  ///
  /// In en, this message translates to:
  /// **'Fishing log'**
  String get brandTagline;

  /// Card editor tab: style and format.
  ///
  /// In en, this message translates to:
  /// **'Style'**
  String get cardSectionStyle;

  /// Card editor tab: which photo the card uses.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get cardSectionPhoto;

  /// Card editor tab: which details the card shows.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get cardSectionDetails;

  /// Card editor tab: an optional text written by the user.
  ///
  /// In en, this message translates to:
  /// **'Caption'**
  String get cardSectionCaption;

  /// Card editor option to make the card without a photo.
  ///
  /// In en, this message translates to:
  /// **'No photo'**
  String get cardNoPhoto;

  /// Card editor photo tab when the trip or catch has no photos.
  ///
  /// In en, this message translates to:
  /// **'No photos to use on the card.'**
  String get cardNoPhotos;

  /// Screen reader label of a photo thumbnail in the card editor.
  ///
  /// In en, this message translates to:
  /// **'Photo {number}'**
  String cardPhotoOption(String number);

  /// Card editor switch: show weather and moon on the card.
  ///
  /// In en, this message translates to:
  /// **'Weather and moon'**
  String get cardShowWeather;

  /// Card editor switch: show the bait on the card.
  ///
  /// In en, this message translates to:
  /// **'Bait'**
  String get cardShowBait;

  /// Hint of the caption field in the card editor.
  ///
  /// In en, this message translates to:
  /// **'Write a caption (optional)'**
  String get cardCaptionHint;

  /// Field label on the tag card for the user's caption.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get cardFieldNotes;

  /// Bottom navigation tab: logbook statistics.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get navStats;

  /// Title of the statistics screen.
  ///
  /// In en, this message translates to:
  /// **'Your numbers'**
  String get statsTitle;

  /// Statistics screen with no trips yet.
  ///
  /// In en, this message translates to:
  /// **'Your numbers show up after your first trip.'**
  String get statsEmpty;

  /// Label under the number of trips.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{trip} other{trips}}'**
  String statsTripsLabel(int count);

  /// Share of catches released, e.g. '65% released'.
  ///
  /// In en, this message translates to:
  /// **'{percent} released'**
  String statsReleased(String percent);

  /// Catches per hour fished, e.g. '0.8 per hour fished'.
  ///
  /// In en, this message translates to:
  /// **'{rate} per hour fished'**
  String statsPerHour(String rate);

  /// Title of the chart of catches per hour of the day.
  ///
  /// In en, this message translates to:
  /// **'Catches by time of day'**
  String get statsByHourTitle;

  /// Summary under the hour chart.
  ///
  /// In en, this message translates to:
  /// **'Most catches between {start} and {end}'**
  String statsPeakHour(String start, String end);

  /// Screen reader label of one bar of the hour chart.
  ///
  /// In en, this message translates to:
  /// **'{time}: {count, plural, =1{1 catch} other{{count} catches}}'**
  String statsHourBar(String time, int count);

  /// Statistics section title.
  ///
  /// In en, this message translates to:
  /// **'Most caught species'**
  String get statsSpeciesTitle;

  /// Statistics section title.
  ///
  /// In en, this message translates to:
  /// **'Baits that catch the most'**
  String get statsBaitsTitle;

  /// Statistics section title.
  ///
  /// In en, this message translates to:
  /// **'Personal bests'**
  String get statsRecordsTitle;

  /// Statistics section title: the trip with the most catches.
  ///
  /// In en, this message translates to:
  /// **'Best trip'**
  String get statsBestTrip;

  /// The best trip's date and catch count.
  ///
  /// In en, this message translates to:
  /// **'{date}: {count, plural, =1{1 catch} other{{count} catches}}'**
  String statsBestTripValue(String date, int count);

  /// Number of catches next to a species or bait.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 catch} other{{count} catches}}'**
  String statsCount(int count);

  /// Title of the bait list screen.
  ///
  /// In en, this message translates to:
  /// **'Baits'**
  String get tackleBaits;

  /// Title of the gear list screen.
  ///
  /// In en, this message translates to:
  /// **'Gear'**
  String get tackleGear;

  /// Dialog title when editing a bait.
  ///
  /// In en, this message translates to:
  /// **'Edit bait'**
  String get tackleEditBait;

  /// Dialog title when editing gear.
  ///
  /// In en, this message translates to:
  /// **'Edit gear'**
  String get tackleEditGear;

  /// Action that archives a bait or gear.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get tackleArchive;

  /// Action that brings an archived bait or gear back.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get tackleRestore;

  /// Section with archived baits or gear.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get tackleArchived;

  /// Explains what archiving does.
  ///
  /// In en, this message translates to:
  /// **'They stay on older catches, but leave the pickers.'**
  String get tackleArchivedNote;

  /// Empty bait list.
  ///
  /// In en, this message translates to:
  /// **'No baits yet. Add the ones you use most.'**
  String get tackleEmptyBaits;

  /// Empty gear list.
  ///
  /// In en, this message translates to:
  /// **'No gear yet. Add your rods, reels and lines.'**
  String get tackleEmptyGear;

  /// Settings section.
  ///
  /// In en, this message translates to:
  /// **'Baits and gear'**
  String get settingsSectionTackle;

  /// Settings row subtitle: how many active baits.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{None yet} =1{1 bait} other{{count} baits}}'**
  String settingsBaitsCount(int count);

  /// Settings row subtitle: how many active gear items.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{None yet} =1{1 item} other{{count} items}}'**
  String settingsGearCount(int count);

  /// Settings section.
  ///
  /// In en, this message translates to:
  /// **'Your data'**
  String get settingsSectionData;

  /// Settings action that shares a JSON file with everything logged.
  ///
  /// In en, this message translates to:
  /// **'Export data'**
  String get settingsExport;

  /// Subtitle of the export action.
  ///
  /// In en, this message translates to:
  /// **'A JSON file with your trips, catches and baits. Photos stay on the phone.'**
  String get settingsExportHint;

  /// Error when exporting fails.
  ///
  /// In en, this message translates to:
  /// **'Could not export. Try again.'**
  String get settingsExportFailed;

  /// Settings action that deletes everything.
  ///
  /// In en, this message translates to:
  /// **'Delete all data'**
  String get settingsWipe;

  /// Subtitle of the delete-all action.
  ///
  /// In en, this message translates to:
  /// **'Trips, catches, photos and baits. This can\'t be undone.'**
  String get settingsWipeHint;

  /// Title of the delete-all confirmation.
  ///
  /// In en, this message translates to:
  /// **'Delete all data?'**
  String get wipeTitle;

  /// Body of the delete-all confirmation.
  ///
  /// In en, this message translates to:
  /// **'Everything you logged leaves this phone: trips, catches, photos, baits and settings. Export first if you want to keep a copy.'**
  String get wipeBody;

  /// Confirm button of the delete-all dialog.
  ///
  /// In en, this message translates to:
  /// **'Delete everything'**
  String get wipeConfirm;

  /// Button that opens the form for a trip that already happened.
  ///
  /// In en, this message translates to:
  /// **'Log a past trip'**
  String get pastTripAction;

  /// Title of the past trip form.
  ///
  /// In en, this message translates to:
  /// **'Past trip'**
  String get pastTripTitle;

  /// Section title in the past trip form.
  ///
  /// In en, this message translates to:
  /// **'Trip photos'**
  String get pastTripPhotos;

  /// Explains what photos do in the past trip form.
  ///
  /// In en, this message translates to:
  /// **'Each photo becomes a catch. Their date and place suggest the trip\'s.'**
  String get pastTripPhotosHint;

  /// Button to add a photo to a past trip.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get pastTripAddPhoto;

  /// Note when the form was filled from photo metadata.
  ///
  /// In en, this message translates to:
  /// **'Date and place suggested by the photos.'**
  String get pastTripSuggested;

  /// Save button of the past trip form.
  ///
  /// In en, this message translates to:
  /// **'Save trip'**
  String get pastTripSave;

  /// Error when importing a photo fails.
  ///
  /// In en, this message translates to:
  /// **'Could not read this photo. Try another one.'**
  String get pastTripPhotoFailed;

  /// Button that opens the place search.
  ///
  /// In en, this message translates to:
  /// **'Search a place by name'**
  String get placeSearchAction;

  /// Hint of the place search field.
  ///
  /// In en, this message translates to:
  /// **'Lake, river, town…'**
  String get placeSearchHint;

  /// Place search without results.
  ///
  /// In en, this message translates to:
  /// **'No place found with that name.'**
  String get placeSearchEmpty;

  /// Place search error.
  ///
  /// In en, this message translates to:
  /// **'No connection to search. Try again.'**
  String get placeSearchFailed;

  /// Shown in the trip form when a searched place set the location.
  ///
  /// In en, this message translates to:
  /// **'Place marked on the map'**
  String get placeSearchPointSaved;

  /// Card editor tab: the card's color theme (recolors the whole card).
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get cardSectionTheme;

  /// Card theme named after the red-head fishing lure (the brand colors: red over deep water).
  ///
  /// In en, this message translates to:
  /// **'Red head'**
  String get cardThemeRedHead;

  /// Card theme: light logbook paper with dark ink.
  ///
  /// In en, this message translates to:
  /// **'Paper'**
  String get cardThemePaper;

  /// Card theme named after the peacock bass (tucunaré): olive, gold and red.
  ///
  /// In en, this message translates to:
  /// **'Peacock bass'**
  String get cardThemeTucunare;

  /// Card theme: warm light colors of sunrise on the water.
  ///
  /// In en, this message translates to:
  /// **'Dawn'**
  String get cardThemeDawn;

  /// Card theme: night fishing, dark blue with moonlight.
  ///
  /// In en, this message translates to:
  /// **'Moon'**
  String get cardThemeMoon;

  /// Card theme: river green with a chartreuse lure accent.
  ///
  /// In en, this message translates to:
  /// **'River'**
  String get cardThemeRiver;

  /// Photo filter option: the photo as taken.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get cardFilterNone;

  /// Photo filter: the photo in two colors of the card theme.
  ///
  /// In en, this message translates to:
  /// **'Duotone'**
  String get cardFilterDuotone;

  /// Photo filter: engraved lines, like an old field guide illustration.
  ///
  /// In en, this message translates to:
  /// **'Engraving'**
  String get cardFilterEngraving;

  /// Photo filter: printed dots, like a magazine.
  ///
  /// In en, this message translates to:
  /// **'Halftone'**
  String get cardFilterHalftone;

  /// Screen reader label while a photo filter is being applied.
  ///
  /// In en, this message translates to:
  /// **'Applying the filter'**
  String get cardFilterWorking;

  /// Snackbar when a photo filter fails.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t apply the filter to this photo.'**
  String get cardFilterFailed;

  /// Unit symbol: kilometer.
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get unitKilometer;

  /// Unit symbol: mile (distance).
  ///
  /// In en, this message translates to:
  /// **'mi'**
  String get unitMile;

  /// Card style: a stylized map of the fishing area.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get cardStyleMap;

  /// Card editor toggle: show the stylized map of the place.
  ///
  /// In en, this message translates to:
  /// **'Map of the place'**
  String get cardShowMap;

  /// Card editor note: why there is no map.
  ///
  /// In en, this message translates to:
  /// **'Private trips never show a map.'**
  String get cardMapPrivate;

  /// Card editor note: map data not downloaded yet.
  ///
  /// In en, this message translates to:
  /// **'The map arrives once the phone is online.'**
  String get cardMapPending;

  /// Card editor note: no water features near the place.
  ///
  /// In en, this message translates to:
  /// **'OpenStreetMap has no water mapped around here.'**
  String get cardMapEmpty;

  /// Card editor note: the trip has no location, so no map.
  ///
  /// In en, this message translates to:
  /// **'This trip has no place.'**
  String get cardMapNoPlace;

  /// Card editor note explaining the map's ring.
  ///
  /// In en, this message translates to:
  /// **'The circle marks the area, never the exact spot.'**
  String get cardMapArea;

  /// Required credit printed on every map (ODbL license).
  ///
  /// In en, this message translates to:
  /// **'© OpenStreetMap contributors'**
  String get mapAttribution;

  /// Settings: title of the map data credit.
  ///
  /// In en, this message translates to:
  /// **'Map data'**
  String get settingsMapData;

  /// Settings: map data credit and license.
  ///
  /// In en, this message translates to:
  /// **'© OpenStreetMap contributors, available under the Open Database License (ODbL).'**
  String get settingsMapDataCredit;

  /// Card style: the catch on the cover of a fishing magazine named after the app.
  ///
  /// In en, this message translates to:
  /// **'Cover'**
  String get cardStyleCover;

  /// Settings section heading for the sign-in account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsSectionAccount;

  /// Settings: subtitle of the sign-in row when signed out.
  ///
  /// In en, this message translates to:
  /// **'Back up your logbook and use it on another phone'**
  String get settingsSignInHint;

  /// Title of the account screen.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountTitle;

  /// Account screen: explanation shown when signed out.
  ///
  /// In en, this message translates to:
  /// **'Sign in to keep your logbook and photos on the server and see them on your other phones. Without an account everything keeps working on this phone.'**
  String get accountIntro;

  /// Account screen: email field label.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get accountEmail;

  /// Account screen: button that emails a sign-in code.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get accountSendCode;

  /// Account screen: shown after the sign-in code was emailed.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to {email}. It is valid for 10 minutes.'**
  String accountCodeSent(String email);

  /// Account screen: sign-in code field label.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get accountCode;

  /// Sign-in action (settings row and account screen button).
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get accountSignIn;

  /// Account screen: go back to the email step.
  ///
  /// In en, this message translates to:
  /// **'Use another email'**
  String get accountChangeEmail;

  /// Account screen: email a new sign-in code.
  ///
  /// In en, this message translates to:
  /// **'Send a new code'**
  String get accountResendCode;

  /// Account screen: advanced section with the server address.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get accountServer;

  /// Account screen: helper under the server address field.
  ///
  /// In en, this message translates to:
  /// **'Only change this if you run your own Piscatio server.'**
  String get accountServerHint;

  /// Account screen: error when the server address is not valid.
  ///
  /// In en, this message translates to:
  /// **'Enter an address that starts with https://'**
  String get accountServerInvalid;

  /// Account screen: the sign-in code is wrong.
  ///
  /// In en, this message translates to:
  /// **'Wrong code. Check the email and try again.'**
  String get accountErrorCodeWrong;

  /// Account screen: the sign-in code expired.
  ///
  /// In en, this message translates to:
  /// **'This code has expired. Ask for a new one.'**
  String get accountErrorCodeExpired;

  /// Account screen: the server refused the email address.
  ///
  /// In en, this message translates to:
  /// **'Check the email address.'**
  String get accountErrorEmailInvalid;

  /// Account screen: the server is limiting requests.
  ///
  /// In en, this message translates to:
  /// **'Too many tries. Wait a few minutes.'**
  String get accountErrorTooMany;

  /// Account screen: the server could not be reached.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the server. Check your connection and try again.'**
  String get accountErrorOffline;

  /// Account status: last sync happened today.
  ///
  /// In en, this message translates to:
  /// **'Synced today at {time}'**
  String accountSyncedToday(String time);

  /// Account status: last sync happened on another day.
  ///
  /// In en, this message translates to:
  /// **'Synced on {date} at {time}'**
  String accountSyncedOn(String date, String time);

  /// Account status: no sync has finished yet.
  ///
  /// In en, this message translates to:
  /// **'Not synced yet'**
  String get accountNeverSynced;

  /// Account status: a sync is about to run.
  ///
  /// In en, this message translates to:
  /// **'Syncing now'**
  String get accountSyncSoon;

  /// Account status: the last sync failed and will be retried.
  ///
  /// In en, this message translates to:
  /// **'No connection to the server. It will try again by itself.'**
  String get accountSyncRetrying;

  /// Account screen: button that syncs right away.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get accountSyncNow;

  /// Account screen: what the server keeps about locations.
  ///
  /// In en, this message translates to:
  /// **'The server keeps the exact spot so your phones can show it. Nobody else sees it: cards follow each trip\'s privacy.'**
  String get accountPrivacyNote;

  /// Account screen: sign out action.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get accountSignOut;

  /// Account screen: subtitle of the sign out action.
  ///
  /// In en, this message translates to:
  /// **'Your logbook stays on this phone.'**
  String get accountSignOutHint;

  /// Account screen: delete account action and its confirm button.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get accountDelete;

  /// Account screen: subtitle of the delete account action.
  ///
  /// In en, this message translates to:
  /// **'Erases the account and the copy on the server.'**
  String get accountDeleteHint;

  /// Delete account dialog title.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get accountDeleteTitle;

  /// Delete account dialog text.
  ///
  /// In en, this message translates to:
  /// **'The server erases the account, the trips and the photos. The logbook on this phone and on your other phones stays. This cannot be undone.'**
  String get accountDeleteBody;

  /// Snackbar after the account was deleted.
  ///
  /// In en, this message translates to:
  /// **'Account deleted'**
  String get accountDeleted;

  /// Delete all data dialog: extra line shown when signed in.
  ///
  /// In en, this message translates to:
  /// **'You will be signed out. The copy on the server stays: to erase it, delete the account.'**
  String get wipeSignedInNote;

  /// Active trip: heading of the current weather row.
  ///
  /// In en, this message translates to:
  /// **'Weather now'**
  String get liveWeatherTitle;

  /// Active trip: credit under the current weather (required by MET Norway).
  ///
  /// In en, this message translates to:
  /// **'Data: MET Norway'**
  String get liveWeatherSource;

  /// Current weather: rain expected in the next hour.
  ///
  /// In en, this message translates to:
  /// **'Rain next hour'**
  String get liveWeatherRainNextHour;

  /// Stats: heading of the section with patterns in the person's fishing.
  ///
  /// In en, this message translates to:
  /// **'What worked'**
  String get insightsTitle;

  /// Stats: shown in 'What worked' when there is not enough data.
  ///
  /// In en, this message translates to:
  /// **'No patterns yet. They show up here when something repeats: at least 3 catches over 2 trips.'**
  String get insightsEmpty;

  /// What worked: a 3-hour window of the day, e.g. 'Between 06:00 and 09:00'.
  ///
  /// In en, this message translates to:
  /// **'Between {start} and {end}'**
  String insightsHours(String start, String end);

  /// What worked: catches per hour fished under a condition vs the person's average.
  ///
  /// In en, this message translates to:
  /// **'{rate} fish per hour. Your average is {average}.'**
  String insightsRate(String rate, String average);

  /// What worked: moon group.
  ///
  /// In en, this message translates to:
  /// **'New moon'**
  String get insightsMoonNew;

  /// What worked: moon group (from new to full).
  ///
  /// In en, this message translates to:
  /// **'Waxing moon'**
  String get insightsMoonWaxing;

  /// What worked: moon group.
  ///
  /// In en, this message translates to:
  /// **'Full moon'**
  String get insightsMoonFull;

  /// What worked: moon group (from full to new).
  ///
  /// In en, this message translates to:
  /// **'Waning moon'**
  String get insightsMoonWaning;

  /// What worked: the bait that took most catches of a species.
  ///
  /// In en, this message translates to:
  /// **'{species} on {bait}'**
  String insightsBait(String species, String bait);

  /// What worked: how many of the species' catches (with a bait recorded) came on that bait.
  ///
  /// In en, this message translates to:
  /// **'{count} of {total} catches with a bait noted'**
  String insightsBaitDetail(int count, int total);

  /// Card photo filter: the catch painted in ochre and charcoal on stone, like a cave painting. Colors follow the card theme.
  ///
  /// In en, this message translates to:
  /// **'Cave art'**
  String get cardFilterRupestre;

  /// Card editor tab: zoom and position of the photo and the map.
  ///
  /// In en, this message translates to:
  /// **'Frame'**
  String get cardSectionFrame;

  /// Card editor, Frame tab: how to frame with gestures.
  ///
  /// In en, this message translates to:
  /// **'Drag and pinch the photo or the map on the card.'**
  String get cardFrameHint;

  /// Card editor, Frame tab: slider label.
  ///
  /// In en, this message translates to:
  /// **'Photo zoom'**
  String get cardFramePhoto;

  /// Card editor, Frame tab: slider label.
  ///
  /// In en, this message translates to:
  /// **'Map zoom'**
  String get cardFrameMap;

  /// Card editor, Frame tab: put the photo and the map back as they were.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get cardFrameReset;

  /// Card editor, Frame tab: shown when there is nothing to frame.
  ///
  /// In en, this message translates to:
  /// **'This card has no photo or map to frame.'**
  String get cardFrameNothing;

  /// Card editor, Theme tab: switch that paints the photo and its filter in the theme's colors.
  ///
  /// In en, this message translates to:
  /// **'Theme colors on the photo'**
  String get cardThemePhoto;

  /// Trip: the business (pay lake, lodge, guide…) where the trip happened.
  ///
  /// In en, this message translates to:
  /// **'Fishing venue'**
  String get venueField;

  /// Venue picker: no venue for this trip.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get venueNone;

  /// Venue picker: search field hint.
  ///
  /// In en, this message translates to:
  /// **'Search by name or city'**
  String get venueSearchHint;

  /// Venue picker: heading of the results around the trip's area.
  ///
  /// In en, this message translates to:
  /// **'Near this trip'**
  String get venueNearby;

  /// Venue picker: empty results.
  ///
  /// In en, this message translates to:
  /// **'No venues found.'**
  String get venueNoResults;

  /// Venue picker: shown when signed out.
  ///
  /// In en, this message translates to:
  /// **'Sign in to find venues.'**
  String get venueSignIn;

  /// Venue: checked by the Piscatio team (label of the badge icon).
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get venueVerified;

  /// Venue kind.
  ///
  /// In en, this message translates to:
  /// **'Pay lake'**
  String get venueKindPayLake;

  /// Venue kind.
  ///
  /// In en, this message translates to:
  /// **'Lodge'**
  String get venueKindLodge;

  /// Venue kind.
  ///
  /// In en, this message translates to:
  /// **'Guide'**
  String get venueKindGuide;

  /// Venue kind.
  ///
  /// In en, this message translates to:
  /// **'Tackle shop'**
  String get venueKindShop;

  /// Venue kind.
  ///
  /// In en, this message translates to:
  /// **'Marina'**
  String get venueKindMarina;

  /// Venue kind.
  ///
  /// In en, this message translates to:
  /// **'Fishing boat'**
  String get venueKindCharter;

  /// Venue kind.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get venueKindOther;

  /// Account: consent switch to share anonymous totals with venues where the person fishes.
  ///
  /// In en, this message translates to:
  /// **'Help venues with anonymous numbers'**
  String get accountShareInsights;

  /// Account: explanation under the insights consent switch.
  ///
  /// In en, this message translates to:
  /// **'Venues where you fish see totals such as species and best hours, only from 10 or more anglers. Never your name or your spots.'**
  String get accountShareInsightsHint;
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
