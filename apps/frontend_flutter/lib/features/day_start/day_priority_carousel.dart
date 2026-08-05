import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/theme_context.dart';
import '../../shared/utils/serenity_palette.dart';
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
          padding: const EdgeInsets.fromLTRB(0, 14, 0, 0),
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
                  right: index == count - 1 ? 0 : 10,
                  top: 2,
                  bottom: 6,
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
        const SizedBox(height: 10),
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
    final palette = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(
          colors: [
            palette.primary.withValues(alpha: isDark ? 0.28 : 0.16),
            palette.secondary.withValues(alpha: isDark ? 0.22 : 0.12),
          ],
        ),
        border: Border.all(color: palette.primary.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          '$count',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: palette.primary,
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
                        borderRadius: BorderRadius.circular(999),
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
                          borderRadius: BorderRadius.circular(999),
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

class _PrioritySlideCard extends StatefulWidget {
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

  @override
  State<_PrioritySlideCard> createState() => _PrioritySlideCardState();
}

class _PrioritySlideCardState extends State<_PrioritySlideCard> {
  bool _pressed = false;

  IconData get _kindIcon => switch (widget.priority.kind) {
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
    final gain = widget.priority.serenityGain;
    final tagColor = switch (widget.priority.kind) {
      DayPriorityKind.payment => const Color(0xFFE57373),
      DayPriorityKind.document => palette.primary,
      DayPriorityKind.appointment => palette.secondary,
      DayPriorityKind.messaging => palette.accent,
      DayPriorityKind.other => ConfidiaColors.textSecondary(isDark),
    };

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 110),
        child: AnimatedContainer(
          duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      Color.lerp(const Color(0xFF152238), palette.primary, 0.12)!,
                      Color.lerp(const Color(0xFF0F1A2A), palette.secondary, 0.1)!,
                    ]
                  : [
                      Colors.white,
                      Color.lerp(const Color(0xFFF4F8FC), palette.primary, 0.08)!,
                    ],
            ),
            border: Border.all(
              color: widget.emphasized
                  ? palette.primary.withValues(alpha: isDark ? 0.55 : 0.4)
                  : palette.primary.withValues(alpha: isDark ? 0.22 : 0.14),
              width: widget.emphasized ? 1.4 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.08),
                blurRadius: widget.emphasized ? 16 : 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
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
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [palette.primary, palette.secondary],
                        ),
                      ),
                      child: Icon(_kindIcon, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.index} / ${widget.total}',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: ConfidiaColors.textSecondary(isDark),
                                  fontWeight: FontWeight.w600,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                          ),
                          if (widget.priority.tag != null)
                            Text(
                              widget.priority.tag!,
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
                          borderRadius: BorderRadius.circular(999),
                          color: SerenityPalette.excellent.withValues(alpha: isDark ? 0.14 : 0.1),
                          border: Border.all(
                            color: SerenityPalette.excellent.withValues(alpha: 0.45),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
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
                const SizedBox(height: 14),
                Text(
                  widget.priority.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                        letterSpacing: -0.2,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.priority.subtitle,
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
                            color: palette.primary,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, size: 16, color: palette.primary),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
