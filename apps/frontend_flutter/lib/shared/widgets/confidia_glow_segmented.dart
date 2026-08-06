import 'package:flutter/material.dart';

import '../../core/theme/tokens/tokens.dart';

class ConfidiaGlowSegment<T> {
  final T value;
  final String label;
  final IconData icon;

  const ConfidiaGlowSegment({
    required this.value,
    required this.label,
    required this.icon,
  });
}

/// Sélecteur segmenté  -  indicateur glissant animé, sélection discrète.
class ConfidiaGlowSegmentedControl<T> extends StatelessWidget {
  final T value;
  final List<ConfidiaGlowSegment<T>> segments;
  final ValueChanged<T> onChanged;
  final bool expand;

  const ConfidiaGlowSegmentedControl({
    super.key,
    required this.value,
    required this.segments,
    required this.onChanged,
    this.expand = false,
  });

  static const _segmentHeight = 36.0;
  static const _shellPadding = 3.0;
  static const _compactSegmentWidth = 96.0;

  int get _selectedIndex {
    final i = segments.indexWhere((s) => s.value == value);
    return i < 0 ? 0 : i;
  }

  Alignment _thumbAlignment(int index) {
    if (segments.length <= 1) return Alignment.center;
    final x = -1.0 + (2.0 * index / (segments.length - 1));
    return Alignment(x, 0);
  }

  Widget _buildShell(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedIndex = _selectedIndex;
    final ink = isDark ? Colors.white : Colors.black;

    return Container(
      width: expand ? double.infinity : null,
      padding: const EdgeInsets.all(_shellPadding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: ink.withValues(alpha: 0.05),
        border: Border.fromBorderSide(AppBorders.standard(isDark)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.05),
            blurRadius: 12,
            spreadRadius: -4,
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final innerWidth = constraints.maxWidth;
          final segmentWidth = innerWidth / segments.length;

          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              AnimatedAlign(
                alignment: _thumbAlignment(selectedIndex),
                duration: const Duration(milliseconds: 340),
                curve: Curves.easeOutCubic,
                child: Container(
                  width: segmentWidth,
                  height: _segmentHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: AppColors.surface2(isDark),
                    border: Border.fromBorderSide(AppBorders.standard(isDark)),
                  ),
                ),
              ),
              Row(
                children: List.generate(segments.length, (i) {
                  final seg = segments[i];
                  final selected = i == selectedIndex;
                  return Expanded(
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => onChanged(seg.value),
                        mouseCursor: SystemMouseCursors.click,
                        borderRadius: BorderRadius.circular(8),
                        hoverColor: ink.withValues(
                          alpha: isDark ? AppOpacity.hoverInkDark : AppOpacity.hoverInkLight,
                        ),
                        splashColor: ink.withValues(alpha: AppOpacity.quiet),
                        highlightColor: Colors.transparent,
                        child: SizedBox(
                          height: _segmentHeight,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedScale(
                                scale: selected ? 1.05 : 1,
                                duration: const Duration(milliseconds: 280),
                                curve: Curves.easeOutCubic,
                                child: Icon(
                                  seg.icon,
                                  size: 14,
                                  color: selected
                                      ? AppColors.textPrimary(isDark)
                                      : AppColors.textSecondary(isDark),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 280),
                                  curve: Curves.easeOutCubic,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                    letterSpacing: 0.2,
                                    color: selected
                                        ? AppColors.textPrimary(isDark)
                                        : AppColors.textSecondary(isDark),
                                  ),
                                  child: Text(
                                    seg.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shell = _buildShell(context);

    if (expand) return shell;

    final outerWidth = segments.length * _compactSegmentWidth + _shellPadding * 2;
    return Center(
      child: SizedBox(
        width: outerWidth,
        child: shell,
      ),
    );
  }
}
