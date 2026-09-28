import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/formatting/l10n.dart';
import '../../application/card_data.dart';
import '../card_canvas.dart';
import '../card_theme.dart';
import '../painters/tag_painters.dart';
import 'chart_card.dart' show stableSeed;

/// Tag: a museum specimen tag in manila card, hanging from its string over
/// the darkened photo. Printed field names, typed values, a rubber stamp
/// for records.
class TagCatchCard extends StatelessWidget {
  const TagCatchCard({super.key, required this.data, required this.format});

  final CatchCardData data;
  final CardFormat format;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final seed = stableSeed(data.id);
    final record = data.record;
    final scientific = data.scientificName;
    final fate = data.released == null
        ? null
        : data.released!
        ? l10n.cardFieldReleased
        : l10n.cardFieldKept;
    return _TagScene(
      format: format,
      photoPath: data.photoPath,
      seed: seed,
      stamp: record == null
          ? null
          : record.isFirst
          ? _Stamp(
              lines: [l10n.cardFirstOfSpecies],
              color: const Color(0xFF1E3A6E),
              seed: seed,
            )
          : _Stamp(
              lines: [l10n.cardRecord, ?record.improvement],
              color: const Color(0xFFC4232B),
              seed: seed,
            ),
      header: _Typed(
        l10n.cardCatchNumber('${data.catchNumber}'),
        seed: seed,
        size: 44,
        bold: true,
      ),
      children: [
        _Field(
          label: l10n.cardFieldSpecies,
          value: scientific ?? data.speciesName,
          italic: scientific != null,
          seed: seed + 1,
        ),
        if (scientific != null)
          _Field(
            label: l10n.cardFieldCommonName,
            value: data.speciesName,
            seed: seed + 2,
          ),
        if (data.place != null)
          _Field(
            label: l10n.cardFieldPlace,
            value: data.place!,
            seed: seed + 3,
          ),
        _Pair(
          _Field(
            label: l10n.cardFieldDate,
            value: data.romanDate,
            seed: seed + 4,
          ),
          _Field(
            label: l10n.cardFieldTime,
            value: data.timeLabel,
            seed: seed + 5,
          ),
        ),
        if (data.lengthLabel != null || data.weightLabel != null)
          _Pair(
            data.lengthLabel == null
                ? null
                : _Field(
                    label: l10n.cardFieldLength,
                    value: data.lengthLabel!,
                    seed: seed + 6,
                  ),
            data.weightLabel == null
                ? null
                : _Field(
                    label: l10n.cardFieldWeight,
                    value: data.weightLabel!,
                    seed: seed + 7,
                  ),
          ),
        if (data.baitLabel != null || fate != null)
          _Pair(
            data.baitLabel == null
                ? null
                : _Field(
                    label: l10n.cardFieldBait,
                    value: data.baitLabel!,
                    seed: seed + 8,
                  ),
            fate == null
                ? null
                : _Field(
                    label: l10n.cardFieldFate,
                    value: fate,
                    seed: seed + 9,
                  ),
          ),
      ],
    );
  }
}

/// The trip version: a field register listing the catches, records typed
/// with the red half of the ribbon.
class TagTripCard extends StatelessWidget {
  const TagTripCard({super.key, required this.data, required this.format});

  final TripCardData data;
  final CardFormat format;

