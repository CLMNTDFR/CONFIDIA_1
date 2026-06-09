import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';

/// Info-bulle sobre, lisible en thème clair et sombre.
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
      color: isDark ? ConfidiaColors.darkSurfaceElevated : Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: ConfidiaColors.border(isDark)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.1),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static TextStyle textStyle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      color: ConfidiaColors.textPrimary(isDark),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: child,
    );
  }
}
