import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/theme_context.dart';

/// Bouton d'action compact, glassy avec léger glow. Style premium sobre.
class ConfidiaGlowButton extends StatefulWidget {
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
            borderRadius: BorderRadius.circular(9),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: enabled
                  ? [
                      context.palette.primary.withValues(alpha: 0.92),
                      context.palette.secondary.withValues(alpha: 0.78),
                    ]
                  : [
                      context.palette.primary.withValues(alpha: 0.4),
                      context.palette.secondary.withValues(alpha: 0.35),
                    ],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: enabled ? 0.16 : 0.08)),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: context.palette.primary.withValues(alpha: 0.22),
                      blurRadius: 10,
                      spreadRadius: -4,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          )
        : BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: enabled ? 0.06 : 0.03),
            border: Border.all(
              color: ConfidiaColors.border(isDark).withValues(alpha: enabled ? 0.9 : 0.5),
            ),
          );

    return GestureDetector(
      onTapDown: enabled ? (_) => _press.forward() : null,
      onTapUp: enabled ? (_) => _press.reverse() : null,
      onTapCancel: () => _press.reverse(),
      onTap: widget.onPressed,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: widget.expand ? double.infinity : null,
          constraints: const BoxConstraints(minHeight: 34),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: decoration,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 14,
                color: widget.primary
                    ? Colors.white.withValues(alpha: enabled ? 1 : 0.6)
                    : (isDark ? Colors.white70 : context.palette.primary).withValues(alpha: enabled ? 1 : 0.5),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.15,
                    height: 1.2,
                    color: widget.primary
                        ? Colors.white.withValues(alpha: enabled ? 1 : 0.6)
                        : Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: enabled ? 1 : 0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
