import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/device.dart';
import '../../../core/formatting/formatters.dart';
import '../../../core/formatting/l10n.dart';
import '../../../core/providers.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/action_slab.dart';
import '../../../core/widgets/section_label.dart';
import '../../../domain/models/trip.dart';
import '../../common/trip_row.dart';
import '../../trip/application/trip_controller.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  var _starting = false;

  Future<void> _start() async {
    if (_starting) return;
    setState(() => _starting = true);
    try {
      await ref.read(tripControllerProvider).startTrip();
      if (mounted) await context.push(AppRoutes.activeTrip);
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final active = ref.watch(activeTripProvider).value;
    final recent = ref.watch(recentTripsProvider).value ?? const [];
    final past = recent.where((o) => !o.trip.isActive).toList();

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  PiscatioSizes.gutter,
                  20,
                  PiscatioSizes.gutter,
                  8,
                ),
                child: ExcludeSemantics(
                  child: Text(
                    l10n.appTitle,
                    style: Theme.of(context).textTheme.displaySmall!
                        .copyWith(fontSize: 26, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ),
            if (active != null)
              SliverToBoxAdapter(child: _ActiveTripBanner(trip: active)),
            if (past.isEmpty && active == null)
              const SliverToBoxAdapter(child: _FirstTrip())
            else if (past.isNotEmpty) ...[
              SliverToBoxAdapter(child: SectionLabel(l10n.homeRecentTrips)),
              SliverList.builder(
                itemCount: past.length,
                itemBuilder: (context, i) => TripRow(
                  overview: past[i],
                  onTap: () => context.push(AppRoutes.trip(past[i].trip.id)),
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(
          PiscatioSizes.gutter,
          8,
          PiscatioSizes.gutter,
          12,
        ),
        child: active == null
            ? ActionSlab(
                label: l10n.startTripAction,
                icon: Icons.phishing_rounded,
                onPressed: _starting ? null : _start,
              )
            : ActionSlab(
                label: l10n.resumeTripAction,
                icon: Icons.play_arrow_rounded,
                onPressed: () => context.push(AppRoutes.activeTrip),
              ),
      ),
    );
  }
}

/// A trip is running: show its clock big, tap to go back to it.
class _ActiveTripBanner extends ConsumerWidget {
  const _ActiveTripBanner({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final now =
        ref.watch(nowTickerProvider).value ?? ref.read(clockProvider).now();
    final catches = ref.watch(tripCatchesProvider(trip.id)).value ?? const [];
    const fg = PiscatioColors.foam;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PiscatioSizes.gutter,
        12,
        PiscatioSizes.gutter,
        8,
      ),
      child: Material(
        // On the dark theme the page itself is deep water: lift the block.
        color: Theme.of(context).brightness == Brightness.dark
            ? PiscatioColors.deepWater3
            : PiscatioColors.deepWater,
        borderRadius: BorderRadius.circular(PiscatioRadii.slab),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push(AppRoutes.activeTrip),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.activeTripLabel,
                  style: text.titleSmall!.copyWith(
                    color: PiscatioColors.reedOnDark,
                  ),
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    Formatters.timer(trip.duration(now)),
                    maxLines: 1,
                    style: text.displayMedium!.copyWith(
                      color: fg,
                      fontFeatures: tabularFigures,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.catchCount(catches.length),
                  style: text.titleMedium!.copyWith(color: fg),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Empty state: the first trip is the only thing to do here.
class _FirstTrip extends StatelessWidget {
  const _FirstTrip();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PiscatioSizes.gutter,
        48,
        PiscatioSizes.gutter,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.homeEmptyTitle, style: text.headlineLarge),
          const SizedBox(height: 12),
          Text(
            l10n.homeEmptyBody,
            style: text.bodyLarge!.copyWith(color: context.palette.muted),
          ),
        ],
      ),
    );
  }
}
