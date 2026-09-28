import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatting/formatters_provider.dart';
import '../../../core/formatting/l10n.dart';
import '../../../core/providers.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/section_label.dart';
import '../../common/trip_row.dart';

/// Every trip, newest first, grouped by month.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final f = context.formatters(ref);
    final text = Theme.of(context).textTheme;
    final trips = ref.watch(tripHistoryProvider).value ?? const [];
    final months = groupBy(trips, (o) {
      final local = o.trip.startedAt.toLocal();
      return DateTime(local.year, local.month);
    });

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  PiscatioSizes.gutter,
                  24,
                  PiscatioSizes.gutter,
                  4,
                ),
                child: Semantics(
                  header: true,
                  child: Text(l10n.navLogbook, style: text.headlineLarge),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: PiscatioSizes.gutter - 8,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => context.push(AppRoutes.pastTrip),
                    icon: const Icon(Icons.history_rounded),
                    label: Text(l10n.pastTripAction),
                  ),
                ),
              ),
            ),
            if (trips.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    PiscatioSizes.gutter,
                    16,
                    PiscatioSizes.gutter,
                    0,
                  ),
                  child: Text(
                    l10n.historyEmpty,
                    style: text.bodyLarge!.copyWith(
                      color: context.palette.muted,
                    ),
                  ),
                ),
              ),
            for (final entry in months.entries) ...[
              SliverToBoxAdapter(
                child: SectionLabel(f.monthYear(entry.key.toUtc())),
              ),
              SliverList.builder(
                itemCount: entry.value.length,
                itemBuilder: (context, i) {
                  final o = entry.value[i];
                  return TripRow(
                    overview: o,
                    onTap: () => o.trip.isActive
                        ? context.push(AppRoutes.activeTrip)
                        : context.push(AppRoutes.trip(o.trip.id)),
                  );
                },
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}
