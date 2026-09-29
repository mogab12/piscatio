import 'package:flutter/widgets.dart';

import '../../../core/theme/tokens.dart';
import '../application/card_data.dart';

/// Makes the card's palette available to everything drawn on it, whatever
/// the app theme: a shared card must look the same for everyone.
class CardPaletteScope extends InheritedWidget {
  const CardPaletteScope({
    super.key,
    required this.palette,
    required super.child,
  });

  final CardPalette palette;

  static CardPalette of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CardPaletteScope>()?.palette ??
      CardPalette.redHead;

  @override
  bool updateShouldNotify(CardPaletteScope old) => old.palette != palette;
}

extension CardPaletteContext on BuildContext {
  CardPalette get cardPalette => CardPaletteScope.of(this);
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
