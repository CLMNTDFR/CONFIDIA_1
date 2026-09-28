import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/theme_context.dart';
import '../../core/theme/tokens/tokens.dart';
import '../../shared/models/serenity_briefing_model.dart';
import '../../shared/utils/serenity_palette.dart';
import '../../shared/widgets/confidia_demo_badge.dart';
import '../../shared/widgets/confidia_tooltip.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/serenity_score_ring.dart';
import '../../shared/widgets/workspace_empty_hint.dart';
import 'serenity_briefing_provider.dart';

/// Score card + 14-day curve - narrative briefing inside « Commencer ma journée ».
class SerenityBriefingWidget extends ConsumerWidget {
  const SerenityBriefingWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final briefing = ref.watch(serenityBriefingProvider);
    final palette = context.palette;
    final accent = SerenityPalette.forScore(briefing.score, palette: palette);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = ConfidiaColors.textSecondary(isDark);

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Indice de sérénité',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const ConfidiaDemoBadge(compact: true),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const _ScoreLegend(),
                    const SizedBox(height: 6),
                    Text(
                      briefing.scoreHistory.length >= 2
                          ? 'Évolution sur 14 jours'
                          : 'Aujourd\'hui',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              SerenityScoreRing(
                score: briefing.score,
                label: briefing.level.label,
                color: accent,
                size: 52,
                scoreFontSize: 17,
                labelFontSize: 10,
              ),
            ],
          ),
          if (briefing.scoreHistory.length >= 2) ...[
            const SizedBox(height: 18),
            _ScoreHistoryChart(history: briefing.scoreHistory, palette: palette),
          ] else ...[
            const SizedBox(height: 12),
            WorkspaceEmptyHint(
              icon: Icons.show_chart_rounded,
              title: 'Pas encore d\'historique',
              subtitle: 'La courbe se construira jour après jour à partir d\'aujourd\'hui.',
            ),
          ],
        ],
      ),
    );
  }
}

class _ScoreLegend extends StatelessWidget {
  const _ScoreLegend();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: const [
        _LegendDot(color: SerenityPalette.excellent, label: '>60'),
        _LegendDot(color: SerenityPalette.moderate, label: '41-60'),
        _LegendDot(color: SerenityPalette.attention, label: '≤40'),
      ],
    );
  }
}

class _ScoreHistoryChart extends StatefulWidget {
  final List<SerenityScorePoint> history;
  final ConfidiaPalette palette;

  const _ScoreHistoryChart({required this.history, required this.palette});

  @override
  State<_ScoreHistoryChart> createState() => _ScoreHistoryChartState();
}

class _ScoreHistoryChartState extends State<_ScoreHistoryChart> with SingleTickerProviderStateMixin {
  late final AnimationController _draw;
  late final Animation<double> _progress;
  int? _hoveredIndex;

  @override
  void initState() {
    super.initState();
    _draw = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _progress = CurvedAnimation(parent: _draw, curve: Curves.easeOutCubic);
    _draw.forward();
  }

