import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/theme_context.dart';
import '../../shared/models/week_overview_model.dart';
import '../../shared/widgets/cofid_ia_brand.dart';
import '../../shared/widgets/confidia_chart_card.dart';
import '../../shared/widgets/confidia_demo_badge.dart';
import '../../shared/widgets/confidia_glow_chip.dart';
import '../../shared/widgets/glass_card.dart';
import 'week_overview_provider.dart';

abstract final class WeekWorkloadColors {
  static const calm = Color(0xFF43A047);
  static const medium = Color(0xFFFB8C00);
  static const busy = Color(0xFFE53935);

  static Color forLevel(WorkloadLevel level) => switch (level) {
        WorkloadLevel.calm => calm,
        WorkloadLevel.medium => medium,
        WorkloadLevel.busy => busy,
      };
}

const _dayAbbrevs = ['LUN', 'MAR', 'MER', 'JEU', 'VEN', 'SAM', 'DIM'];

class WeekOverviewWidget extends ConsumerStatefulWidget {
  const WeekOverviewWidget({super.key});

  @override
  ConsumerState<WeekOverviewWidget> createState() => _WeekOverviewWidgetState();
}

class _WeekOverviewWidgetState extends ConsumerState<WeekOverviewWidget> {
  int? _selectedIndex;

  static const _detailsAnimDuration = Duration(milliseconds: 280);

  @override
  Widget build(BuildContext context) {
    final overview = ref.watch(weekOverviewProvider);
    final scopes = ref.watch(weekOverviewScopesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedDay = _selectedIndex != null ? overview.days[_selectedIndex!] : null;

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(ConfidiaSpacing.md, ConfidiaSpacing.md, ConfidiaSpacing.md, ConfidiaSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(onOpenCalendar: () => context.go('/calendar')),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: WeekCalendarScope.values.map((scope) {
              final selected = scopes.contains(scope);
              return ConfidiaGlowChip(
                label: scope.label,
                selected: selected,
                compact: true,
                accentColor: _scopeAccent(scope, context),
                onTap: () {
                  final next = Set<WeekCalendarScope>.from(scopes);
                  if (selected) {
                    if (next.length > 1) next.remove(scope);
                  } else {
                    next.add(scope);
                  }
                  ref.read(weekOverviewScopesProvider.notifier).state = next;
                  setState(() => _selectedIndex = null);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          _WeekDaysRow(
            days: overview.days,
            selectedIndex: _selectedIndex,
            onDayTap: (index) => setState(() {
              _selectedIndex = _selectedIndex == index ? null : index;
            }),
          ),
          AnimatedSize(
            duration: _detailsAnimDuration,
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: selectedDay == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _AnimatedDayDetails(
                      key: ValueKey(selectedDay.date),
                      day: selectedDay,
                      isDark: isDark,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Color _scopeAccent(WeekCalendarScope scope, BuildContext context) {
    final palette = context.palette;
    return switch (scope) {
      WeekCalendarScope.personal => palette.accent,
      WeekCalendarScope.family => palette.secondary,
      WeekCalendarScope.professional => palette.primary,
    };
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onOpenCalendar;

  const _Header({required this.onOpenCalendar});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: ConfidiaColors.textSecondary(isDark).withValues(alpha: isDark ? 0.12 : 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.calendar_view_week_rounded, size: 20, color: ConfidiaColors.textSecondary(isDark)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ma semaine en un coup d\'œil',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text.rich(
                TextSpan(
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: ConfidiaColors.textSecondary(isDark),
                        height: 1.35,
                      ),
                  children: [
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: CofidIaBrand(
                        fontSize: Theme.of(context).textTheme.labelSmall?.fontSize,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: ConfidiaDemoBadge(compact: true),
                      ),
                    ),
                    const TextSpan(text: ' analyse vos agendas pour définir vos priorités.'),
                  ],
                ),
              ),
            ],
          ),
        ),
        ConfidiaSeeAllButton(onTap: onOpenCalendar),
      ],
    );
  }
}

class _WeekDaysRow extends StatelessWidget {
  final List<WeekDayOverview> days;
  final int? selectedIndex;
  final ValueChanged<int> onDayTap;

  static const _minCardWidth = 84.0;
  static const _cardGap = 8.0;
  static const _rowHeight = 106.0;

  const _WeekDaysRow({
    required this.days,
    required this.selectedIndex,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final minRowWidth = days.length * _minCardWidth + (days.length - 1) * _cardGap;
        final canFit = constraints.maxWidth >= minRowWidth;
        final cardWidth = canFit
            ? (constraints.maxWidth - (days.length - 1) * _cardGap) / days.length
            : _minCardWidth;

        final cards = List.generate(
          days.length,
          (i) => _DayCard(
            day: days[i],
            dayAbbrev: _dayAbbrevs[i],
            selected: selectedIndex == i,
            onTap: () => onDayTap(i),
          ),
        );

        return SizedBox(
          height: _rowHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: canFit ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
            itemCount: cards.length,
            separatorBuilder: (_, __) => const SizedBox(width: _cardGap),
            itemBuilder: (_, i) => SizedBox(
              width: cardWidth,
              height: _rowHeight,
              child: cards[i],
            ),
          ),
        );
      },
    );
  }
}

class _DayCard extends StatelessWidget {
  final WeekDayOverview day;
  final String dayAbbrev;
  final bool selected;
  final VoidCallback onTap;

