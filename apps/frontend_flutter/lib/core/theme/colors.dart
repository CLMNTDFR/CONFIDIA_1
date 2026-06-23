import 'package:flutter/material.dart';

/// Couleurs sémantiques et surfaces  -  indépendantes du thème de marque.
/// Pour primary / secondary / gradients : [ConfidiaPalette] via `context.palette`.
abstract final class ConfidiaColors {
  static const Color darkBackground = Color(0xFF06060B);
  static const Color darkSurface = Color(0xFF0E0E16);
  static const Color darkSurfaceElevated = Color(0xFF161622);
  static const Color darkSurfaceVariant = Color(0xFF1C1C2A);
  static const Color darkBorder = Color(0xFF2A2A3C);
  static const Color darkBorderSubtle = Color(0xFF1F1F2E);
  static const Color darkTextPrimary = Color(0xFFF4F4F8);
  static const Color darkTextSecondary = Color(0xFF9B9BAB);
  static const Color darkTextTertiary = Color(0xFF6B6B7B);

  static const Color lightBackground = Color(0xFFF5F5FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFFAFAFE);
  static const Color lightSurfaceVariant = Color(0xFFF0F0F6);
  static const Color lightBorder = Color(0xFFE4E4EE);
  static const Color lightBorderSubtle = Color(0xFFF0F0F5);
  static const Color lightTextPrimary = Color(0xFF12121E);
  static const Color lightTextSecondary = Color(0xFF5C5C6E);
  static const Color lightTextTertiary = Color(0xFF9090A0);

  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  static Color surface(bool isDark) => isDark ? darkSurface : lightSurface;
  static Color surfaceElevated(bool isDark) => isDark ? darkSurfaceElevated : lightSurfaceElevated;
  static Color border(bool isDark) => isDark ? darkBorder : lightBorder;
  static Color textPrimary(bool isDark) => isDark ? darkTextPrimary : lightTextPrimary;
  static Color textSecondary(bool isDark) => isDark ? darkTextSecondary : lightTextSecondary;
}
