import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/background.dart';
import '../../core/formatting/l10n.dart';
import '../../core/theme/tokens.dart';
import '../../data/remote/place_name_service.dart';
import '../settings/application/preferences.dart';

/// Finds a place by name with the platform geocoder (needs a connection).
/// Returns the chosen place, or null.
Future<PlaceResult?> showPlaceSearch(BuildContext context) =>
    showModalBottomSheet<PlaceResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => const _PlaceSearchSheet(),
    );

class _PlaceSearchSheet extends ConsumerStatefulWidget {
  const _PlaceSearchSheet();

  @override
  ConsumerState<_PlaceSearchSheet> createState() => _PlaceSearchSheetState();
}

class _PlaceSearchSheetState extends ConsumerState<_PlaceSearchSheet> {
  final _query = TextEditingController();
  List<PlaceResult>? _results;
  var _loading = false;
  var _failed = false;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _query.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final found = await ref
          .read(placeNameServiceProvider)
          .search(q, languageCode: ref.read(effectiveLanguageProvider));
      if (mounted) setState(() => _results = found);
    } on Exception {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final muted = Theme.of(context).textTheme.bodyLarge!
        .copyWith(color: context.palette.muted);
    final results = _results;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: PiscatioSizes.gutter,
            ),
            child: TextField(
              controller: _query,
              autofocus: true,
              textInputAction: TextInputAction.search,
              textCapitalization: TextCapitalization.words,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                labelText: l10n.placeSearchAction,
                hintText: l10n.placeSearchHint,
                suffixIcon: IconButton(
                  tooltip: l10n.placeSearchAction,
                  icon: const Icon(Icons.search_rounded),
                  onPressed: _search,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (_loading) const LinearProgressIndicator(),
          if (_failed)
            Padding(
              padding: const EdgeInsets.all(PiscatioSizes.gutter),
              child: Text(l10n.placeSearchFailed, style: muted),
            )
          else if (results != null && results.isEmpty)
            Padding(
              padding: const EdgeInsets.all(PiscatioSizes.gutter),
              child: Text(l10n.placeSearchEmpty, style: muted),
            )
          else if (results != null)
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final r in results)
                    ListTile(
                      minTileHeight: PiscatioSizes.minTouch,
                      leading: const Icon(Icons.place_outlined),
                      title: Text(r.name),
                      subtitle: r.region == null ? null : Text(r.region!),
                      onTap: () => Navigator.of(context).pop(r),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
