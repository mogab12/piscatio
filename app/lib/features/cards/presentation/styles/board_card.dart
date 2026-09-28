import 'package:flutter/material.dart';

import '../../../../core/formatting/l10n.dart';
import '../../application/card_data.dart';
import '../card_canvas.dart';
import '../card_theme.dart';
import '../painters/board_painter.dart';

/// Board: the photo, and at the bottom the measuring board with a red
/// notch at the fish's length. A record shows as the previous best's gold
/// mark on the same scale: the gap between the marks is the improvement.
class BoardCatchCard extends StatelessWidget {
  const BoardCatchCard({super.key, required this.data, required this.format});

  final CatchCardData data;
  final CardFormat format;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final story = format == CardFormat.story;
    final hasPhoto = CardPhoto.exists(data.photoPath);
    final s = data.ruler;
    final record = data.record;
    final previous = s.previous;
    final secondary = data.lengthLabel != null ? data.weightLabel : null;
    return _BoardLayout(
      format: format,
      photoPath: data.photoPath,
      board: BoardPainter(
        ticks: scaleTicks(s, (v) => cardNumber(context, v)),
        marks: [
          if (record != null && !record.isFirst && previous != null)
            BoardMark(
              s.fraction(previous),
              CardInk.gold,
              notch: false,
              label: data.previousRecordLabel == null
                  ? null
                  : l10n.cardPreviousRecord(data.previousRecordLabel!),
            ),
          BoardMark(s.fraction(s.value), CardInk.red),
        ],
        numberStyle: CardType.condensed(
          story ? 34 : 30,
          weight: FontWeight.w800,
        ),
        printStyle: CardType.condensed(story ? 26 : 23),
        unitLabel: data.rulerUnit,
        brand: l10n.brandName,
        brandNotch: CardInk.red,
      ),
      children: [
        if (record != null)
          _RecordLine(
            record.isFirst
                ? l10n.cardFirstOfSpecies
                : record.improvement == null
                ? l10n.cardRecord
                : l10n.cardRecordImprovement(record.improvement!),
            story: story,
          ),
        if (data.headline.isNotEmpty)
          CardHeadline(
            parts: data.headline,
            size: story ? (hasPhoto ? 270 : 340) : 210,
          )
        else
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.bottomLeft,
            child: Text(
              data.timeLabel,
              style: CardType.numbers(story ? 240 : 180),
            ),
          ),
        SizedBox(height: story ? 28 : 20),
        Text(
          data.speciesName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: CardType.text(
            story ? 82 : 64,
            weight: FontWeight.w700,
            height: 1.02,
            letterSpacing: story ? -1.6 : -1.2,
          ),
        ),
        if (data.scientificName != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              data.scientificName!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CardType.text(
                story ? 38 : 32,
                style: FontStyle.italic,
                color: CardInk.muted,
              ),
            ),
          ),
        SizedBox(height: story ? 32 : 22),
        _Facts(
          story: story,
          facts: [
            data.dateLabel,
            if (data.headline.isNotEmpty) data.timeLabel,
            ?secondary,
            ?data.place,
          ],
        ),
      ],
    );
  }
}

/// Board for a trip: the board becomes the trip's time scale (hours from
/// the start), shaded as far as it lasted, with a notch per catch.
class BoardTripCard extends StatelessWidget {
  const BoardTripCard({super.key, required this.data, required this.format});

