import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/theme_context.dart';
import 'confidia_tooltip.dart';

class ConfidiaButton extends StatefulWidget {
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
  State<ConfidiaButton> createState() => _ConfidiaButtonState();
}

class _ConfidiaButtonState extends State<ConfidiaButton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1, end: 0.96).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!widget.loading && widget.icon != null) ...[Icon(widget.icon, size: 18), const SizedBox(width: 8)],
        AnimatedOpacity(
          opacity: widget.loading ? 0.75 : 1,
          duration: const Duration(milliseconds: 200),
          child: Text(widget.loading ? (widget.loadingLabel ?? widget.label) : widget.label),
        ),
      ],
    );

    final padding = EdgeInsets.symmetric(horizontal: widget.compact ? 14 : 20, vertical: widget.compact ? 10 : 14);

    return GestureDetector(
      onTapDown: widget.onPressed == null ? null : (_) => _controller.forward(),
      onTapUp: widget.onPressed == null ? null : (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.loading ? null : widget.onPressed,
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: padding,
          decoration: BoxDecoration(
            gradient: widget.outlined ? null : context.palette.primaryGradient,
            color: widget.outlined ? Colors.transparent : null,
            borderRadius: BorderRadius.circular(12),
            border: widget.outlined ? Border.all(color: ConfidiaColors.border(Theme.of(context).brightness == Brightness.dark)) : null,
            boxShadow: widget.outlined
                ? null
                : [BoxShadow(color: context.palette.primary.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: DefaultTextStyle(
            style: TextStyle(
              color: widget.outlined ? Theme.of(context).colorScheme.onSurface : Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class ConfidiaIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool showBadge;

  const ConfidiaIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.showBadge = false,
  });

  @override
  State<ConfidiaIconButton> createState() => _ConfidiaIconButtonState();
}

class _ConfidiaIconButtonState extends State<ConfidiaIconButton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1, end: 0.9).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final btn = GestureDetector(
      onTapDown: widget.onPressed == null ? null : (_) => _controller.forward(),
      onTapUp: widget.onPressed == null ? null : (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onPressed,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDark ? ConfidiaColors.darkSurfaceVariant : ConfidiaColors.lightSurfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ConfidiaColors.border(isDark)),
          ),
          child: Icon(widget.icon, size: 20),
        ),
      ),
    );

  final wrapped = widget.tooltip != null ? ConfidiaTooltip(message: widget.tooltip!, child: btn) : btn;

    if (!widget.showBadge) return wrapped;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        wrapped,
        Positioned(right: 6, top: 6, child: Container(width: 8, height: 8, decoration: BoxDecoration(color: context.palette.primary, shape: BoxShape.circle))),
      ],
    );
  }
}
