import 'package:flutter/material.dart';

import '../../core/theme/tokens/tokens.dart';

/// Discreet chrome material: light blur, nearly opaque fill, diffuse shadow,
/// very faint top wash. Not for content cards.
class ConfidiaChromeMaterial extends StatelessWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;

  const ConfidiaChromeMaterial({
    super.key,
    required this.child,
    this.borderRadius = BorderRadius.zero,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = AppColors.surface1(isDark).withValues(
      alpha: isDark ? AppOpacity.chromeDark : AppOpacity.chromeLight,
    );
    final wash = Color.alphaBlend(
      AppColors.borderInk(isDark).withValues(alpha: AppOpacity.innerLight),
      fill,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: AppShadows.chrome(isDark: isDark),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: BackdropFilter(
          filter: AppBlur.chromeFilter,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              border: Border.fromBorderSide(AppBorders.standard(isDark)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [wash, fill],
                stops: const [0.0, 0.28],
              ),
            ),
            child: padding == null ? child : Padding(padding: padding!, child: child),
          ),
        ),
      ),
    );
  }
}
