import 'package:flutter/material.dart';

import '../../core/theme/tokens/tokens.dart';

/// Zone cliquable unifiée : curseur main + hover discret + press scale.
///
/// À utiliser pour tout contrôle custom basé sur [GestureDetector]
/// (les boutons Material gèrent déjà le curseur).
class ConfidiaTappable extends StatefulWidget {
  final VoidCallback? onTap;
  final Widget child;
  final double pressScale;
  final BorderRadius? borderRadius;
  final bool hoverOverlay;
  final ValueChanged<bool>? onHoverChanged;

  const ConfidiaTappable({
    super.key,
    required this.onTap,
    required this.child,
    this.pressScale = 0.97,
    this.borderRadius,
    this.hoverOverlay = true,
    this.onHoverChanged,
  });

  @override
  State<ConfidiaTappable> createState() => _ConfidiaTappableState();
}

class _ConfidiaTappableState extends State<ConfidiaTappable> with SingleTickerProviderStateMixin {
  late final AnimationController _press;
  late final Animation<double> _scale;
  bool _hovered = false;

  bool get _enabled => widget.onTap != null;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(vsync: this, duration: AppDurations.press);
    _scale = Tween<double>(begin: 1, end: widget.pressScale).animate(
      CurvedAnimation(parent: _press, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(covariant ConfidiaTappable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pressScale != widget.pressScale) {
      _scale = Tween<double>(begin: 1, end: widget.pressScale).animate(
        CurvedAnimation(parent: _press, curve: Curves.easeOut),
      );
    }
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  void _setHovered(bool value) {
    if (_hovered == value) return;
    setState(() => _hovered = value);
    widget.onHoverChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final showHover = widget.hoverOverlay && _hovered && _enabled;
    final ink = (isDark ? Colors.white : Colors.black).withValues(
      alpha: isDark ? AppOpacity.hoverInkDark : AppOpacity.hoverInkLight,
    );

    return MouseRegion(
      cursor: _enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: _enabled ? (_) => _setHovered(true) : null,
      onExit: _enabled ? (_) => _setHovered(false) : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _enabled ? (_) => _press.forward() : null,
        onTapUp: _enabled ? (_) => _press.reverse() : null,
        onTapCancel: () => _press.reverse(),
        onTap: widget.onTap,
        child: ScaleTransition(
          scale: _scale,
          child: AnimatedContainer(
            duration: AppDurations.fast,
            curve: Curves.easeOut,
            foregroundDecoration: showHover
                ? BoxDecoration(
                    borderRadius: widget.borderRadius,
                    color: ink,
                  )
                : null,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
