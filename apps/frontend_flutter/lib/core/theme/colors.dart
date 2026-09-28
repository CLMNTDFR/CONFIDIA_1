import 'package:flutter/material.dart';

import 'tokens/app_colors.dart';

/// Backward-compatible facade. Source of truth: [AppColors].
abstract final class ConfidiaColors {
  static const Color darkBackground = AppColors.darkBackground;
  static const Color darkSurface = AppColors.darkSurface;
  static const Color darkSurfaceElevated = AppColors.darkSurfaceElevated;
  static const Color darkSurfaceVariant = AppColors.darkSurfaceVariant;
  static Color get darkBorder => AppColors.darkBorder;
  static Color get darkBorderSubtle => AppColors.darkBorderSubtle;
  static const Color darkTextPrimary = AppColors.darkTextPrimary;
  static const Color darkTextSecondary = AppColors.darkTextSecondary;
  static const Color darkTextTertiary = AppColors.darkTextTertiary;

  static const Color lightBackground = AppColors.lightBackground;
  static const Color lightSurface = AppColors.lightSurface;
  static const Color lightSurfaceElevated = AppColors.lightSurfaceElevated;
  static const Color lightSurfaceVariant = AppColors.lightSurfaceVariant;
  static Color get lightBorder => AppColors.lightBorder;
  static Color get lightBorderSubtle => AppColors.lightBorderSubtle;
  static const Color lightTextPrimary = AppColors.lightTextPrimary;
  static const Color lightTextSecondary = AppColors.lightTextSecondary;
  static const Color lightTextTertiary = AppColors.lightTextTertiary;

  static const Color success = AppColors.success;
  static const Color warning = AppColors.warning;
  static const Color error = AppColors.error;
  static const Color info = AppColors.info;

  static Color surface0(bool isDark) => AppColors.surface0(isDark);
  static Color surface1(bool isDark) => AppColors.surface1(isDark);
  static Color surface2(bool isDark) => AppColors.surface2(isDark);

  static Color surface(bool isDark) => AppColors.surface(isDark);
  static Color surfaceElevated(bool isDark) => AppColors.surfaceElevated(isDark);
  static Color border(bool isDark) => AppColors.border(isDark);
  static Color textPrimary(bool isDark) => AppColors.textPrimary(isDark);
  static Color textSecondary(bool isDark) => AppColors.textSecondary(isDark);
}
