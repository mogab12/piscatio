import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatting/l10n.dart';
import '../../../core/providers.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/action_slab.dart';
import '../../../domain/models/enums.dart';
import '../application/card_builder.dart';
import '../application/card_data.dart';
import '../application/card_exporter.dart';
import 'card_view.dart';

enum CardSubject { catchItem, trip }

/// Pick a style and a format, choose whether the place shows, share.
class CardEditorScreen extends ConsumerStatefulWidget {
  const CardEditorScreen({super.key, required this.subject, required this.id});

  final CardSubject subject;
  final String id;

  @override
  ConsumerState<CardEditorScreen> createState() => _CardEditorScreenState();
}

class _CardEditorScreenState extends ConsumerState<CardEditorScreen> {
  var _style = CardStyle.board;
  var _format = CardFormat.story;
  var _showPlace = true;
  var _sharing = false;
  final _boundary = GlobalKey();

  String _styleName(CardStyle s) => switch (s) {
    CardStyle.board => context.l10n.cardStyleBoard,
    CardStyle.chart => context.l10n.cardStyleChart,
    CardStyle.tag => context.l10n.cardStyleTag,
  };

  String _formatName(CardFormat f) => switch (f) {
    CardFormat.story => context.l10n.cardFormatStory,
    CardFormat.square => context.l10n.cardFormatSquare,
  };

  Future<void> _share(String? photoPath) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final sharer = ref.read(cardSharerProvider);
    setState(() => _sharing = true);
    try {
      if (photoPath != null && File(photoPath).existsSync()) {
        await precacheImage(FileImage(File(photoPath)), context);
      }
      await WidgetsBinding.instance.endOfFrame;
      final boundary =
          _boundary.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final png = await captureCard(boundary);
      final name = 'piscatio-${_style.name}-${_format.name}.png';
      await sharer.sharePng(png, name);
    } on Exception {
      messenger.showSnackBar(SnackBar(content: Text(l10n.cardShareFailed)));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (
      Widget? card,
      String? place,
      String? photo,
      String? tripId,
    ) = switch (widget.subject) {
      CardSubject.catchItem => () {
        final data = ref.watch(catchCardDataProvider(widget.id));
        final tripId = ref.watch(catchProvider(widget.id)).value?.tripId;
        if (data == null) return (null, null, null, tripId);
        return (
          CatchCardView(
            data: _showPlace ? data : data.withoutPlace(),
            style: _style,
            format: _format,
          ),
          data.place,
          data.photoPath,
          tripId,
        );
      }(),
      CardSubject.trip => () {
        final data = ref.watch(tripCardDataProvider(widget.id));
        if (data == null) return (null, null, null, widget.id);
        return (
          TripCardView(
            data: _showPlace ? data : data.withoutPlace(),
            style: _style,
            format: _format,
          ),
          data.place,
          data.photoPath,
          widget.id,
        );
      }(),
    };
    final privacy = tripId == null
        ? null
        : ref.watch(tripProvider(tripId)).value?.privacyLevel;
    final placeNote = switch ((place, privacy)) {
      (null, PrivacyLevel.private || PrivacyLevel.friends) =>
        l10n.cardPlacePrivate,
      (null, _) => l10n.cardPlaceUnknown,
      (_, PrivacyLevel.approximate) => l10n.cardPlaceRegion,
      _ => null,
    };

    return Scaffold(
      appBar: AppBar(title: Text(l10n.cardCreate)),
      body: card == null
          ? const SizedBox()
          : Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      PiscatioSizes.gutter,
                      4,
                      PiscatioSizes.gutter,
                      16,
                    ),
                    child: Center(
                      child: Semantics(
                        image: true,
                        label: l10n.cardPreviewLabel(
                          _styleName(_style),
                          _formatName(_format),
                        ),
                        excludeSemantics: true,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              PiscatioRadii.thumb,
                            ),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              PiscatioRadii.thumb,
                            ),
                            child: FittedBox(
                              child: RepaintBoundary(
                                key: _boundary,
                                child: card,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                _ChipRow(
                  children: [
                    for (final s in CardStyle.values)
                      ChoiceChip(
                        label: Text(_styleName(s)),
                        selected: _style == s,
                        showCheckmark: false,
                        onSelected: (_) => setState(() => _style = s),
                      ),
                  ],
                ),
                _ChipRow(
                  children: [
                    for (final f in CardFormat.values)
                      ChoiceChip(
                        label: Text(_formatName(f)),
                        selected: _format == f,
                        showCheckmark: false,
                        onSelected: (_) => setState(() => _format = f),
                      ),
                  ],
                ),
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: PiscatioSizes.gutter,
                  ),
                  title: Text(l10n.cardShowPlace),
                  subtitle: placeNote == null ? null : Text(placeNote),
                  value: place != null && _showPlace,
                  onChanged: place == null
                      ? null
                      : (v) => setState(() => _showPlace = v),
                ),
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
          label: l10n.cardShare,
          icon: Icons.ios_share_rounded,
          onPressed: card == null || _sharing ? null : () => _share(photo),
        ),
      ),
    );
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: PiscatioSizes.minTouch,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: PiscatioSizes.gutter),
        children: [
          for (final (i, c) in children.indexed) ...[
            if (i > 0) const SizedBox(width: 8),
            Center(child: c),
          ],
        ],
      ),
    );
  }
}
