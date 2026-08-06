import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_opacity.dart';
import 'app_radius.dart';

/// Bordures standardisées. Traits quasi invisibles ; le focus reste lisible.
abstract final class AppBorders {
  static const double hairline = 1;
  static const double focus = 1.4;

  static BorderSide subtle(bool isDark) => BorderSide(
        color: AppColors.borderSubtle(isDark),
        width: hairline,
      );

  static BorderSide standard(bool isDark, {double alpha = AppOpacity.borderHairline}) => BorderSide(
        color: AppColors.borderInk(isDark).withValues(alpha: alpha),
        width: hairline,
      );

  static BorderSide focusSide(Color accent) => BorderSide(
        color: accent.withValues(alpha: AppOpacity.borderFocus),
        width: focus,
      );

  static BorderSide error({double width = hairline}) => BorderSide(
        color: AppColors.error.withValues(alpha: 0.7),
        width: width,
      );

  static OutlineInputBorder input({
    required bool isDark,
    double alpha = AppOpacity.borderHairline,
    Color? accent,
    double width = hairline,
  }) {
    return OutlineInputBorder(
      borderRadius: AppRadius.controlAll,
      borderSide: BorderSide(
        color: accent ?? AppColors.borderInk(isDark).withValues(alpha: alpha),
        width: width,
      ),
    );
  }
}
