import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'palette.dart';
import 'tokens/tokens.dart';

abstract final class ConfidiaTheme {
  static final Map<String, ThemeData> _cache = {};

  static ThemeData dark(ConfidiaPalette palette) =>
      _cache.putIfAbsent('d-${palette.id.name}', () => _buildTheme(isDark: true, palette: palette));

  static ThemeData light(ConfidiaPalette palette) =>
      _cache.putIfAbsent('l-${palette.id.name}', () => _buildTheme(isDark: false, palette: palette));

  static ThemeData _buildTheme({required bool isDark, required ConfidiaPalette palette}) {
    final surface1 = AppColors.surface1(isDark);
    final surface2 = AppColors.surface2(isDark);
    final hairline = AppBorders.standard(isDark);

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: Colors.transparent,
      extensions: [ConfidiaPaletteTheme(palette: palette)],
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: palette.primary,
        onPrimary: Colors.white,
        secondary: palette.secondary,
        onSecondary: Colors.white,
        tertiary: palette.accent,
        surface: surface1,
        onSurface: AppColors.textPrimary(isDark),
        error: AppColors.error,
        onError: Colors.white,
      ),
      textTheme: AppTypography.textTheme(isDark: isDark),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: AppElevation.flat,
        scrolledUnderElevation: AppElevation.flat,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      cardTheme: CardThemeData(
        color: surface1,
        elevation: AppElevation.flat,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardAll,
          side: hairline,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: surface1.withValues(
          alpha: isDark ? AppOpacity.inputFillDark : AppOpacity.inputFillLight,
        ),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary(isDark),
        ),
        floatingLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: palette.primary,
          letterSpacing: 0.2,
        ),
        hintStyle: TextStyle(
          fontSize: 13,
          color: AppColors.textSecondary(isDark),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        prefixIconConstraints: const BoxConstraints(minWidth: 42, minHeight: 38),
        suffixIconConstraints: const BoxConstraints(minWidth: 42, minHeight: 38),
        border: AppBorders.input(isDark: isDark, alpha: AppOpacity.borderMedium),
        enabledBorder: AppBorders.input(isDark: isDark, alpha: AppOpacity.borderHairline),
        focusedBorder: AppBorders.input(
          isDark: isDark,
          accent: palette.primary.withValues(alpha: AppOpacity.borderFocus),
          width: AppBorders.focus,
        ),
        errorBorder: AppBorders.input(
          isDark: isDark,
          accent: AppColors.error.withValues(alpha: 0.7),
        ),
        focusedErrorBorder: AppBorders.input(
          isDark: isDark,
          accent: AppColors.error.withValues(alpha: 0.85),
          width: AppBorders.focus,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: Colors.white,
          elevation: AppElevation.flat,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonAll),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary(isDark),
          side: hairline,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonAll),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: palette.primary,
        foregroundColor: Colors.white,
        elevation: AppElevation.overlay,
      ),
      dividerTheme: DividerThemeData(color: hairline.color, thickness: AppBorders.hairline),
      chipTheme: ChipThemeData(
        backgroundColor: surface2,
        side: hairline,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.chipAll),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface1,
        indicatorColor: palette.primary.withValues(alpha: AppOpacity.indicator),
        height: AppSpacing.materialNavBarHeight,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surface1,
        behavior: SnackBarBehavior.floating,
        elevation: AppElevation.modal,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.buttonAll,
          side: hairline,
        ),
        contentTextStyle: TextStyle(
          color: AppColors.textPrimary(isDark),
          fontWeight: FontWeight.w600,
          fontSize: 14,
          height: 1.35,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: AppRadius.buttonAll),
          ),
        ),
      ),
    );
  }
}
