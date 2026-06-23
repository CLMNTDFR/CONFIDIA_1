import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/theme_context.dart';

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

/// Sélecteur segmenté premium  -  indicateur glissant animé, glow sobre.
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

    return Container(
      width: expand ? double.infinity : null,
      padding: const EdgeInsets.all(_shellPadding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
        border: Border.all(color: ConfidiaColors.border(isDark).withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: context.palette.secondary.withValues(alpha: isDark ? 0.08 : 0.05),
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
                    borderRadius: BorderRadius.circular(9),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        context.palette.primary.withValues(alpha: 0.92),
                        context.palette.secondary.withValues(alpha: 0.78),
                      ],
                    ),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                    boxShadow: [
                      BoxShadow(
                        color: context.palette.primary.withValues(alpha: 0.28),
                        blurRadius: 14,
                        spreadRadius: -4,
                        offset: const Offset(0, 3),
                      ),
                    ],
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
                      child: InkWell(
                        onTap: () => onChanged(seg.value),
                        borderRadius: BorderRadius.circular(9),
                        splashColor: context.palette.primary.withValues(alpha: 0.08),
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
                                  color: selected ? Colors.white : ConfidiaColors.textSecondary(isDark),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 280),
                                  curve: Curves.easeOutCubic,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                    letterSpacing: 0.2,
                                    color: selected ? Colors.white : ConfidiaColors.textSecondary(isDark),
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
