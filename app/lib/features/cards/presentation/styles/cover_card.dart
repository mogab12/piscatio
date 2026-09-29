import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/formatting/l10n.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/brand.dart';
import '../../application/card_data.dart';
import '../card_canvas.dart';
import '../card_theme.dart';

/// Cover: the catch on the cover of a fishing magazine called Piscatio.
/// The name is the masthead across the top; the catch is the cover story,
/// with a sticker for records.
class CoverCatchCard extends StatelessWidget {
  const CoverCatchCard({super.key, required this.data, required this.format});

  final CatchCardData data;
  final CardFormat format;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final record = data.record;
    final weather = [?data.moon?.label, ?data.temperatureLabel].join(', ');
    return _CoverLayout(
      format: format,
      photoPath: data.photoPath,
      issue: l10n.cardCatchNumber('${data.catchNumber}'),
      date: data.dateLabel,
      caption: data.caption,
      kicker: data.speciesName,
      headline: data.headline,
      lines: [
        if (data.headline.isEmpty) data.timeLabel,
        if (data.lengthLabel != null) ?data.weightLabel,
        ?data.baitLabel,
        ?data.place,
        if (weather.isNotEmpty) weather,
      ],
      sticker: record == null
          ? null
          : record.isFirst
          ? [l10n.cardFirstOfSpecies]
          : [l10n.cardRecord, ?record.improvement],
    );
  }
}

class CoverTripCard extends StatelessWidget {
  const CoverTripCard({super.key, required this.data, required this.format});

  final TripCardData data;
  final CardFormat format;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _CoverLayout(
      format: format,
      photoPath: data.photoPath,
      issue: data.romanDate,
      date: data.dateLabel,
      caption: data.caption,
      kicker: data.place ?? data.durationLabel,
      headline: [
        CardQuantity(
          cardNumber(context, data.catchCount.toDouble()),
          l10n.catchCountLabel(data.catchCount),
        ),
      ],
      lines: [
        for (final (name, count) in data.speciesTally.take(3))
          '$name ${cardNumber(context, count.toDouble())}',
        if (data.place != null) data.durationLabel,
        ?data.biggestLabel,
      ],
      sticker: data.recordCount > 0
          ? [l10n.cardRecordCount(data.recordCount)]
          : null,
    );
  }
}

class _CoverLayout extends StatelessWidget {
  const _CoverLayout({
    required this.format,
    required this.photoPath,
    required this.issue,
    required this.date,
    required this.caption,
    required this.kicker,
    required this.headline,
    required this.lines,
    required this.sticker,
  });

  final CardFormat format;
  final String? photoPath;
  final String issue;
  final String date;
  final String? caption;
  final String kicker;
  final List<CardQuantity> headline;
  final List<String> lines;
  final List<String>? sticker;

  @override
  Widget build(BuildContext context) {
    final p = context.cardPalette;
    final story = format == CardFormat.story;
    final margin = story ? 64.0 : 56.0;
    final top = story ? CardSafeArea.storyTop - 10 : 44.0;
    final bottom = story ? CardSafeArea.storyBottom : 52.0;
    final hasPhoto = CardPhoto.exists(photoPath);
    final ground = p.ground;
    return Stack(
      children: [
        Positioned.fill(child: CardPhoto(path: photoPath)),
        if (hasPhoto) ...[
          // Under the masthead and under the cover lines only.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  // Deep enough for the caption under the issue line.
                  stops: story ? const [0.16, 0.42] : const [0.12, 0.46],
                  colors: [
                    ground.withValues(alpha: p.dark ? 0.8 : 0.88),
                    ground.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: story
                      ? const [0.42, 0.7, 0.9]
                      : const [0.3, 0.62, 0.9],
                  colors: [
                    ground.withValues(alpha: 0),
                    ground.withValues(alpha: 0.72),
                    ground.withValues(alpha: 0.94),
                  ],
                ),
              ),
            ),
          ),
        ],
        Positioned(
          left: margin,
          right: margin,
          top: top,
          child: _Masthead(
            story: story,
            issue: issue,
            date: date,
            caption: caption,
          ),
        ),
        Positioned(
          left: margin,
          right: margin,
          bottom: bottom,
          child: _CoverLines(
            story: story,
            kicker: kicker,
            headline: headline,
            lines: lines,
          ),
        ),
        if (sticker != null)
          Positioned(
            right: margin - 8,
            bottom: bottom + (story ? 560 : 330),
            child: _Sticker(lines: sticker!, size: story ? 290 : 220),
          ),
      ],
    );
  }
}

