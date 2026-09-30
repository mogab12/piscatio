import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatting/formatters_provider.dart';
import '../../../core/formatting/l10n.dart';
import '../../../core/theme/tokens.dart';
import '../../../domain/models/geo_point.dart';
import '../../../domain/models/venue.dart';
import '../application/venue_search.dart';

/// What the person picked: a venue, or none (the trip is unlinked).
class VenuePick {
  const VenuePick(this.venue);

  final Venue? venue;
}

/// Picks the venue of a trip: venues around the trip's area first, then by
/// name or city. Null when dismissed.
Future<VenuePick?> showVenuePicker(BuildContext context, {GeoPoint? near}) =>
    showModalBottomSheet<VenuePick>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _VenuePicker(near: near),
    );

class _VenuePicker extends ConsumerStatefulWidget {
  const _VenuePicker({this.near});

  final GeoPoint? near;

  @override
  ConsumerState<_VenuePicker> createState() => _VenuePickerState();
}

class _VenuePickerState extends ConsumerState<_VenuePicker> {
  final _query = TextEditingController();
  Timer? _debounce;
  List<Venue> _results = const [];
  VenueSearchProblem? _problem;
  var _loading = true;
  var _request = 0;

  @override
  void initState() {
    super.initState();
    _run();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final request = ++_request;
    setState(() => _loading = true);
    try {
      final found = await ref
          .read(venueSearchProvider)
          .search(query: _query.text, near: widget.near);
      if (!mounted || request != _request) return;
      setState(() {
        _results = found;
        _problem = null;
        _loading = false;
      });
    } on VenueSearchFailure catch (e) {
      if (!mounted || request != _request) return;
      setState(() {
        _problem = e.problem;
        _loading = false;
      });
    }
  }

  void _changed(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _run);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final f = context.formatters(ref);
    final text = Theme.of(context).textTheme;
    final muted = context.palette.muted;
    final message = switch (_problem) {
      VenueSearchProblem.signedOut => l10n.venueSignIn,
      VenueSearchProblem.offline => l10n.accountErrorOffline,
      null when !_loading && _results.isEmpty => l10n.venueNoResults,
      null => null,
    };
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.75,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                PiscatioSizes.gutter,
                0,
                PiscatioSizes.gutter,
                8,
              ),
              child: TextField(
                controller: _query,
                onChanged: _changed,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: l10n.venueSearchHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                ),
              ),
            ),
            if (_loading) const LinearProgressIndicator(minHeight: 2),
            ListTile(
              leading: const Icon(Icons.block_rounded),
              title: Text(l10n.venueNone),
              onTap: () => Navigator.of(context).pop(const VenuePick(null)),
            ),
            if (widget.near != null && _query.text.trim().isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  PiscatioSizes.gutter,
                  12,
                  PiscatioSizes.gutter,
                  4,
                ),
                child: Text(
                  l10n.venueNearby,
                  style: text.titleSmall!.copyWith(color: muted),
                ),
              ),
            if (message != null)
              Padding(
                padding: const EdgeInsets.all(PiscatioSizes.gutter),
                child: Text(
                  message,
                  style: text.bodyLarge!.copyWith(color: muted),
                ),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, i) {
                  final v = _results[i];
                  return ListTile(
                    leading: const Icon(Icons.storefront_outlined),
                    title: Row(
                      children: [
                        Flexible(child: Text(v.name)),
                        if (v.verified) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.verified_rounded,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary,
                            semanticLabel: l10n.venueVerified,
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text(venueSubtitle(l10n, f, v)),
                    onTap: () => Navigator.of(context).pop(VenuePick(v)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
