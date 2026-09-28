import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatting/formatters_provider.dart';
import '../../core/formatting/l10n.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/photo_thumb.dart';
import '../../domain/models/catch.dart';
import 'species_label.dart';

/// One catch in a list: photo, species, time and whatever was measured.
class CatchTile extends ConsumerWidget {
  const CatchTile({super.key, required this.item, this.onTap});

  final Catch item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final f = context.formatters(ref);
    final text = Theme.of(context).textTheme;
    final name =
        ref.watch(speciesNameProvider(item.speciesId)) ?? l10n.speciesUnknown;
    final measures = [
      if (item.weightGrams != null) f.weight(item.weightGrams!),
      if (item.lengthMillimeters != null) f.length(item.lengthMillimeters!),
    ];
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: PiscatioSizes.gutter,
          vertical: 10,
        ),
        child: Row(
          children: [
            PhotoThumb(relativePath: item.coverPhoto?.relativePath),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: text.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    f.time(item.caughtAt),
                    style: text.bodyMedium!.copyWith(
                      color: context.palette.muted,
                    ),
                  ),
                ],
              ),
            ),
            if (measures.isNotEmpty) ...[
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final m in measures)
                    Text(
                      m,
                      style: text.titleMedium!.copyWith(
                        fontFamily: PiscatioFonts.expanded,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                ],
              ),
            ],
            if (item.released ?? false) ...[
              const SizedBox(width: 8),
              Tooltip(
                message: l10n.catchReleased,
                child: Icon(
                  Icons.water_drop_outlined,
                  color: context.palette.muted,
                  semanticLabel: l10n.catchReleased,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
