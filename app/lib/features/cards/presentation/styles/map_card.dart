import 'package:flutter/material.dart';

import '../../../../core/formatting/l10n.dart';
import '../../../../domain/services/map_sketch.dart';
import '../../application/card_data.dart';
import '../card_canvas.dart';
import '../card_theme.dart';
import '../painters/chart_painters.dart';
import '../painters/map_painter.dart';
import 'chart_card.dart' show stableSeed;

/// Map inks for a printed sketch map: the board's white for land, its ink
/// for water, the accent for the ring.
MapInks posterMapInks(CardPalette p) => MapInks(
  land: p.board,
  water: p.boardInk,
  contour: Color.lerp(p.boardInk, p.board, 0.24)!,
  road: Color.lerp(p.board, p.boardInk, 0.3)!,
  ring: p.accentInk,
  label: p.boardInk,
  float: (p.boardInk, p.board),
);

/// Map: the place first. A printed sketch of the water around it with the
/// ring where the fish came from (never the exact spot), the photo as a
/// medallion, then what was caught.
class MapCatchCard extends StatelessWidget {
  const MapCatchCard({super.key, required this.data, required this.format});

  final CatchCardData data;
  final CardFormat format;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final record = data.record;
    return _MapLayout(
      format: format,
      seed: stableSeed(data.id),
      map: data.map,
      scale: data.mapScale,
      photoPath: data.photoPath,
      title: data.place ?? data.speciesName,
      subtitle: data.place == null ? data.scientificName : data.speciesName,
      headline: data.headline,
      caption: data.caption,
      record: record == null
          ? null
          : record.isFirst
          ? l10n.cardFirstOfSpecies
          : record.improvement == null
          ? l10n.cardRecord
          : l10n.cardRecordImprovement(record.improvement!),
      facts: [
        data.dateLabel,
        data.timeLabel,
        if (data.lengthLabel != null) ?data.weightLabel,
        ?data.baitLabel,
      ],
    );
  }
}

class MapTripCard extends StatelessWidget {
  const MapTripCard({super.key, required this.data, required this.format});

  final TripCardData data;
  final CardFormat format;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _MapLayout(
      format: format,
      seed: stableSeed(data.id),
      map: data.map,
      scale: data.mapScale,
      photoPath: data.photoPath,
      title: data.place ?? data.dateLabel,
      subtitle:
          '${cardNumber(context, data.speciesCount.toDouble())} '
          '${l10n.speciesCountLabel(data.speciesCount)}',
      headline: [
        CardQuantity(
          cardNumber(context, data.catchCount.toDouble()),
          l10n.catchCountLabel(data.catchCount),
        ),
      ],
      caption: data.caption,
      record: data.recordCount > 0
          ? l10n.cardRecordCount(data.recordCount)
          : null,
      facts: [
        if (data.place != null) data.dateLabel,
        data.timeRangeLabel,
        data.durationLabel,
      ],
    );
  }
}

class _MapLayout extends StatelessWidget {
  const _MapLayout({
    required this.format,
    required this.seed,
    required this.map,
    required this.scale,
    required this.photoPath,
    required this.title,
    required this.subtitle,
    required this.headline,
    required this.caption,
    required this.record,
    required this.facts,
  });

  final CardFormat format;
  final int seed;
  final MapSketch? map;
  final CardMapScale? scale;
  final String? photoPath;
  final String title;
  final String? subtitle;
  final List<CardQuantity> headline;
  final String? caption;
  final String? record;
  final List<String> facts;

  @override
  Widget build(BuildContext context) {
    final story = format == CardFormat.story;
    final signature = CardSignature.originFor(format);
    final hasPhoto = CardPhoto.exists(photoPath);
    final medallion = story ? 300.0 : 250.0;
    final frame = _MapFrame(map: map, scale: scale, seed: seed);
    final text = _Text(
      story: story,
      title: title,
      subtitle: subtitle,
      headline: headline,
      caption: caption,
      record: record,
      facts: facts,
    );
    if (story) {
      const mapTop = 400.0;
      const mapHeight = 800.0;
      return Stack(
        children: [
          Positioned(
            left: signature.dx,
            top: signature.dy,
            child: CardSignature(format: format),
          ),
          Positioned(
            left: 60,
            right: 60,
            top: mapTop,
            height: mapHeight,
            child: frame,
          ),
          // Over the map's top corner: clear of the brand and of the scale
          // and credit along the map's bottom edge.
          if (hasPhoto)
            Positioned(
              right: 84,
              top: mapTop - medallion * 0.42,
              child: _Medallion(path: photoPath!, size: medallion),
            ),
          Positioned(
            left: 72,
            right: 72,
            top: mapTop + mapHeight + 44,
            bottom: CardSafeArea.storyBottom,
            child: text,
          ),
        ],
      );
    }
    return Stack(
      children: [
        Positioned(
          left: signature.dx,
          top: signature.dy,
          child: CardSignature(format: format),
        ),
        Positioned(left: 60, top: 170, width: 560, bottom: 60, child: frame),
        Positioned(
          left: 660,
          right: 60,
          top: hasPhoto ? 170 + medallion + 28 : 170,
          bottom: 60,
          child: text,
        ),
        if (hasPhoto)
          Positioned(
            left: 660,
            top: 170,
            child: _Medallion(path: photoPath!, size: medallion),
          ),
      ],
    );
  }
}

