import 'dart:ui';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/theme_context.dart';
import '../../shared/data/mock_ecosystem.dart';
import '../../shared/widgets/confidia_chart_card.dart';
import '../../shared/widgets/confidia_chart_tooltips.dart';
import '../../shared/widgets/premium_bar_rod.dart';
import '../../shared/widgets/premium_chart_motion.dart';
import '../../shared/widgets/premium_chart_stage.dart';
import '../../shared/widgets/premium_donut_chart.dart';
import '../payments/payments_provider.dart';
import 'dashboard_chart_data.dart';

Widget _chartArea(
  Widget chart, {
  double fallback = 200,
  bool tooltipOverflow = false,
}) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final baseHeight = constraints.hasBoundedHeight && constraints.maxHeight.isFinite && constraints.maxHeight > 0
          ? constraints.maxHeight
          : fallback;
      final height = tooltipOverflow ? baseHeight + 56 : baseHeight;
      return SizedBox(height: height, child: chart);
    },
  );
}

class ExpensesTrendChartWidget extends StatefulWidget {
  const ExpensesTrendChartWidget({super.key});

  @override
  State<ExpensesTrendChartWidget> createState() => _ExpensesTrendChartWidgetState();
}

class _ExpensesTrendChartWidgetState extends State<ExpensesTrendChartWidget> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final points = DashboardChartData.expenseTrend();
    final spots = List.generate(points.length, (i) => FlSpot(i.toDouble(), points[i].value));
    final maxY = points.map((p) => p.value).reduce((a, b) => a > b ? a : b) * 1.15;
    final peak = points.reduce((a, b) => a.value > b.value ? a : b);
    final hasFocus = _touchedIndex != null;

    return ConfidiaChartCard(
      title: 'Évolution des dépenses',
      subtitle: 'Pic · ${peak.value.toStringAsFixed(0)} € en ${peak.label}',
      linkRoute: '/payments',
      allowTooltipOverflow: true,
      headerExtras: [
        ConfidiaChartMetricChip(label: 'Courbe mensuelle', color: context.palette.primary),
      ],
      chart: _chartArea(
        tooltipOverflow: true,
        PremiumChartStage(
          accentColors: [context.palette.primary, context.palette.secondary],
          clipChart: false,
          child: PremiumChartMotionScope(
            hasFocus: hasFocus,
            builder: (context, motion) {
              final scaledSpots = spots
                  .map((s) => FlSpot(s.x, motion.scaleY(s.y)))
                  .toList();
              final lineAlpha = 1.0 - 0.25 * motion.focus;

              return Padding(
                padding: const EdgeInsets.only(top: 4, right: 2),
                child: LineChart(
                  duration: Duration.zero,
                  LineChartData(
                    minY: 0,
                    maxY: maxY,
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false, reservedSize: 36),
                      ),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 38,
                          interval: maxY / 4,
                          getTitlesWidget: (value, _) => Text(
                            '${value.round()}€',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  fontSize: 9,
                                  color: ConfidiaColors.textSecondary(isDark)
                                      .withValues(alpha: motion.labelAlpha(isActive: true, base: 0.85, dimmed: 0.55)),
                                ),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final i = value.toInt();
                            if (i < 0 || i >= points.length) return const SizedBox.shrink();
                            final active = _touchedIndex == i;
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                points[i].label,
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      fontSize: 10,
                                      fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                                      color: active
                                          ? context.palette.primary
                                          : ConfidiaColors.textSecondary(isDark)
                                              .withValues(alpha: motion.labelAlpha(isActive: false, base: 0.8, dimmed: 0.45)),
                                    ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    lineTouchData: LineTouchData(
                      touchCallback: (event, response) {
                        if (!event.isInterestedForInteractions ||
                            response == null ||
                            response.lineBarSpots == null ||
                            response.lineBarSpots!.isEmpty) {
                          setState(() => _touchedIndex = null);
                          return;
                        }
                        setState(() => _touchedIndex = response.lineBarSpots!.first.x.toInt());
                      },
                      touchTooltipData: ConfidiaChartTooltips.line(
                        context,
                        allowOverflow: true,
                        labelBuilder: (index, value) => '${points[index].label}\n${value.toStringAsFixed(0)} €',
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: scaledSpots,
                        isCurved: true,
                        curveSmoothness: 0.3,
                        barWidth: 3 - 0.4 * motion.focus,
                        isStrokeCapRound: true,
                        gradient: LinearGradient(
                          colors: [
                            context.palette.primary.withValues(alpha: lineAlpha),
                            context.palette.secondary.withValues(alpha: 0.85 - 0.3 * motion.focus),
                          ],
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              context.palette.primary.withValues(alpha: (isDark ? 0.24 : 0.16) * motion.entry),
                              context.palette.secondary.withValues(alpha: 0.02),
                            ],
                          ),
                        ),
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, _, __, ___) {
                            final active = _touchedIndex == spot.x.toInt();
                            final focusBoost = active ? motion.focus * 2.3 : 0.0;
                            return FlDotCirclePainter(
                              radius: 3.2 + focusBoost,
                              color: Colors.white,
                              strokeWidth: 2 + (active ? 0.5 * motion.focus : 0),
                              strokeColor: active ? context.palette.secondary : context.palette.primary,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class DocumentsCategoryChartWidget extends StatefulWidget {
  const DocumentsCategoryChartWidget({super.key});

  @override
  State<DocumentsCategoryChartWidget> createState() => _DocumentsCategoryChartWidgetState();
}

class _DocumentsCategoryChartWidgetState extends State<DocumentsCategoryChartWidget> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = context.palette;
    final slices = DashboardChartData.documentsByCategory(MockEcosystem.documents, palette);
    final total = slices.fold<double>(0, (sum, s) => sum + s.value);

    return ConfidiaChartCard(
      title: 'Répartition documentaire',
      subtitle: '${total.toInt()} documents · ${slices.length} catégories',
      linkRoute: '/documents',
      chart: SizedBox(
        height: 256,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              left: -76,
              top: -8,
              bottom: -8,
              width: 228,
              child: PremiumDonutChart(
                slices: slices,
                size: 220,
                strokeWidth: 7,
                gapDegrees: 5.5,
                activeIndex: _touchedIndex,
                baseOpacity: _touchedIndex != null ? 0.22 : 0.38,
                onSectionEnter: (index) => setState(() => _touchedIndex = index),
                onSectionExit: () => setState(() => _touchedIndex = null),
                center: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${total.toInt()}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: ConfidiaColors.textPrimary(isDark).withValues(alpha: 0.55),
                            height: 1,
                          ),
                    ),
                    Text(
                      'docs',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: ConfidiaColors.textSecondary(isDark).withValues(alpha: 0.45),
                            letterSpacing: 0.5,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 96,
              top: 0,
              right: 0,
              bottom: 0,
              child: _CategoryBreakdownList(
                slices: slices,
                total: total,
                isDark: isDark,
                highlightedIndex: _touchedIndex,
                onHover: (index) => setState(() => _touchedIndex = index),
                onExit: () => setState(() => _touchedIndex = null),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryBreakdownList extends StatelessWidget {
  final List<ChartSlice> slices;
  final double total;
  final bool isDark;
  final int? highlightedIndex;
  final ValueChanged<int> onHover;
  final VoidCallback onExit;

  const _CategoryBreakdownList({
    required this.slices,
    required this.total,
    required this.isDark,
    required this.highlightedIndex,
    required this.onHover,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.zero,
      physics: const BouncingScrollPhysics(),
      itemCount: slices.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final slice = slices[i];
        final pct = total == 0 ? 0.0 : slice.value / total;
        final active = highlightedIndex == i;

        return MouseRegion(
          onEnter: (_) => onHover(i),
          onExit: (_) => onExit(),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: active
                      ? (isDark ? Colors.black : Colors.white).withValues(alpha: isDark ? 0.42 : 0.72)
                      : (isDark ? Colors.black : Colors.white).withValues(alpha: isDark ? 0.28 : 0.52),
                  border: Border.all(
                    color: active
                        ? slice.color.withValues(alpha: 0.28)
                        : ConfidiaColors.border(isDark),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [slice.color, slice.color.withValues(alpha: 0.65)],
                            ),
                            boxShadow: active
                                ? [BoxShadow(color: slice.color.withValues(alpha: 0.35), blurRadius: 6)]
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            slice.label,
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: (isDark ? Colors.white : Colors.black).withValues(alpha: isDark ? 0.07 : 0.05),
                            border: Border.all(
                              color: ConfidiaColors.border(isDark),
                            ),
                          ),
                          child: Text(
                            '${slice.value.toInt()}',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: ConfidiaColors.textSecondary(isDark),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${(pct * 100).round()}%',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: active ? slice.color : ConfidiaColors.textPrimary(isDark),
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: SizedBox(
                        height: 3,
                        child: Stack(
                          children: [
                            Container(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06)),
                            FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: pct.clamp(0.04, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [slice.color.withValues(alpha: 0.55), slice.color],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class HubActivityChartWidget extends StatefulWidget {
  const HubActivityChartWidget({super.key});

  @override
  State<HubActivityChartWidget> createState() => _HubActivityChartWidgetState();
}

class _HubActivityChartWidgetState extends State<HubActivityChartWidget> {
  int? _touchedGroup;
  int? _touchedRod;

  List<({String label, Color color})> _series(BuildContext context) => [
    (label: 'Documents', color: context.palette.primary),
    (label: 'Mails', color: context.palette.secondary),
    (label: 'Paiements', color: context.palette.accent),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final series = _series(context);
    final months = DashboardChartData.hubActivity();
    final maxY = months
        .map((m) => [m.documents, m.emails, m.payments].reduce((a, b) => a > b ? a : b))
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
    final hasFocus = _touchedGroup != null;

    return ConfidiaChartCard(
      title: 'Activité du hub',
      subtitle: 'Documents, mails et paiements traités',
      linkRoute: '/dashboard',
      allowTooltipOverflow: true,
      headerExtras: series
          .map((s) => ConfidiaChartMetricChip(label: s.label, color: s.color))
          .toList(),
      chart: _chartArea(
        tooltipOverflow: true,
        fallback: 210,
        PremiumChartStage(
          accentColors: [context.palette.primary, context.palette.accent],
          primaryGlowAlignment: const Alignment(-0.75, 0.1),
          secondaryGlowAlignment: const Alignment(0.85, -0.55),
          clipChart: false,
          child: PremiumChartMotionScope(
            hasFocus: hasFocus,
            builder: (context, motion) {
              return Padding(
                padding: const EdgeInsets.only(top: 4, right: 2),
                child: BarChart(
                  duration: Duration.zero,
                  BarChartData(
                    maxY: maxY + 2,
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false, reservedSize: 36),
                      ),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 24,
                          interval: 2,
                          getTitlesWidget: (value, _) => Text(
                            value.toInt().toString(),
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  fontSize: 9,
                                  color: ConfidiaColors.textSecondary(isDark)
                                      .withValues(alpha: motion.labelAlpha(isActive: true, base: 0.85, dimmed: 0.5)),
                                ),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, _) {
                            final i = value.toInt();
                            if (i < 0 || i >= months.length) return const SizedBox.shrink();
                            final active = _touchedGroup == i;
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                months[i].label,
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      fontSize: 10,
                                      fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                                      color: active
                                          ? context.palette.accent
                                          : ConfidiaColors.textSecondary(isDark)
                                              .withValues(alpha: motion.labelAlpha(isActive: false, base: 0.8, dimmed: 0.45)),
                                    ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    barTouchData: BarTouchData(
                      touchCallback: (event, response) {
                        if (!event.isInterestedForInteractions || response == null || response.spot == null) {
                          setState(() {
                            _touchedGroup = null;
                            _touchedRod = null;
                          });
                          return;
                        }
                        setState(() {
                          _touchedGroup = response.spot!.touchedBarGroupIndex;
                          _touchedRod = response.spot!.touchedRodDataIndex;
                        });
                      },
                      touchTooltipData: ConfidiaChartTooltips.bar(
                        context,
                        allowOverflow: true,
                        itemBuilder: (groupIndex, rodIndex) {
                          if (rodIndex < 0 || rodIndex >= series.length) return null;
                          final month = months[groupIndex];
                          final values = [month.documents, month.emails, month.payments];
                          final entry = series[rodIndex];
                          return BarTooltipItem(
                            '${entry.label} · ${values[rodIndex]}',
                            ConfidiaChartTooltips.label(context, color: entry.color, fontSize: 11),
                            children: [
                              TextSpan(
                                text: '\n${month.label}',
                                style: ConfidiaChartTooltips.caption(context),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    barGroups: List.generate(
                      months.length,
                      (i) {
                        final groupActive = !hasFocus || _touchedGroup == i;
                        final values = [
                          months[i].documents.toDouble(),
                          months[i].emails.toDouble(),
                          months[i].payments.toDouble(),
                        ];
                        return BarChartGroupData(
                          x: i,
                          barsSpace: 4,
                          barRods: List.generate(3, (rodIndex) {
                            return premiumGroupedBarRod(
                              toY: values[rodIndex],
                              color: series[rodIndex].color,
                              isGroupActive: groupActive,
                              isRodActive: _touchedGroup == i && _touchedRod == rodIndex,
                              motion: motion,
                            );
                          }),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class PaymentsOverviewChartWidget extends ConsumerStatefulWidget {
  const PaymentsOverviewChartWidget({super.key});

  @override
  ConsumerState<PaymentsOverviewChartWidget> createState() => _PaymentsOverviewChartWidgetState();
}

class _PaymentsOverviewChartWidgetState extends ConsumerState<PaymentsOverviewChartWidget> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final payments = ref.watch(paymentsProvider);
    final palette = context.palette;
    final slices = DashboardChartData.paymentsByStatus(payments, palette);
    final total = slices.fold<double>(0, (sum, s) => sum + s.value);
    final maxY = slices.isEmpty ? 1.0 : slices.map((s) => s.value).reduce((a, b) => a > b ? a : b) * 1.2;
    final hasFocus = _touchedIndex != null;

    return ConfidiaChartCard(
      title: 'Vue des paiements',
      subtitle: '${total.toStringAsFixed(0)} € au total',
      linkRoute: '/payments',
      allowTooltipOverflow: true,
      headerExtras: slices
          .map((s) => ConfidiaChartMetricChip(
                label: s.label,
                color: s.color,
                value: '${s.value.toStringAsFixed(0)} €',
              ))
          .toList(),
      chart: _chartArea(
        tooltipOverflow: true,
        PremiumChartStage(
          accentColors: slices.map((s) => s.color).take(3).toList(),
          primaryGlowAlignment: const Alignment(-0.7, -0.4),
          secondaryGlowAlignment: const Alignment(0.8, 0.65),
          clipChart: false,
          child: PremiumChartMotionScope(
            hasFocus: hasFocus,
            builder: (context, motion) {
              return Padding(
                padding: const EdgeInsets.only(top: 6, right: 2),
                child: BarChart(
                  duration: Duration.zero,
                  BarChartData(
                    maxY: maxY,
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 36,
                          getTitlesWidget: (value, meta) {
                            final i = value.toInt();
                            if (i < 0 || i >= slices.length) return const SizedBox.shrink();
                            final active = _touchedIndex == i;
                            return Text(
                              '${slices[i].value.toStringAsFixed(0)}€',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: slices[i].color.withValues(
                                      alpha: motion.dimOpacity(isActive: active, active: 1, idle: 0.85, dimmed: 0.45),
                                    ),
                                  ),
                            );
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 36,
                          getTitlesWidget: (value, _) => Text(
                            '${value.round()}€',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  fontSize: 9,
                                  color: ConfidiaColors.textSecondary(isDark)
                                      .withValues(alpha: motion.labelAlpha(isActive: true, base: 0.85, dimmed: 0.5)),
                                ),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final i = value.toInt();
                            if (i < 0 || i >= slices.length) return const SizedBox.shrink();
                            final active = _touchedIndex == i;
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                slices[i].label,
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      fontSize: 9,
                                      fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                                      color: active
                                          ? slices[i].color
                                          : ConfidiaColors.textSecondary(isDark)
                                              .withValues(alpha: motion.labelAlpha(isActive: false, base: 0.8, dimmed: 0.45)),
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    barTouchData: BarTouchData(
                      touchCallback: (event, response) {
                        if (!event.isInterestedForInteractions || response == null || response.spot == null) {
                          setState(() => _touchedIndex = null);
                          return;
                        }
                        setState(() => _touchedIndex = response.spot!.touchedBarGroupIndex);
                      },
                      touchTooltipData: ConfidiaChartTooltips.bar(
                        context,
                        allowOverflow: true,
                        itemBuilder: (groupIndex, rodIndex) {
                          final slice = slices[groupIndex];
                          return BarTooltipItem(
                            '${slice.label} · ${slice.value.toStringAsFixed(2)} €',
                            ConfidiaChartTooltips.label(context, color: slice.color, fontSize: 11),
                          );
                        },
                      ),
                    ),
                    barGroups: List.generate(
                      slices.length,
                      (i) => BarChartGroupData(
                        x: i,
                        barRods: [
                          premiumBarRod(
                            toY: slices[i].value,
                            color: slices[i].color,
                            isActive: !hasFocus || _touchedIndex == i,
                            motion: motion,
                            width: 20,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
