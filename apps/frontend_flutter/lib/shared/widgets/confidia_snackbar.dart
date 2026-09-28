import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/theme_context.dart';
import 'mobile_shell_insets.dart';

enum ConfidiaSnackType { success, error, warning, info }

/// Compact floating toast, centered on desktop, adapted for mobile.
void showConfidiaSnackBar(
  BuildContext context,
  String message, {
  ConfidiaSnackType type = ConfidiaSnackType.info,
  Duration duration = const Duration(seconds: 3),
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final palette = context.palette;
  final isMobileShell = ConfidiaMobileShell.isMobileShell(context);

  final (Color accent, Color surface, IconData icon) = switch (type) {
    ConfidiaSnackType.success => (
        ConfidiaColors.success,
        isDark ? const Color(0xFF0F2E24) : const Color(0xFFECFDF5),
        Icons.check_circle_rounded,
      ),
    ConfidiaSnackType.error => (
        ConfidiaColors.error,
        isDark ? const Color(0xFF3F1717) : const Color(0xFFFEF2F2),
        Icons.error_outline_rounded,
      ),
    ConfidiaSnackType.warning => (
        ConfidiaColors.warning,
        isDark ? const Color(0xFF3D2E0A) : const Color(0xFFFFFBEB),
        Icons.warning_amber_rounded,
      ),
    ConfidiaSnackType.info => (
        palette.primary,
        isDark ? const Color(0xFF12182A) : const Color(0xFFEFF6FF),
        Icons.info_outline_rounded,
      ),
  };

  final messenger = ScaffoldMessenger.of(context);
  messenger.clearSnackBars();
  messenger.hideCurrentSnackBar();

  // Flutter forbids width + margin together: width on desktop (auto-centering), margin on mobile.
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      duration: duration,
      backgroundColor: surface,
      elevation: isDark ? 10 : 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: accent.withValues(alpha: isDark ? 0.45 : 0.35)),
      ),
      width: isMobileShell ? null : 380,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      // Scaffold already places the snackbar above the bar. A FAB margin
      // would push the toast into the middle of the content.
      margin: isMobileShell
          ? const EdgeInsets.fromLTRB(ConfidiaSpacing.md, 0, ConfidiaSpacing.md, ConfidiaSpacing.sm)
          : null,
      content: Row(
        children: [
          Icon(icon, color: accent, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: isDark ? Colors.white.withValues(alpha: 0.92) : ConfidiaColors.lightTextPrimary,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
            ),
          ),
        ],
      ),
    ),
  );
}

extension ConfidiaSnackBarContext on BuildContext {
  void showConfidiaSnack(String message, {ConfidiaSnackType type = ConfidiaSnackType.info}) =>
      showConfidiaSnackBar(this, message, type: type);
}
