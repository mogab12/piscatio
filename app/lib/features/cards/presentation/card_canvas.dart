import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/brand.dart';
import '../application/card_data.dart';
import '../application/photo_filters.dart';
import 'card_theme.dart';

/// Fixed-size drawing surface for a card: [CardFormat.size] canvas pixels,
/// no system text scaling (the image must look the same for everyone).
class CardCanvas extends StatelessWidget {
  const CardCanvas({
    super.key,
    required this.format,
    required this.child,
    this.palette = CardPalette.redHead,
    this.photoFilter = CardPhotoFilter.none,
  });

  final CardFormat format;
  final CardPalette palette;
  final CardPhotoFilter photoFilter;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.maybeOf(context) ?? const MediaQueryData();
    return MediaQuery(
      data: media.copyWith(textScaler: TextScaler.noScaling),
      child: CardPaletteScope(
        palette: palette,
        photoFilter: photoFilter,
        child: SizedBox.fromSize(
          size: format.size,
          child: ClipRect(
            child: DefaultTextStyle(
              style: CardType.text(32, color: palette.text),
              child: ColoredBox(color: palette.ground, child: child),
            ),
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

/// The catch photo filling its box; the card's ground when there is none or
/// it cannot be read.
class CardPhoto extends StatelessWidget {
  const CardPhoto({super.key, required this.path, this.darken = 0});

  final String? path;

  /// 0–1 veil of the card's ground over the photo (darkens it on dark
  /// palettes, lightens it on light ones).
  final double darken;

  static bool exists(String? path) => path != null && File(path).existsSync();

  @override
  Widget build(BuildContext context) {
    final palette = context.cardPalette;
    final ground = palette.ground;
    if (!exists(path)) return ColoredBox(color: ground);
    final filter = context.cardPhotoFilter;
    final tint = photoTint(palette, filter);
    final image = Image.file(
      File(path!),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => ColoredBox(color: ground),
    );
    Widget layer(Color color, int channel) => ColorFiltered(
      colorFilter: ColorFilter.matrix(
        channelInk(color: color.toARGB32(), channel: channel),
      ),
      child: image,
    );
    final inks = rupestreInks(palette);
    return Stack(
      fit: StackFit.expand,
      children: [
        if (filter == CardPhotoFilter.rupestre) ...[
          // The stone, its relief, the ochre, then the charcoal on top.
          ColoredBox(color: inks.stone),
          layer(inks.relief, 2),
          layer(inks.ochre, 1),
          layer(inks.charcoal, 0),
        ] else if (tint == null)
          image
        else
          ColorFiltered(colorFilter: tint, child: image),
        if (darken > 0) ColoredBox(color: ground.withValues(alpha: darken)),
      ],
    );
  }
}

/// Small brand mark (float + name) for imprints and printed labels.
class BrandMark extends StatelessWidget {
  const BrandMark({
    super.key,
    required this.color,
    this.size = 34,
    this.floatBottom,
  });

  final double size;
  final Color color;

  /// Lower half of the float, e.g. the paper it is printed on.
  final Color? floatBottom;

  @override
  Widget build(BuildContext context) =>
      BrandLockup(size: size, color: color, floatBottom: floatBottom);
}

/// Where the brand sits on every card: top left, big enough to read in a
/// story at a glance, with the tagline. Inside the story safe zone (clear
/// of the platform's own header).
class CardSignature extends StatelessWidget {
  const CardSignature({
    super.key,
    required this.format,
    this.color,
    this.floatBottom,
  });

  final CardFormat format;

  /// Defaults to the palette's text color.
  final Color? color;
  final Color? floatBottom;

  /// Top-left corner of the signature.
  static Offset originFor(CardFormat format) => format == CardFormat.story
      ? const Offset(72, CardSafeArea.storyTop)
      : const Offset(60, 56);

  @override
  Widget build(BuildContext context) {
    final p = context.cardPalette;
    return BrandLockup(
      size: format == CardFormat.story ? 80 : 60,
      color: color ?? p.text,
      floatBottom: floatBottom ?? floatBottomFor(p),
      tagline: true,
    );
  }

  /// White below the waterline on dark grounds; on light ones the float
  /// takes the paper's color inside its dark outline.
  static Color floatBottomFor(CardPalette p) => p.dark ? p.text : p.ground;
}

/// Stories get covered by the platform's UI: the header (progress bar,
/// profile) at the top and the reply bar at the bottom. Content stays
/// between these lines.
abstract final class CardSafeArea {
  static const storyTop = 230.0;
  static const storyBottom = 250.0;
}

/// Big number with its unit set smaller on the same baseline: "52 cm",
/// "2 lb 3 oz".
class CardHeadline extends StatelessWidget {
  const CardHeadline({
    super.key,
    required this.parts,
    required this.size,
    this.color,
    this.unitColor,
  });

  final List<CardQuantity> parts;
  final double size;

  /// Defaults to the palette's text color.
  final Color? color;
  final Color? unitColor;

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? context.cardPalette.text;
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
