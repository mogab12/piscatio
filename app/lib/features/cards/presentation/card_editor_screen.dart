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

enum _Section { style, theme, photo, details, caption }

/// Make the card yours: style and format, color theme, photo, which
/// details show, a caption. Then share.
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
  var _options = const CardOptions();
  var _section = _Section.style;
  var _sharing = false;
  final _boundary = GlobalKey();
  final _caption = TextEditingController();

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  String _styleName(CardStyle s) => switch (s) {
    CardStyle.board => context.l10n.cardStyleBoard,
    CardStyle.chart => context.l10n.cardStyleChart,
    CardStyle.tag => context.l10n.cardStyleTag,
  };

  String _formatName(CardFormat f) => switch (f) {
    CardFormat.story => context.l10n.cardFormatStory,
    CardFormat.square => context.l10n.cardFormatSquare,
  };

  String _sectionName(_Section s) => switch (s) {
    _Section.style => context.l10n.cardSectionStyle,
    _Section.theme => context.l10n.cardSectionTheme,
    _Section.photo => context.l10n.cardSectionPhoto,
    _Section.details => context.l10n.cardSectionDetails,
    _Section.caption => context.l10n.cardSectionCaption,
  };

  String _paletteName(CardPalette p) => switch (p) {
    CardPalette.redHead => context.l10n.cardThemeRedHead,
    CardPalette.paper => context.l10n.cardThemePaper,
    CardPalette.tucunare => context.l10n.cardThemeTucunare,
    CardPalette.dawn => context.l10n.cardThemeDawn,
    CardPalette.moon => context.l10n.cardThemeMoon,
    CardPalette.river => context.l10n.cardThemeRiver,
  };

  void _set(CardOptions o) => setState(() => _options = o);

  Future<void> _share(String? photoPath) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final sharer = ref.read(cardSharerProvider);
    FocusScope.of(context).unfocus();
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
      String? shownPhoto,
      String? defaultPhoto,
      List<String> photos,
      String? tripId,
    ) = switch (widget.subject) {
      CardSubject.catchItem => () {
        final data = ref.watch(catchCardDataProvider(widget.id));
        final tripId = ref.watch(catchProvider(widget.id)).value?.tripId;
        if (data == null) return (null, null, null, null, <String>[], tripId);
        final view = CatchCardView(
          data: data,
          style: _style,
          format: _format,
          options: _options,
        );
        return (
          view,
          data.place,
          view.shown.photoPath,
          data.photoPath,
          data.photoOptions,
          tripId,
        );
      }(),
      CardSubject.trip => () {
        final data = ref.watch(tripCardDataProvider(widget.id));
        if (data == null) {
          return (null, null, null, null, <String>[], widget.id);
        }
        final view = TripCardView(
          data: data,
          style: _style,
          format: _format,
          options: _options,
        );
        return (
          view,
          data.place,
          view.shown.photoPath,
          data.photoPath,
          data.photoOptions,
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

    final panel = switch (_section) {
      _Section.style => Column(
        children: [
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
        ],
      ),
      _Section.theme => _ChipRow(
        height: 104,
        children: [
          for (final p in CardPalette.values)
            _Swatch(
              palette: p,
              label: _paletteName(p),
              selected: _options.palette == p,
              onTap: () => _set(_options.copyWith(palette: p)),
            ),
        ],
      ),
      _Section.photo =>
        photos.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: PiscatioSizes.gutter,
                ),
                child: Text(
                  l10n.cardNoPhotos,
                  style: Theme.of(context).textTheme.bodyMedium!
                      .copyWith(color: context.palette.muted),
                ),
              )
            : _ChipRow(
                height: 96,
                children: [
                  _PhotoTile(
                    label: l10n.cardNoPhoto,
                    selected: shownPhoto == null,
                    onTap: () => _set(_options.withPhoto(null)),
                  ),
                  for (final (i, p) in photos.indexed)
                    _PhotoTile(
                      path: p,
                      label: l10n.cardPhotoOption('${i + 1}'),
                      selected: _options.photoChosen
                          ? shownPhoto == p
                          : defaultPhoto == p,
                      onTap: () => _set(_options.withPhoto(p)),
                    ),
                ],
              ),
      _Section.details => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: PiscatioSizes.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 4,
              children: [
                FilterChip(
                  label: Text(l10n.cardShowPlace),
                  selected: place != null && _options.showPlace,
                  onSelected: place == null
                      ? null
                      : (v) => _set(_options.copyWith(showPlace: v)),
                ),
                FilterChip(
                  label: Text(l10n.cardShowWeather),
                  selected: _options.showWeather,
                  onSelected: (v) => _set(_options.copyWith(showWeather: v)),
                ),
                FilterChip(
                  label: Text(l10n.cardShowBait),
                  selected: _options.showBait,
                  onSelected: (v) => _set(_options.copyWith(showBait: v)),
                ),
              ],
            ),
            if (placeNote != null) ...[
              const SizedBox(height: 6),
              Text(
                placeNote,
                style: Theme.of(context).textTheme.bodyMedium!
                    .copyWith(color: context.palette.muted),
              ),
            ],
          ],
        ),
      ),
      _Section.caption => Padding(
        padding: const EdgeInsets.symmetric(horizontal: PiscatioSizes.gutter),
        child: TextField(
          controller: _caption,
          maxLength: 80,
          maxLines: 2,
          minLines: 1,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(hintText: l10n.cardCaptionHint),
          onChanged: (v) => _set(_options.copyWith(caption: v)),
        ),
      ),
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
                      12,
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
                const Divider(height: 1),
                Row(
                  children: [
                    for (final s in _Section.values)
                      Expanded(
                        child: _SectionTab(
                          icon: switch (s) {
                            _Section.style =>
                              Icons.dashboard_customize_outlined,
                            _Section.theme => Icons.palette_outlined,
                            _Section.photo => Icons.photo_outlined,
                            _Section.details => Icons.tune_rounded,
                            _Section.caption => Icons.short_text_rounded,
                          },
                          label: _sectionName(s),
                          selected: _section == s,
                          onTap: () => setState(() => _section = s),
                        ),
                      ),
                  ],
                ),
                SizedBox(
                  height: 136,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: panel,
                  ),
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
          onPressed: card == null || _sharing ? null : () => _share(shownPhoto),
        ),
      ),
    );
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({
    required this.children,
    this.height = PiscatioSizes.minTouch,
  });

  final List<Widget> children;
  final double height;

  @override
  Widget build(BuildContext context) {
    // Not lazy: every option is built (and reachable by screen readers).
    return SizedBox(
      height: height,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: PiscatioSizes.gutter),
        child: Row(
          children: [
            for (final (i, c) in children.indexed) ...[
              if (i > 0) const SizedBox(width: 10),
              c,
            ],
          ],
        ),
      ),
    );
  }
}

