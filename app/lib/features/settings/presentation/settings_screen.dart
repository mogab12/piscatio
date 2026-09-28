import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatting/formatters_provider.dart';
import '../../../core/formatting/l10n.dart';
import '../../../core/locale.dart';
import '../../../core/providers.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/choice_sheet.dart';
import '../../../core/widgets/section_label.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/services/units.dart';
import '../application/preferences.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  /// Value used in the language sheet for "follow the device".
  static const _deviceLanguage = '';

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
            SectionLabel(l10n.settingsSectionAbout),
            ListTile(
              leading: const Icon(Icons.cloud_outlined),
              title: Text(l10n.settingsWeatherData),
              subtitle: Text(l10n.settingsWeatherDataCredit),
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
