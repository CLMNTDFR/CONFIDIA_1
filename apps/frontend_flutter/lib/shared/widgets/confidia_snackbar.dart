import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/theme_context.dart';
import 'mobile_shell_insets.dart';

enum ConfidiaSnackType { success, error, warning, info }

/// Affiche un message flottant lisible sur fond clair et sombre.
void showConfidiaSnackBar(
  BuildContext context,
  String message, {
  ConfidiaSnackType type = ConfidiaSnackType.info,
  Duration duration = const Duration(seconds: 3),
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final palette = context.palette;
  final isMobileShell = ConfidiaMobileShell.isMobileShell(context);

  final (Color background, Color foreground, IconData icon) = switch (type) {
    ConfidiaSnackType.success => (
        isDark ? const Color(0xFF0D3D2E) : const Color(0xFFECFDF5),
        isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857),
        Icons.check_circle_rounded,
      ),
    ConfidiaSnackType.error => (
        isDark ? const Color(0xFF451A1A) : const Color(0xFFFEF2F2),
        isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C),
        Icons.error_outline_rounded,
      ),
    ConfidiaSnackType.warning => (
        isDark ? const Color(0xFF422006) : const Color(0xFFFFFBEB),
        isDark ? const Color(0xFFFCD34D) : const Color(0xFFB45309),
        Icons.warning_amber_rounded,
      ),
    ConfidiaSnackType.info => (
        isDark ? palette.primary.withValues(alpha: 0.22) : palette.primary.withValues(alpha: 0.1),
        isDark ? ConfidiaColors.darkTextPrimary : palette.primary,
        Icons.info_outline_rounded,
      ),
  };

  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();

  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      duration: duration,
      backgroundColor: background,
      elevation: isDark ? 8 : 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: foreground.withValues(alpha: 0.22)),
      ),
      margin: EdgeInsets.only(
        left: ConfidiaSpacing.lg,
        right: ConfidiaSpacing.lg,
        bottom: isMobileShell ? ConfidiaMobileShell.fabBottom(context) : ConfidiaSpacing.lg,
      ),
      content: Row(
        children: [
          Icon(icon, color: foreground, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
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
