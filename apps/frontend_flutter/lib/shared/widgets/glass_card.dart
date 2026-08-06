import 'package:flutter/material.dart';

import '../../core/theme/spacing.dart';
import '../../core/theme/theme_context.dart';
import '../../core/theme/tokens/tokens.dart';

/// Carte de contenu. Quasi sans flou : surface opaque et ombre douce.
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
    final decoration = BoxDecoration(
      color: fill,
      borderRadius: radius,
      border: Border.fromBorderSide(AppBorders.standard(isDark)),
      boxShadow: AppShadows.card(isDark: isDark, palette: context.palette),
    );

    final content = clipContent
        ? ClipRRect(
            borderRadius: radius,
            child: Container(padding: resolvedPadding, decoration: decoration, child: child),
          )
        : Container(
            decoration: decoration,
            padding: resolvedPadding,
            child: child,
          );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: content,
        ),
      );
    }
    return content;
  }
}
