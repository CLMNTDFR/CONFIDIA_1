import 'package:flutter/material.dart';

/// Affiche le logo d'une marque tierce si [assetPath] est fourni et présent dans le bundle.
/// Les PNG noirs sur fond transparent reçoivent un socle clair en dark mode.
class BrandIcon extends StatelessWidget {
  final String? assetPath;
  final IconData fallbackIcon;
  final Color fallbackColor;
  final double size;
  final double borderRadius;
  final bool adaptForTheme;

  const BrandIcon({
    super.key,
    required this.assetPath,
    required this.fallbackIcon,
    required this.fallbackColor,
    this.size = 18,
    this.borderRadius = 4,
    this.adaptForTheme = true,
  });

  @override
  Widget build(BuildContext context) {
    if (assetPath == null) {
      return Icon(fallbackIcon, size: size, color: fallbackColor);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final needsLightBackdrop = adaptForTheme && isDark;

    final image = Image.asset(
      assetPath!,
      width: size,
      height: size,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => Icon(fallbackIcon, size: size, color: fallbackColor),
    );

    if (!needsLightBackdrop) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: image,
      );
    }

    return Container(
      width: size + 4,
      height: size + 4,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(borderRadius + 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: image,
      ),
    );
  }
}

/// Logo + libellé pour les chips de fournisseurs.
class BrandLabel extends StatelessWidget {
  final String? assetPath;
  final IconData fallbackIcon;
  final Color fallbackColor;
  final String label;
  final double iconSize;
  final TextStyle? labelStyle;
  final bool showLabel;

  const BrandLabel({
    super.key,
    required this.assetPath,
    required this.fallbackIcon,
    required this.fallbackColor,
    required this.label,
    this.iconSize = 14,
    this.labelStyle,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BrandIcon(
          assetPath: assetPath,
          fallbackIcon: fallbackIcon,
          fallbackColor: fallbackColor,
          size: iconSize,
        ),
        if (showLabel) ...[
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: labelStyle ??
                  TextStyle(
                    fontSize: iconSize * 0.85,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white.withValues(alpha: 0.9) : fallbackColor,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}
