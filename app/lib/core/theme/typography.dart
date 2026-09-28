import 'package:flutter/material.dart';

import 'tokens.dart';

/// Archivo in three widths. Expanded heavy italic is reserved for big
/// numbers (the "boat decal" voice); everything else is plain Archivo.
TextTheme buildTextTheme(Color ink, Color muted) {
  TextStyle numbers(double size, FontWeight weight, {double height = 1.0}) =>
      TextStyle(
        fontFamily: PiscatioFonts.expanded,
        fontStyle: FontStyle.italic,
        fontWeight: weight,
        fontSize: size,
        height: height,
        letterSpacing: -0.5,
        color: ink,
      );
  TextStyle text(
    double size,
    FontWeight weight, {
    double height = 1.35,
    Color? color,
    double letterSpacing = 0,
  }) => TextStyle(
    fontFamily: PiscatioFonts.text,
    fontWeight: weight,
    fontSize: size,
    height: height,
    letterSpacing: letterSpacing,
    color: color ?? ink,
  );

  return TextTheme(
    displayLarge: numbers(64, FontWeight.w900, height: 0.95),
    displayMedium: numbers(44, FontWeight.w800),
    displaySmall: numbers(30, FontWeight.w800),
    headlineLarge: text(32, FontWeight.w700, height: 1.1, letterSpacing: -0.6),
    headlineMedium: text(
      26,
      FontWeight.w700,
      height: 1.15,
      letterSpacing: -0.4,
    ),
    headlineSmall: text(22, FontWeight.w700, height: 1.2, letterSpacing: -0.2),
    titleLarge: text(20, FontWeight.w700, height: 1.25),
    titleMedium: text(17, FontWeight.w600, height: 1.3),
    titleSmall: text(15, FontWeight.w600, height: 1.3),
    bodyLarge: text(17, FontWeight.w400, height: 1.45),
    bodyMedium: text(15, FontWeight.w400, height: 1.45),
    bodySmall: text(13, FontWeight.w400, height: 1.4, color: muted),
    labelLarge: text(16, FontWeight.w600, height: 1.2),
    labelMedium: text(14, FontWeight.w500, height: 1.2),
    labelSmall: text(12, FontWeight.w500, height: 1.2, color: muted),
  );
}

/// Tabular figures so a ticking timer does not jitter.
const tabularFigures = [FontFeature.tabularFigures()];
