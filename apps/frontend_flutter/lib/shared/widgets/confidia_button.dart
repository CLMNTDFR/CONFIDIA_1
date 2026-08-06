import 'package:flutter/material.dart';

import '../../core/theme/theme_context.dart';
import '../../core/theme/tokens/tokens.dart';
import 'confidia_tappable.dart';
import 'confidia_tooltip.dart';

class ConfidiaButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool outlined;
  final bool compact;
  final bool loading;
  final String? loadingLabel;

  const ConfidiaButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.outlined = false,
    this.compact = false,
    this.loading = false,
    this.loadingLabel,
  });

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!loading && icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
        AnimatedOpacity(
          opacity: loading ? 0.75 : 1,
          duration: AppDurations.quick,
          child: Text(loading ? (loadingLabel ?? label) : label),
        ),
      ],
    );

    final padding = EdgeInsets.symmetric(horizontal: compact ? 16 : 20, vertical: compact ? 8 : 16);

    return ConfidiaTappable(
      onTap: loading ? null : onPressed,
      pressScale: 0.96,
      borderRadius: AppRadius.buttonAll,
      child: AnimatedContainer(
        duration: AppDurations.quick,
        padding: padding,
        decoration: BoxDecoration(
          gradient: outlined ? null : context.palette.primaryGradient,
          color: outlined ? Colors.transparent : null,
          borderRadius: AppRadius.buttonAll,
          border: outlined
              ? Border.fromBorderSide(
                  AppBorders.standard(Theme.of(context).brightness == Brightness.dark),
                )
              : null,
          boxShadow: outlined
              ? null
              : [
                  BoxShadow(
                    color: context.palette.primary.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: DefaultTextStyle(
          style: TextStyle(
            color: outlined ? Theme.of(context).colorScheme.onSurface : Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Bouton icône chrome (top bar, actions). [compact] = 36 px (modales).
class ConfidiaIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool showBadge;
  final bool compact;

  const ConfidiaIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.showBadge = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = compact ? 36.0 : 40.0;
    final iconSize = compact ? 18.0 : 20.0;

    final btn = ConfidiaTappable(
      onTap: onPressed,
      pressScale: 0.9,
      borderRadius: AppRadius.mdAll,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.surface2(isDark),
          borderRadius: AppRadius.mdAll,
          border: Border.fromBorderSide(AppBorders.standard(isDark)),
        ),
        child: Icon(
          icon,
          size: iconSize,
          color: AppColors.textPrimary(isDark),
        ),
      ),
    );

    final wrapped = tooltip != null ? ConfidiaTooltip(message: tooltip!, child: btn) : btn;

    if (!showBadge) return wrapped;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        wrapped,
        Positioned(
          right: 6,
          top: 6,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: context.palette.primary, shape: BoxShape.circle),
          ),
        ),
      ],
    );
  }
}

/// Fermeture de modale / overlay  -  même chrome que [ConfidiaIconButton] compact.
class ConfidiaCloseButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String tooltip;

  const ConfidiaCloseButton({
    super.key,
    this.onPressed,
    this.tooltip = 'Fermer',
  });

  @override
  Widget build(BuildContext context) {
    return ConfidiaIconButton(
      icon: Icons.close_rounded,
      tooltip: tooltip,
      compact: true,
      onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
    );
  }
}
