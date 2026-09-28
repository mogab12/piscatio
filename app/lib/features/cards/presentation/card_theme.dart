import 'package:flutter/painting.dart';

import '../../../core/theme/tokens.dart';

/// Card colors. Cards are always "night" pieces (deep water, paper objects
/// on top), whatever the app theme, so they read the same when shared.
abstract final class CardInk {
  static const water = PiscatioColors.deepWater;
  static const water2 = PiscatioColors.deepWater2;
  static const water3 = PiscatioColors.deepWater3;
  static const paper = PiscatioColors.paper;
  static const foam = PiscatioColors.foam;
  static const muted = PiscatioColors.reedOnDark;
  static const red = PiscatioColors.redHead;
  static const redOnDark = PiscatioColors.redHeadOnDark;
  static const gold = PiscatioColors.dorado;

  /// Board plastic: a touch off pure white, so the white text next to it
  /// still reads as the brightest thing.
  static const board = Color(0xFFF7F9F8);
  static const boardStop = Color(0xFF2E4D56);

  /// Chart linework on deep water.
  static const isobath = Color(0xFF1C4854);
  static const isobathStrong = Color(0xFF2A5E6A);
  static const sounding = Color(0xFF3D6D78);

  /// Specimen tag: manila card stock, printed and typed inks.
  static const manila = Color(0xFFE4D29E);
  static const manilaShade = Color(0xFFD3BE84);
  static const manilaEdge = Color(0xFFC4AE72);
  static const printed = Color(0xFF6B5B33);
  static const typed = Color(0xFF1D2326);
  static const typedRed = Color(0xFFB3202A);
  static const string = Color(0xFFEFE8D6);
}

/// Text styles on the fixed card canvas (sizes in canvas pixels).
abstract final class CardType {
  /// Big numbers: Archivo Expanded heavy italic, the "boat decal" voice.
  static TextStyle numbers(
    double size, {
    Color color = CardInk.paper,
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
    Color color = CardInk.paper,
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
    Color color = CardInk.muted,
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
    Color color = CardInk.typed,
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
