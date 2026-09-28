import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/locale.dart';
import '../../../core/providers.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/services/units.dart';

/// Language the app shows right now (explicit choice or device).
final effectiveLanguageProvider = Provider<String>((ref) {
  final chosen = ref.watch(settingsProvider).value?.languageCode;
  return resolveAppLocale(
    chosenLanguage: chosen,
    deviceLocales: ref.watch(deviceLocalesProvider),
  ).languageCode;
});

/// Language the device alone would give us.
final deviceLanguageProvider = Provider<String>(
  (ref) => resolveAppLocale(
    chosenLanguage: null,
    deviceLocales: ref.watch(deviceLocalesProvider),
  ).languageCode,
);

class PreferencesController {
  PreferencesController(this._ref);

  final Ref _ref;

  /// Stores null when the choice equals the device language, so the app
  /// keeps following the device if it changes later.
  Future<void> chooseLanguage(String? code) {
    final device = _ref.read(deviceLanguageProvider);
    return _ref
        .read(settingsRepositoryProvider)
        .setLanguage(code == device ? null : code);
  }

  Future<void> chooseUnits(UnitSystem system) =>
      _ref.read(settingsRepositoryProvider).setUnitSystem(system);

  Future<void> chooseDefaultPrivacy(PrivacyLevel level) =>
      _ref.read(settingsRepositoryProvider).setDefaultPrivacy(level);
}

final preferencesControllerProvider = Provider(PreferencesController.new);
