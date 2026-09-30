import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/formatting/l10n.dart';
import '../../application/card_data.dart';
import '../card_canvas.dart';
import '../card_theme.dart';

/// The year on one page of the logbook: the year set huge, the three
/// counts that matter, the months as bars (the best one in the accent) and
/// a few lines on the year's fish. A chosen photo sits behind, dimmed.
class YearCard extends StatelessWidget {
  const YearCard({super.key, required this.data, required this.format});

  final YearCardData data;
  final CardFormat format;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.cardPalette;
    final story = format == CardFormat.story;
    final margin = story ? 72.0 : 60.0;
    final hasPhoto = CardPhoto.exists(data.photoPath);
    final signature = CardSignature.originFor(format);
    final lines = [
      if (data.topSpeciesName != null)
        l10n.yearTopSpecies(
          data.topSpeciesName!,
          cardNumber(context, data.topSpeciesCount.toDouble()),
        ),
      if (data.biggestLabel != null) l10n.yearBiggest(data.biggestLabel!),
      if (data.newSpeciesCount > 0) l10n.yearNewSpecies(data.newSpeciesCount),
      if (data.topBaitLabel != null) l10n.yearTopBait(data.topBaitLabel!),
      l10n.yearDaysFished(data.daysFished),
    ];
    return Stack(
      children: [
        if (hasPhoto) ...[
          Positioned.fill(child: CardPhoto(path: data.photoPath)),
          // Dimmed evenly so every number reads over any photo.
          Positioned.fill(
            child: ColoredBox(
              color: p.ground.withValues(alpha: p.dark ? 0.7 : 0.8),
            ),
          ),
        ],
        Positioned(
          left: signature.dx,
          top: signature.dy,
          child: CardSignature(format: format),
        ),
        Positioned(
          left: margin,
          right: margin,
          top: story ? 430 : 176,
          bottom: story ? CardSafeArea.storyBottom : 56,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.cardYearTitle,
                style: CardType.condensed(story ? 46 : 34, color: p.accent),
              ),
              SizedBox(
                height: story ? 300 : 170,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${data.year}',
                    style: CardType.numbers(story ? 330 : 190),
                  ),
                ),
              ),
              SizedBox(height: story ? 24 : 12),
              Row(
                children: [
                  _Figure(
                    value: data.tripCount,
                    label: l10n.statsTripsLabel(data.tripCount),
                    story: story,
                  ),
                  _Figure(
                    value: data.catchCount,
                    label: l10n.catchCountLabel(data.catchCount),
                    story: story,
                  ),
                  _Figure(
                    value: data.speciesCount,
                    label: l10n.speciesCountLabel(data.speciesCount),
                    story: story,
                  ),
                ],
              ),
              SizedBox(height: story ? 56 : 28),
              // As tall as the lines below leave room for.
              Flexible(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: story ? 420 : 260),
                  child: _MonthBars(
                    byMonth: data.byMonth,
                    letters: data.monthLetters,
                    best: data.bestMonth,
                    story: story,
                  ),
                ),
              ),
              SizedBox(height: story ? 48 : 22),
              if (data.caption != null)
                Padding(
                  padding: EdgeInsets.only(bottom: story ? 20 : 10),
                  child: Text(
                    '“${data.caption}”',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: CardType.text(
                      story ? 44 : 32,
                      weight: FontWeight.w700,
                      style: FontStyle.italic,
                      height: 1.12,
                    ),
                  ),
                ),
              for (final l in lines.take(
                story ? (data.caption == null ? 4 : 3) : 2,
              ))
                Padding(
                  padding: EdgeInsets.only(bottom: story ? 8 : 4),
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
          ),
        ),
      ],
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({
    required this.value,
    required this.label,
    required this.story,
  });

  final int value;
  final String label;
  final bool story;

  @override
  Widget build(BuildContext context) {
    final p = context.cardPalette;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              cardNumber(context, value.toDouble()),
              maxLines: 1,
              style: CardType.numbers(story ? 130 : 84),
            ),
          ),
          SizedBox(height: story ? 10 : 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: CardType.condensed(story ? 36 : 26, color: p.soft),
          ),
        ],
      ),
    );
  }
}

/// Twelve bars, one per month; the best month in the accent.
class _MonthBars extends StatelessWidget {
  const _MonthBars({
    required this.byMonth,
    required this.letters,
    required this.best,
    required this.story,
  });

  final List<int> byMonth;
  final List<String> letters;
  final int? best;
  final bool story;

  @override
  Widget build(BuildContext context) {
    final p = context.cardPalette;
    final top = math.max(1, byMonth.fold(0, math.max));
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var m = 0; m < 12; m++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: story ? 7 : 5),
              child: Column(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: byMonth[m] == 0
                            ? 0.02
                            : math.max(0.06, byMonth[m] / top),
                        widthFactor: 1,
                        child: ColoredBox(
                          color: best == m + 1
                              ? p.accent
                              : p.text.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: story ? 12 : 8),
                  Text(
                    letters[m],
                    style: CardType.condensed(
                      story ? 32 : 24,
                      color: best == m + 1 ? p.accent : p.soft,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
