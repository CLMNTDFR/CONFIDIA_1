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
    final surface = AppColors.surface(isDark);
    final surfaceVariant = AppColors.surfaceVariant(isDark);
    final border = AppColors.border(isDark);

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
        surface: surface,
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
        color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurface,
        elevation: AppElevation.flat,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardAll,
          side: BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: isDark
            ? AppColors.darkSurfaceElevated.withValues(alpha: AppOpacity.inputFillDark)
            : Colors.white.withValues(alpha: AppOpacity.inputFillLight),
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
        border: AppBorders.input(isDark: isDark, alpha: AppOpacity.borderStrong),
        enabledBorder: AppBorders.input(isDark: isDark, alpha: AppOpacity.borderMedium),
        focusedBorder: AppBorders.input(
          isDark: isDark,
          accent: palette.primary.withValues(alpha: AppOpacity.borderFocus),
          width: AppBorders.focus,
        ),
        errorBorder: AppBorders.input(isDark: isDark, accent: AppColors.error),
        focusedErrorBorder: AppBorders.input(
          isDark: isDark,
          accent: AppColors.error,
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
          side: BorderSide(color: border),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonAll),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: palette.primary,
        foregroundColor: Colors.white,
        elevation: AppElevation.overlay,
      ),
      dividerTheme: DividerThemeData(color: border, thickness: AppBorders.hairline),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceVariant,
        side: BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.chipAll),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: palette.primary.withValues(alpha: AppOpacity.indicator),
        height: AppSpacing.materialNavBarHeight,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurface,
        behavior: SnackBarBehavior.floating,
        elevation: AppElevation.modal,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.buttonAll,
          side: BorderSide(color: border.withValues(alpha: 0.6)),
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
