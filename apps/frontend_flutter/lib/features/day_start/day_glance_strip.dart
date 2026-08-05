import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/theme_context.dart';
import '../../shared/utils/serenity_palette.dart';
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

  const _GlanceItem({
    required this.kind,
    required this.icon,
    required this.value,
    required this.label,
    required this.accent,
    required this.route,
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
    final palette = context.palette;
    final items = <_GlanceItem>[
      _GlanceItem(
        kind: DayGlanceKind.documents,
        icon: Icons.description_outlined,
        value: '${metrics.newDocuments}',
        label: 'Documents',
        accent: palette.primary,
        route: '/documents',
      ),
      _GlanceItem(
        kind: DayGlanceKind.appointments,
        icon: Icons.calendar_today_outlined,
        value: '${metrics.appointmentsToday}',
        label: 'Rendez-vous',
        accent: palette.secondary,
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
      ),
      if (showSerenity)
        _GlanceItem(
          kind: DayGlanceKind.serenity,
          icon: Icons.shield_outlined,
          value: '${metrics.serenityScore}',
          label: 'Sérénité',
          accent: SerenityPalette.forScore(metrics.serenityScore, palette: palette),
          route: '/dashboard',
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'En un coup d\'œil',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 8.0;
            final cardH = dense ? 92.0 : 100.0;

            Widget card(_GlanceItem item) => _GlanceCard(
                  item: item,
                  dense: dense,
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

class _GlanceCard extends StatefulWidget {
  final _GlanceItem item;
  final bool dense;
  final int? serenityScore;
  final VoidCallback onTap;

  const _GlanceCard({
    required this.item,
    required this.dense,
    required this.onTap,
    this.serenityScore,
  });

  @override
  State<_GlanceCard> createState() => _GlanceCardState();
}

class _GlanceCardState extends State<_GlanceCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final item = widget.item;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Semantics(
      button: true,
      label: '${item.label}: ${item.kind == DayGlanceKind.serenity ? '${widget.serenityScore}/100' : item.value}',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1,
          duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 110),
          child: AnimatedContainer(
            duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 160),
            width: double.infinity,
            height: double.infinity,
            padding: EdgeInsets.fromLTRB(8, widget.dense ? 10 : 12, 8, widget.dense ? 8 : 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: isDark
                  ? ConfidiaColors.darkSurfaceElevated.withValues(alpha: 0.92)
                  : Colors.white.withValues(alpha: 0.92),
              border: Border.all(color: item.accent.withValues(alpha: _pressed ? 0.55 : 0.28)),
              boxShadow: [
                BoxShadow(
                  color: item.accent.withValues(alpha: isDark ? 0.12 : 0.08),
                  blurRadius: _pressed ? 4 : 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(item.icon, color: item.accent, size: widget.dense ? 18 : 20),
                const Spacer(),
                if (item.kind == DayGlanceKind.serenity)
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${widget.serenityScore}',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: item.accent,
                                height: 1,
                                fontSize: widget.dense ? 20 : 22,
                              ),
                        ),
                        TextSpan(
                          text: '/100',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: ConfidiaColors.textSecondary(isDark),
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
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
                          fontWeight: FontWeight.w900,
                          color: ConfidiaColors.textPrimary(isDark),
                          height: 1,
                          fontSize: widget.dense ? 22 : 24,
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
                        fontSize: 10,
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
