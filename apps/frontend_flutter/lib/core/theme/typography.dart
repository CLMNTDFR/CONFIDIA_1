import 'package:flutter/material.dart';

import 'tokens/app_typography.dart';

/// Façade rétrocompatible. Source : [AppTypography].
abstract final class ConfidiaTypography {
  static TextTheme textTheme({required bool isDark}) => AppTypography.textTheme(isDark: isDark);
}
