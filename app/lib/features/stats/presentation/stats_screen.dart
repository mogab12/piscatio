import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/formatting/formatters.dart';
import '../../../core/formatting/formatters_provider.dart';
import '../../../core/formatting/l10n.dart';
import '../../../core/providers.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/section_label.dart';
import '../../../domain/models/tackle.dart';
import '../../../domain/services/logbook_stats.dart';
import '../../../domain/services/records.dart';
import '../../common/species_label.dart';
import '../application/stats_providers.dart';

/// The whole logbook in numbers: totals, when fish bite, what bites,
/// personal bests. Everything is computed from the trips and catches.
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final stats = ref.watch(logbookStatsProvider);
    return Scaffold(
      body: SafeArea(
        child: stats == null
            ? const SizedBox()
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        PiscatioSizes.gutter,
                        24,
                        PiscatioSizes.gutter,
                        8,
                      ),
                      child: Text(l10n.statsTitle, style: text.headlineLarge),
                    ),
                  ),
                  if (stats.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(PiscatioSizes.gutter),
                        child: Text(
                          l10n.statsEmpty,
                          style: text.bodyLarge!.copyWith(
                            color: context.palette.muted,
                          ),
                        ),
                      ),
                    )
                  else
                    SliverList.list(
                      children: [
                        _Totals(stats: stats),
                        if (stats.catchCount > 0) ...[
                          SectionLabel(l10n.statsByHourTitle),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: PiscatioSizes.gutter,
                            ),
                            child: HourChart(byHour: stats.byHour),
                          ),
                        ],
                        if (stats.species.isNotEmpty) ...[
                          SectionLabel(l10n.statsSpeciesTitle),
                          _Ranking(
                            rows: [
                              for (final (id, n) in stats.species.take(5))
                                (
                                  ref.watch(speciesNameProvider(id)) ??
                                      l10n.speciesUnknown,
                                  n,
                                ),
                            ],
                            hidden: math.max(0, stats.species.length - 5),
                          ),
                        ],
                        if (stats.baits.isNotEmpty)
                          _BaitRanking(baits: stats.baits),
                        const _Records(),
                        if (stats.bestTripId != null)
                          _BestTrip(
                            tripId: stats.bestTripId!,
                            catches: stats.bestTripCatches,
                          ),
                        const SizedBox(height: 32),
                      ],
                    ),
                ],
              ),
      ),
    );
  }
}

class _Totals extends ConsumerWidget {
  const _Totals({required this.stats});

  final LogbookStats stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final f = context.formatters(ref);
    final text = Theme.of(context).textTheme;
    final muted = text.bodyLarge!.copyWith(color: context.palette.muted);
    final pct = NumberFormat.percentPattern(l10n.localeName)
      ..maximumFractionDigits = 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PiscatioSizes.gutter,
        8,
        PiscatioSizes.gutter,
        8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            label:
                '${stats.catchCount} ${l10n.catchCountLabel(stats.catchCount)}',
            excludeSemantics: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('${stats.catchCount}', style: text.displayLarge),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    l10n.catchCountLabel(stats.catchCount),
                    style: text.headlineSmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 32,
            runSpacing: 16,
            children: [
              _Figure(
                value: '${stats.tripCount}',
                label: l10n.statsTripsLabel(stats.tripCount),
              ),
              _Figure(
                value: f.duration(stats.timeFished),
                label: l10n.tripStatDuration,
              ),
              _Figure(
                value: '${stats.speciesCount}',
                label: l10n.speciesCountLabel(stats.speciesCount),
              ),
            ],
          ),
          if (stats.catchCount > 0) ...[
            const SizedBox(height: 16),
            Text(
              l10n.statsPerHour(
                f.number(stats.catchesPerHour, maxFractionDigits: 1),
              ),
              style: muted,
            ),
            Text(
              l10n.statsReleased(
                pct.format(stats.releasedCount / stats.catchCount),
              ),
              style: muted,
            ),
          ],
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Semantics(
      label: '$value $label',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: text.displaySmall),
          Text(
            label,
            style: text.labelMedium!.copyWith(color: context.palette.muted),
          ),
        ],
      ),
    );
  }
}

