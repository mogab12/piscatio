import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatting/formatters_provider.dart';
import '../../../core/formatting/l10n.dart';
import '../../../core/providers.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/action_slab.dart';
import '../../../core/widgets/section_label.dart';
import '../../../domain/services/year_summary.dart';
import '../../cards/application/card_builder.dart';
import '../../common/species_label.dart';

/// The years with trips, newest first.
final fishingYearsProvider = Provider<List<int>>((ref) {
  final trips = ref.watch(tripHistoryProvider).value ?? const [];
  return fishingYears([for (final o in trips) o.trip]);
});

/// "Year in review": the year's numbers, its months and its fish, and the
/// way to its card.
class YearSummaryScreen extends ConsumerWidget {
  const YearSummaryScreen({super.key, required this.year});

  final int year;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final f = context.formatters(ref);
    final theme = Theme.of(context);
    final summary = ref.watch(yearSummaryProvider(year));
    final years = ref.watch(fishingYearsProvider);
    String species(String id) =>
        ref.watch(speciesNameProvider(id)) ?? l10n.speciesUnknown;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.yearTitle('$year'))),
      body: summary == null
          ? const SizedBox()
          : ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                if (years.length > 1)
                  SizedBox(
                    height: PiscatioSizes.minTouch,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: PiscatioSizes.gutter,
                      ),
                      children: [
                        for (final y in years)
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: ChoiceChip(
                              label: Text('$y'),
                              selected: y == year,
                              showCheckmark: false,
                              onSelected: (_) => context.pushReplacement(
                                AppRoutes.yearSummary(y),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                if (summary.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(PiscatioSizes.gutter),
                    child: Text(
                      l10n.yearEmpty,
                      style: theme.textTheme.bodyLarge!.copyWith(
                        color: context.palette.muted,
                      ),
                    ),
                  )
                else ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      PiscatioSizes.gutter,
                      16,
                      PiscatioSizes.gutter,
                      0,
                    ),
                    child: Row(
                      children: [
                        _Figure(
                          value: f.number(summary.tripCount.toDouble()),
                          label: l10n.statsTripsLabel(summary.tripCount),
                        ),
                        _Figure(
                          value: f.number(summary.catchCount.toDouble()),
                          label: l10n.catchCountLabel(summary.catchCount),
                        ),
                        _Figure(
                          value: f.number(summary.speciesCount.toDouble()),
                          label: l10n.speciesCountLabel(summary.speciesCount),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final line in [
                    l10n.yearDaysFished(summary.daysFished),
                    l10n.yearTimeFished(f.duration(summary.timeFished)),
                    if (summary.releasedCount > 0)
                      l10n.yearReleased(summary.releasedCount),
                    if (summary.newSpecies.isNotEmpty)
                      l10n.yearNewSpecies(summary.newSpecies.length),
                    if (summary.topSpeciesId != null)
                      l10n.yearTopSpecies(
                        species(summary.topSpeciesId!),
                        f.number(summary.species.first.$2.toDouble()),
                      ),
                    if (summary.biggest case final b?)
                      l10n.yearBiggest(
                        l10n.cardBiggestValue(
                          b.speciesId == null
                              ? l10n.speciesUnknown
                              : species(b.speciesId!),
                          b.weightGrams != null
                              ? f.weight(b.weightGrams!)
                              : f.length(b.lengthMillimeters!),
                        ),
                      ),
                    if (summary.bestMonth != null)
                      l10n.yearBestMonth(f.monthName(summary.bestMonth!)),
                  ])
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: PiscatioSizes.gutter,
                        vertical: 4,
                      ),
                      child: Text(line, style: theme.textTheme.bodyLarge),
                    ),
                  if (summary.catchCount > 0) ...[
                    SectionLabel(l10n.yearByMonthTitle),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: PiscatioSizes.gutter,
                      ),
                      child: _MonthChart(
                        summary: summary,
                        letters: f.monthLetters(),
                      ),
                    ),
                  ],
                ],
              ],
            ),
      bottomNavigationBar: summary == null || summary.isEmpty
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(
                PiscatioSizes.gutter,
                8,
                PiscatioSizes.gutter,
                16,
              ),
              child: ActionSlab(
                label: l10n.yearCreateCard,
                icon: Icons.auto_awesome_outlined,
                onPressed: () => context.push(AppRoutes.yearCard(year)),
              ),
            ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: PiscatioFonts.expanded,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w900,
            fontSize: 40,
            height: 1,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium!
              .copyWith(color: context.palette.muted),
        ),
      ],
    ),
  );
}

/// Catches per month as bars; the best month in the accent.
class _MonthChart extends StatelessWidget {
  const _MonthChart({required this.summary, required this.letters});

  final YearSummary summary;
  final List<String> letters;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final top = math.max(1, summary.byMonth.fold(0, math.max));
    return Semantics(
      label: context.l10n.yearByMonthTitle,
      child: SizedBox(
        height: 160,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var m = 0; m < 12; m++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            widthFactor: 1,
                            heightFactor: summary.byMonth[m] == 0
                                ? 0.02
                                : math.max(0.06, summary.byMonth[m] / top),
                            child: ColoredBox(
                              color: summary.bestMonth == m + 1
                                  ? scheme.primary
                                  : scheme.onSurface.withValues(alpha: 0.35),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      ExcludeSemantics(
                        child: Text(
                          letters[m],
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
