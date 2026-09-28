import 'package:flutter/widgets.dart';

import '../l10n/generated/app_localizations.dart';

const fallbackLocale = Locale('en');

/// Picks the app locale: the user's explicit choice, else the first device
/// language we support, else English.
Locale resolveAppLocale({
  required String? chosenLanguage,
  required List<Locale> deviceLocales,
}) {
  final supported = AppLocalizations.supportedLocales
      .map((l) => l.languageCode)
      .toSet();
  if (chosenLanguage != null && supported.contains(chosenLanguage)) {
    return Locale(chosenLanguage);
  }
  for (final device in deviceLocales) {
    if (supported.contains(device.languageCode)) {
      return Locale(device.languageCode);
    }
  }
  return fallbackLocale;
}

/// Languages offered in settings, each shown in its own language.
const languageNames = <String, String>{
  'pt': 'Português (Brasil)',
  'en': 'English',
  'es': 'Español',
};
