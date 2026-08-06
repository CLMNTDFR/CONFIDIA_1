import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_opacity.dart';
import 'app_radius.dart';

/// Bordures standardisées du Design System.
abstract final class AppBorders {
  static const double hairline = 1;
  static const double emphasis = 1.4;
  static const double focus = 1.5;

  static BorderSide subtle(bool isDark) => BorderSide(
        color: AppColors.borderSubtle(isDark),
        width: hairline,
      );

  static BorderSide standard(bool isDark, {double alpha = AppOpacity.opaque}) => BorderSide(
        color: AppColors.border(isDark).withValues(alpha: alpha),
        width: hairline,
      );

  static BorderSide strong(bool isDark) => BorderSide(
        color: AppColors.border(isDark).withValues(alpha: AppOpacity.borderStrong),
        width: hairline,
      );

  static BorderSide focusSide(Color accent) => BorderSide(
        color: accent.withValues(alpha: AppOpacity.borderFocus),
        width: focus,
      );

  static BorderSide error({double width = hairline}) => BorderSide(
        color: AppColors.error,
        width: width,
      );

  static OutlineInputBorder input({
    required bool isDark,
    double alpha = AppOpacity.opaque,
    Color? accent,
    double width = hairline,
  }) {
    return OutlineInputBorder(
      borderRadius: AppRadius.controlAll,
      borderSide: BorderSide(
        color: accent ?? AppColors.border(isDark).withValues(alpha: alpha),
        width: width,
      ),
    );
  }
}
