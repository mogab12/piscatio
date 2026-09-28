import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatting/formatters_provider.dart';
import '../../core/formatting/l10n.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/photo_thumb.dart';
import '../../domain/models/trip.dart';

/// A past trip in a list: cover photo, date, place and duration, and the
/// catch count set big on the right.
class TripRow extends ConsumerWidget {
  const TripRow({super.key, required this.overview, this.onTap});

  final TripOverview overview;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final f = context.formatters(ref);
    final text = Theme.of(context).textTheme;
    final trip = overview.trip;
    final muted = text.bodyMedium!.copyWith(color: context.palette.muted);
    final details = [
      if (trip.locationName != null) trip.locationName!,
      if (trip.endedAt != null) f.duration(trip.duration(trip.endedAt!)),
    ];
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: PiscatioSizes.gutter,
          vertical: 12,
        ),
        child: Row(
          children: [
            PhotoThumb(relativePath: overview.coverPhotoPath, size: 72),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(f.weekdayDate(trip.startedAt), style: text.titleMedium),
                  for (final d in details)
                    Text(
                      d,
                      style: muted,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Semantics(
              label: l10n.catchCount(overview.catchCount),
              excludeSemantics: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${overview.catchCount}', style: text.displaySmall),
                  Text(
                    l10n.catchCountLabel(overview.catchCount),
                    style: text.labelSmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