/// Catches per hour of the day: one series, one hue, the busiest hour
/// marked in the accent and labeled. Tap a bar to read its value.
class HourChart extends StatefulWidget {
  const HourChart({super.key, required this.byHour});

  final List<int> byHour;

  @override
  State<HourChart> createState() => _HourChartState();
}

class _HourChartState extends State<HourChart> {
  int? _selected;

  String _hour(BuildContext context, int h) =>
      DateFormat.Hm(context.l10n.localeName)
          .format(DateTime(2000, 1, 1, h % 24));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final palette = context.palette;
    final scheme = Theme.of(context).colorScheme;
    final peak = LogbookStats.peakOf(widget.byHour);
    final shown = _selected ?? peak;
    final top = widget.byHour.reduce(math.max);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The value being read: the busiest hour, or the tapped one.
        SizedBox(
          height: 24,
          child: shown == null
              ? null
              : Text(
                  l10n.statsHourBar(
                    _hour(context, shown),
                    widget.byHour[shown],
                  ),
                  style: text.labelLarge,
                ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 132,
          child: LayoutBuilder(
            builder: (context, box) {
              final slot = box.maxWidth / 24;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (d) => setState(
                  () => _selected = (d.localPosition.dx / slot).floor().clamp(
                    0,
                    23,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _HourBarsPainter(
                          byHour: widget.byHour,
                          max: top,
                          highlight: shown,
                          bar: palette.ruleStrong,
                          accent: scheme.primary,
                          baseline: palette.rule,
                        ),
                      ),
                    ),
                    // One screen-reader stop per hour with catches.
                    Row(
                      children: [
                        for (var h = 0; h < 24; h++)
                          Expanded(
                            child: widget.byHour[h] == 0
                                ? const SizedBox.expand()
                                : Semantics(
                                    label: l10n.statsHourBar(
                                      _hour(context, h),
                                      widget.byHour[h],
                                    ),
                                    child: const SizedBox.expand(),
                                  ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        // Axis: four ticks, the rest is read by tapping.
        Row(
          children: [
            for (final h in const [0, 6, 12, 18])
              Expanded(
                child: Text(
                  _hour(context, h),
                  style: text.labelSmall,
                  textAlign: TextAlign.left,
                ),
              ),
          ],
        ),
        if (peak != null) ...[
          const SizedBox(height: 12),
          Text(
            l10n.statsPeakHour(_hour(context, peak), _hour(context, peak + 1)),
            style: text.bodyLarge,
          ),
        ],
      ],
    );
  }
}

class _HourBarsPainter extends CustomPainter {
  _HourBarsPainter({
    required this.byHour,
    required this.max,
    required this.highlight,
    required this.bar,
    required this.accent,
    required this.baseline,
  });

  final List<int> byHour;
  final int max;
  final int? highlight;
  final Color bar;
  final Color accent;
  final Color baseline;

  @override
  void paint(Canvas canvas, Size size) {
    final slot = size.width / byHour.length;
    // Thin bars with air between them (never fill the slot).
    final w = math.min(24.0, slot - 2);
    canvas.drawLine(
      Offset(0, size.height - 0.5),
      Offset(size.width, size.height - 0.5),
      Paint()
        ..color = baseline
        ..strokeWidth = 1,
    );
    if (max == 0) return;
    for (var h = 0; h < byHour.length; h++) {
      final n = byHour[h];
      if (n == 0) continue;
      final hgt = math.max(3.0, (size.height - 1) * n / max);
      final x = h * slot + (slot - w) / 2;
      final r = math.min(4.0, w / 2);
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(x, size.height - 1 - hgt, w, hgt),
          topLeft: Radius.circular(r),
          topRight: Radius.circular(r),
        ),
        Paint()..color = h == highlight ? accent : bar,
      );
    }
  }

  @override
  bool shouldRepaint(_HourBarsPainter old) =>
      old.byHour != byHour || old.highlight != highlight || old.bar != bar;
}

/// Names with counts and a thin proportional bar, most first.
class _Ranking extends StatelessWidget {
  const _Ranking({required this.rows, this.hidden = 0});

  final List<(String, int)> rows;
  final int hidden;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final palette = context.palette;
    final top = rows.map((r) => r.$2).fold(1, math.max);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: PiscatioSizes.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (name, n) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Semantics(
                label: '$name, ${l10n.statsCount(n)}',
                excludeSemantics: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(name, style: text.titleMedium)),
                        Text(
                          l10n.statsCount(n),
                          style: text.bodyMedium!.copyWith(
                            color: palette.muted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LayoutBuilder(
                      builder: (context, box) => Container(
                        height: 6,
                        width: math.max(6, box.maxWidth * n / top),
                        decoration: BoxDecoration(
                          color: palette.ruleStrong,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (hidden > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                l10n.cardMoreCatches(hidden),
                style: text.bodyMedium!.copyWith(color: palette.muted),
              ),
            ),
        ],
      ),
    );
  }
}

class _BaitRanking extends ConsumerWidget {
  const _BaitRanking({required this.baits});

  final List<(String, int)> baits;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final names = <String, String>{
      for (final b in ref.watch(allBaitsProvider).value ?? const <Bait>[])
        b.id: b.name,
    };
    final rows = [
      for (final (id, n) in baits.take(3))
        if (names[id] != null) (names[id]!, n),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(l10n.statsBaitsTitle),
        _Ranking(rows: rows),
      ],
    );
  }
}

class _Records extends ConsumerWidget {
  const _Records();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final f = context.formatters(ref);
    final bests = ref.watch(personalBestsProvider);
    if (bests.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(l10n.statsRecordsTitle),
        for (final b in bests)
          _RecordRow(
            best: b,
            name:
                ref.watch(speciesNameProvider(b.speciesId)) ??
                l10n.speciesUnknown,
            f: f,
          ),
      ],
    );
  }
}

