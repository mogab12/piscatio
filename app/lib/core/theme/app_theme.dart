import 'package:flutter/material.dart';

import 'tokens.dart';
import 'typography.dart';

abstract final class AppTheme {
  static ThemeData light() => _build(
    brightness: Brightness.light,
    scheme: const ColorScheme(
      brightness: Brightness.light,
      primary: PiscatioColors.redHead,
      onPrimary: PiscatioColors.paper,
      primaryContainer: Color(0xFFFFDAD6),
      onPrimaryContainer: Color(0xFF410002),
      secondary: PiscatioColors.deepWater,
      onSecondary: PiscatioColors.paper,
      secondaryContainer: PiscatioColors.mist,
      onSecondaryContainer: PiscatioColors.deepWater,
      tertiary: PiscatioColors.dorado,
      onTertiary: PiscatioColors.deepWater,
      error: PiscatioColors.errorLight,
      onError: PiscatioColors.paper,
      surface: PiscatioColors.paper,
      onSurface: PiscatioColors.deepWater,
      onSurfaceVariant: PiscatioColors.reed,
      surfaceContainerLowest: PiscatioColors.paper,
      surfaceContainerLow: Color(0xFFF6F9F8),
      surfaceContainer: PiscatioColors.mist,
      surfaceContainerHigh: PiscatioColors.mistStrong,
      surfaceContainerHighest: Color(0xFFCFDCD9),
      outline: Color(0xFF8AA3A9),
      outlineVariant: PiscatioColors.mistStrong,
      inverseSurface: PiscatioColors.deepWater,
      onInverseSurface: PiscatioColors.foam,
      inversePrimary: PiscatioColors.redHeadOnDark,
    ),
    palette: PiscatioPalette.light,
  );

  static ThemeData dark() => _build(
    brightness: Brightness.dark,
    scheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: PiscatioColors.redHeadDark,
      onPrimary: PiscatioColors.paper,
      primaryContainer: Color(0xFF7A0F0C),
      onPrimaryContainer: Color(0xFFFFDAD6),
      secondary: PiscatioColors.foam,
      onSecondary: PiscatioColors.deepWater,
      secondaryContainer: PiscatioColors.deepWater3,
      onSecondaryContainer: PiscatioColors.foam,
      tertiary: PiscatioColors.dorado,
      onTertiary: PiscatioColors.deepWater,
      error: PiscatioColors.errorDark,
      onError: Color(0xFF5F1410),
      surface: PiscatioColors.deepWater,
      onSurface: PiscatioColors.foam,
      onSurfaceVariant: PiscatioColors.reedOnDark,
      surfaceContainerLowest: Color(0xFF07202A),
      surfaceContainerLow: Color(0xFF0E2F39),
      surfaceContainer: PiscatioColors.deepWater2,
      surfaceContainerHigh: PiscatioColors.deepWater3,
      surfaceContainerHighest: Color(0xFF1F525F),
      outline: Color(0xFF5E828B),
      outlineVariant: PiscatioColors.deepWater3,
      inverseSurface: PiscatioColors.foam,
      onInverseSurface: PiscatioColors.deepWater,
      inversePrimary: PiscatioColors.redHead,
    ),
    palette: PiscatioPalette.dark,
  );

  static ThemeData _build({
    required Brightness brightness,
    required ColorScheme scheme,
    required PiscatioPalette palette,
  }) {
    final text = buildTextTheme(scheme.onSurface, palette.muted);
    final fieldRadius = BorderRadius.circular(PiscatioRadii.field);
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: PiscatioFonts.text,
      textTheme: text,
      scaffoldBackgroundColor: scheme.surface,
      extensions: [palette],
      splashFactory: InkSparkle.splashFactory,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
        toolbarHeight: 64,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: scheme.surface,
        indicatorColor: scheme.secondaryContainer,
        surfaceTintColor: Colors.transparent,
        // Condensed: five tabs, and "Comunidade" still fits on one line.
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.labelMedium!.copyWith(
            fontFamily: PiscatioFonts.condensed,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, PiscatioSizes.minTouch),
          textStyle: text.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PiscatioRadii.button),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, PiscatioSizes.minTouch),
          textStyle: text.labelLarge,
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.outline, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PiscatioRadii.button),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          textStyle: text.labelLarge,
          foregroundColor: scheme.onSurface,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: BorderSide(color: scheme.onSurface, width: 2),
        ),
        labelStyle: text.bodyLarge!.copyWith(color: palette.muted),
        hintStyle: text.bodyLarge!.copyWith(color: palette.muted),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(PiscatioRadii.sheet),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: text.headlineSmall,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PiscatioRadii.sheet),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: text.bodyLarge!.copyWith(
          color: scheme.onInverseSurface,
        ),
        actionTextColor: scheme.inversePrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PiscatioRadii.field),
        ),
      ),
      listTileTheme: ListTileThemeData(
        minTileHeight: PiscatioSizes.minTouch,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: PiscatioSizes.gutter,
        ),
        titleTextStyle: text.titleMedium,
        subtitleTextStyle: text.bodyMedium!.copyWith(color: palette.muted),
        iconColor: scheme.onSurface,
      ),
      dividerTheme: DividerThemeData(
        color: palette.rule,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        // Selected chips fill with the text color, so their label flips to
        // the surface color (every chip type, not only choice chips).
        labelStyle: text.labelLarge!.copyWith(
          color: WidgetStateColor.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? scheme.surface
                : scheme.onSurface,
          ),
        ),
        side: BorderSide.none,
        backgroundColor: scheme.surfaceContainer,
        selectedColor: scheme.onSurface,
        secondaryLabelStyle: text.labelLarge!.copyWith(color: scheme.surface),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PiscatioRadii.field),
        ),
        showCheckmark: false,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? scheme.onPrimary : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? scheme.primary : null,
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.outline,
        ),
      ),
    );
  }
}
