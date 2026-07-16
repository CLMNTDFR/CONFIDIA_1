import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/theme_context.dart';
import '../../shared/models/serenity_briefing_model.dart';
import '../../shared/utils/serenity_palette.dart';
import '../../shared/widgets/ai_streaming_text.dart';
import '../../shared/widgets/cofid_ia_brand.dart';
import '../../shared/widgets/confidia_ai_robot.dart';
import '../../shared/widgets/confidia_glow_button.dart';
import '../../shared/widgets/glass_card.dart';
import 'serenity_briefing_provider.dart';

/// Briefing IA de sérénité — sections distinctes, courbe temporelle colorée.
class SerenityBriefingWidget extends ConsumerStatefulWidget {
  const SerenityBriefingWidget({super.key});

  @override
  ConsumerState<SerenityBriefingWidget> createState() => _SerenityBriefingWidgetState();
}

class _SerenityBriefingWidgetState extends ConsumerState<SerenityBriefingWidget> with SingleTickerProviderStateMixin {
  int _detailLevel = 0;
  late final AnimationController _pulse;

  static const _animDuration = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final briefing = ref.watch(serenityBriefingProvider);

    return _SerenityBriefingCard(
      briefing: briefing,
      detailLevel: _detailLevel,
      pulse: _pulse,
      onToggleLevel: () {
        setState(() {
          if (_detailLevel >= 2) {
            _detailLevel = 0;
          } else {
            _detailLevel++;
          }
        });
      },
    );
  }
}

class _SerenityBriefingCard extends StatelessWidget {
  final SerenityBriefing briefing;
  final int detailLevel;
  final AnimationController pulse;
  final VoidCallback onToggleLevel;

  const _SerenityBriefingCard({
    required this.briefing,
    required this.detailLevel,
    required this.pulse,
    required this.onToggleLevel,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final accent = SerenityPalette.forScore(briefing.score, palette: palette);

    return GlassCard(
      padding: const EdgeInsets.all(ConfidiaSpacing.sm + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SerenitySection(
            title: 'Indice de sérénité',
            icon: Icons.spa_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CompactHeader(
                  greeting: briefing.greeting,
                  score: briefing.score,
                  levelLabel: briefing.level.label,
                  accent: accent,
                  pulse: pulse,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _SerenitySection(
            title: 'Évolution dans le temps',
            icon: Icons.timeline_rounded,
            subtitle: '14 derniers jours · score quotidien',
            child: _ScoreHistoryChart(history: briefing.scoreHistory, palette: palette),
          ),
          AnimatedSize(
            duration: _SerenityBriefingWidgetState._animDuration,
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: detailLevel == 0
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _SerenitySection(
                      title: 'Briefing du jour',
                      icon: Icons.wb_sunny_outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AiStreamingText(
                            key: ValueKey(briefing.summary),
                            text: briefing.summary,
                            showThinkingRobot: false,
                            thinkingDelay: const Duration(milliseconds: 280),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.45),
                          ),
                          const SizedBox(height: 8),
                          _MetricsGrid(metrics: briefing.metrics, palette: palette),
                        ],
                      ),
                    ),
                  ),
          ),
          AnimatedSize(
            duration: _SerenityBriefingWidgetState._animDuration,
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: detailLevel < 2
                ? const SizedBox.shrink()
                : Column(
                    children: [
                      const SizedBox(height: 8),
                      _SerenitySection(
                        title: 'Facteurs identifiés',
                        icon: Icons.warning_amber_rounded,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final columns = constraints.maxWidth >= 420 ? 2 : 1;
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                crossAxisSpacing: 6,
                                mainAxisSpacing: 6,
                                mainAxisExtent: 30,
                              ),
                              itemCount: briefing.factors.length,
                              itemBuilder: (_, index) => _FactorChip(factor: briefing.factors[index]),
                            );
                          },
                        ),
                      ),
                      if (briefing.actions.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _SerenitySection(
                          title: 'Actions recommandées',
                          icon: Icons.auto_awesome_rounded,
                          child: Column(
                            children: briefing.actions
                                .asMap()
                                .entries
                                .map((e) => _ActionRow(action: e.value, index: e.key))
                                .toList(),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
          const SizedBox(height: 10),
          Center(
            child: ConfidiaGlowButton(
              label: _ctaLabel(detailLevel),
              icon: _ctaIcon(detailLevel),
              primary: detailLevel < 2,
              onPressed: onToggleLevel,
            ),
          ),
        ],
      ),
    );
  }

  String _ctaLabel(int level) => switch (level) {
        0 => 'Voir le briefing',
        1 => 'Analyser les facteurs',
        _ => 'Réduire',
      };

