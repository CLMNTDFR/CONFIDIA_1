import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/colors.dart';
import 'confidia_tooltip.dart';
import 'glass_card.dart';

/// Bouton compact « Voir tout » — flèche discrète, cohérente sur tout le tableau de bord.
class ConfidiaSeeAllButton extends StatelessWidget {
  final VoidCallback onTap;

  const ConfidiaSeeAllButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ConfidiaTooltip(
      message: 'Voir tout',
      child: IconButton(
        visualDensity: VisualDensity.compact,
        icon: Icon(Icons.arrow_forward_rounded, size: 18, color: ConfidiaColors.textSecondary(isDark)),
        onPressed: onTap,
      ),
    );
  }
}

/// Enveloppe graphique partagée pour le tableau de bord.
class ConfidiaChartCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? linkRoute;
  final Widget chart;
  final Widget? footer;
  final List<Widget>? headerExtras;

  const ConfidiaChartCard({
    super.key,
    required this.title,
    this.subtitle,
    this.linkRoute,
    required this.chart,
    this.footer,
    this.headerExtras,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final fillHeight = constraints.hasBoundedHeight && constraints.maxHeight.isFinite;

        return GlassCard(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(subtitle!, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: ConfidiaColors.textSecondary(isDark))),
                        ],
                      ],
                    ),
                  ),
                  if (linkRoute != null) ConfidiaSeeAllButton(onTap: () => context.go(linkRoute!)),
                ],
              ),
              if (headerExtras != null && headerExtras!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(spacing: 6, runSpacing: 6, children: headerExtras!),
              ],
              const SizedBox(height: 12),
              if (fillHeight) Expanded(child: chart) else chart,
              if (footer != null) ...[
                const SizedBox(height: 10),
                footer!,
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Pastille compacte pour métriques / séries de graphiques.
class ConfidiaChartMetricChip extends StatelessWidget {
  final String label;
  final Color color;
  final String? value;

  const ConfidiaChartMetricChip({
    super.key,
    required this.label,
    required this.color,
    this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            value != null ? '$label · $value' : label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: ConfidiaColors.textPrimary(isDark),
                ),
          ),
        ],
      ),
    );
  }
}
