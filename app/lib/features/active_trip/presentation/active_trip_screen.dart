import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/device.dart';
import '../../../core/formatting/formatters.dart';
import '../../../core/formatting/formatters_provider.dart';
import '../../../core/formatting/l10n.dart';
import '../../../core/providers.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/action_slab.dart';
import '../../../domain/models/catch.dart';
import '../../../domain/models/trip.dart';
import '../../common/catch_tile.dart';
import '../../trip/application/trip_controller.dart';
import '../../weather/presentation/live_weather_row.dart';
import 'time_ruler.dart';

/// The trip in progress. Built for the riverbank: one huge timer, one huge
/// "+ Catch" button at the thumb, almost nothing else to hit by accident.
class ActiveTripScreen extends ConsumerWidget {
  const ActiveTripScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeTripProvider);
    return active.when(
      loading: () => const Scaffold(),
      error: (_, _) =>
          Scaffold(body: Center(child: Text(context.l10n.errorGeneric))),
      data: (trip) {
        if (trip == null) return const _NoActiveTrip();
        return _ActiveTripView(trip: trip);
      },
    );
  }
}

class _NoActiveTrip extends StatelessWidget {
  const _NoActiveTrip();

  @override
  Widget build(BuildContext context) {
    // No trip running (e.g. it was just finished). If this screen is still
    // the visible one, go home; if we are already navigating away, stay put.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted && (ModalRoute.of(context)?.isCurrent ?? false)) {
        context.go(AppRoutes.home);
      }
    });
    return const Scaffold();
  }
}

class _ActiveTripView extends ConsumerWidget {
  const _ActiveTripView({required this.trip});

  final Trip trip;

  Future<void> _confirmFinish(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.finishTripTitle),
        content: Text(l10n.finishTripBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.finishTripConfirm),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    // Leave first: once the trip ends this screen has nothing to show. Pop
    // this screen off the root navigator (back to whatever opened it, i.e.
    // Home with its tab bar), then stack the trip's detail and its summary
    // on top: closing the summary shows the trip, and back from there
    // returns home. Using the router directly (rather than the context
    // extensions) avoids relying on `context` staying valid across the
    // navigation calls.
    final router = GoRouter.of(context);
    final controller = ref.read(tripControllerProvider);
    router.pop();
    unawaited(router.push(AppRoutes.trip(trip.id)));
    unawaited(router.push(AppRoutes.tripSummary(trip.id)));
    await controller.finishTrip(trip.id);
  }

  /// Opens the capture flow; once saved, offers Undo for a few seconds.
  Future<void> _capture(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final repository = ref.read(catchRepositoryProvider);
    // A pending Undo would float over the capture screen's buttons.
    messenger.hideCurrentSnackBar();
    final savedId = await context.push<String>(AppRoutes.capture(trip.id));
    if (savedId == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.catchSaved),
          action: SnackBarAction(
            label: l10n.actionUndo,
            onPressed: () => repository.deleteCatch(savedId),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final catches = ref.watch(tripCatchesProvider(trip.id)).value ?? const [];
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: l10n.activeTripMinimize,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.home),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: () => _confirmFinish(context, ref),
              child: Text(l10n.finishTripAction),
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _Header(trip: trip, catches: catches),
          ),
          if (catches.isEmpty)
            SliverToBoxAdapter(child: _EmptyCatches())
          else
            SliverList.builder(
              itemCount: catches.length,
              itemBuilder: (context, i) => CatchTile(
                item: catches[i],
                onTap: () => context.push(AppRoutes.catchDetail(catches[i].id)),
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
        child: ActionSlab(
          label: l10n.addCatchAction,
          onPressed: () => _capture(context, ref),
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.trip, required this.catches});

  final Trip trip;
  final List<Catch> catches;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final f = context.formatters(ref);
    final text = Theme.of(context).textTheme;
    final now =
        ref.watch(nowTickerProvider).value ?? ref.read(clockProvider).now();
    final elapsed = trip.duration(now);
    final muted = text.bodyLarge!.copyWith(color: context.palette.muted);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PiscatioSizes.gutter,
        0,
        PiscatioSizes.gutter,
        12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.activeTripLabel, style: muted),
          const SizedBox(height: 4),
          Semantics(
            label: l10n.activeTripElapsed(f.duration(elapsed)),
            excludeSemantics: true,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                Formatters.timer(elapsed),
                style: text.displayLarge!.copyWith(
                  fontSize: 76,
                  fontFeatures: tabularFigures,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          TimeRuler(
            start: trip.startedAt,
            now: now,
            catchTimes: [for (final c in catches) c.caughtAt],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 20,
            runSpacing: 8,
            children: [
              _Fact(
                icon: Icons.schedule_rounded,
                text: l10n.activeTripStartedAt(f.time(trip.startedAt)),
              ),
              _Fact(
                icon: Icons.brightness_3_outlined,
                text: f.moonPhase(trip.moonPhase),
              ),
              _Fact(
                icon: trip.location == null
                    ? Icons.location_searching_rounded
                    : Icons.location_on_rounded,
                text: trip.location == null
                    ? l10n.activeTripNoLocation
                    : l10n.activeTripLocationSaved,
              ),
            ],
          ),
          LiveWeatherRow(
            tripId: trip.id,
            padding: const EdgeInsets.only(top: 20),
          ),
          const SizedBox(height: 28),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('${catches.length}', style: text.displaySmall),
              const SizedBox(width: 10),
              Text(
                l10n.catchCountLabel(catches.length),
                style: text.titleLarge,
              ),
            ],
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

class _EmptyCatches extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PiscatioSizes.gutter,
        8,
        PiscatioSizes.gutter,
        0,
      ),
      child: Text(
        context.l10n.activeTripEmpty,
        style: Theme.of(context).textTheme.bodyLarge!
            .copyWith(color: context.palette.muted),
      ),
    );
  }
}
