import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';

/// Chip / pill glowy sobre — filtres, actions, liens compacts.
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
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(5),
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
        color: selected
            ? (_isBrandChip ? widget.accentColor : Colors.white)
            : ConfidiaColors.textSecondary(isDark),
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = widget.accentColor ?? ConfidiaColors.primary;
    final selected = widget.selected;
    final hovered = _hovered && !selected;
    final brandSelected = _isBrandChip && selected;
    final fontSize = widget.compact ? 10.0 : 11.0;
    final iconSize = widget.compact ? 12.0 : 14.0;
    final hPad = widget.compact ? 8.0 : 12.0;
    final vPad = widget.compact ? 5.0 : 7.0;

    return MouseRegion(
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
              borderRadius: BorderRadius.circular(9),
              gradient: selected && !brandSelected
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        ConfidiaColors.primary.withValues(alpha: 0.9),
                        ConfidiaColors.secondary.withValues(alpha: 0.75),
                      ],
                    )
                  : null,
              color: brandSelected
                  ? accent.withValues(alpha: isDark ? 0.18 : 0.1)
                  : selected
                      ? null
                      : hovered
                          ? (_isBrandChip ? accent.withValues(alpha: 0.08) : ConfidiaColors.primary.withValues(alpha: isDark ? 0.1 : 0.06))
                          : Colors.transparent,
              border: Border.all(
                color: brandSelected
                    ? accent.withValues(alpha: 0.55)
                    : selected
                        ? Colors.white.withValues(alpha: 0.15)
                        : hovered
                            ? (_isBrandChip ? accent.withValues(alpha: 0.35) : ConfidiaColors.secondary.withValues(alpha: 0.35))
                            : ConfidiaColors.border(isDark).withValues(alpha: 0.5),
              ),
              boxShadow: brandSelected
                  ? [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.16),
                        blurRadius: 8,
                        spreadRadius: -3,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : selected
                      ? [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.28),
                            blurRadius: 10,
                            spreadRadius: -3,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : hovered
                          ? [
                              BoxShadow(
                                color: (_isBrandChip ? accent : ConfidiaColors.secondary).withValues(alpha: 0.12),
                                blurRadius: 8,
                                spreadRadius: -2,
                              ),
                            ]
                          : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.leading != null || widget.icon != null) ...[
                  _buildLeading(selected: selected, isDark: isDark, iconSize: iconSize),
                  const SizedBox(width: 5),
                ],
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: 0.2,
                    color: brandSelected
                        ? accent
                        : selected
                            ? Colors.white
                            : ConfidiaColors.textSecondary(isDark),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Barre glassy contenant des chips (filtres, actions rapides).
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
      padding: padding ?? const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
        border: Border.all(color: ConfidiaColors.border(isDark).withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: ConfidiaColors.secondary.withValues(alpha: isDark ? 0.08 : 0.05),
            blurRadius: 12,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: children
            .expand((c) => [Padding(padding: const EdgeInsets.symmetric(horizontal: 1), child: c)])
            .toList(),
      ),
    );

    if (centered) return Center(child: bar);
    return bar;
  }
}

/// Rangée horizontale scrollable de chips.
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
            .map((c) => Padding(padding: const EdgeInsets.only(right: 6), child: c))
            .toList(),
      ),
    );
  }
}

/// Lien compact « Voir tout » — glow sobre.
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
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: _hovered ? ConfidiaColors.primary.withValues(alpha: 0.08) : Colors.transparent,
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: ConfidiaColors.primary.withValues(alpha: 0.15),
                      blurRadius: 8,
                      spreadRadius: -2,
                    ),
                  ]
                : null,
          ),
          child: Text(
            widget.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: ConfidiaColors.primary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
          ),
        ),
      ),
    );
  }
}
