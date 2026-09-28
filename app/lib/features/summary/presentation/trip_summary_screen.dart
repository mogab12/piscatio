import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatting/formatters.dart';
import '../../../core/formatting/formatters_provider.dart';
import '../../../core/formatting/l10n.dart';
import '../../../core/providers.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/action_slab.dart';
import '../../../domain/models/catch.dart';
import '../../../domain/models/trip.dart';
import '../../../domain/services/records.dart';
import '../../../domain/services/trip_summary.dart';
import '../../active_trip/presentation/time_ruler.dart';
import '../../common/species_label.dart';
import '../../weather/presentation/weather_panel.dart';

/// Shown right after finishing a trip, on deep water: how it went, the
/// records it set, and the way to a card. Closing it lands on the trip.
class TripSummaryScreen extends ConsumerWidget {
  const TripSummaryScreen({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trip = ref.watch(tripProvider(tripId)).value;
    final catches = ref.watch(tripCatchesProvider(tripId)).value;
    return Theme(
      data: AppTheme.dark(),
      child: Builder(
        builder: (context) {
          final l10n = context.l10n;
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                tooltip: l10n.actionClose,
                icon: const Icon(Icons.close_rounded),
                onPressed: () => context.canPop()
                    ? context.pop()
                    : context.go(AppRoutes.trip(tripId)),
              ),
            ),
            body: trip == null || catches == null
                ? const SizedBox()
                : _SummaryBody(trip: trip, catches: catches),
            bottomNavigationBar: SafeArea(
              minimum: const EdgeInsets.fromLTRB(
                PiscatioSizes.gutter,
                8,
                PiscatioSizes.gutter,
                16,
              ),
              child: ActionSlab(
                label: l10n.cardCreate,
                icon: Icons.ios_share_rounded,
                onPressed: trip == null
                    ? null
                    : () => context.push(AppRoutes.tripCard(tripId)),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SummaryBody extends ConsumerWidget {
  const _SummaryBody({required this.trip, required this.catches});

  final Trip trip;
  final List<Catch> catches;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final f = context.formatters(ref);
    final text = Theme.of(context).textTheme;
    final muted = context.palette.muted;
    final now = ref.watch(clockProvider).now();
    final summary = summarizeTrip(trip, catches, now);
    final all = ref.watch(allCatchesProvider).value ?? const <Catch>[];
    final baits = ref.watch(baitsProvider).value ?? const [];
    String species(Catch c) =>
        (c.speciesId == null
            ? null
            : ref.watch(speciesNameProvider(c.speciesId!))) ??
        l10n.speciesUnknown;
    final records = [
      for (final c in catches.reversed)
        if (recordStatus(c, all) case final s
            when s.isRecord || s.firstOfSpecies)
          (c, s),
    ];
    final biggest = summary.biggest;
    final topBait = baits
        .where((b) => b.id == summary.topBaitId)
        .firstOrNull
        ?.name;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        PiscatioSizes.gutter,
        0,
        PiscatioSizes.gutter,
        24,
      ),
      children: [
        Text(l10n.summaryTitle, style: text.headlineLarge),
        const SizedBox(height: 6),
        Text(
          f.weekdayDate(trip.startedAt),
          style: text.bodyLarge!.copyWith(color: muted),
        ),
        if (trip.endedAt != null)
          Text(
            l10n.tripTimeRange(f.time(trip.startedAt), f.time(trip.endedAt!)),
            style: text.bodyLarge!.copyWith(color: muted),
          ),
        const SizedBox(height: 28),
        Semantics(
          label: '${f.duration(summary.duration)} ${l10n.tripStatDuration}',
          excludeSemantics: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  f.duration(summary.duration),
                  style: text.displayLarge,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.tripStatDuration,
                style: text.titleLarge!.copyWith(color: muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 28,
          runSpacing: 8,
          children: [
            _Count(
              value: summary.catchCount,
              label: l10n.catchCountLabel(summary.catchCount),
            ),
            _Count(
              value: summary.speciesCount,
              label: l10n.speciesCountLabel(summary.speciesCount),
            ),
          ],
        ),
        const SizedBox(height: 24),
        TimeRuler(
          start: trip.startedAt,
          now: trip.endedAt ?? now,
          catchTimes: [for (final c in catches) c.caughtAt],
        ),
        if (records.isNotEmpty) ...[
          const SizedBox(height: 28),
          Text(l10n.summaryRecords, style: text.titleLarge),
          const SizedBox(height: 8),
          for (final (c, s) in records)
            _RecordRow(item: c, status: s, species: species(c), f: f),
        ],
        const SizedBox(height: 24),
        if (biggest != null)
          _Fact(
            icon: Icons.straighten_rounded,
            text: l10n.tripBiggestCatch(
              species(biggest),
              biggest.weightGrams != null
                  ? f.weight(biggest.weightGrams!)
                  : f.length(biggest.lengthMillimeters!),
            ),
          ),
        if (topBait != null)
          _Fact(
            icon: Icons.set_meal_outlined,
            text: l10n.summaryTopBait(topBait),
          ),
        if (trip.locationRegion != null)
          _Fact(icon: Icons.place_outlined, text: trip.locationRegion!),
        _Fact(
          icon: Icons.brightness_3_outlined,
          text: f.moonPhase(trip.moonPhase),
        ),
        const SizedBox(height: 20),
        WeatherPanel(tripId: trip.id, onDark: true),
      ],
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text('$value', style: text.displaySmall),
        const SizedBox(width: 8),
        Text(label, style: text.titleMedium),
      ],
    );
  }
}

/// A record set on this trip: gold rule, what kind, which fish.
class _RecordRow extends StatelessWidget {
  const _RecordRow({
    required this.item,
    required this.status,
    required this.species,
    required this.f,
  });

  final Catch item;
  final CatchRecordStatus status;
  final String species;
  final Formatters f;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final gold = context.palette.record;
    final mark = status.headline;
    final pct = mark?.improvement;
    final kind = status.firstOfSpecies
        ? l10n.cardFirstOfSpecies
        : pct == null
        ? l10n.cardRecord
        : l10n.cardRecordImprovement(f.percentGain(pct));
    final measure = item.weightGrams != null
        ? f.weight(item.weightGrams!)
        : item.lengthMillimeters != null
        ? f.length(item.lengthMillimeters!)
        : null;
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.only(left: 14),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: gold, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(kind, style: text.titleMedium!.copyWith(color: gold)),
          Text(
            measure == null
                ? species
                : l10n.summaryRecordLine(species, measure),
            style: text.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 22, color: context.palette.muted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}
