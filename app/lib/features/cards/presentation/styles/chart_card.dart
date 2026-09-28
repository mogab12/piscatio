import 'package:flutter/material.dart';

import '../../../../core/formatting/l10n.dart';
import '../../application/card_data.dart';
import '../card_canvas.dart';
import '../card_theme.dart';
import '../painters/chart_painters.dart';
import '../painters/moon_painter.dart';

/// Stable across runs and platforms (unlike String.hashCode): FNV-1a.
int stableSeed(String s) {
  var h = 0x811c9dc5;
  for (final unit in s.codeUnits) {
    h ^= unit;
    h = (h * 0x01000193) & 0xffffffff;
  }
  return h & 0x7fffffff;
}

/// Chart: a night nautical chart. The contours are drawn from the card's
/// id, never from the real place. The featured number is set like a
/// sounding (depths are italic on charts); a compass rose carries the real
/// wind and the moon of that day; a title block holds the details.
class ChartCatchCard extends StatelessWidget {
  const ChartCatchCard({super.key, required this.data, required this.format});

  final CatchCardData data;
  final CardFormat format;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final record = data.record;
    final measured = data.headline.isNotEmpty;
    final rows = <(String, String)>[
      if (data.place != null) (l10n.cardFieldPlace, data.place!),
      (l10n.cardFieldDate, data.dateLabel),
      if (measured) (l10n.cardFieldTime, data.timeLabel),
      if (data.lengthLabel != null && data.weightLabel != null)
        (l10n.cardFieldWeight, data.weightLabel!),
      if (data.baitLabel != null) (l10n.cardFieldBait, data.baitLabel!),
      if (data.temperatureLabel != null)
        (l10n.cardFieldAir, data.temperatureLabel!),
      if (data.pressureLabel != null)
        (l10n.cardFieldPressure, data.pressureLabel!),
    ];
    return _ChartLayout(
      format: format,
      seed: stableSeed(data.id),
      photoPath: data.photoPath,
      edition: data.romanDate,
      sounding: (size) => measured
          ? CardHeadline(
              parts: data.headline,
              size: size,
              unitColor: CardInk.muted,
            )
          : FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.bottomLeft,
              child: Text(data.timeLabel, style: CardType.numbers(size * 0.75)),
            ),
      rose: _Rose(moon: data.moon, wind: data.wind),
      cartouche: (compact) => _Cartouche(
        title: data.speciesName,
        subtitle: data.scientificName,
        record: record == null
            ? null
            : record.isFirst
            ? l10n.cardFirstOfSpecies
            : record.improvement == null
            ? l10n.cardRecord
            : l10n.cardRecordImprovement(record.improvement!),
        rows: rows.take(compact ? 2 : 6).toList(),
        compact: compact,
      ),
    );
  }
}

class ChartTripCard extends StatelessWidget {
  const ChartTripCard({super.key, required this.data, required this.format});

  final TripCardData data;
  final CardFormat format;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rows = <(String, String)>[
      if (data.place != null) (l10n.cardFieldPlace, data.place!),
      (l10n.cardFieldTime, data.timeRangeLabel),
      (l10n.cardFieldDuration, data.durationLabel),
      if (data.biggestLabel != null)
        (l10n.cardFieldBiggest, data.biggestLabel!),
      if (data.topBaitLabel != null) (l10n.cardFieldBait, data.topBaitLabel!),
      if (data.temperatureLabel != null)
        (l10n.cardFieldAir, data.temperatureLabel!),
    ];
    return _ChartLayout(
      format: format,
      seed: stableSeed(data.id),
      photoPath: data.photoPath,
      edition: data.romanDate,
      sounding: (size) => CardHeadline(
        parts: [
          CardQuantity(
            cardNumber(context, data.catchCount.toDouble()),
            l10n.catchCountLabel(data.catchCount),
          ),
        ],
        size: size,
        unitColor: CardInk.muted,
      ),
      rose: _Rose(moon: data.moon, wind: data.wind),
      cartouche: (compact) => _Cartouche(
        title: data.dateLabel,
        record: data.recordCount > 0
            ? l10n.cardRecordCount(data.recordCount)
            : null,
        rows: rows.take(compact ? 2 : 5).toList(),
        legend: data.speciesTally,
        legendLimit: compact ? 2 : 4,
        compact: compact,
      ),
    );
  }
}