  IconData _ctaIcon(int level) => switch (level) {
        0 => Icons.expand_more_rounded,
        1 => Icons.insights_rounded,
        _ => Icons.expand_less_rounded,
      };
}

class _SerenitySection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget child;

  const _SerenitySection({
    required this.title,
    required this.icon,
    required this.child,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
        border: Border.all(color: ConfidiaColors.border(isDark).withValues(alpha: 0.65)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: palette.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    if (subtitle != null)
                      Text(subtitle!, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _CompactHeader extends StatelessWidget {
  final String greeting;
  final int score;
  final String levelLabel;
  final Color accent;
  final AnimationController pulse;

  const _CompactHeader({
    required this.greeting,
    required this.score,
    required this.levelLabel,
    required this.accent,
    required this.pulse,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ConfidiaAiRobot(size: 28, speaking: true),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CofidIaBrand(fontSize: 11),
              Text(
                greeting,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: ConfidiaColors.textSecondary(isDark),
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
        _AnimatedScoreRing(score: score, label: levelLabel, color: accent, pulse: pulse),
      ],
    );
  }
}

class _AnimatedScoreRing extends StatelessWidget {
  final int score;
  final String label;
  final Color color;
  final AnimationController pulse;

  const _AnimatedScoreRing({
    required this.score,
    required this.label,
    required this.color,
    required this.pulse,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: score / 100),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, progress, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: pulse,
              builder: (context, child) {
                return Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.1 + pulse.value * 0.08),
                        blurRadius: 8 + pulse.value * 4,
                      ),
                    ],
                  ),
                  child: child,
                );
              },
              child: CustomPaint(
                size: const Size(54, 54),
                painter: _ScoreRingPainter(progress: progress, color: color),
                child: Center(
                  child: Text(
                    '$score',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: color,
                          height: 1,
                          fontSize: 18,
                        ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 3),
            SizedBox(
              width: 72,
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: color,
                      height: 1.1,
                    ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ScoreRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ScoreRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    const start = -math.pi / 2;
    const sweep = math.pi * 2;

    final track = Paint()
      ..color = color.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start, sweep, false, track);

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start, sweep * progress, false, fill);
  }

  @override
  bool shouldRepaint(covariant _ScoreRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
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
    _draw = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
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
    final delta = widget.history.length >= 2 ? widget.history.last.score - widget.history.first.score : 0;
    final first = widget.history.first.date;
    final last = widget.history.last.date;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 88,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final layout = _ChartLayout.compute(widget.history, Size(constraints.maxWidth, 76));
              final visibleCount = (layout.points.length * _progress.value).ceil().clamp(2, layout.points.length);

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _LegendDot(color: SerenityPalette.excellent, label: '≥80'),
                        const SizedBox(width: 6),
                        _LegendDot(color: SerenityPalette.moderate, label: '50-79'),
                        const SizedBox(width: 6),
                        _LegendDot(color: SerenityPalette.attention, label: '<50'),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 22,
                    left: 0,
                    right: 0,
                    height: 64,
                    child: AnimatedBuilder(
                      animation: _progress,
                      builder: (context, _) {
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            CustomPaint(
                              size: Size(constraints.maxWidth, 64),
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
                                tooltip: _pointTooltip(widget.history[i]),
                                onHover: (hovered) {
                                  setState(() => _hoveredIndex = hovered ? i : null);
                                },
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              DateFormat('d MMM', 'fr_FR').format(first),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 9),
            ),
            const Spacer(),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  delta >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                  size: 13,
                  color: delta >= 0 ? SerenityPalette.excellent : SerenityPalette.attention,
                ),
                Text(
                  ' ${delta >= 0 ? '+' : ''}$delta pts · 14 j',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 9,
                        color: delta >= 0 ? SerenityPalette.excellent : SerenityPalette.attention,
                      ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              DateFormat('d MMM', 'fr_FR').format(last),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 9, fontWeight: FontWeight.w700),
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

class _ChartPointHitTarget extends StatelessWidget {
  final Offset point;
  final String tooltip;
  final ValueChanged<bool> onHover;

  const _ChartPointHitTarget({
    required this.point,
    required this.tooltip,
    required this.onHover,
  });

  static const _hitSize = 22.0;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: point.dx - _hitSize / 2,
      top: point.dy - _hitSize / 2,
      width: _hitSize,
      height: _hitSize,
      child: MouseRegion(
        onEnter: (_) => onHover(true),
        onExit: (_) => onHover(false),
        child: Tooltip(
          message: tooltip,
          waitDuration: const Duration(milliseconds: 120),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _ChartLayout {
  final Rect chartRect;
  final double yMin;
  final double yMax;
  final List<Offset> points;
  final List<int> scores;

  const _ChartLayout({
    required this.chartRect,
    required this.yMin,
    required this.yMax,
    required this.points,
    required this.scores,
  });

  factory _ChartLayout.compute(List<SerenityScorePoint> history, Size size) {
    if (history.length < 2) {
      return _ChartLayout(chartRect: Rect.zero, yMin: 0, yMax: 100, points: const [], scores: const []);
    }

    final scoreValues = history.map((p) => p.score.toDouble()).toList();
    final minScore = scoreValues.reduce(math.min);
    final maxScore = scoreValues.reduce(math.max);
    final range = math.max(12, maxScore - minScore);
    final yMin = minScore - 4;
    final yMax = yMin + range + 8;
    final chartRect = Rect.fromLTWH(4, 4, size.width - 8, size.height - 8);

    final points = <Offset>[];
    for (var i = 0; i < history.length; i++) {
      final x = chartRect.left + (i / (history.length - 1)) * chartRect.width;
      final t = (history[i].score - yMin) / (yMax - yMin);
      final y = chartRect.bottom - t * chartRect.height;
      points.add(Offset(x, y));
    }

    return _ChartLayout(
      chartRect: chartRect,
      yMin: yMin,
      yMax: yMax,
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 3),
        Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 9)),
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
      final score = layout.scores[i];
      final color = SerenityPalette.forScore(score, palette: palette);
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

class _MetricsGrid extends StatelessWidget {
  final List<SerenityMetric> metrics;
  final ConfidiaPalette palette;

  const _MetricsGrid({required this.metrics, required this.palette});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellW = (constraints.maxWidth - 6) / 2;
        return Wrap(
          spacing: 6,
          runSpacing: 6,
          children: metrics.asMap().entries.map((e) {
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 280 + e.key * 50),
              curve: Curves.easeOutCubic,
              builder: (context, t, child) {
                final clamped = t.clamp(0.0, 1.0);
                return Opacity(opacity: clamped, child: Transform.scale(scale: 0.92 + clamped * 0.08, child: child));
              },
              child: SizedBox(width: cellW, child: _MetricPill(metric: e.value, palette: palette)),
            );
          }).toList(),
        );
      },
    );
  }
}

