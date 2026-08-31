import 'package:flutter/material.dart';

import '../../core/mvp/confidia_mvp_scope.dart';
import '../../core/theme/tokens/tokens.dart';
import 'confidia_tooltip.dart';

/// Pastille « Démo » pour pages et fonctions hors MVP Holberton.
class ConfidiaDemoBadge extends StatelessWidget {
  final bool compact;
  final bool onAccent;

  const ConfidiaDemoBadge({
    super.key,
    this.compact = false,
    this.onAccent = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = onAccent
        ? Colors.white
        : AppColors.textSecondary(isDark);
    final fill = onAccent
        ? Colors.white.withValues(alpha: 0.16)
        : ink.withValues(alpha: isDark ? 0.1 : 0.07);

    return ConfidiaTooltip(
      message: ConfidiaMvpScope.demoTooltip,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 5 : 7,
          vertical: compact ? 1 : 2,
        ),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: AppRadius.smAll,
          border: Border.all(color: ink.withValues(alpha: onAccent ? 0.45 : 0.28)),
        ),
        child: Text(
          'Démo',
          style: TextStyle(
            fontSize: compact ? 8 : 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
            height: 1.1,
            color: ink,
          ),
        ),
      ),
    );
  }
}