class _ChartLayout extends StatelessWidget {
  const _ChartLayout({
    required this.format,
    required this.seed,
    required this.photoPath,
    required this.edition,
    required this.sounding,
    required this.rose,
    required this.cartouche,
  });

  final CardFormat format;
  final int seed;
  final String? photoPath;
  final String edition;
  final Widget Function(double size) sounding;
  final Widget rose;
  final Widget Function(bool compact) cartouche;

  static const _pad = 88.0;

  @override
  Widget build(BuildContext context) {
    final story = format == CardFormat.story;
    final hasPhoto = CardPhoto.exists(photoPath);
    final margin = CardType.condensed(22);
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: ContourPainter(
              seed: seed,
              line: CardInk.isobath,
              strongLine: CardInk.isobathStrong,
              soundingStyle: CardType.text(
                24,
                style: FontStyle.italic,
                color: CardInk.sounding,
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: CustomPaint(
            painter: ChartBorderPainter(
              ink: CardInk.muted,
              paper: CardInk.water,
            ),
          ),
        ),
        // Margin notes outside the neatline, like a chart's imprint.
        Positioned(
          left: ChartBorderPainter.inset,
          bottom: 4,
          child: Text(edition, style: margin),
        ),
        const Positioned(
          right: ChartBorderPainter.inset,
          bottom: 5,
          child: BrandMark(size: 20, color: CardInk.muted),
        ),
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.all(_pad),
            child: story ? _story(hasPhoto) : _square(hasPhoto),
          ),
        ),
      ],
    );
  }

  Widget _story(bool hasPhoto) {
    if (!hasPhoto) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 40),
          SizedBox(height: 400, child: _soundingBox(400)),
          const Spacer(),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(width: 470, height: 540, child: rose),
          ),
          const Spacer(),
          cartouche(false),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: _Inset(path: photoPath!)),
        const SizedBox(height: 40),
        SizedBox(
          height: 390,
          child: Row(
            children: [
              Expanded(child: _soundingBox(290)),
              const SizedBox(width: 12),
              SizedBox(width: 340, child: rose),
            ],
          ),
        ),
        const SizedBox(height: 36),
        cartouche(false),
      ],
    );
  }

  Widget _square(bool hasPhoto) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (hasPhoto) ...[
                Expanded(child: _Inset(path: photoPath!)),
                const SizedBox(width: 32),
                SizedBox(
                  width: 330,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 130, child: _soundingBox(130)),
                      const SizedBox(height: 16),
                      Expanded(child: rose),
                    ],
                  ),
                ),
              ] else ...[
                Expanded(child: _soundingBox(250)),
                const SizedBox(width: 16),
                SizedBox(width: 360, child: rose),
              ],
            ],
          ),
        ),
        const SizedBox(height: 30),
        cartouche(true),
      ],
    );
  }

  Widget _soundingBox(double size) =>
      Align(alignment: Alignment.bottomLeft, child: sounding(size));
}

/// Compass rose with the wind arrow and, in the middle, the moon.
class _Rose extends StatelessWidget {
  const _Rose({required this.moon, required this.wind});

  final CardMoon moon;
  final CardWind? wind;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return LayoutBuilder(
      builder: (context, box) {
        // Captions under the ring, like notes beside a chart's rose.
        final noteSize = (box.maxWidth * 0.075).clamp(22.0, 32.0);
        final captions = wind == null ? 1 : 2;
        final side = [
          box.maxWidth,
          box.maxHeight - noteSize * 1.45 * captions - 12,
        ].reduce((a, b) => a < b ? a : b);
        final r = side / 2 - 40;
        final note = CardType.text(
          noteSize,
          style: FontStyle.italic,
          color: CardInk.muted,
          height: 1.3,
        );
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox.square(
              dimension: side,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: CompassRosePainter(
                        ink: CardInk.muted,
                        accent: CardInk.redOnDark,
                        letterStyle: CardType.condensed(
                          side * 0.075,
                          color: CardInk.foam,
                        ),
                        letters: [
                          l10n.compassN,
                          l10n.compassE,
                          l10n.compassS,
                          l10n.compassW,
                        ],
                        windFromDegrees: wind?.fromDegrees,
                      ),
                    ),
                  ),
                  SizedBox.square(
                    dimension: r * 0.62,
                    child: CustomPaint(
                      painter: MoonPainter(
                        illumination: moon.illumination,
                        waxing: moon.waxing,
                        southern: moon.southern,
                        lit: CardInk.foam,
                        dark: CardInk.water3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(moon.label, style: note, maxLines: 1),
            if (wind != null) Text(wind!.label, style: note, maxLines: 1),
          ],
        );
      },
    );
  }
}