/// One tab of the editor: icon over a short name, the selected one marked
/// with the accent underline.
class _SectionTab extends StatelessWidget {
  const _SectionTab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? scheme.onSurface : context.palette.muted;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: PiscatioSizes.minTouch),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? scheme.primary : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium!
                    .copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A theme to pick: a disc of its ground with the accent and the record
/// color on it, and its name under it.
class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.palette,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final CardPalette palette;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PiscatioRadii.field),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? ink : Colors.transparent,
                    width: 3,
                  ),
                ),
                child: CustomPaint(
                  painter: _PalettePainter(palette),
                  child: selected
                      ? Icon(Icons.check_rounded, color: palette.text)
                      : null,
                ),
              ),
              const SizedBox(height: 4),
              Text(label, style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _PalettePainter extends CustomPainter {
  _PalettePainter(this.palette);

  final CardPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    canvas
      ..drawCircle(c, r, Paint()..color = palette.ground)
      ..drawCircle(
        c,
        r - 0.5,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = palette.text.withValues(alpha: 0.25),
      )
      ..drawArc(
        Rect.fromCircle(center: c, radius: r),
        -0.6,
        1.9,
        true,
        Paint()..color = palette.accent,
      )
      ..drawCircle(
        c + Offset(-r * 0.42, r * 0.42),
        r * 0.2,
        Paint()..color = palette.record,
      );
  }

  @override
  bool shouldRepaint(_PalettePainter old) => old.palette != palette;
}

/// A photo to pick (or "no photo" when [path] is null).
class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.label,
    required this.selected,
    required this.onTap,
    this.path,
  });

  final String? path;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PiscatioRadii.thumb),
        child: Container(
          width: 80,
          height: 80,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: scheme.surfaceContainer,
            borderRadius: BorderRadius.circular(PiscatioRadii.thumb),
            border: Border.all(
              color: selected ? scheme.onSurface : Colors.transparent,
              width: 3,
            ),
          ),
          child: path == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                )
              : Image.file(
                  File(path!),
                  fit: BoxFit.cover,
                  cacheWidth: 240,
                  errorBuilder: (_, _, _) => const SizedBox(),
                ),
        ),
      ),
    );
  }
}
