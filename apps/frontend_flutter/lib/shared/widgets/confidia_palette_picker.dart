import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/theme_context.dart';

/// Sélecteur de thème couleur (bleu / rose).
class ConfidiaPalettePicker extends StatelessWidget {
  final ConfidiaPaletteId value;
  final ValueChanged<ConfidiaPaletteId> onChanged;

  const ConfidiaPalettePicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PaletteOption(
            label: ConfidiaPaletteId.blue.label,
            palette: ConfidiaPalette.blue,
            selected: value == ConfidiaPaletteId.blue,
            onTap: () => onChanged(ConfidiaPaletteId.blue),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _PaletteOption(
            label: ConfidiaPaletteId.rose.label,
            palette: ConfidiaPalette.rose,
            selected: value == ConfidiaPaletteId.rose,
            onTap: () => onChanged(ConfidiaPaletteId.rose),
          ),
        ),
      ],
    );
  }
}

class _PaletteOption extends StatelessWidget {
  final String label;
  final ConfidiaPalette palette;
  final bool selected;
  final VoidCallback onTap;

  const _PaletteOption({
    required this.label,
    required this.palette,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final current = context.palette;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? palette.primary.withValues(alpha: 0.65)
                  : ConfidiaColors.border(isDark).withValues(alpha: 0.6),
              width: selected ? 1.5 : 1,
            ),
            color: selected
                ? palette.primary.withValues(alpha: isDark ? 0.12 : 0.06)
                : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: palette.primary.withValues(alpha: 0.18),
                      blurRadius: 10,
                      spreadRadius: -3,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              _SwatchDot(color: palette.primary),
              const SizedBox(width: 4),
              _SwatchDot(color: palette.secondary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected ? palette.primary : ConfidiaColors.textPrimary(isDark),
                      ),
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded, size: 16, color: current.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwatchDot extends StatelessWidget {
  final Color color;

  const _SwatchDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 4,
            spreadRadius: -1,
          ),
        ],
      ),
    );
  }
}
