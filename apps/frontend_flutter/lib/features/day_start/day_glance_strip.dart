import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/tokens/tokens.dart';
import '../../shared/utils/serenity_palette.dart';
import '../../shared/widgets/confidia_demo_badge.dart';
import '../../shared/widgets/confidia_tappable.dart';
import 'day_briefing_model.dart';

enum DayGlanceKind { documents, appointments, deadlines, payments, serenity }

/// Disposition du bandeau : grille (briefing) ou rangée (accueil).
enum DayGlanceLayout { grid, row }

class _GlanceItem {
  final DayGlanceKind kind;
  final IconData icon;
  final String value;
  final String label;
  final Color accent;
  final String route;
  final bool demo;

  const _GlanceItem({
    required this.kind,
    required this.icon,
    required this.value,
    required this.label,
    required this.accent,
    required this.route,
    this.demo = false,
  });
}

/// Bandeau « En un coup d'œil ».
class DayGlanceStrip extends StatelessWidget {
  final DayGlanceMetrics metrics;
  final VoidCallback? beforeNavigate;
  final bool dense;
  final DayGlanceLayout layout;
  final bool showSerenity;

  const DayGlanceStrip({
    super.key,
    required this.metrics,
    this.beforeNavigate,
    this.dense = false,
    this.layout = DayGlanceLayout.grid,
    this.showSerenity = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = ConfidiaColors.textSecondary(isDark);
    final items = <_GlanceItem>[
      _GlanceItem(
        kind: DayGlanceKind.documents,
        icon: Icons.description_outlined,
        value: '${metrics.newDocuments}',
        label: 'Documents',
        accent: muted,
        route: '/documents',
      ),
      _GlanceItem(
        kind: DayGlanceKind.appointments,
        icon: Icons.calendar_today_outlined,
        value: '${metrics.appointmentsToday}',
        label: 'Rendez-vous',
        accent: muted,
        route: '/calendar',
      ),
      _GlanceItem(
        kind: DayGlanceKind.deadlines,
        icon: Icons.alarm_rounded,
        value: '${metrics.deadlinesToday}',
        label: 'Échéances',
        accent: ConfidiaColors.warning,
        route: '/calendar',
      ),
      _GlanceItem(
        kind: DayGlanceKind.payments,
        icon: Icons.credit_card_rounded,
        value: '${metrics.paymentsDue}',
        label: 'Paiements',
        accent: ConfidiaColors.success,
        route: '/payments',
        demo: true,
      ),
      if (showSerenity)
        _GlanceItem(
          kind: DayGlanceKind.serenity,
          icon: Icons.shield_outlined,
          value: '${metrics.serenityScore}',
          label: 'Sérénité',
          accent: SerenityPalette.forScore(metrics.serenityScore),
          route: '/dashboard',
          demo: true,
        ),
    ];

    final showTitle = layout == DayGlanceLayout.grid;
    final quietChrome = layout == DayGlanceLayout.row;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle) ...[
          Text(
            'En un coup d\'œil',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 8.0;
            final cardH = dense ? 92.0 : 100.0;

            Widget card(_GlanceItem item) => _GlanceCard(
                  item: item,
                  dense: dense,
                  quietChrome: quietChrome,
                  serenityScore: item.kind == DayGlanceKind.serenity ? metrics.serenityScore : null,
                  onTap: () {
                    beforeNavigate?.call();
                    if (item.route != '/dashboard' ||
                        GoRouterState.of(context).matchedLocation != '/dashboard') {
                      context.go(item.route);
                    }
                  },
                );

            if (layout == DayGlanceLayout.row) {
              return SizedBox(
                height: cardH,
                child: Row(
                  children: [
                    for (var i = 0; i < items.length; i++) ...[
                      if (i > 0) const SizedBox(width: gap),
                      Expanded(child: card(items[i])),
                    ],
                  ],
                ),
              );
            }

            const cols = 3;
            final cardW = (constraints.maxWidth - gap * (cols - 1)) / cols;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              alignment: WrapAlignment.center,
              children: [
                for (final item in items)
                  SizedBox(width: cardW, height: cardH, child: card(item)),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _GlanceCard extends StatelessWidget {
  final _GlanceItem item;
  final bool dense;
  final bool quietChrome;
  final int? serenityScore;
  final VoidCallback onTap;

  const _GlanceCard({
    required this.item,
    required this.dense,
    required this.quietChrome,
    required this.onTap,
    this.serenityScore,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final quiet = quietChrome;
    final radius = BorderRadius.circular(12);

    return Semantics(
      button: true,
      label: '${item.label}: ${item.kind == DayGlanceKind.serenity ? '$serenityScore/100' : item.value}',
      child: ConfidiaTappable(
        onTap: onTap,
        pressScale: 0.96,
        borderRadius: radius,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          padding: EdgeInsets.fromLTRB(8, dense ? 8 : 12, 8, dense ? 8 : 8),
          decoration: BoxDecoration(
            borderRadius: radius,
            color: AppColors.surface1(isDark),
            border: Border.fromBorderSide(
              quiet
                  ? AppBorders.subtle(isDark)
                  : BorderSide(color: item.accent.withValues(alpha: 0.22)),
            ),
            boxShadow: quiet ? AppShadows.none : AppShadows.card(isDark: isDark),
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  Icon(item.icon, color: item.accent, size: dense ? 18 : 20),
                  const Spacer(),
                  if (item.kind == DayGlanceKind.serenity)
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '$serenityScore',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: item.accent,
                                  height: 1,
                                  fontSize: dense ? 20 : 22,
                                ),
                          ),
                          TextSpan(
                            text: '/100',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: ConfidiaColors.textSecondary(isDark),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    )
                  else
                    Text(
                      item.value,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: ConfidiaColors.textPrimary(isDark),
                            height: 1,
                            fontSize: dense ? 22 : 24,
                          ),
                    ),
                  const Spacer(),
                  Text(
                    item.label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: ConfidiaColors.textSecondary(isDark),
                          fontWeight: FontWeight.w600,
                          height: 1.1,
                        ),
                  ),
                ],
              ),
              if (item.demo)
                const Positioned(
                  top: 0,
                  right: 0,
                  child: ConfidiaDemoBadge(compact: true),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
