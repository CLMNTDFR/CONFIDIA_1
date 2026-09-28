import 'package:flutter/material.dart';

import '../../core/theme/tokens/tokens.dart';

/// Understated tooltip, aligned with CONFIDIA chrome (light and dark).
class ConfidiaTooltip extends StatelessWidget {
  final String message;
  final Widget child;
  final bool preferBelow;

  const ConfidiaTooltip({
    super.key,
    required this.message,
    required this.child,
    this.preferBelow = true,
  });

  static BoxDecoration decoration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: AppColors.surface1(isDark),
      borderRadius: AppRadius.mdAll,
      border: Border.fromBorderSide(AppBorders.standard(isDark)),
      boxShadow: AppShadows.card(isDark: isDark),
    );
  }

  static TextStyle textStyle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      color: AppColors.textPrimary(isDark),
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.35,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message,
      preferBelow: preferBelow,
      waitDuration: const Duration(milliseconds: 350),
      decoration: decoration(context),
      textStyle: textStyle(context),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: child,
    );
  }
}
