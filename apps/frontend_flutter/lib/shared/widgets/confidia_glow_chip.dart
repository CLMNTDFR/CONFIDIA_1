import 'package:flutter/material.dart';

import '../../core/theme/tokens/tokens.dart';

/// Selection chip / pill: filters, actions, compact links.
class ConfidiaGlowChip extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final Widget? leading;
  final Color? accentColor;
  final bool compact;

  const ConfidiaGlowChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.leading,
    this.accentColor,
    this.compact = false,
  });

  @override
  State<ConfidiaGlowChip> createState() => _ConfidiaGlowChipState();
}

class _ConfidiaGlowChipState extends State<ConfidiaGlowChip> with SingleTickerProviderStateMixin {
  late final AnimationController _press;
  late final Animation<double> _scale;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(vsync: this, duration: const Duration(milliseconds: 90));
    _scale = Tween<double>(begin: 1, end: 0.96).animate(CurvedAnimation(parent: _press, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  bool get _isBrandChip => widget.accentColor != null;

  Widget _buildLeading({required bool selected, required bool isDark, required double iconSize}) {
    if (widget.leading != null) {
      final logo = widget.leading!;
      if (_isBrandChip) {
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: selected ? 0.1 : 0.06),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: logo,
        );
      }
      return logo;
    }

    if (widget.icon != null) {
      return Icon(
        widget.icon,
        size: iconSize,
        color: selected ? AppColors.textPrimary(isDark) : AppColors.textSecondary(isDark),
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = widget.accentColor;
    final selected = widget.selected;
    final hovered = _hovered && !selected;
    final fontSize = widget.compact ? 10.0 : 11.0;
    final iconSize = widget.compact ? 12.0 : 14.0;
    final iconOnly = widget.label.isEmpty && (widget.icon != null || widget.leading != null);
    final hPad = iconOnly ? (widget.compact ? 8.0 : 10.0) : (widget.compact ? 8.0 : 12.0);
    final vPad = widget.compact ? 4.0 : 8.0;
    final ink = isDark ? Colors.white : Colors.black;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (_) => _press.forward(),
        onTapUp: (_) => _press.reverse(),
        onTapCancel: () => _press.reverse(),
        onTap: widget.onTap,
        child: ScaleTransition(
          scale: _scale,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: selected
                  ? AppColors.surface2(isDark)
                  : hovered
                      ? (accent != null
                          ? accent.withValues(alpha: 0.08)
                          : ink.withValues(alpha: isDark ? 0.1 : 0.06))
                      : Colors.transparent,
              border: Border.fromBorderSide(AppBorders.standard(isDark)),
              boxShadow: hovered
                  ? [
                      BoxShadow(
                        color: (accent ?? Colors.black).withValues(
                          alpha: accent != null ? 0.12 : (isDark ? 0.12 : 0.06),
                        ),
                        blurRadius: 8,
                        spreadRadius: -2,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.leading != null || widget.icon != null)
                  _buildLeading(selected: selected, isDark: isDark, iconSize: iconSize),
                if (widget.label.isNotEmpty) ...[
                  if (widget.leading != null || widget.icon != null) const SizedBox(width: 4),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      letterSpacing: 0.2,
                      color: selected ? AppColors.textPrimary(isDark) : AppColors.textSecondary(isDark),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bar containing chips (filters, quick actions).
class ConfidiaGlowChipBar extends StatelessWidget {
  final List<Widget> children;
  final bool centered;
  final EdgeInsetsGeometry? padding;

  const ConfidiaGlowChipBar({
    super.key,
    required this.children,
    this.centered = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bar = Container(
      padding: padding ?? const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
        border: Border.fromBorderSide(AppBorders.standard(isDark)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.05),
            blurRadius: 12,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: children
            .expand((c) => [Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: c)])
            .toList(),
      ),
    );

    if (centered) return Center(child: bar);
    return bar;
  }
}

/// Horizontally scrollable chip row.
class ConfidiaGlowChipScroll extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  const ConfidiaGlowChipScroll({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        children: children
            .map((c) => Padding(padding: const EdgeInsets.only(right: 8), child: c))
            .toList(),
      ),
    );
  }
}

/// Compact « Voir tout » link.
class ConfidiaGlowLink extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const ConfidiaGlowLink({super.key, required this.label, required this.onTap});

  @override
  State<ConfidiaGlowLink> createState() => _ConfidiaGlowLinkState();
}

class _ConfidiaGlowLinkState extends State<ConfidiaGlowLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final linkColor = AppColors.textSecondary(isDark);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: _hovered ? (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06) : Colors.transparent,
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.06),
                      blurRadius: 8,
                      spreadRadius: -2,
                    ),
                  ]
                : null,
          ),
          child: Text(
            widget.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: linkColor,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
          ),
        ),
      ),
    );
  }
}