class _RecordRow extends StatelessWidget {
  const _RecordRow({required this.best, required this.name, required this.f});

  final PersonalBest best;
  final String name;
  final Formatters f;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final gold = context.palette.record;
    Widget mark(String value, String catchId) => InkWell(
      onTap: () => context.push(AppRoutes.catchDetail(catchId)),
      borderRadius: BorderRadius.circular(PiscatioRadii.field),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: PiscatioSizes.minTouch),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Center(child: Text(value, style: text.titleMedium)),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: PiscatioSizes.gutter),
      child: Container(
        padding: const EdgeInsets.only(left: 12),
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: gold, width: 4)),
        ),
        child: Row(
          children: [
            Expanded(child: Text(name, style: text.bodyLarge)),
            if (best.heaviest != null)
              mark(f.weight(best.heaviest!.weightGrams!), best.heaviest!.id),
            if (best.longest != null)
              mark(
                f.length(best.longest!.lengthMillimeters!),
                best.longest!.id,
              ),
          ],
        ),
      ),
    );
  }
}

class _BestTrip extends ConsumerWidget {
  const _BestTrip({required this.tripId, required this.catches});

  final String tripId;
  final int catches;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final f = context.formatters(ref);
    final trip = ref.watch(tripProvider(tripId)).value;
    if (trip == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(l10n.statsBestTrip),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: PiscatioSizes.gutter,
          ),
          minTileHeight: PiscatioSizes.minTouch,
          title: Text(l10n.statsBestTripValue(f.date(trip.startedAt), catches)),
          subtitle: trip.locationName == null ? null : Text(trip.locationName!),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => context.push(AppRoutes.trip(tripId)),
        ),
      ],
    );
  }
}
