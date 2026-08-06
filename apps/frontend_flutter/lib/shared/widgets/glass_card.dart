import 'package:flutter/material.dart';

import '../../core/theme/spacing.dart';
import '../../core/theme/theme_context.dart';
import '../../core/theme/tokens/tokens.dart';

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
      alpha: isDark ? AppOpacity.glassDark : AppOpacity.glassLight,
    );
    final decoration = BoxDecoration(
      color: fill,
      borderRadius: radius,
      border: Border.fromBorderSide(AppBorders.standard(isDark)),
      boxShadow: AppShadows.card(isDark: isDark, palette: context.palette),
    );

    final Widget content;
    if (clipContent) {
      content = ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: AppBlur.glassFilter,
          child: Container(padding: resolvedPadding, decoration: decoration, child: child),
        ),
      );
    } else {
      content = Container(
        decoration: decoration,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: radius,
                child: BackdropFilter(
                  filter: AppBlur.glassFilter,
                  child: Container(color: decoration.color),
                ),
              ),
            ),
            Padding(padding: resolvedPadding, child: child),
          ],
        ),
      );
    }

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: content,
        ),
      );
    }
    return content;
  }
}