  @override
  void dispose() {
    _draw.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final delta = widget.history.last.score - widget.history.first.score;
    final first = widget.history.first.date;
    final last = widget.history.last.date;
    final trendColor = delta >= 0 ? SerenityPalette.excellent : SerenityPalette.attention;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = ConfidiaColors.textSecondary(isDark);
    final dateFmt = DateFormat('d MMM', 'fr_FR');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 96,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final layout = _ChartLayout.compute(
                widget.history,
                Size(constraints.maxWidth, 96),
              );

              return AnimatedBuilder(
                animation: _progress,
                builder: (context, _) {
                  final visibleCount =
                      (layout.points.length * _progress.value).ceil().clamp(2, layout.points.length);
                  return Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      CustomPaint(
                        size: Size(constraints.maxWidth, 96),
                        painter: _ScoreHistoryPainter(
                          layout: layout,
                          progress: _progress.value,
                          palette: widget.palette,
                          hoveredIndex: _hoveredIndex,
                        ),
                      ),
                      for (var i = 0; i < visibleCount; i++)
                        _ChartPointHitTarget(
                          point: layout.points[i],
                          chartWidth: constraints.maxWidth,
                          chartHeight: 96,
                          tooltip: _pointTooltip(widget.history[i]),
                          onHover: (hovered) {
                            setState(() => _hoveredIndex = hovered ? i : null);
                          },
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Text(
                dateFmt.format(first),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: muted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _TrendBadge(delta: delta, color: trendColor),
            Expanded(
              child: Text(
                dateFmt.format(last),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: muted,
                      fontWeight: FontWeight.w600,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _pointTooltip(SerenityScorePoint point) {
    final date = DateFormat('EEEE d MMMM', 'fr_FR').format(point.date);
    final capitalized = date.isNotEmpty ? '${date[0].toUpperCase()}${date.substring(1)}' : date;
    return '$capitalized · ${point.score}/100';
  }
}

class _TrendBadge extends StatelessWidget {
  final int delta;
  final Color color;

  const _TrendBadge({required this.delta, required this.color});

  @override
  Widget build(BuildContext context) {
    final up = delta >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.pillAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            up ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '${up ? '+' : ''}$delta pts',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}

class _ChartPointHitTarget extends StatelessWidget {
  final Offset point;
  final double chartWidth;
  final double chartHeight;
  final String tooltip;
  final ValueChanged<bool> onHover;

  const _ChartPointHitTarget({
    required this.point,
    required this.chartWidth,
    required this.chartHeight,
    required this.tooltip,
    required this.onHover,
  });

  static const _hitSize = 22.0;

  @override
  Widget build(BuildContext context) {
    final left = (point.dx - _hitSize / 2).clamp(0.0, math.max(0.0, chartWidth - _hitSize)).toDouble();
    final top = (point.dy - _hitSize / 2).clamp(0.0, chartHeight - _hitSize).toDouble();

    return Positioned(
      left: left,
      top: top,
      width: _hitSize,
      height: _hitSize,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => onHover(true),
        onExit: (_) => onHover(false),
        child: ConfidiaTooltip(
          message: tooltip,
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _ChartLayout {
  final List<Offset> points;
  final List<int> scores;

  const _ChartLayout({required this.points, required this.scores});

  factory _ChartLayout.compute(List<SerenityScorePoint> history, Size size) {
    if (history.length < 2) {
      return const _ChartLayout(points: [], scores: []);
    }

    final scoreValues = history.map((p) => p.score.toDouble()).toList();
    final minScore = scoreValues.reduce(math.min);
    final maxScore = scoreValues.reduce(math.max);
    final range = math.max(12.0, maxScore - minScore);
    final yMin = minScore - 4;
    final yMax = yMin + range + 8;
    final chartRect = Rect.fromLTWH(6, 8, size.width - 12, size.height - 16);

    final points = <Offset>[];
    for (var i = 0; i < history.length; i++) {
      final x = chartRect.left + (i / (history.length - 1)) * chartRect.width;
      final t = (history[i].score - yMin) / (yMax - yMin);
      final y = chartRect.bottom - t * chartRect.height;
      points.add(Offset(x, y));
    }

    return _ChartLayout(
      points: points,
      scores: history.map((p) => p.score).toList(),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final muted = ConfidiaColors.textSecondary(Theme.of(context).brightness == Brightness.dark);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: muted,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}

class _ScoreHistoryPainter extends CustomPainter {
  final _ChartLayout layout;
  final double progress;
  final ConfidiaPalette palette;
  final int? hoveredIndex;

  _ScoreHistoryPainter({
    required this.layout,
    required this.progress,
    required this.palette,
    this.hoveredIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final history = layout.points;
    if (history.length < 2) return;

    final visibleCount = (history.length * progress).ceil().clamp(2, history.length);
    final visible = history.take(visibleCount).toList();

    for (var i = 1; i < visible.length; i++) {
      final color = SerenityPalette.forScore(layout.scores[i], palette: palette);
      final paint = Paint()
        ..color = color
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(visible[i - 1], visible[i], paint);
    }

    for (var i = 0; i < visible.length; i++) {
      final color = SerenityPalette.forScore(layout.scores[i], palette: palette);
      final isHovered = hoveredIndex == i;
      final isLast = i == visible.length - 1;
      final radius = isHovered ? 4.5 : (isLast ? 3.5 : 2.5);
      canvas.drawCircle(visible[i], radius, Paint()..color = color);
      if (isHovered || isLast) {
        canvas.drawCircle(
          visible[i],
          radius + 3,
          Paint()
            ..color = color.withValues(alpha: 0.18)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ScoreHistoryPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.hoveredIndex != hoveredIndex ||
      oldDelegate.layout != layout;
}
