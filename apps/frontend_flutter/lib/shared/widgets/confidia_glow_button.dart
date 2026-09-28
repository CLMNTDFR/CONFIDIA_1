import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/theme_context.dart';
import '../../core/theme/tokens/tokens.dart';
import 'confidia_tappable.dart';

/// Compact action button. Primary = understated brand fill (no neon glow).
class ConfidiaGlowButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool primary;
  final bool expand;

  const ConfidiaGlowButton({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
    this.primary = true,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final enabled = onPressed != null;
    final brand = context.palette.primary;
    final radius = BorderRadius.circular(12);

    final decoration = primary
        ? BoxDecoration(
            borderRadius: radius,
            color: brand.withValues(alpha: enabled ? 1 : 0.45),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: brand.withValues(alpha: 0.18),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          )
        : BoxDecoration(
            borderRadius: radius,
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: enabled ? 0.06 : 0.03),
            border: Border.fromBorderSide(
              enabled ? AppBorders.standard(isDark) : AppBorders.subtle(isDark),
            ),
          );

    final fg = primary
        ? Colors.white.withValues(alpha: enabled ? 1 : 0.6)
        : ConfidiaColors.textSecondary(isDark).withValues(alpha: enabled ? 1 : 0.5);

    return ConfidiaTappable(
      onTap: onPressed,
      pressScale: 0.97,
      borderRadius: radius,
      child: Container(
        width: expand ? double.infinity : null,
        constraints: const BoxConstraints(minHeight: 36),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: decoration,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.15,
                  height: 1.2,
                  color: fg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