/// Photo inset with a double frame, like the enlarged plans on a chart.
class _Inset extends StatelessWidget {
  const _Inset({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: CardInk.water,
        border: Border.all(color: CardInk.muted, width: 3),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            border: Border.all(color: CardInk.muted, width: 1.5),
          ),
          child: CardPhoto(path: path),
        ),
      ),
    );
  }
}

/// The chart's title block: double rule, title, a short table, a legend.
class _Cartouche extends StatelessWidget {
  const _Cartouche({
    required this.title,
    required this.rows,
    required this.compact,
    this.subtitle,
    this.record,
    this.legend = const [],
    this.legendLimit = 4,
  });

  final String title;
  final String? subtitle;
  final String? record;
  final List<(String, String)> rows;
  final List<(String, int)> legend;
  final int legendLimit;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final label = CardType.condensed(compact ? 26 : 30);
    final value = CardType.text(compact ? 30 : 34, weight: FontWeight.w600);
    final rule = BorderSide(color: CardInk.water3, width: compact ? 1.5 : 2);
    final shown = legend.take(legendLimit).toList();
    final hidden = legend.length - shown.length;
    Widget row(String l, String v) => Container(
      padding: EdgeInsets.symmetric(vertical: compact ? 9 : 12),
      decoration: BoxDecoration(border: Border(top: rule)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          SizedBox(
            width: compact ? 150 : 230,
            child: Text(l, style: label),
          ),
          Expanded(
            child: Text(
              v,
              style: value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: CardInk.water,
        border: Border.all(color: CardInk.muted, width: 3),
      ),
      child: Container(
        margin: const EdgeInsets.all(9),
        padding: EdgeInsets.fromLTRB(
          compact ? 28 : 40,
          compact ? 24 : 34,
          compact ? 28 : 40,
          compact ? 18 : 26,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: CardInk.muted, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: CardType.text(
                compact ? 46 : 62,
                weight: FontWeight.w700,
                height: 1.05,
                letterSpacing: -1,
              ),
            ),
            if (subtitle != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CardType.text(
                    compact ? 28 : 34,
                    style: FontStyle.italic,
                    color: CardInk.muted,
                  ),
                ),
              ),
            if (record != null)
              Container(
                margin: EdgeInsets.only(top: compact ? 14 : 20),
                padding: EdgeInsets.only(top: compact ? 10 : 14),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: CardInk.gold, width: 4),
                  ),
                ),
                child: Text(
                  record!,
                  style: CardType.text(
                    compact ? 30 : 36,
                    weight: FontWeight.w700,
                    color: CardInk.gold,
                  ),
                ),
              ),
            SizedBox(height: compact ? 14 : 22),
            for (final (l, v) in rows) row(l, v),
            if (shown.isNotEmpty) ...[
              Container(
                decoration: BoxDecoration(border: Border(top: rule)),
                padding: EdgeInsets.only(top: compact ? 12 : 16),
                child: Wrap(
                  spacing: compact ? 20 : 30,
                  runSpacing: 6,
                  children: [
                    for (final (name, count) in shown)
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: cardNumber(context, count.toDouble()),
                              style: CardType.numbers(
                                compact ? 30 : 36,
                                weight: FontWeight.w800,
                                color: CardInk.foam,
                              ),
                            ),
                            TextSpan(text: ' $name', style: value),
                          ],
                        ),
                      ),
                    if (hidden > 0)
                      Text(
                        l10n.cardMoreCatches(hidden),
                        style: value.copyWith(color: CardInk.muted),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
