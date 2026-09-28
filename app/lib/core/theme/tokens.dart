import 'package:flutter/material.dart';

/// Palette "Red head": the colors of a red-head lure, a float and deep water.
/// See docs/DESIGN.md.
abstract final class PiscatioColors {
  static const redHead = Color(0xFFE4262C);
  static const redHeadDark = Color(0xFFF23A30);
  static const redHeadOnDark = Color(0xFFFF6A5E);
  static const deepWater = Color(0xFF0B2A33);
  static const deepWater2 = Color(0xFF12363F);
  static const deepWater3 = Color(0xFF184450);
  static const paper = Color(0xFFFFFFFF);
  static const mist = Color(0xFFEDF2F1);
  static const mistStrong = Color(0xFFDCE6E4);
  static const foam = Color(0xFFF1F6F5);
  static const dorado = Color(0xFFF4B400);
  static const reed = Color(0xFF4A6670);
  static const reedOnDark = Color(0xFF9DB7BD);
  static const errorLight = Color(0xFF9E1B1B);
  static const errorDark = Color(0xFFFFB4A8);
}

/// Radii follow hierarchy instead of one value everywhere.
abstract final class PiscatioRadii {
  static const slab = 24.0;
  static const sheet = 28.0;
  static const field = 14.0;
  static const thumb = 10.0;
  static const button = 16.0;
}

abstract final class PiscatioSizes {
  /// Minimum touch target for wet hands.
  static const minTouch = 56.0;

  /// Height of the primary action slab (Start trip, + Catch).
  static const actionSlab = 76.0;

  /// Horizontal page gutter.
  static const gutter = 20.0;
}

abstract final class PiscatioFonts {
  static const text = 'Archivo';
  static const expanded = 'ArchivoExpanded';
  static const condensed = 'ArchivoCondensed';

  /// Typewriter face, only for the specimen-tag card (it is the metaphor).
  static const typed = 'CourierPrime';
}

/// Semantic colors that Material's ColorScheme has no slot for.
@immutable
class PiscatioPalette extends ThemeExtension<PiscatioPalette> {
  const PiscatioPalette({
    required this.muted,
    required this.accentText,
    required this.record,
    required this.onRecord,
    required this.rule,
    required this.ruleStrong,
  });

  /// Secondary text.
  final Color muted;

  /// Red used as text/icon color (brighter on dark for contrast).
  final Color accentText;

  /// Personal records and achievements.
  final Color record;
  final Color onRecord;

  /// Ruler ticks and quiet separators.
  final Color rule;
  final Color ruleStrong;

  static const light = PiscatioPalette(
    muted: PiscatioColors.reed,
    accentText: PiscatioColors.redHead,
    record: PiscatioColors.dorado,
    onRecord: PiscatioColors.deepWater,
    rule: PiscatioColors.mistStrong,
    ruleStrong: PiscatioColors.reed,
  );

  static const dark = PiscatioPalette(
    muted: PiscatioColors.reedOnDark,
    accentText: PiscatioColors.redHeadOnDark,
    record: PiscatioColors.dorado,
    onRecord: PiscatioColors.deepWater,
    rule: PiscatioColors.deepWater3,
    ruleStrong: PiscatioColors.reedOnDark,
  );

  @override
  PiscatioPalette copyWith({
    Color? muted,
    Color? accentText,
    Color? record,
    Color? onRecord,
    Color? rule,
    Color? ruleStrong,
  }) => PiscatioPalette(
    muted: muted ?? this.muted,
    accentText: accentText ?? this.accentText,
    record: record ?? this.record,
    onRecord: onRecord ?? this.onRecord,
    rule: rule ?? this.rule,
    ruleStrong: ruleStrong ?? this.ruleStrong,
  );

  @override
  PiscatioPalette lerp(PiscatioPalette? other, double t) {
    if (other == null) return this;
    return PiscatioPalette(
      muted: Color.lerp(muted, other.muted, t)!,
      accentText: Color.lerp(accentText, other.accentText, t)!,
      record: Color.lerp(record, other.record, t)!,
      onRecord: Color.lerp(onRecord, other.onRecord, t)!,
      rule: Color.lerp(rule, other.rule, t)!,
      ruleStrong: Color.lerp(ruleStrong, other.ruleStrong, t)!,
    );
  }
}

extension PiscatioThemeX on BuildContext {
  PiscatioPalette get palette => Theme.of(this).extension<PiscatioPalette>()!;
}
