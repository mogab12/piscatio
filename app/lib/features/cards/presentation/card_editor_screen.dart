import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/background.dart';
import '../../../core/formatting/l10n.dart';
import '../../../core/providers.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/action_slab.dart';
import '../../../core/widgets/choice_sheet.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/social.dart';
import '../../community/application/community.dart';
import '../../community/presentation/publish_sheet.dart';
import '../application/card_builder.dart';
import '../application/card_data.dart';
import '../application/card_exporter.dart';
import '../application/card_map.dart';
import '../application/photo_filter_service.dart';
import '../application/photo_filters.dart';
import '../application/stories_sharer.dart';
import 'card_view.dart';

enum CardSubject { catchItem, trip }

enum _Section { style, theme, photo, frame, details, caption }

enum _ShareTarget { community, stories, apps }

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
  /// Chosen by the person; until then [_styleFor] picks one.
  CardStyle? _style;
  var _format = CardFormat.story;
  var _options = const CardOptions();
  var _section = _Section.style;
  var _sharing = false;
  var _filtering = false;

  /// Only the latest filter request may update the card.
  var _filterRequest = 0;

  /// The map is asked for once, when the editor finds it missing.
  var _mapRequested = false;
  final _boundary = GlobalKey();
  final _caption = TextEditingController();

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  /// The cover shows the brand best, but needs a photo.
  CardStyle _styleFor(String? photo) =>
      _style ?? (photo != null ? CardStyle.cover : CardStyle.board);

  String _styleName(CardStyle s) => switch (s) {
    CardStyle.board => context.l10n.cardStyleBoard,
    CardStyle.cover => context.l10n.cardStyleCover,
    CardStyle.chart => context.l10n.cardStyleChart,
    CardStyle.tag => context.l10n.cardStyleTag,
    CardStyle.map => context.l10n.cardStyleMap,
  };

  String _formatName(CardFormat f) => switch (f) {
    CardFormat.story => context.l10n.cardFormatStory,
    CardFormat.square => context.l10n.cardFormatSquare,
  };

  String _sectionName(_Section s) => switch (s) {
    _Section.style => context.l10n.cardSectionStyle,
    _Section.theme => context.l10n.cardSectionTheme,
    _Section.photo => context.l10n.cardSectionPhoto,
    _Section.frame => context.l10n.cardSectionFrame,
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

  String _filterName(CardPhotoFilter f) => switch (f) {
    CardPhotoFilter.none => context.l10n.cardFilterNone,
    CardPhotoFilter.rupestre => context.l10n.cardFilterRupestre,
    CardPhotoFilter.engraving => context.l10n.cardFilterEngraving,
    CardPhotoFilter.halftone => context.l10n.cardFilterHalftone,
    CardPhotoFilter.duotone => context.l10n.cardFilterDuotone,
  };

  void _set(CardOptions o) => setState(() => _options = o);

  /// A drag or pinch on the card while framing.
  void _frame(CardFrameTarget target, CardFrame frame) => _set(
    target == CardFrameTarget.photo
        ? _options.copyWith(photoFrame: frame)
        : _options.copyWith(mapFrame: frame),
  );

  /// Shows [filter] on [source] as soon as its filtered version is ready
  /// (made off the UI thread, then cached).
  Future<void> _applyFilter(CardPhotoFilter filter, String? source) async {
    final request = ++_filterRequest;
    final pending = filter != CardPhotoFilter.none && source != null;
    setState(() {
      _options = _options.withFilter(filter);
      _filtering = pending;
    });
    if (!pending) return;
    final messenger = ScaffoldMessenger.of(context);
    final failed = context.l10n.cardFilterFailed;
    String? path;
    try {
      path = await ref
          .read(photoFilterServiceProvider)
          .separation(source, filter);
    } on Exception {
      path = null;
    }
    if (!mounted || request != _filterRequest) return;
    setState(() {
      _filtering = false;
      _options = _options.withFilter(
        path == null ? CardPhotoFilter.none : filter,
        filteredPath: path,
      );
    });
    if (path == null) {
      messenger.showSnackBar(SnackBar(content: Text(failed)));
    }
  }

  /// The card as shown, as PNG at its canvas size.
  Future<Uint8List> _capture(String? photoPath) async {
    if (photoPath != null && File(photoPath).existsSync()) {
      await precacheImage(FileImage(File(photoPath)), context);
    }
    await WidgetsBinding.instance.endOfFrame;
    final boundary =
        _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    return captureCard(boundary);
  }

  /// Where the card goes: the community (signed in), Instagram Stories
  /// (when it can take it) or any other app. With only the last, straight
  /// to the share sheet.
  Future<void> _share(String? photoPath, CardStyle style) async {
    final l10n = context.l10n;
    FocusScope.of(context).unfocus();
    final signedIn = await ref.read(accountRepositoryProvider).read() != null;
    final stories = await ref.read(storiesSharerProvider).available();
    if (!mounted) return;
    var target = _ShareTarget.apps;
    if (signedIn || stories) {
      final picked = await showModalBottomSheet<_ShareTarget>(
        context: context,
        useRootNavigator: true,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  PiscatioSizes.gutter,
                  0,
                  PiscatioSizes.gutter,
                  12,
                ),
                child: Text(
                  l10n.shareTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              for (final (t, label) in [
                if (signedIn) (_ShareTarget.community, l10n.publishTitle),
                if (stories) (_ShareTarget.stories, l10n.shareToStories),
                (_ShareTarget.apps, l10n.shareToApps),
              ])
                ChoiceRow(
                  label: label,
                  selected: false,
                  onTap: () => Navigator.of(context).pop(t),
                ),
            ],
          ),
        ),
      );
      if (picked == null || !mounted) return;
      target = picked;
    }
    switch (target) {
      case _ShareTarget.community:
        await _publish(photoPath);
      case _ShareTarget.stories:
        await _toStories(photoPath);
      case _ShareTarget.apps:
        await _toApps(photoPath, style);
    }
  }

  Future<void> _toApps(String? photoPath, CardStyle style) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final sharer = ref.read(cardSharerProvider);
    setState(() => _sharing = true);
    try {
      final png = await _capture(photoPath);
      final name = 'piscatio-${style.name}-${_format.name}.png';
      await sharer.sharePng(png, name);
    } on Exception {
      messenger.showSnackBar(SnackBar(content: Text(l10n.cardShareFailed)));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _toStories(String? photoPath) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final stories = ref.read(storiesSharerProvider);
    setState(() => _sharing = true);
    try {
      final png = await _capture(photoPath);
      final ground = _options.palette.ground;
      final opened = await stories.share(
        png,
        sticker: _format != CardFormat.story,
        top: ground,
        bottom: ground,
      );
      if (!opened) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.storiesFailed)));
      }
    } on Exception {
      messenger.showSnackBar(SnackBar(content: Text(l10n.cardShareFailed)));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  /// Publishes the card to the community: the person picks who sees it,
  /// the card is drawn for that audience (friends may see the region) and
  /// queued; it goes up as soon as there is internet.
  Future<void> _publish(String? photoPath) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    SocialProfile? profile;
    var known = false;
    // Listened while asked: a provider nobody listens to is paused.
    final listening = ref.listenManual(myProfileProvider, (_, _) {});
    try {
      profile = await ref
          .read(myProfileProvider.future)
          .timeout(const Duration(seconds: 8));
      known = true;
    } on Object {
      // Offline: queue anyway; the community tab explains if it fails.
    } finally {
      listening.close();
    }
    if (!mounted) return;
    if (known && profile == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.publishNeedsProfile),
          action: SnackBarAction(
            label: l10n.communityCreateAction,
            onPressed: () => router.push(AppRoutes.communityProfile),
          ),
        ),
      );
      return;
    }
    final choice = await showPublishSheet(context);
    if (choice == null || !mounted) return;
    final (audience, caption) = choice;
    final community = ref.read(communityControllerProvider);
    final (kind, tripId, catchId, speciesId) = switch (widget.subject) {
      CardSubject.catchItem => () {
        final item = ref.read(catchProvider(widget.id)).value;
        return (PostKind.catchCard, item?.tripId, widget.id, item?.speciesId);
      }(),
      CardSubject.trip => (PostKind.tripCard, widget.id, null, null),
    };
    final venueId = tripId == null
        ? null
        : ref.read(tripProvider(tripId)).value?.venueId;
    setState(() {
      _sharing = true;
      _options = _options.copyWith(audience: audience);
    });
    try {
      final png = await _capture(photoPath);
      final size = _format.size;
      await community.publish(
        png: png,
        width: size.width.round(),
        height: size.height.round(),
        kind: kind,
        audience: audience,
        tripId: tripId,
        catchId: catchId,
        speciesId: speciesId,
        venueId: venueId,
        caption: caption,
      );
      messenger.showSnackBar(SnackBar(content: Text(l10n.publishQueued)));
    } on Exception {
      messenger.showSnackBar(SnackBar(content: Text(l10n.cardShareFailed)));
    } finally {
      if (mounted) {
        setState(() {
          _sharing = false;
          _options = _options.copyWith(audience: CardAudience.everyone);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final onFrame = _section == _Section.frame ? _frame : null;
    // Only the chart and map styles draw the map.
    bool drawsMap(CardStyle s) => s == CardStyle.chart || s == CardStyle.map;
    final (
      Widget? card,
      String? place,
      String? shownPhoto,
      String? defaultPhoto,
      List<String> photos,
      String? tripId,
      bool mapShown,
    ) = switch (widget.subject) {
      CardSubject.catchItem => () {
        final data = ref.watch(catchCardDataProvider(widget.id));
        final tripId = ref.watch(catchProvider(widget.id)).value?.tripId;
        if (data == null) {
          return (null, null, null, null, <String>[], tripId, false);
        }
        final view = CatchCardView(
          data: data,
          style: _styleFor(data.photoPath),
          format: _format,
          options: _options,
          onFrame: onFrame,
        );
        return (
          view,
          data.place,
          view.shown.photoPath,
          data.photoPath,
          data.photoOptions,
          tripId,
          view.shown.map != null && drawsMap(view.style),
        );
      }(),
      CardSubject.trip => () {
        final data = ref.watch(tripCardDataProvider(widget.id));
        if (data == null) {
          return (null, null, null, null, <String>[], widget.id, false);
        }
        final view = TripCardView(
          data: data,
          style: _styleFor(data.photoPath),
          format: _format,
          options: _options,
          onFrame: onFrame,
        );
        return (
          view,
          data.place,
          view.shown.photoPath,
          data.photoPath,
          data.photoOptions,
          widget.id,
          view.shown.map != null && drawsMap(view.style),
        );
      }(),
    };
    final sourcePhoto = _options.sourcePhoto(defaultPhoto);
    final style = _styleFor(defaultPhoto);
    final privacy = tripId == null
        ? null
        : ref.watch(tripProvider(tripId)).value?.privacyLevel;
    final mapState = tripId == null
        ? CardMapState.noPlace
        : ref.watch(tripMapProvider(tripId)).state;
    if (mapState == CardMapState.pending && privacy != null && !_mapRequested) {
      _mapRequested = true;
      final work = ref.read(backgroundWorkProvider);
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => work.mapFor(tripId!, privacy),
      );
    }
    final mapNote = switch (mapState) {
      CardMapState.ready => l10n.cardMapArea,
      CardMapState.noPlace => l10n.cardMapNoPlace,
      CardMapState.private => l10n.cardMapPrivate,
      CardMapState.pending => l10n.cardMapPending,
      CardMapState.empty => l10n.cardMapEmpty,
    };
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
                  selected: style == s,
                  showCheckmark: false,
                  onSelected:
                      s == CardStyle.map &&
                          mapState != CardMapState.ready &&
                          style != s
                      ? null
                      : (_) => setState(() => _style = s),
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
      _Section.theme => Column(
        children: [
          _ChipRow(
            height: 96,
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
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: PiscatioSizes.gutter,
            ),
            child: _ToggleTile(
              icon: Icons.format_color_fill_rounded,
              label: l10n.cardThemePhoto,
              value: _options.photoThemed,
              onChanged: shownPhoto == null
                  ? null
                  : (v) => _set(_options.copyWith(photoThemed: v)),
            ),
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
            : Column(
                children: [
                  _ChipRow(
                    children: [
                      for (final f in CardPhotoFilter.values)
                        ChoiceChip(
                          label: Text(_filterName(f)),
                          selected: _options.photoFilter == f,
                          showCheckmark: false,
                          onSelected: sourcePhoto == null
                              ? null
                              : (_) => _applyFilter(f, sourcePhoto),
                        ),
                    ],
                  ),
                  _ChipRow(
                    height: 96,
                    children: [
                      _PhotoTile(
                        label: l10n.cardNoPhoto,
                        selected: sourcePhoto == null,
                        onTap: () {
                          _set(_options.withPhoto(null));
                          _applyFilter(_options.photoFilter, null);
                        },
                      ),
                      for (final (i, p) in photos.indexed)
                        _PhotoTile(
                          path: p,
                          label: l10n.cardPhotoOption('${i + 1}'),
                          selected: sourcePhoto == p,
                          onTap: () {
                            _set(_options.withPhoto(p));
                            _applyFilter(_options.photoFilter, p);
                          },
                        ),
                    ],
                  ),
                ],
              ),
      _Section.frame => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: PiscatioSizes.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              shownPhoto != null || mapShown
                  ? l10n.cardFrameHint
                  : l10n.cardFrameNothing,
              style: Theme.of(context).textTheme.bodyMedium!
                  .copyWith(color: context.palette.muted),
            ),
            if (shownPhoto != null)
              _ZoomRow(
                label: l10n.cardFramePhoto,
                target: CardFrameTarget.photo,
                frame: _options.photoFrame,
                onChanged: (f) => _frame(CardFrameTarget.photo, f),
              ),
            if (mapShown)
              _ZoomRow(
                label: l10n.cardFrameMap,
                target: CardFrameTarget.map,
                frame: _options.mapFrame,
                onChanged: (f) => _frame(CardFrameTarget.map, f),
              ),
          ],
        ),
      ),
      _Section.details => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: PiscatioSizes.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ToggleGrid(
              children: [
                _ToggleTile(
                  icon: Icons.place_outlined,
                  label: l10n.cardShowPlace,
                  value: place != null && _options.showPlace,
                  onChanged: place == null
                      ? null
                      : (v) => _set(_options.copyWith(showPlace: v)),
                ),
                _ToggleTile(
                  icon: Icons.cloud_outlined,
                  label: l10n.cardShowWeather,
                  value: _options.showWeather,
                  onChanged: (v) => _set(_options.copyWith(showWeather: v)),
                ),
                _ToggleTile(
                  icon: Icons.set_meal_outlined,
                  label: l10n.cardShowBait,
                  value: _options.showBait,
                  onChanged: (v) => _set(_options.copyWith(showBait: v)),
                ),
                _ToggleTile(
                  icon: Icons.map_outlined,
                  label: l10n.cardShowMap,
                  value: mapState == CardMapState.ready && _options.showMap,
                  onChanged: mapState != CardMapState.ready
                      ? null
                      : (v) => _set(_options.copyWith(showMap: v)),
                ),
              ],
            ),
            for (final note in [?placeNote, mapNote]) ...[
              const SizedBox(height: 6),
              Text(
                note,
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
                          _styleName(style),
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
                if (_filtering)
                  LinearProgressIndicator(
                    minHeight: 2,
                    semanticsLabel: l10n.cardFilterWorking,
                  )
                else
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
                            _Section.frame => Icons.crop_rounded,
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
                  height: 164,
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
          onPressed: card == null || _sharing
              ? null
              : () => _share(shownPhoto, style),
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
/// Zoom of the photo or the map: the same as pinching, for those who
/// prefer (or need) a slider.
class _ZoomRow extends StatelessWidget {
  const _ZoomRow({
    required this.label,
    required this.target,
    required this.frame,
    required this.onChanged,
  });

  final String label;
  final CardFrameTarget target;
  final CardFrame frame;
  final ValueChanged<CardFrame> onChanged;

  @override
  Widget build(BuildContext context) {
    final max = CardFrame.maxZoomFor(target);
    final percent = NumberFormat.percentPattern(
      Localizations.localeOf(context).toString(),
    );
    return Row(
      children: [
        SizedBox(
          width: 104,
          child: Text(label, style: Theme.of(context).textTheme.labelLarge),
        ),
        Expanded(
          child: Slider(
            value: frame.zoom.clamp(1.0, max),
            min: 1,
            max: max,
            semanticFormatterCallback: percent.format,
            onChanged: (v) => onChanged(
              CardFrame(zoom: v, focus: frame.focus).clampFor(target),
            ),
          ),
        ),
        IconButton(
          tooltip: context.l10n.cardFrameReset,
          icon: const Icon(Icons.restart_alt_rounded),
          onPressed: frame.isFill ? null : () => onChanged(CardFrame.fill),
        ),
      ],
    );
  }
}

/// Two columns of [_ToggleTile]s.
class _ToggleGrid extends StatelessWidget {
  const _ToggleGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      const gap = 8.0;
      final width = (box.maxWidth - gap) / 2;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [for (final c in children) SizedBox(width: width, child: c)],
      );
    },
  );
}

/// One detail of the card that can be shown or hidden: its name always
/// readable, a switch that says plainly whether it is on. The whole tile
/// toggles it; greyed out when the card has nothing to show for it.
class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onChanged != null;
    final ink = enabled ? scheme.onSurface : context.palette.muted;
    return MergeSemantics(
      child: Material(
        color: value ? scheme.surfaceContainerHigh : scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PiscatioRadii.field),
          side: BorderSide(
            color: value ? scheme.onSurface : scheme.outlineVariant,
            width: value ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? () => onChanged!(!value) : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: PiscatioSizes.minTouch,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 0, 6),
              child: Row(
                children: [
                  Icon(icon, size: 18, color: ink),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge!.copyWith(
                        color: ink,
                        fontWeight: value ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: value,
                      onChanged: onChanged,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
              // Six tabs on a narrow phone: the label shrinks to fit.
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.labelMedium!
                      .copyWith(color: color),
                ),
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
