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
import '../../../domain/models/catch.dart';
import '../../../domain/models/trip.dart';
import '../../../domain/services/trip_summary.dart';
import '../../common/catch_tile.dart';
import '../../common/confirm_delete.dart';
import '../../common/species_label.dart';
import '../../trip/application/trip_controller.dart';
import '../../weather/presentation/weather_panel.dart';

class TripDetailScreen extends ConsumerWidget {
  const TripDetailScreen({super.key, required this.tripId});

  final String tripId;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final ok = await confirmDelete(
      context,
      title: l10n.deleteTripTitle,
      body: l10n.deleteTripBody,
    );
    if (!ok || !context.mounted) return;
    final controller = ref.read(tripControllerProvider);
    context.go(AppRoutes.history);
    await controller.deleteTrip(tripId);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final trip = ref.watch(tripProvider(tripId));
    return trip.when(
      loading: () => const Scaffold(),
      error: (_, _) => Scaffold(body: Center(child: Text(l10n.errorGeneric))),
      data: (trip) {
        if (trip == null) {
          return Scaffold(
            appBar: AppBar(leading: const _BackOrToHistory()),
            body: Center(child: Text(l10n.tripNotFound)),
          );
        }
        final catches = ref.watch(tripCatchesProvider(tripId)).value ?? [];
        return Scaffold(
          appBar: AppBar(
            leading: const _BackOrToHistory(),
            actions: [
              if (!trip.isActive)
                IconButton(
                  tooltip: l10n.cardCreate,
                  icon: const Icon(Icons.ios_share_rounded),
                  onPressed: () => context.push(AppRoutes.tripCard(tripId)),
                ),
              IconButton(
                tooltip: l10n.actionEdit,
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => context.push(AppRoutes.editTrip(tripId)),
              ),
              IconButton(
                tooltip: l10n.deleteTripTitle,
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: () => _delete(context, ref),
              ),
            ],
          ),
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _TripHeader(trip: trip, catches: catches),
              ),
              SliverToBoxAdapter(
                child: SectionLabel(l10n.catchCount(catches.length)),
              ),
              if (catches.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: PiscatioSizes.gutter,
                    ),
                    child: Text(
                      l10n.tripNoCatches,
                      style: Theme.of(context).textTheme.bodyLarge!
                          .copyWith(color: context.palette.muted),
                    ),
                  ),
                ),
              SliverList.builder(
                itemCount: catches.length,
                itemBuilder: (context, i) => CatchTile(
                  item: catches[i],
                  onTap: () =>
                      context.push(AppRoutes.catchDetail(catches[i].id)),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(
              PiscatioSizes.gutter,
              8,
              PiscatioSizes.gutter,
              16,
            ),
            child: trip.isActive
                ? ActionSlab(
                    label: l10n.resumeTripAction,
                    icon: Icons.play_arrow_rounded,
                    onPressed: () => context.push(AppRoutes.activeTrip),
                  )
                : OutlinedButton.icon(
                    onPressed: () => context.push(AppRoutes.capture(tripId)),
                    icon: const Icon(Icons.add_rounded),
                    label: Text(l10n.tripAddCatch),
                  ),
          ),
        );
      },
    );
  }
}

/// Pops back if possible, otherwise returns to the logbook tab (which keeps
/// the bottom navigation bar). Guards against this screen ever being a dead
/// end, however it was reached — e.g. finishing a trip pushes this screen
/// after leaving the active trip screen, so there is normally a route to
/// pop to, but this covers any other path that lands here directly.
class _BackOrToHistory extends StatelessWidget {
  const _BackOrToHistory();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: context.l10n.actionBack,
      icon: const Icon(Icons.arrow_back_rounded),
      onPressed: () =>
          context.canPop() ? context.pop() : context.go(AppRoutes.history),
    );
  }
}

class _TripHeader extends ConsumerWidget {
  const _TripHeader({required this.trip, required this.catches});

  final Trip trip;
  final List<Catch> catches;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final f = context.formatters(ref);
    final text = Theme.of(context).textTheme;
    final now = ref.watch(clockProvider).now();
    final summary = summarizeTrip(trip, catches, now);
    final biggest = summary.biggest;
    final biggestName = biggest == null
        ? null
        : ref.watch(speciesNameProvider(biggest.speciesId)) ??
              l10n.speciesUnknown;
    final muted = text.bodyLarge!.copyWith(color: context.palette.muted);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PiscatioSizes.gutter,
        0,
        PiscatioSizes.gutter,
        4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(f.weekdayDate(trip.startedAt), style: text.headlineLarge),
          const SizedBox(height: 4),
          Text(
            trip.endedAt == null
                ? l10n.activeTripStartedAt(f.time(trip.startedAt))
                : l10n.tripTimeRange(
                    f.time(trip.startedAt),
                    f.time(trip.endedAt!),
                  ),
            style: muted,
          ),
          if (trip.locationName != null)
            Text(trip.locationName!, style: text.titleMedium),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _Stat(
                  value: f.duration(summary.duration),
                  label: l10n.tripStatDuration,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _Stat(
                  value: '${summary.catchCount}',
                  label: l10n.catchCountLabel(summary.catchCount),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _Stat(
                  value: '${summary.speciesCount}',
                  label: l10n.speciesCountLabel(summary.speciesCount),
                ),
              ),
            ],
          ),
          if (biggest != null) ...[
            const SizedBox(height: 20),
            Text(
              l10n.tripBiggestCatch(
                biggestName!,
                biggest.weightGrams != null
                    ? f.weight(biggest.weightGrams!)
                    : f.length(biggest.lengthMillimeters!),
              ),
              style: text.titleMedium,
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 20,
            runSpacing: 8,
            children: [
              _Fact(
                icon: Icons.brightness_3_outlined,
                text: f.moonPhase(trip.moonPhase),
              ),
              _Fact(
                icon: Icons.lock_outline_rounded,
                text: f.privacyLevel(trip.privacyLevel),
              ),
              if (trip.locationRegion != null)
                _Fact(icon: Icons.place_outlined, text: trip.locationRegion!),
            ],
          ),
          const SizedBox(height: 20),
          WeatherPanel(tripId: trip.id),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

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
          // Fixed height keeps the labels aligned when a value is scaled.
          SizedBox(
            height: 38,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.bottomLeft,
              child: Text(value, style: text.displaySmall, maxLines: 1),
            ),
          ),
          Text(
            label,
            style: text.labelMedium!.copyWith(color: context.palette.muted),
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: context.palette.muted),
        const SizedBox(width: 6),
        Text(text, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
