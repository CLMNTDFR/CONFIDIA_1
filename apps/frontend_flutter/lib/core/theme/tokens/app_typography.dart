import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typographie du Design System (Inter). Source pour [ThemeData.textTheme].
abstract final class AppTypography {
  static TextTheme textTheme({required bool isDark}) {
    final base = GoogleFonts.interTextTheme();
    final color = AppColors.textPrimary(isDark);
    final secondary = AppColors.textSecondary(isDark);

    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.5,
        color: color,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: color,
      ),
      displaySmall: base.displaySmall?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: color,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: secondary,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: color,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: secondary,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: color,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: secondary,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: secondary,
      ),
    );
  }
}
