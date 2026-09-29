import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatting/formatters_provider.dart';
import '../../../core/formatting/l10n.dart';
import '../../../core/locale.dart';
import '../../../core/providers.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/choice_sheet.dart';
import '../../../core/widgets/section_label.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/services/units.dart';
import '../application/data_controller.dart';
import '../application/preferences.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  /// Value used in the language sheet for "follow the device".
  static const _deviceLanguage = '';

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final failed = context.l10n.settingsExportFailed;
    try {
      await ref.read(dataControllerProvider).exportAndShare();
    } on Exception {
      messenger.showSnackBar(SnackBar(content: Text(failed)));
    }
  }

  Future<void> _wipe(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.wipeTitle),
        content: Text(l10n.wipeBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.wipeConfirm),
          ),
        ],
      ),
    );
    if (ok != true) return;
    PaintingBinding.instance.imageCache.clear();
    // Settings are gone too: the router sends the app back to onboarding.
    await ref.read(dataControllerProvider).wipeAll();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final f = context.formatters(ref);
    final settings = ref.watch(settingsProvider).value;
    final chosenLanguage = settings?.languageCode;
    final deviceLanguage = ref.watch(deviceLanguageProvider);
    final units = ref.watch(unitSystemProvider);
    final privacy = settings?.defaultPrivacy ?? PrivacyLevel.private;
    final prefs = ref.read(preferencesControllerProvider);

    final languageLabel = chosenLanguage == null
        ? l10n.settingsLanguageDevice(languageNames[deviceLanguage]!)
        : languageNames[chosenLanguage]!;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                PiscatioSizes.gutter,
                24,
                PiscatioSizes.gutter,
                0,
              ),
              child: Semantics(
                header: true,
                child: Text(
                  l10n.navSettings,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ),
            ),
            SectionLabel(l10n.settingsSectionPreferences),
            ListTile(
              leading: const Icon(Icons.translate_rounded),
              title: Text(l10n.settingsLanguage),
              subtitle: Text(languageLabel),
              onTap: () async {
                final picked = await showChoiceSheet<String>(
                  context: context,
                  title: l10n.settingsLanguage,
                  selected: chosenLanguage ?? _deviceLanguage,
                  choices: [
                    Choice(
                      _deviceLanguage,
                      l10n.settingsLanguageDevice(
                        languageNames[deviceLanguage]!,
                      ),
                    ),
                    for (final e in languageNames.entries)
                      Choice(e.key, e.value),
                  ],
                );
                if (picked == null) return;
                await prefs.chooseLanguage(
                  picked == _deviceLanguage ? null : picked,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.straighten_rounded),
              title: Text(l10n.settingsUnits),
              subtitle: Text(
                l10n.settingsUnitsValue(
                  f.unitSystemName(units),
                  f.unitSystemExample(units),
                ),
              ),
              onTap: () async {
                final picked = await showChoiceSheet<UnitSystem>(
                  context: context,
                  title: l10n.settingsUnits,
                  selected: units,
                  choices: [
                    for (final u in UnitSystem.values)
                      Choice(
                        u,
                        f.unitSystemName(u),
                        description: f.unitSystemExample(u),
                      ),
                  ],
                );
                if (picked != null) await prefs.chooseUnits(picked);
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: Text(l10n.settingsDefaultPrivacy),
              subtitle: Text(f.privacyLevel(privacy)),
              onTap: () async {
                final picked = await showChoiceSheet<PrivacyLevel>(
                  context: context,
                  title: l10n.settingsDefaultPrivacy,
                  selected: privacy,
                  choices: [
                    for (final p in PrivacyLevel.values)
                      Choice(
                        p,
                        f.privacyLevel(p),
                        description: f.privacyDescription(p),
                      ),
                  ],
                );
                if (picked != null) await prefs.chooseDefaultPrivacy(picked);
              },
            ),
            SectionLabel(l10n.settingsSectionTackle),
            ListTile(
              leading: const Icon(Icons.set_meal_outlined),
              title: Text(l10n.tackleBaits),
              subtitle: Text(
                l10n.settingsBaitsCount(
                  (ref.watch(baitsProvider).value ?? const []).length,
                ),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push(AppRoutes.baits),
            ),
            ListTile(
              leading: const Icon(Icons.phishing_outlined),
              title: Text(l10n.tackleGear),
              subtitle: Text(
                l10n.settingsGearCount(
                  (ref.watch(gearProvider).value ?? const []).length,
                ),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push(AppRoutes.gear),
            ),
            SectionLabel(l10n.settingsSectionData),
            ListTile(
              leading: const Icon(Icons.file_download_outlined),
              title: Text(l10n.settingsExport),
              subtitle: Text(l10n.settingsExportHint),
              onTap: () => _export(context, ref),
            ),
            ListTile(
              leading: Icon(
                Icons.delete_forever_outlined,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                l10n.settingsWipe,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              subtitle: Text(l10n.settingsWipeHint),
              onTap: () => _wipe(context, ref),
            ),
            SectionLabel(l10n.settingsSectionAbout),
            ListTile(
              leading: const Icon(Icons.cloud_outlined),
              title: Text(l10n.settingsWeatherData),
              subtitle: Text(l10n.settingsWeatherDataCredit),
            ),
            ListTile(
              leading: const Icon(Icons.map_outlined),
              title: Text(l10n.settingsMapData),
              subtitle: Text(l10n.settingsMapDataCredit),
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: Text(l10n.settingsLicenses),
              onTap: () => showLicensePage(
                context: context,
                applicationName: l10n.appTitle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