  const _DayCard({
    required this.day,
    required this.dayAbbrev,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = WeekWorkloadColors.forLevel(day.workloadLevel);
    final isToday = _isToday(day.date);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          height: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: isDark ? 0.12 : 0.08)
                : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white.withValues(alpha: 0.65)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected || isToday
                  ? color.withValues(alpha: selected ? 0.7 : 0.45)
                  : ConfidiaColors.border(isDark),
              width: selected || isToday ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              Text(
                dayAbbrev,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      fontSize: 10,
                      height: 1.1,
                      color: ConfidiaColors.textSecondary(isDark),
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                day.dateLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                      height: 1.1,
                    ),
              ),
              const SizedBox(height: 8),
              WeekWorkloadGauge(loadScore: day.loadScore, level: day.workloadLevel),
              const SizedBox(height: 4),
              Text(
                day.workloadLevel.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      height: 1.1,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
}

class _AnimatedDayDetails extends StatelessWidget {
  final WeekDayOverview day;
  final bool isDark;

  const _AnimatedDayDetails({super.key, required this.day, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 8),
          child: child,
        ),
      ),
      child: _DayDetailsStrip(day: day, isDark: isDark),
    );
  }
}

class _DayDetailsStrip extends StatelessWidget {
  final WeekDayOverview day;
  final bool isDark;

  const _DayDetailsStrip({required this.day, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = WeekWorkloadColors.forLevel(day.workloadLevel);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.1 : 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            '${day.dayLabel} · ${day.dateLabel}',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          _DetailPill(label: '${day.totalAppointments} rdv', color: color),
          _DetailPill(label: '${day.meetingCount} réunions', isDark: isDark),
          _DetailPill(label: '${day.deadlineCount} échéances', isDark: isDark),
          _DetailPill(label: '${day.taskCount} tâches', isDark: isDark),
          Text(
            day.workloadLevel.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _DetailPill extends StatelessWidget {
  final String label;
  final Color? color;
  final bool isDark;

  const _DetailPill({required this.label, this.color, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    final tint = color ?? ConfidiaColors.textSecondary(isDark);

    return Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: tint,
            fontWeight: color != null ? FontWeight.w600 : null,
          ),
    );
  }
}

class WeekWorkloadGauge extends StatelessWidget {
  final double loadScore;
  final WorkloadLevel level;

  const WeekWorkloadGauge({
    super.key,
    required this.loadScore,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    final color = WeekWorkloadColors.forLevel(level);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: 56,
      height: 32,
      child: CustomPaint(
        painter: _WeekWorkloadGaugePainter(
          loadScore: loadScore,
          color: color,
          trackColor: ConfidiaColors.border(isDark),
        ),
      ),
    );
  }
}

class _WeekWorkloadGaugePainter extends CustomPainter {
  final double loadScore;
  final Color color;
  final Color trackColor;

  _WeekWorkloadGaugePainter({
    required this.loadScore,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 1);
    const sweep = math.pi * 0.88;
    const start = math.pi + (math.pi - sweep) / 2;
    final radius = size.width * 0.38;

    final track = Paint()
      ..color = trackColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final fill = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final arcRect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(arcRect, start, sweep, false, track);

    final progressSweep = sweep * loadScore.clamp(0.06, 1.0);
    canvas.drawArc(arcRect, start, progressSweep, false, fill);

    final angle = start + progressSweep;
    final dot = Offset(center.dx + radius * math.cos(angle), center.dy + radius * math.sin(angle));
    canvas.drawCircle(dot, 3.5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _WeekWorkloadGaugePainter oldDelegate) =>
      oldDelegate.loadScore != loadScore || oldDelegate.color != color;
}
