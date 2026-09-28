import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/formatting/l10n.dart';
import '../application/card_data.dart';
import 'card_theme.dart';

/// Fixed-size drawing surface for a card: [CardFormat.size] canvas pixels,
/// no system text scaling (the image must look the same for everyone).
class CardCanvas extends StatelessWidget {
  const CardCanvas({super.key, required this.format, required this.child});

  final CardFormat format;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.maybeOf(context) ?? const MediaQueryData();
    return MediaQuery(
      data: media.copyWith(textScaler: TextScaler.noScaling),
      child: SizedBox.fromSize(
        size: format.size,
        child: ClipRect(
          child: DefaultTextStyle(
            style: CardType.text(32),
            child: ColoredBox(color: CardInk.water, child: child),
          ),
        ),
      ),
    );
  }
}

/// Number in the card's locale ("2,5" in Portuguese).
String cardNumber(BuildContext context, double v) {
  final f = NumberFormat.decimalPattern(
    Localizations.localeOf(context).toString(),
  )..maximumFractionDigits = 1;
  return f.format(v);
}

/// The catch photo filling its box; deep water when there is none or it
/// cannot be read.
class CardPhoto extends StatelessWidget {
  const CardPhoto({super.key, required this.path, this.darken = 0});

  final String? path;

  /// 0–1 veil of deep water over the photo.
  final double darken;

  static bool exists(String? path) => path != null && File(path).existsSync();

  @override
  Widget build(BuildContext context) {
    if (!exists(path)) return const ColoredBox(color: CardInk.water);
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.file(
          File(path!),
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const ColoredBox(color: CardInk.water),
        ),
        if (darken > 0)
          ColoredBox(color: CardInk.water.withValues(alpha: darken)),
      ],
    );
  }
}

/// The red notch of the trip ruler plus the wordmark.
class BrandMark extends StatelessWidget {
  const BrandMark({
    super.key,
    this.size = 34,
    this.color = CardInk.paper,
    this.notch = CardInk.red,
  });

  final double size;
  final Color color;
  final Color notch;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: Size(size * 0.62, size * 0.62),
          painter: _NotchPainter(notch),
        ),
        SizedBox(width: size * 0.28),
        Text(
          context.l10n.brandName,
          style: CardType.numbers(
            size,
            color: color,
            weight: FontWeight.w800,
          ).copyWith(height: 1),
        ),
      ],
    );
  }
}

class _NotchPainter extends CustomPainter {
  _NotchPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_NotchPainter old) => old.color != color;
}

/// Big number with its unit set smaller on the same baseline: "52 cm",
/// "2 lb 3 oz".
class CardHeadline extends StatelessWidget {
  const CardHeadline({
    super.key,
    required this.parts,
    required this.size,
    this.color = CardInk.paper,
    this.unitColor,
  });

  final List<CardQuantity> parts;
  final double size;
  final Color color;
  final Color? unitColor;

  @override
  Widget build(BuildContext context) {
    final number = CardType.numbers(size, color: color);
    final unit = CardType.numbers(
      size * 0.32,
      color: unitColor ?? color,
      weight: FontWeight.w800,
    );
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.bottomLeft,
      child: Text.rich(
        TextSpan(
          children: [
            for (final (i, q) in parts.indexed) ...[
              if (i > 0) TextSpan(text: '  ', style: unit),
              TextSpan(text: q.value, style: number),
              TextSpan(text: ' ${q.unit}', style: unit),
            ],
          ],
        ),
        maxLines: 1,
        softWrap: false,
      ),
    );
  }
}
