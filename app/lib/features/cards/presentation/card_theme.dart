import 'package:flutter/widgets.dart';

import '../../../core/theme/tokens.dart';
import '../application/card_data.dart';
import '../application/photo_filters.dart';

/// Makes the card's palette (and how its photo is drawn) available to
/// everything on it, whatever the app theme: a shared card must look the
/// same for everyone.
class CardPaletteScope extends InheritedWidget {
  const CardPaletteScope({
    super.key,
    required this.palette,
    this.photoFilter = CardPhotoFilter.none,
    required super.child,
  });

  final CardPalette palette;

  /// The photo given to the card is this filter's separation image.
  final CardPhotoFilter photoFilter;

  static CardPaletteScope? _of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CardPaletteScope>();

  static CardPalette of(BuildContext context) =>
      _of(context)?.palette ?? CardPalette.redHead;

  @override
  bool updateShouldNotify(CardPaletteScope old) =>
      old.palette != palette || old.photoFilter != photoFilter;
}

extension CardPaletteContext on BuildContext {
  CardPalette get cardPalette => CardPaletteScope.of(this);

  CardPhotoFilter get cardPhotoFilter =>
      CardPaletteScope._of(this)?.photoFilter ?? CardPhotoFilter.none;
}

/// Inks a one-ink filtered photo in the palette's colors: drawings in the
/// board's ink on its white, the duotone from the palette's shadow to its
/// light. Null for the plain photo and for layered filters ([rupestreInks]).
ColorFilter? photoTint(CardPalette p, CardPhotoFilter filter) {
  int argb(Color c) => c.toARGB32();
  final matrix = switch (filter) {
    CardPhotoFilter.none || CardPhotoFilter.rupestre => null,
    CardPhotoFilter.duotone => filterTint(
      base: argb(p.shadow),
      first: argb(p.highlight),
    ),
    CardPhotoFilter.engraving || CardPhotoFilter.halftone => filterTint(
      base: argb(p.board),
      first: argb(p.boardInk),
    ),
  };
  return matrix == null ? null : ColorFilter.matrix(matrix);
}

/// The cave painting in the theme's materials: its stone is the tag's card
/// stock (sand, bone, moonlit grey…), the ochre its accent ink, the
/// charcoal its typewriter ribbon.
({Color stone, Color relief, Color ochre, Color charcoal}) rupestreInks(
  CardPalette p,
) {
  final stone = Color.lerp(p.stock, p.board, 0.2)!;
  return (
    stone: stone,
    relief: Color.lerp(stone, p.typed, 0.5)!,
    ochre: p.accentInk,
    charcoal: p.typed,
  );
}

/// Text styles on the fixed card canvas (sizes in canvas pixels). Without a
/// color they take the palette's text color from the canvas.
abstract final class CardType {
  /// Big numbers: Archivo Expanded heavy italic, the "boat decal" voice.
  static TextStyle numbers(
    double size, {
    Color? color,
    FontWeight weight = FontWeight.w900,
  }) => TextStyle(
    fontFamily: PiscatioFonts.expanded,
    fontStyle: FontStyle.italic,
    fontWeight: weight,
    fontSize: size,
    height: 0.9,
    letterSpacing: -size * 0.02,
    color: color,
  );

  static TextStyle text(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color? color,
    FontStyle style = FontStyle.normal,
    double height = 1.2,
    double letterSpacing = 0,
  }) => TextStyle(
    fontFamily: PiscatioFonts.text,
    fontWeight: weight,
    fontStyle: style,
    fontSize: size,
    height: height,
    letterSpacing: letterSpacing,
    color: color,
  );

  /// Dense labels and table heads.
  static TextStyle condensed(
    double size, {
    FontWeight weight = FontWeight.w700,
    Color? color,
    double height = 1.1,
  }) => TextStyle(
    fontFamily: PiscatioFonts.condensed,
    fontWeight: weight,
    fontSize: size,
    height: height,
    color: color,
  );

  /// Typewriter, only on the specimen tag.
  static TextStyle typed(
    double size, {
    Color? color,
    bool italic = false,
    bool bold = false,
  }) => TextStyle(
    fontFamily: PiscatioFonts.typed,
    fontSize: size,
    height: 1.15,
    fontStyle: italic ? FontStyle.italic : FontStyle.normal,
    fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
    color: color,
  );
}
