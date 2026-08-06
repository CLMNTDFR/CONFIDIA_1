import 'package:flutter/material.dart';

import '../palette.dart';
import 'app_colors.dart';
import 'app_opacity.dart';

/// Ombres sobres type Cursor / macOS (peu de couches, blur doux).
abstract final class AppShadows {
  static List<BoxShadow> soft({required bool isDark, Color? accent}) {
    if (accent != null) {
      return [
        BoxShadow(
          color: accent.withValues(alpha: isDark ? AppOpacity.glowSoft : AppOpacity.tintSoft),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];
    }
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ];
  }

  static List<BoxShadow> card({required bool isDark, ConfidiaPalette? palette}) {
    return [
      BoxShadow(
        color: isDark
            ? Colors.black.withValues(alpha: 0.28)
            : (palette?.primary ?? AppColors.info).withValues(alpha: 0.04),
        blurRadius: 24,
        offset: const Offset(0, 8),
      ),
    ];
  }

  static List<BoxShadow> tooltip({required bool isDark}) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.1),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> glow(Color color, {double alpha = AppOpacity.glowMedium}) => [
        BoxShadow(
          color: color.withValues(alpha: alpha),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  static const List<BoxShadow> none = <BoxShadow>[];
}
