import 'package:flutter/material.dart';

import '../../core/theme/spacing.dart';
import '../../core/theme/tokens/tokens.dart';

/// Statistique compacte · une ligne d'info dense.
class CompactStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const CompactStat({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface1(isDark),
        borderRadius: BorderRadius.circular(12),
        border: Border.fromBorderSide(AppBorders.standard(isDark)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                Text(label, style: Theme.of(context).textTheme.labelSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StatsRow extends StatelessWidget {
  final List<CompactStat> stats;

  const StatsRow({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final isWide = c.maxWidth >= 700;
        if (isWide) {
          return Row(
            children: stats
                .map((s) => Expanded(child: Padding(padding: const EdgeInsets.only(right: ConfidiaSpacing.sm), child: s)))
                .toList(),
          );
        }
        return Wrap(
          spacing: ConfidiaSpacing.sm,
          runSpacing: ConfidiaSpacing.sm,
          children: stats.map((s) => SizedBox(width: (c.maxWidth - ConfidiaSpacing.sm) / 2, child: s)).toList(),
        );
      },
    );
  }
}
