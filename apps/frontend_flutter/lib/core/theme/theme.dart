import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'colors.dart';
import 'spacing.dart';
import 'typography.dart';

abstract final class ConfidiaTheme {
  static ThemeData dark() => _buildTheme(isDark: true);
  static ThemeData light() => _buildTheme(isDark: false);

  static ThemeData _buildTheme({required bool isDark}) {
    final surface = isDark ? ConfidiaColors.darkSurface : ConfidiaColors.lightSurface;
    final surfaceVariant = isDark ? ConfidiaColors.darkSurfaceVariant : ConfidiaColors.lightSurfaceVariant;
    final border = isDark ? ConfidiaColors.darkBorder : ConfidiaColors.lightBorder;

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: ConfidiaColors.primary,
        onPrimary: Colors.white,
        secondary: ConfidiaColors.secondary,
        onSecondary: Colors.white,
        tertiary: ConfidiaColors.accent,
        surface: surface,
        onSurface: ConfidiaColors.textPrimary(isDark),
        error: ConfidiaColors.error,
        onError: Colors.white,
      ),
      textTheme: ConfidiaTypography.textTheme(isDark: isDark),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      cardTheme: CardThemeData(
        color: isDark ? ConfidiaColors.darkSurfaceElevated : ConfidiaColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ConfidiaSpacing.radiusLg),
          side: BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ConfidiaColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: ConfidiaSpacing.md, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ConfidiaColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: ConfidiaSpacing.lg, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ConfidiaColors.textPrimary(isDark),
          side: BorderSide(color: border),
          padding: const EdgeInsets.symmetric(horizontal: ConfidiaSpacing.lg, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: ConfidiaColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceVariant,
        side: BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: ConfidiaColors.primary.withValues(alpha: 0.12),
        height: 68,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceVariant,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }
}