  static const maxRows = 7;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final seed = stableSeed(data.id);
    final shown = data.catches.length > maxRows
        ? data.catches.take(maxRows - 1).toList()
        : data.catches;
    final hidden = data.catches.length - shown.length;
    final rule = BoxDecoration(
      border: Border(
        bottom: BorderSide(
          color: CardInk.water.withValues(alpha: 0.28),
          width: 1.5,
        ),
      ),
    );
    return _TagScene(
      format: format,
      photoPath: data.photoPath,
      seed: seed,
      stamp: data.recordCount == 0
          ? null
          : _Stamp(
              lines: [l10n.cardRecordCount(data.recordCount)],
              color: const Color(0xFFC4232B),
              seed: seed,
            ),
      tagSize: const Size(800, 1320),
      header: _Typed(data.romanDate, seed: seed, size: 44, bold: true),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Text(
            l10n.cardFieldLog,
            style: CardType.condensed(
              40,
              weight: FontWeight.w800,
              color: CardInk.water,
            ),
          ),
        ),
        if (data.place != null)
          _Field(
            label: l10n.cardFieldPlace,
            value: data.place!,
            seed: seed + 1,
          ),
        _Pair(
          _Field(
            label: l10n.cardFieldTime,
            value: data.timeRangeLabel,
            seed: seed + 2,
          ),
          _Field(
            label: l10n.cardFieldDuration,
            value: data.durationLabel,
            seed: seed + 3,
          ),
          flex: (3, 2),
        ),
        const SizedBox(height: 6),
        for (final (i, c) in shown.indexed)
          Container(
            padding: const EdgeInsets.only(top: 10, bottom: 6),
            decoration: rule,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                SizedBox(
                  width: 170,
                  child: _Typed(c.timeLabel, seed: seed + 20 + i, size: 36),
                ),
                Expanded(
                  child: _Typed(
                    c.speciesName,
                    seed: seed + 40 + i,
                    size: 36,
                    ellipsis: true,
                  ),
                ),
                if (c.measureLabel != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: _Typed(
                      c.measureLabel!,
                      seed: seed + 60 + i,
                      size: 36,
                      color: c.isRecord ? CardInk.typedRed : CardInk.typed,
                      bold: c.isRecord,
                    ),
                  ),
              ],
            ),
          ),
        if (hidden > 0)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: _Typed(
              l10n.cardMoreCatches(hidden),
              seed: seed + 90,
              size: 36,
            ),
          ),
        if (data.catches.isNotEmpty) const SizedBox(height: 22),
        Wrap(
          spacing: 40,
          children: [
            _Typed(
              '${data.catchCount} ${l10n.catchCountLabel(data.catchCount)}',
              seed: seed + 91,
              size: 40,
              bold: true,
            ),
            _Typed(
              '${data.speciesCount} ${l10n.speciesCountLabel(data.speciesCount)}',
              seed: seed + 92,
              size: 40,
              bold: true,
            ),
          ],
        ),
      ],
    );
  }
}

/// Darkened photo, the string, the tilted tag and its stamp.
class _TagScene extends StatelessWidget {
  const _TagScene({
    required this.format,
    required this.photoPath,
    required this.seed,
    required this.header,
    required this.children,
    this.stamp,
    this.tagSize = const Size(800, 1240),
  });

  final CardFormat format;
  final String? photoPath;
  final int seed;
  final Widget header;
  final List<Widget> children;
  final Widget? stamp;
  final Size tagSize;

  @override
  Widget build(BuildContext context) {
    final story = format == CardFormat.story;
    final canvas = format.size;
    // Leave room above the tag for the string.
    final scale = math.min(
      story ? 0.9 : 0.8,
      (canvas.height - (story ? 110 : 40) - 110) / tagSize.height,
    );
    // A slight, seeded tilt: always between 2.5 and 4.5 degrees.
    final tilt = -(2.5 + (seed % 20) / 10) * math.pi / 180;
    final center = story
        ? Offset(
            canvas.width / 2 + 10,
            canvas.height - 110 - tagSize.height * scale / 2,
          )
        : Offset(
            canvas.width / 2 + 20,
            canvas.height - 40 - tagSize.height * scale / 2,
          );
    final holeLocal =
        (TagPainter.holeCenterFor(tagSize) - tagSize.center(Offset.zero)) *
        scale;
    final hole =
        center +
        Offset(
          holeLocal.dx * math.cos(tilt) - holeLocal.dy * math.sin(tilt),
          holeLocal.dx * math.sin(tilt) + holeLocal.dy * math.cos(tilt),
        );
    return Stack(
      children: [
        Positioned.fill(child: CardPhoto(path: photoPath, darken: 0.55)),
        Positioned(
          left: center.dx - tagSize.width / 2,
          top: center.dy - tagSize.height / 2,
          width: tagSize.width,
          height: tagSize.height,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.rotationZ(tilt)
              ..scaleByDouble(scale, scale, 1, 1),
            child: _Tag(
              seed: seed,
              header: header,
              stamp: stamp,
              children: children,
            ),
          ),
        ),
        Positioned.fill(
          child: CustomPaint(
            painter: StringPainter(
              hole: hole,
              holeRadius: TagPainter.holeRadiusFor(tagSize) * scale,
              color: CardInk.string,
              angle: tilt,
            ),
          ),
        ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({
    required this.seed,
    required this.header,
    required this.children,
    this.stamp,
  });

  final int seed;
  final Widget header;
  final List<Widget> children;
  final Widget? stamp;

  @override
  Widget build(BuildContext context) {
    const printed = CardInk.water;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: TagPainter(
              seed: seed,
              paper: CardInk.manila,
              shade: CardInk.manilaShade,
              edge: CardInk.manilaEdge,
              hole: const Color(0xFF071C22),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(64, 176, 64, 56),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const BrandMark(size: 30, color: printed),
                  const Spacer(),
                  header,
                ],
              ),
              const SizedBox(height: 16),
              // Printed double rule under the heading.
              Container(height: 3, color: printed),
              const SizedBox(height: 4),
              Container(height: 1.2, color: printed),
              const SizedBox(height: 26),
              ...children,
            ],
          ),
        ),
        if (stamp != null)
          Positioned(
            right: -34,
            bottom: 70,
            child: Transform.rotate(angle: 0.16, child: stamp),
          ),
      ],
    );
  }
}

