import 'package:flutter/material.dart';

import 'app_opacity.dart';

/// Semantic colors and surfaces. Design System source of truth.
///
/// macOS hierarchy: three levels only (luminosity > outlines).
/// Independent of the brand theme ([ConfidiaPalette] / `context.palette`).
abstract final class AppColors {
  // --- Dark: Surface 0 / 1 / 2 ---
  /// Main background.
  static const Color darkSurface0 = Color(0xFF06060B);

  /// Cards and chrome. Lighter than the background, soft contrast.
  static const Color darkSurface1 = Color(0xFF12121A);

  /// Active / selected / chip elements.
  static const Color darkSurface2 = Color(0xFF1A1A22);

  static const Color darkBackground = darkSurface0;
  static const Color darkSurface = darkSurface1;
  static const Color darkSurfaceElevated = darkSurface1;
  static const Color darkSurfaceVariant = darkSurface2;

  /// Border ink (opaque). Compose with [AppOpacity.border*], do not
  /// reapply a strong alpha on [border].
  static const Color darkBorderInk = Color(0xFFFFFFFF);

  static const Color darkTextPrimary = Color(0xFFF4F4F8);
  static const Color darkTextSecondary = Color(0xFF9B9BAB);
  static const Color darkTextTertiary = Color(0xFF6B6B7B);

  // --- Light: Surface 0 / 1 / 2 ---
  static const Color lightSurface0 = Color(0xFFF5F5FA);
  static const Color lightSurface1 = Color(0xFFFFFFFF);
  static const Color lightSurface2 = Color(0xFFEEEEF4);

  static const Color lightBackground = lightSurface0;
  static const Color lightSurface = lightSurface1;
  static const Color lightSurfaceElevated = lightSurface1;
  static const Color lightSurfaceVariant = lightSurface2;

  static const Color lightBorderInk = Color(0xFF000000);

  static const Color lightTextPrimary = Color(0xFF12121E);
  static const Color lightTextSecondary = Color(0xFF5C5C6E);
  static const Color lightTextTertiary = Color(0xFF9090A0);

  // Semantic
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  /// Ready-to-use hairline border. Do not chain `.withValues(alpha:)`.
  static Color darkBorder = darkBorderInk.withValues(alpha: AppOpacity.borderHairline);
  static Color darkBorderSubtle = darkBorderInk.withValues(alpha: AppOpacity.borderSubtle);
  static Color lightBorder = lightBorderInk.withValues(alpha: AppOpacity.borderHairline);
  static Color lightBorderSubtle = lightBorderInk.withValues(alpha: AppOpacity.borderSubtle);

  static Color surface0(bool isDark) => isDark ? darkSurface0 : lightSurface0;
  static Color surface1(bool isDark) => isDark ? darkSurface1 : lightSurface1;
  static Color surface2(bool isDark) => isDark ? darkSurface2 : lightSurface2;

  static Color background(bool isDark) => surface0(isDark);
  static Color surface(bool isDark) => surface1(isDark);
  static Color surfaceElevated(bool isDark) => surface1(isDark);
  static Color surfaceVariant(bool isDark) => surface2(isDark);
  static Color borderInk(bool isDark) => isDark ? darkBorderInk : lightBorderInk;
  static Color border(bool isDark) => borderInk(isDark).withValues(alpha: AppOpacity.borderHairline);
  static Color borderSubtle(bool isDark) => borderInk(isDark).withValues(alpha: AppOpacity.borderSubtle);
  static Color textPrimary(bool isDark) => isDark ? darkTextPrimary : lightTextPrimary;
  static Color textSecondary(bool isDark) => isDark ? darkTextSecondary : lightTextSecondary;
  static Color textTertiary(bool isDark) => isDark ? darkTextTertiary : lightTextTertiary;
}
