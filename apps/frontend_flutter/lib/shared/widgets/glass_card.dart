import 'package:flutter/material.dart';

import '../../core/theme/spacing.dart';
import '../../core/theme/tokens/tokens.dart';

/// Carte de contenu. Quasi sans flou : surface opaque et ombre douce.
///
/// [Material] + [clipBehavior] : les surbrillances InkWell / ListTile
/// restent dans les coins arrondis (pas de splash rectangulaire).
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final double borderRadius;
  final bool highlighted;
  final bool clipContent;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.borderRadius = ConfidiaSpacing.radiusLg,
    this.highlighted = false,
    this.clipContent = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final radius = BorderRadius.circular(borderRadius);
    final resolvedPadding = padding ?? const EdgeInsets.all(ConfidiaSpacing.lg);
    final base = highlighted ? AppColors.surface2(isDark) : AppColors.surface1(isDark);
    final fill = base.withValues(
      alpha: isDark ? AppOpacity.contentDark : AppOpacity.contentLight,
    );

    final surface = Material(
      color: fill,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: AppBorders.standard(isDark),
      ),
      clipBehavior: clipContent ? Clip.antiAlias : Clip.none,
      child: onTap == null
          ? Padding(padding: resolvedPadding, child: child)
          : InkWell(
              onTap: onTap,
              mouseCursor: SystemMouseCursors.click,
              hoverColor: (isDark ? Colors.white : Colors.black).withValues(
                alpha: isDark ? AppOpacity.hoverInkDark : AppOpacity.hoverInkLight,
              ),
              splashColor: (isDark ? Colors.white : Colors.black).withValues(alpha: AppOpacity.quiet),
              child: Padding(padding: resolvedPadding, child: child),
            ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: AppShadows.card(isDark: isDark),
      ),
      child: surface,
    );
  }
}