  final TripCardData data;
  final CardFormat format;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final story = format == CardFormat.story;
    final hasPhoto = CardPhoto.exists(data.photoPath);
    return _BoardLayout(
      format: format,
      photoPath: data.photoPath,
      board: BoardPainter(
        ticks: hourTicks(data.spanHours),
        marks: [
          for (final c in data.catches)
            BoardMark(c.offset, c.isRecord ? CardInk.gold : CardInk.red),
        ],
        numberStyle: CardType.condensed(
          story ? 34 : 30,
          weight: FontWeight.w800,
        ),
        printStyle: CardType.condensed(story ? 26 : 23),
        unitLabel: l10n.cardHoursUnit,
        brand: l10n.brandName,
        brandNotch: CardInk.red,
        fillFraction: data.elapsedFraction,
        fillColor: const Color(0xFFDDE7E5),
        notchScale: 0.55,
      ),
      children: [
        if (data.recordCount > 0)
          _RecordLine(l10n.cardRecordCount(data.recordCount), story: story),
        CardHeadline(
          parts: [
            CardQuantity(
              cardNumber(context, data.catchCount.toDouble()),
              l10n.catchCountLabel(data.catchCount),
            ),
          ],
          size: story ? (hasPhoto ? 270 : 340) : 210,
        ),
        SizedBox(height: story ? 36 : 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Stat(
              value: data.durationLabel,
              label: l10n.tripStatDuration,
              story: story,
            ),
            SizedBox(width: story ? 64 : 48),
            _Stat(
              value: cardNumber(context, data.speciesCount.toDouble()),
              label: l10n.speciesCountLabel(data.speciesCount),
              story: story,
            ),
          ],
        ),
        if (data.biggestLabel != null && story) ...[
          const SizedBox(height: 28),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${l10n.cardFieldBiggest}  ',
                  style: CardType.text(36, color: CardInk.muted),
                ),
                TextSpan(
                  text: data.biggestLabel,
                  style: CardType.text(36, weight: FontWeight.w600),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        SizedBox(height: story ? 32 : 22),
        _Facts(
          story: story,
          facts: [data.dateLabel, data.timeRangeLabel, ?data.place],
        ),
      ],
    );
  }
}

/// Photo, scrim, the text block and the board along the bottom.
class _BoardLayout extends StatelessWidget {
  const _BoardLayout({
    required this.format,
    required this.photoPath,
    required this.board,
    required this.children,
  });

  final CardFormat format;
  final String? photoPath;
  final BoardPainter board;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final story = format == CardFormat.story;
    final margin = story ? 72.0 : 60.0;
    final boardHeight = story ? 210.0 : 160.0;
    final hasPhoto = CardPhoto.exists(photoPath);
    return Stack(
      children: [
        Positioned.fill(child: CardPhoto(path: photoPath)),
        if (hasPhoto)
          // Functional scrim: only where the text sits.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: story ? const [0.28, 0.6, 0.86] : const [0, 0.5, 0.86],
                  colors: [
                    CardInk.water.withValues(alpha: 0),
                    CardInk.water.withValues(alpha: 0.72),
                    CardInk.water.withValues(alpha: 0.94),
                  ],
                ),
              ),
            ),
          ),
        Positioned(
          left: margin,
          right: margin,
          bottom: margin + boardHeight + (story ? 64 : 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
        Positioned(
          left: margin - 28,
          right: margin - 28,
          bottom: margin,
          height: boardHeight,
          child: CustomPaint(painter: board),
        ),
      ],
    );
  }
}

class _RecordLine extends StatelessWidget {
  const _RecordLine(this.text, {required this.story});

  final String text;
  final bool story;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: story ? 18 : 12),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: CardType.text(
          story ? 40 : 34,
          weight: FontWeight.w700,
          color: CardInk.gold,
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, required this.story});

  final String value;
  final String label;
  final bool story;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: CardType.numbers(
            story ? 64 : 52,
            weight: FontWeight.w800,
          ).copyWith(height: 1),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: CardType.text(story ? 32 : 28, color: CardInk.muted),
        ),
      ],
    );
  }
}

/// Quiet facts in one wrapping row, spaced apart (no separators).
class _Facts extends StatelessWidget {
  const _Facts({required this.facts, required this.story});

  final List<String> facts;
  final bool story;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: story ? 36 : 28,
      runSpacing: 10,
      children: [
        for (final f in facts)
          Text(
            f,
            style: CardType.text(
              story ? 34 : 30,
              weight: FontWeight.w500,
              color: CardInk.foam,
            ),
          ),
      ],
    );
  }
}