class _MetricPill extends StatelessWidget {
  final SerenityMetric metric;
  final ConfidiaPalette palette;

  const _MetricPill({required this.metric, required this.palette});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = palette.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
        border: Border.all(color: ConfidiaColors.border(isDark).withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Icon(_iconForDomain(metric.domain), size: 13, color: accent),
          const SizedBox(width: 5),
          Text('${metric.value}', style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              metric.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForDomain(SerenityDomain domain) => switch (domain) {
        SerenityDomain.messaging => Icons.mail_outline_rounded,
        SerenityDomain.calendar => Icons.calendar_month_rounded,
        SerenityDomain.payments => Icons.payments_outlined,
        SerenityDomain.documents => Icons.folder_outlined,
        SerenityDomain.notifications => Icons.notifications_none_rounded,
      };
}

class _FactorChip extends StatelessWidget {
  final SerenityFactor factor;

  const _FactorChip({required this.factor});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = switch (factor.severity) {
      'high' => SerenityPalette.attention,
      'medium' => SerenityPalette.moderate,
      _ => ConfidiaColors.textSecondary(isDark),
    };

    return Tooltip(
      message: factor.detail,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.35)),
          color: color.withValues(alpha: isDark ? 0.1 : 0.06),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Container(width: 5, height: 5, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                factor.label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Text('-${factor.impact}', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w800, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final SerenityAction action;
  final int index;

  const _ActionRow({required this.action, required this.index});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 240 + index * 40),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        final clamped = t.clamp(0.0, 1.0);
        return Opacity(opacity: clamped, child: Transform.translate(offset: Offset(0, (1 - clamped) * 4), child: child));
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.go(action.route),
            borderRadius: BorderRadius.circular(8),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: palette.primary.withValues(alpha: isDark ? 0.07 : 0.04),
                border: Border.all(color: palette.primary.withValues(alpha: 0.12)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(_iconFromName(action.icon), size: 14, color: palette.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          action.label,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          action.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 9),
                        ),
                      ],
                    ),
                  ),
                  if (action.aiPowered) ...[
                    const SizedBox(width: 6),
                    const CofidIaBrand(fontSize: 10),
                  ],
                  Icon(Icons.chevron_right_rounded, size: 15, color: ConfidiaColors.textSecondary(isDark)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconFromName(String name) => switch (name) {
        'mail' => Icons.mail_rounded,
        'calendar_month' => Icons.calendar_month_rounded,
        'account_tree' => Icons.account_tree_rounded,
        'payment' => Icons.payment_rounded,
        'folder' => Icons.folder_rounded,
        _ => Icons.auto_awesome_rounded,
      };
}
