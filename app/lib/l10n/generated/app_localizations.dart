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