/// Typewriter text: each letter struck a little harder or softer.
class _Typed extends StatelessWidget {
  const _Typed(
    this.text, {
    required this.seed,
    this.size = 46,
    this.italic = false,
    this.bold = false,
    this.color = CardInk.typed,
    this.ellipsis = false,
  });

  final String text;
  final int seed;
  final double size;
  final bool italic;
  final bool bold;
  final Color color;
  final bool ellipsis;

  @override
  Widget build(BuildContext context) {
    final rnd = math.Random(seed);
    final style = CardType.typed(size, italic: italic, bold: bold);
    final span = TextSpan(
      children: [
        for (final ch in text.characters)
          TextSpan(
            text: ch,
            style: style.copyWith(
              color: color.withValues(alpha: 0.74 + rnd.nextDouble() * 0.26),
            ),
          ),
      ],
    );
    if (ellipsis) {
      return Text.rich(span, maxLines: 1, overflow: TextOverflow.ellipsis);
    }
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text.rich(span, maxLines: 1, softWrap: false),
    );
  }
}

/// A form field: printed name, typed value, printed line under it.
class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.value,
    required this.seed,
    this.italic = false,
  });

  final String label;
  final String value;
  final int seed;
  final bool italic;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: CardType.condensed(
              25,
              color: CardInk.water.withValues(alpha: 0.66),
            ),
          ),
          const SizedBox(height: 4),
          _Typed(value, seed: seed, italic: italic),
          const SizedBox(height: 4),
          Container(height: 1.5, color: CardInk.water.withValues(alpha: 0.3)),
        ],
      ),
    );
  }
}

class _Pair extends StatelessWidget {
  const _Pair(this.first, this.second, {this.flex = (1, 1)});

  final Widget? first;
  final Widget? second;
  final (int, int) flex;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: flex.$1, child: first ?? const SizedBox()),
        const SizedBox(width: 36),
        Expanded(flex: flex.$2, child: second ?? const SizedBox()),
      ],
    );
  }
}

class _Stamp extends StatelessWidget {
  const _Stamp({required this.lines, required this.color, required this.seed});

  final List<String> lines;
  final Color color;
  final int seed;

  @override
  Widget build(BuildContext context) {
    final painters = [
      for (final (i, line) in lines.indexed)
        TextPainter(
          text: TextSpan(
            text: line,
            style: i == 0
                ? CardType.condensed(
                    lines.length == 1 ? 60 : 46,
                    weight: FontWeight.w800,
                    color: color,
                    height: 1.05,
                  )
                : CardType.numbers(78, color: color).copyWith(height: 1.1),
          ),
          textDirection: TextDirection.ltr,
        )..layout(),
    ];
    return CustomPaint(
      size: StampPainter.sizeFor(painters),
      painter: StampPainter(lines: painters, color: color, seed: seed),
    );
  }
}