/// The magazine's name across the cover, and the issue line under it.
class _Masthead extends StatelessWidget {
  const _Masthead({
    required this.story,
    required this.issue,
    required this.date,
    required this.caption,
  });

  final bool story;
  final String issue;
  final String date;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.cardPalette;
    final size = story ? 210.0 : 150.0;
    final word = TextStyle(
      fontFamily: PiscatioFonts.expanded,
      fontStyle: FontStyle.italic,
      fontWeight: FontWeight.w900,
      fontSize: size,
      height: 0.92,
      letterSpacing: -size * 0.035,
      color: p.accent,
    );
    final line = CardType.condensed(story ? 34 : 26, color: p.text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: l10n.appTitle,
          child: FittedBox(
            fit: BoxFit.fitWidth,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: size * 0.06),
                  child: FloatMark(
                    height: size * 1.02,
                    ink: p.text,
                    bottom: CardSignature.floatBottomFor(p),
                  ),
                ),
                SizedBox(width: size * 0.12),
                Text(l10n.appTitle, style: word),
              ],
            ),
          ),
        ),
        SizedBox(height: story ? 14 : 10),
        Container(height: story ? 5 : 4, color: p.text),
        SizedBox(height: story ? 12 : 8),
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.brandTagline,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: line,
              ),
            ),
            Text(issue, style: line),
            SizedBox(width: story ? 28 : 20),
            Text(date, style: line),
          ],
        ),
        if (caption != null) ...[
          SizedBox(height: story ? 26 : 16),
          FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: 0.78,
            child: Text(
              '“$caption”',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: CardType.text(
                story ? 46 : 32,
                weight: FontWeight.w700,
                style: FontStyle.italic,
                height: 1.12,
                color: p.text,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// The cover story: species, the measure set huge, and short lines.
class _CoverLines extends StatelessWidget {
  const _CoverLines({
    required this.story,
    required this.kicker,
    required this.headline,
    required this.lines,
  });

  final bool story;
  final String kicker;
  final List<CardQuantity> headline;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final p = context.cardPalette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          kicker,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: CardType.text(
            story ? 92 : 62,
            weight: FontWeight.w800,
            height: 0.98,
            letterSpacing: story ? -2 : -1.4,
          ),
        ),
        if (headline.isNotEmpty) ...[
          SizedBox(height: story ? 8 : 4),
          CardHeadline(
            parts: headline,
            size: story ? 250 : 150,
            unitColor: p.accent,
          ),
        ],
        SizedBox(height: story ? 22 : 14),
        Container(width: story ? 120 : 90, height: 6, color: p.accent),
        SizedBox(height: story ? 18 : 12),
        for (final l in lines.take(story ? 4 : 2))
          Padding(
            padding: EdgeInsets.only(bottom: story ? 6 : 4),
            child: Text(
              l,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CardType.text(
                story ? 40 : 30,
                weight: FontWeight.w600,
                color: p.soft,
              ),
            ),
          ),
      ],
    );
  }
}

/// A round sticker slapped on the cover, slightly turned.
class _Sticker extends StatelessWidget {
  const _Sticker({required this.lines, required this.size});

  final List<String> lines;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.cardPalette;
    final ink = p.dark ? p.ground : p.board;
    return Transform.rotate(
      angle: -10 * math.pi / 180,
      child: Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(size * 0.06),
        decoration: BoxDecoration(color: p.record, shape: BoxShape.circle),
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: ink, width: size * 0.012),
          ),
          child: Center(
            child: SizedBox(
              width: size * 0.66,
              height: size * 0.62,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: SizedBox(
                  width: size * 0.66,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final (i, l) in lines.indexed)
                        if (i == 0)
                          Text(
                            l,
                            textAlign: TextAlign.center,
                            style: CardType.condensed(
                              size * (lines.length == 1 ? 0.15 : 0.13),
                              weight: FontWeight.w800,
                              color: ink,
                              height: 1.02,
                            ),
                          )
                        else
                          // The number stays on one line.
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              l,
                              maxLines: 1,
                              softWrap: false,
                              style: CardType.numbers(
                                size * 0.24,
                                color: ink,
                              ).copyWith(height: 1.1),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
