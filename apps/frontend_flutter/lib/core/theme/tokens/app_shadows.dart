import 'package:flutter/material.dart';

import '../palette.dart';
import 'app_colors.dart';
import 'app_opacity.dart';

/// Ombres sobres. Chrome : très diffuses ; contenu : discrètes.
abstract final class AppShadows {
  /// Ombre chrome (nav, sheets, dialogs, menus). Extrêmement diffuse.
  static List<BoxShadow> chrome({required bool isDark}) => [
        BoxShadow(
          color: Colors.black.withValues(
            alpha: isDark ? AppOpacity.chromeShadowDark : AppOpacity.chromeShadowLight,
          ),
          blurRadius: 28,
          spreadRadius: -4,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> soft({required bool isDark, Color? accent}) {
    if (accent != null) {
      return [
        BoxShadow(
          color: accent.withValues(alpha: isDark ? AppOpacity.glowSoft : AppOpacity.tintSoft),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ];
    }
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? AppOpacity.shadowDark : AppOpacity.shadowLight),
        blurRadius: 14,
        offset: const Offset(0, 4),
      ),
    ];
  }

  static List<BoxShadow> card({required bool isDark, ConfidiaPalette? palette}) {
    return [
      BoxShadow(
        color: isDark
            ? Colors.black.withValues(alpha: AppOpacity.shadowDark)
            : (palette?.primary ?? AppColors.info).withValues(alpha: AppOpacity.shadowLight),
        blurRadius: 16,
        spreadRadius: -2,
        offset: const Offset(0, 6),
      ),
    ];
  }

  static List<BoxShadow> tooltip({required bool isDark}) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.05),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> glow(Color color, {double alpha = AppOpacity.glowMedium}) => [
        BoxShadow(
          color: color.withValues(alpha: alpha),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  static const List<BoxShadow> none = <BoxShadow>[];
}
