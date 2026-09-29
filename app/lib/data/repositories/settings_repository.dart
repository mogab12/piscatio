import 'dart:convert';
import 'dart:math';

import '../../domain/models/app_settings.dart';
import '../../domain/models/enums.dart';
import '../../domain/services/units.dart';
import '../db/app_database.dart';

abstract final class SettingKeys {
  static const language = 'language';
  static const unitSystem = 'unit_system';
  static const defaultPrivacy = 'default_privacy';
  static const onboardingCompleted = 'onboarding_completed';
  static const privacySecret = 'privacy_secret';
  static const speciesSeedVersion = 'species_seed_version';
}

class SettingsRepository {
  SettingsRepository(this._db, {Random? random})
    : _random = random ?? Random.secure();

  final AppDatabase _db;
  final Random _random;

  Stream<AppSettings> watch() =>
      _db.select(_db.settings).watch().map(_toSettings);

  Future<AppSettings> read() async =>
      _toSettings(await _db.select(_db.settings).get());

  static AppSettings _toSettings(List<SettingRow> rows) {
    final map = {for (final r in rows) r.key: r.value};
    return AppSettings(
      languageCode: map[SettingKeys.language],
      unitSystem: UnitSystem.values.asNameMap()[map[SettingKeys.unitSystem]],
      defaultPrivacy:
          PrivacyLevel.values.asNameMap()[map[SettingKeys.defaultPrivacy]] ??
          PrivacyLevel.private,
      onboardingCompleted: map[SettingKeys.onboardingCompleted] == 'true',
    );
  }

  Future<void> setLanguage(String? languageCode) =>
      _put(SettingKeys.language, languageCode);

  Future<void> setUnitSystem(UnitSystem system) =>
      _put(SettingKeys.unitSystem, system.name);

  Future<void> setDefaultPrivacy(PrivacyLevel level) =>
      _put(SettingKeys.defaultPrivacy, level.name);

  Future<void> completeOnboarding() =>
      _put(SettingKeys.onboardingCompleted, 'true');

  /// Per-install secret for the approximate-location offset. Created on
  /// first use and never shown or exported.
  Future<List<int>> privacySecret() async {
    final stored = await getRaw(SettingKeys.privacySecret);
    if (stored != null) return base64Decode(stored);
    final secret = List<int>.generate(32, (_) => _random.nextInt(256));
    await _put(SettingKeys.privacySecret, base64Encode(secret));
    return secret;
  }

  Future<String?> getRaw(String key) async {
    final row = await (_db.select(
      _db.settings,
    )..where((s) => s.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> setRaw(String key, String value) => _put(key, value);

  Future<void> remove(String key) => _put(key, null);

  /// Adopts the account's secret (shared by all the person's devices).
  Future<void> setPrivacySecret(List<int> secret) =>
      _put(SettingKeys.privacySecret, base64Encode(secret));

  Future<void> _put(String key, String? value) async {
    if (value == null) {
      await (_db.delete(_db.settings)..where((s) => s.key.equals(key))).go();
      return;
    }
    await _db
        .into(_db.settings)
        .insertOnConflictUpdate(
          SettingsCompanion.insert(key: key, value: value),
        );
  }
}
