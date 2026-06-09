import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';

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
    final decoration = BoxDecoration(
      color: isDark
          ? ConfidiaColors.darkSurfaceElevated.withValues(alpha: 0.75)
          : Colors.white.withValues(alpha: 0.82),
      borderRadius: radius,
      border: Border.all(
        color: highlighted
            ? ConfidiaColors.primary.withValues(alpha: 0.4)
            : (isDark ? ConfidiaColors.darkBorder : ConfidiaColors.lightBorder),
      ),
      boxShadow: [
        BoxShadow(
          color: isDark ? Colors.black.withValues(alpha: 0.3) : ConfidiaColors.primary.withValues(alpha: 0.04),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ],
    );

    final Widget content;
    if (clipContent) {
      content = ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
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
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
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
