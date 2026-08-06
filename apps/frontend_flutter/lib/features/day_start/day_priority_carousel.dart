import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/theme_context.dart';
import '../../shared/utils/serenity_palette.dart';
import '../../shared/widgets/confidia_tappable.dart';
import 'day_briefing_model.dart';

/// Carrousel horizontal premium des priorités du jour (toutes visibles, scrollables).
class DayPriorityCarousel extends StatefulWidget {
  final List<DayPriority> priorities;
  final int totalGain;
  final ValueChanged<DayPriority> onSelect;

  const DayPriorityCarousel({
    super.key,
    required this.priorities,
    required this.totalGain,
    required this.onSelect,
  });

  @override
  State<DayPriorityCarousel> createState() => _DayPriorityCarouselState();
}

class _DayPriorityCarouselState extends State<DayPriorityCarousel> {
  late final PageController _controller;
  double _page = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.82);
    _controller.addListener(_onScroll);
  }

  void _onScroll() {
    final page = _controller.page;
    if (page == null) return;
    setState(() => _page = page);
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final count = widget.priorities.length;
    final current = _page.round().clamp(0, math.max(0, count - 1));
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Priorités du jour',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              _CountChip(count: count, isDark: isDark),
              if (widget.totalGain > 0) ...[
                const SizedBox(width: 8),
                Text(
                  '+${widget.totalGain} pts',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: SerenityPalette.excellent,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Faites glisser pour parcourir les $count actions',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: ConfidiaColors.textSecondary(isDark),
              ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 188,
          child: PageView.builder(
            controller: _controller,
            itemCount: count,
            padEnds: false,
            onPageChanged: (_) {
              if (!reduceMotion) HapticFeedback.selectionClick();
            },
            itemBuilder: (context, index) {
              final priority = widget.priorities[index];
              final delta = (_page - index).abs().clamp(0.0, 1.0);
              final scale = reduceMotion ? 1.0 : (1 - delta * 0.06);
              final opacity = reduceMotion ? 1.0 : (1 - delta * 0.28);

              return Padding(
                padding: EdgeInsets.only(
                  right: index == count - 4 ? 0 : 8,
                  top: 4,
                  bottom: 8,
                ),
                child: Transform.scale(
                  scale: scale,
                  alignment: Alignment.centerLeft,
                  child: Opacity(
                    opacity: opacity,
                    child: _PrioritySlideCard(
                      index: index + 1,
                      total: count,
                      priority: priority,
                      emphasized: index == current,
                      onTap: () => widget.onSelect(priority),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        _CarouselProgress(
          count: count,
          page: _page,
          isDark: isDark,
        ),
      ],
    );
  }
}

class _CountChip extends StatelessWidget {
  final int count;
  final bool isDark;

  const _CountChip({required this.count, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final muted = ConfidiaColors.textSecondary(isDark);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        color: muted.withValues(alpha: isDark ? 0.16 : 0.1),
        border: Border.all(color: muted.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          '$count',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: muted,
                fontWeight: FontWeight.w900,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
        ),
      ),
    );
  }
}

class _CarouselProgress extends StatelessWidget {
  final int count;
  final double page;
  final bool isDark;

  const _CarouselProgress({
    required this.count,
    required this.page,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 1) return const SizedBox.shrink();
    final palette = context.palette;
    final current = page.round().clamp(0, count - 1) + 1;

    return Row(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final trackW = constraints.maxWidth;
              final thumbW = math.max(28.0, trackW / count);
              final maxLeft = math.max(0.0, trackW - thumbW);
              final left = (page / math.max(1, count - 1)) * maxLeft;

              return SizedBox(
                height: 4,
                child: Stack(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: const SizedBox.expand(),
                    ),
                    Positioned(
                      left: left,
                      width: thumbW,
                      top: 0,
                      bottom: 0,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          gradient: LinearGradient(
                            colors: [palette.primary, palette.secondary],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$current / $count',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: ConfidiaColors.textSecondary(isDark),
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
        ),
      ],
    );
  }
}

class _PrioritySlideCard extends StatelessWidget {
  final int index;
  final int total;
  final DayPriority priority;
  final bool emphasized;
  final VoidCallback onTap;

  const _PrioritySlideCard({
    required this.index,
    required this.total,
    required this.priority,
    required this.emphasized,
    required this.onTap,
  });

  IconData get _kindIcon => switch (priority.kind) {
        DayPriorityKind.payment => Icons.payments_rounded,
        DayPriorityKind.document => Icons.description_rounded,
        DayPriorityKind.appointment => Icons.event_rounded,
        DayPriorityKind.messaging => Icons.mail_rounded,
        DayPriorityKind.other => Icons.flag_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = context.palette;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final gain = priority.serenityGain;
    final muted = ConfidiaColors.textSecondary(isDark);
    final tagColor = switch (priority.kind) {
      DayPriorityKind.payment => const Color(0xFFE57373),
      DayPriorityKind.document => muted,
      DayPriorityKind.appointment => muted,
      DayPriorityKind.messaging => muted,
      DayPriorityKind.other => muted,
    };
    final radius = BorderRadius.circular(20);

    return ConfidiaTappable(
      onTap: onTap,
      pressScale: 0.97,
      borderRadius: radius,
      child: AnimatedContainer(
        duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF152238),
                    const Color(0xFF0F1A2A),
                  ]
                : [
                    Colors.white,
                    const Color(0xFFF4F8FC),
                  ],
          ),
          border: Border.all(
            color: emphasized
                ? palette.primary.withValues(alpha: isDark ? 0.55 : 0.4)
                : muted.withValues(alpha: isDark ? 0.22 : 0.14),
            width: emphasized ? 1.4 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.08),
              blurRadius: emphasized ? 16 : 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: muted.withValues(alpha: isDark ? 0.18 : 0.1),
                    ),
                    child: Icon(_kindIcon, color: muted, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$index / $total',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: ConfidiaColors.textSecondary(isDark),
                                fontWeight: FontWeight.w600,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                        ),
                        if (priority.tag != null)
                          Text(
                            priority.tag!,
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: tagColor,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                      ],
                    ),
                  ),
                  if (gain > 0)
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        color: SerenityPalette.excellent.withValues(alpha: isDark ? 0.14 : 0.1),
                        border: Border.all(
                          color: SerenityPalette.excellent.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Text(
                          '+$gain',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: SerenityPalette.excellent,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                priority.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                      letterSpacing: -0.2,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                priority.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: ConfidiaColors.textSecondary(isDark),
                    ),
              ),
              const Spacer(),
              Row(
                children: [
                  Text(
                    'Ouvrir',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: ConfidiaColors.textPrimary(isDark),
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 16, color: ConfidiaColors.textPrimary(isDark)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
