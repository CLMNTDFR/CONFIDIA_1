import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';

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

/// Sélecteur segmenté premium — glow sobre, centré.
class ConfidiaGlowSegmentedControl<T> extends StatelessWidget {
  final T value;
  final List<ConfidiaGlowSegment<T>> segments;
  final ValueChanged<T> onChanged;

  const ConfidiaGlowSegmentedControl({
    super.key,
    required this.value,
    required this.segments,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Container(
        padding: const EdgeInsets.all(3),
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
          children: segments.map((seg) {
            final selected = seg.value == value;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onChanged(seg.value),
                  borderRadius: BorderRadius.circular(9),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(9),
                      gradient: selected
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                ConfidiaColors.primary.withValues(alpha: 0.9),
                                ConfidiaColors.secondary.withValues(alpha: 0.75),
                              ],
                            )
                          : null,
                      color: selected ? null : Colors.transparent,
                      border: selected
                          ? Border.all(color: Colors.white.withValues(alpha: 0.15))
                          : null,
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: ConfidiaColors.primary.withValues(alpha: 0.25),
                                blurRadius: 10,
                                spreadRadius: -3,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          seg.icon,
                          size: 14,
                          color: selected
                              ? Colors.white
                              : ConfidiaColors.textSecondary(isDark),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          seg.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            letterSpacing: 0.2,
                            color: selected
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
          }).toList(),
        ),
      ),
    );
  }
}
