import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';

/// Bouton d'action compact, glassy avec léger glow — style premium sobre.
class ConfidiaGlowButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool primary;

  const ConfidiaGlowButton({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
    this.primary = true,
  });

  @override
  State<ConfidiaGlowButton> createState() => _ConfidiaGlowButtonState();
}

class _ConfidiaGlowButtonState extends State<ConfidiaGlowButton> with SingleTickerProviderStateMixin {
  late final AnimationController _press;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(vsync: this, duration: const Duration(milliseconds: 90));
    _scale = Tween<double>(begin: 1, end: 0.97).animate(CurvedAnimation(parent: _press, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final enabled = widget.onPressed != null;

    final decoration = widget.primary
        ? BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: enabled
                  ? [
                      ConfidiaColors.primary.withValues(alpha: 0.92),
                      ConfidiaColors.secondary.withValues(alpha: 0.78),
                    ]
                  : [
                      ConfidiaColors.primary.withValues(alpha: 0.4),
                      ConfidiaColors.secondary.withValues(alpha: 0.35),
                    ],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: enabled ? 0.18 : 0.08)),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: ConfidiaColors.primary.withValues(alpha: 0.28),
                      blurRadius: 14,
                      spreadRadius: -4,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: ConfidiaColors.secondary.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          )
        : BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: enabled ? 0.06 : 0.03),
            border: Border.all(
              color: ConfidiaColors.border(isDark).withValues(alpha: enabled ? 0.9 : 0.5),
            ),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: ConfidiaColors.secondary.withValues(alpha: isDark ? 0.12 : 0.08),
                      blurRadius: 10,
                      spreadRadius: -3,
                    ),
                  ]
                : null,
          );

    return GestureDetector(
      onTapDown: enabled ? (_) => _press.forward() : null,
      onTapUp: enabled ? (_) => _press.reverse() : null,
      onTapCancel: () => _press.reverse(),
      onTap: widget.onPressed,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: decoration,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 15,
                color: widget.primary
                    ? Colors.white.withValues(alpha: enabled ? 1 : 0.6)
                    : (isDark ? Colors.white70 : ConfidiaColors.primary).withValues(alpha: enabled ? 1 : 0.5),
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                  color: widget.primary
                      ? Colors.white.withValues(alpha: enabled ? 1 : 0.6)
                      : Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: enabled ? 1 : 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
