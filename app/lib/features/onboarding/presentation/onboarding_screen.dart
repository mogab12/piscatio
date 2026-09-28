import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatting/formatters.dart';
import '../../../core/formatting/l10n.dart';
import '../../../core/locale.dart';
import '../../../core/location/location_service.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/action_slab.dart';
import '../../../core/widgets/brand.dart';
import '../../../domain/services/units.dart';
import '../../settings/application/preferences.dart';

/// Three steps, no account: language, units, location permission. Always in
/// the deep-water palette: it is the app's first impression.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _steps = 3;
  final _pages = PageController();
  var _step = 0;
  var _busy = false;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _goTo(int step) {
    setState(() => _step = step);
    _pages.animateToPage(
      step,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finish({required bool askLocation}) async {
    if (_busy) return;
    setState(() => _busy = true);
    if (askLocation) {
      await ref.read(locationServiceProvider).requestAccess();
    }
    await ref.read(settingsRepositoryProvider).completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.dark(),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Builder(
          builder: (context) => Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  _StepHeader(
                    step: _step,
                    steps: _steps,
                    onBack: _step == 0 ? null : () => _goTo(_step - 1),
                  ),
                  Expanded(
                    child: PageView(
                      controller: _pages,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _LanguageStep(onContinue: () => _goTo(1)),
                        _UnitsStep(onContinue: () => _goTo(2)),
                        _LocationStep(
                          busy: _busy,
                          onAllow: () => _finish(askLocation: true),
                          onSkip: () => _finish(askLocation: false),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({
    required this.step,
    required this.steps,
    required this.onBack,
  });

  final int step;
  final int steps;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 64,
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: onBack == null
                ? null
                : IconButton(
                    onPressed: onBack,
                    tooltip: l10n.actionBack,
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
          ),
          Expanded(
            child: Semantics(
              label: l10n.onboardingStepOf(step + 1, steps),
              child: Row(
                children: [
                  for (var i = 0; i < steps; i++) ...[
                    if (i > 0) const SizedBox(width: 6),
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 240),
                        height: 4,
                        decoration: BoxDecoration(
                          color: i <= step
                              ? scheme.onSurface
                              : scheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: PiscatioSizes.gutter + 44),
        ],
      ),
    );
  }
}

/// Shared layout: scrollable content, action pinned at the bottom.
class _StepLayout extends StatelessWidget {
  const _StepLayout({required this.children, required this.actions});

  final List<Widget> children;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              PiscatioSizes.gutter,
              16,
              PiscatioSizes.gutter,
              24,
            ),
            children: children,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            PiscatioSizes.gutter,
            0,
            PiscatioSizes.gutter,
            16,
          ),
          child: Column(children: actions),
        ),
      ],
    );
  }
}

class _LanguageStep extends ConsumerWidget {
  const _LanguageStep({required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final current = ref.watch(effectiveLanguageProvider);
    return _StepLayout(
      actions: [ActionSlab(label: l10n.actionContinue, onPressed: onContinue)],
      children: [
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerLeft,
          child: BrandLockup(
            size: 40,
            color: Theme.of(context).colorScheme.onSurface,
            floatBottom: Theme.of(context).colorScheme.surface,
          ),
        ),
        const SizedBox(height: 12),
        Text(l10n.onboardingTagline, style: text.headlineMedium),
        const SizedBox(height: 40),
        Text(
          l10n.onboardingLanguageTitle,
          style: text.titleMedium!.copyWith(color: context.palette.muted),
        ),
        const SizedBox(height: 8),
        for (final entry in languageNames.entries)
          _OptionTile(
            selected: entry.key == current,
            onTap: () => ref
                .read(preferencesControllerProvider)
                .chooseLanguage(entry.key),
            child: Text(
              entry.value,
              style: text.titleLarge,
              locale: Locale(entry.key),
            ),
          ),
      ],
    );
  }
}

class _UnitsStep extends ConsumerWidget {
  const _UnitsStep({required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final current = ref.watch(unitSystemProvider);
    return _StepLayout(
      actions: [
        ActionSlab(
          label: l10n.actionContinue,
          onPressed: () async {
            // Persist even the preselected default: it is now a choice.
            await ref.read(preferencesControllerProvider).chooseUnits(current);
            onContinue();
          },
        ),
      ],
      children: [
        const SizedBox(height: 24),
        Text(l10n.onboardingUnitsTitle, style: text.headlineLarge),
        const SizedBox(height: 12),
        Text(
          l10n.onboardingUnitsHint,
          style: text.bodyLarge!.copyWith(color: context.palette.muted),
        ),
        const SizedBox(height: 28),
        for (final system in UnitSystem.values)
          _OptionTile(
            selected: system == current,
            onTap: () =>
                ref.read(preferencesControllerProvider).chooseUnits(system),
            child: _UnitSample(system: system),
          ),
      ],
    );
  }
}

/// Shows the same fish in both unit systems, big.
class _UnitSample extends StatelessWidget {
  const _UnitSample({required this.system});

  final UnitSystem system;

  // A 52.5 cm, 2.35 kg peacock bass.
  static const _grams = 2350;
  static const _millimeters = 525;

  @override
  Widget build(BuildContext context) {
    final f = Formatters(context.l10n, system);
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(f.unitSystemName(system), style: text.titleLarge),
        const SizedBox(height: 10),
        Wrap(
          spacing: 18,
          runSpacing: 4,
          children: [
            Text(f.weight(_grams), style: text.displaySmall),
            Text(f.length(_millimeters), style: text.displaySmall),
          ],
        ),
      ],
    );
  }
}

class _LocationStep extends StatelessWidget {
  const _LocationStep({
    required this.busy,
    required this.onAllow,
    required this.onSkip,
  });

  final bool busy;
  final VoidCallback onAllow;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    return _StepLayout(
      actions: [
        ActionSlab(
          label: l10n.onboardingLocationAllow,
          onPressed: busy ? null : onAllow,
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: busy ? null : onSkip,
            style: TextButton.styleFrom(
              minimumSize: const Size.fromHeight(PiscatioSizes.minTouch),
            ),
            child: Text(l10n.onboardingLocationSkip),
          ),
        ),
      ],
      children: [
        const SizedBox(height: 24),
        Text(l10n.onboardingLocationTitle, style: text.headlineLarge),
        const SizedBox(height: 24),
        _Reason(
          icon: Icons.menu_book_rounded,
          text: l10n.onboardingLocationWhy,
        ),
        _Reason(icon: Icons.lock_rounded, text: l10n.onboardingLocationPrivacy),
        _Reason(
          icon: Icons.signal_wifi_off_rounded,
          text: l10n.onboardingLocationOffline,
        ),
      ],
    );
  }
}

class _Reason extends StatelessWidget {
  const _Reason({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 26, color: context.palette.accentText),
          const SizedBox(width: 16),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}

/// Large selectable block used by the onboarding choices.
class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        selected: selected,
        button: true,
        child: Material(
          color: selected ? scheme.surfaceContainerHigh : scheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PiscatioRadii.slab),
            side: BorderSide(
              color: selected ? scheme.onSurface : scheme.outlineVariant,
              width: selected ? 2 : 1.5,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 68),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Expanded(child: child),
                    if (selected)
                      Icon(
                        Icons.check_rounded,
                        size: 28,
                        color: context.palette.accentText,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