/// The printed map in its frame; decorative contours when there is no map
/// (hidden by the person, or not allowed).
class _MapFrame extends StatelessWidget {
  const _MapFrame({required this.map, required this.scale, required this.seed});

  final MapSketch? map;
  final CardMapScale? scale;
  final int seed;

  @override
  Widget build(BuildContext context) {
    final p = context.cardPalette;
    final l10n = context.l10n;
    final map = this.map;
    final inks = posterMapInks(p);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: inks.land,
        border: Border.all(color: p.text.withValues(alpha: 0.9), width: 4),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: ClipRect(
          child: map == null
              ? CustomPaint(
                  size: Size.infinite,
                  painter: ContourPainter(
                    seed: seed,
                    line: inks.contour,
                    strongLine: inks.road,
                    soundingStyle: CardType.text(
                      24,
                      style: FontStyle.italic,
                      color: inks.road,
                    ),
                  ),
                )
              : CardMapFrame(
                  focusShift: MapPainter.focusShift,
                  painter: (frame) {
                    final bar = scale?.forZoom(map.metersPerUnit, frame.zoom);
                    return MapPainter(
                      sketch: map,
                      inks: inks,
                      labelStyle: CardType.condensed(28, color: inks.label),
                      attribution: l10n.mapAttribution,
                      scaleMeters: bar?.meters,
                      scaleLabel: bar?.label,
                      north: l10n.compassN,
                      zoom: frame.zoom,
                      focus: frame.focus,
                    );
                  },
                ),
        ),
      ),
    );
  }
}

/// The catch photo in a round frame, pinned over the map's corner.
class _Medallion extends StatelessWidget {
  const _Medallion({required this.path, required this.size});

  final String path;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.cardPalette;
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: p.ground,
        border: Border.all(color: p.text.withValues(alpha: 0.9), width: 4),
      ),
      child: ClipOval(child: CardPhoto(path: path)),
    );
  }
}

class _Text extends StatelessWidget {
  const _Text({
    required this.story,
    required this.title,
    required this.subtitle,
    required this.headline,
    required this.caption,
    required this.record,
    required this.facts,
  });

  final bool story;
  final String title;
  final String? subtitle;
  final List<CardQuantity> headline;
  final String? caption;
  final String? record;
  final List<String> facts;

  @override
  Widget build(BuildContext context) {
    final p = context.cardPalette;
    final details = <Widget>[
      Text(
        title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: CardType.text(
          story ? 78 : 50,
          weight: FontWeight.w800,
          height: 1.02,
          letterSpacing: story ? -1.6 : -1,
        ),
      ),
      if (subtitle != null) ...[
        SizedBox(height: story ? 10 : 6),
        Text(
          subtitle!,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: CardType.text(
            story ? 44 : 32,
            weight: FontWeight.w600,
            color: p.soft,
          ),
        ),
      ],
      if (headline.isNotEmpty) ...[
        SizedBox(height: story ? 18 : 12),
        CardHeadline(
          parts: headline,
          size: story ? 140 : 96,
          unitColor: p.muted,
        ),
      ],
      if (record != null) ...[
        SizedBox(height: story ? 14 : 10),
        Text(
          record!,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: CardType.text(
            story ? 40 : 30,
            weight: FontWeight.w700,
            color: p.record,
          ),
        ),
      ],
      if (caption != null) ...[
        SizedBox(height: story ? 14 : 10),
        Text(
          caption!,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: CardType.text(
            story ? 38 : 28,
            weight: FontWeight.w600,
            style: FontStyle.italic,
            color: p.soft,
          ),
        ),
      ],
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Everything the person chose must fit: the block shrinks rather
        // than spill over the platform's reply bar.
        Flexible(
          child: LayoutBuilder(
            builder: (context, box) => FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: box.maxWidth,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: details,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: story ? 20 : 14),
        Wrap(
          spacing: story ? 34 : 22,
          runSpacing: 8,
          children: [
            for (final f in facts)
              Text(
                f,
                style: CardType.text(
                  story ? 32 : 26,
                  weight: FontWeight.w500,
                  color: p.muted,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
