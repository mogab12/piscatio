import 'package:freezed_annotation/freezed_annotation.dart';

import '../services/units.dart';
import 'enums.dart';

part 'app_settings.freezed.dart';

@freezed
abstract class AppSettings with _$AppSettings {
  const factory AppSettings({
    /// Language code chosen by the user; null follows the device.
    String? languageCode,

    /// Null means "derive from the device region".
    UnitSystem? unitSystem,
    @Default(PrivacyLevel.private) PrivacyLevel defaultPrivacy,
    @Default(false) bool onboardingCompleted,
  }) = _AppSettings;
}
