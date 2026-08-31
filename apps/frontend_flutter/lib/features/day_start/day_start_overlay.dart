import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/theme_context.dart';
import '../../shared/utils/serenity_palette.dart';
import '../../core/theme/tokens/tokens.dart';
import '../../shared/widgets/ai_streaming_text.dart';
import '../../shared/widgets/cofid_ia_brand.dart';
import '../../shared/widgets/confidia_ai_robot.dart';
import '../../shared/widgets/confidia_button.dart';
import '../../shared/widgets/confidia_chrome_material.dart';
import '../../shared/widgets/confidia_demo_badge.dart';
import '../../shared/widgets/confidia_glow_button.dart';
import '../../shared/widgets/mobile_shell_insets.dart';
import '../../shared/widgets/stagger_fade.dart';
import 'day_briefing_model.dart';
import 'day_glance_strip.dart';
import 'day_priority_carousel.dart';
import 'day_start_provider.dart';

/// Overlay immersif du rituel « Commencer ma journée ».
/// Même langage que [showConfidiaSheet] : blur en fondu, sheet en slide, centrage shell.
class DayStartOverlay extends ConsumerStatefulWidget {
  const DayStartOverlay({super.key});

  @override
  ConsumerState<DayStartOverlay> createState() => _DayStartOverlayState();
}

class _DayStartOverlayState extends ConsumerState<DayStartOverlay>
    with SingleTickerProviderStateMixin {
  static const double _edgeGap = 12;
  static const double _barrierBlur = 14;

  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: AppDurations.medium,
  );
  late final CurvedAnimation _motion = CurvedAnimation(
    parent: _ctrl,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );

  @override
  void initState() {
    super.initState();
    _ctrl.forward();
  }

  @override
  void dispose() {
    _motion.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    if (!_ctrl.isDismissed) {
      await _ctrl.reverse();
    }
    if (mounted) {
      ref.read(dayStartSessionProvider.notifier).dismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(dayStartSessionProvider);
    if (!session.isOpen) return const SizedBox.shrink();

    final size = MediaQuery.sizeOf(context);
    final viewPadding = MediaQuery.viewPaddingOf(context);
    final isMobile = size.width < 900;
    final wide = size.width >= 720;

    final topChrome = viewPadding.top + ConfidiaSpacing.topBarHeight;
    final bottomChrome = isMobile
        ? ConfidiaMobileShell.navBarHeight + viewPadding.bottom
        : viewPadding.bottom;
    final topInset = topChrome + _edgeGap;
    final bottomInset = bottomChrome + _edgeGap;
    final availableH = (size.height - topInset - bottomInset).clamp(160.0, size.height);

    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _motion,
        builder: (context, _) {
          final t = _motion.value.clamp(0.0, 1.0);
          final sigma = _barrierBlur * t;
          final veil = AppOpacity.veilDark * t;
          final dy = (1.0 - t) * 56;

          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: veil),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: topInset, bottom: bottomInset),
                child: Center(
                  child: Transform.translate(
                    offset: Offset(0, dy),
                    child: Opacity(
                      opacity: t,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24),
                        child: SizedBox(
                          width: (wide ? 560.0 : 440.0)
                              .clamp(0.0, size.width - (isMobile ? 24 : 48)),
                          height: availableH,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: AppRadius.xlAll,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.22 * t),
                                  blurRadius: 36,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 12),
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12 * t),
                                  blurRadius: 64,
                                  spreadRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              type: MaterialType.transparency,
                              child: _DayStartCard(
                                session: session,
                                onDismiss: _dismiss,
                                onSkipStream: () =>
                                    ref.read(dayStartSessionProvider.notifier).markReady(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DayStartCard extends ConsumerStatefulWidget {
  final DayStartSession session;
  final Future<void> Function() onDismiss;
  final VoidCallback onSkipStream;

  const _DayStartCard({
    required this.session,
    required this.onDismiss,
    required this.onSkipStream,
  });

  @override
  ConsumerState<_DayStartCard> createState() => _DayStartCardState();
}

class _DayStartCardState extends ConsumerState<_DayStartCard> {
  final _scrollCtrl = ScrollController();
  bool _showTopFade = false;
  bool _showBottomFade = false;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_syncFades);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncFades());
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_syncFades);
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _DayStartCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncFades());
  }

  void _syncFades() {
    if (!_scrollCtrl.hasClients) {
      if (_showTopFade || _showBottomFade) {
        setState(() {
          _showTopFade = false;
          _showBottomFade = false;
        });
      }
      return;
    }
    final pos = _scrollCtrl.position;
    final top = pos.pixels > 2;
    final bottom = pos.maxScrollExtent > 2 && pos.pixels < pos.maxScrollExtent - 2;
    if (top != _showTopFade || bottom != _showBottomFade) {
      setState(() {
        _showTopFade = top;
        _showBottomFade = bottom;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final briefing = widget.session.briefing;
    final phase = widget.session.phase;
    final showSections = phase == DayStartPhase.ready && briefing != null;
    final streaming = phase == DayStartPhase.streaming && briefing != null;
    final fill = AppColors.surface1(isDark);

    return ConfidiaChromeMaterial(
      borderRadius: AppRadius.xlAll,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 10, 10),
            child: Row(
              children: [
                const ConfidiaAiRobot(size: 32, speaking: true),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          CofidIaBrand(fontSize: 15),
                          SizedBox(width: 8),
                          ConfidiaDemoBadge(compact: true),
                        ],
                      ),
                      Text(
                        'Briefing du jour',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: ConfidiaColors.textSecondary(isDark),
                            ),
                      ),
                    ],
                  ),
                ),
                if (streaming)
                  ConfidiaGlowButton(
                    label: 'Passer',
                    icon: Icons.skip_next_rounded,
                    primary: false,
                    onPressed: widget.onSkipStream,
                  )
                else
                  ConfidiaCloseButton(onPressed: () => widget.onDismiss()),
              ],
            ),
          ),
          Divider(height: 1, color: AppBorders.subtle(isDark).color),
          // Remplit le plafond parent ; le ListView scroll sans overflow.
          Expanded(
            child: Theme(
              data: Theme.of(context).copyWith(
                scrollbarTheme: ScrollbarThemeData(
                  thickness: const WidgetStatePropertyAll(5),
                  radius: const Radius.circular(8),
                  crossAxisMargin: 3,
                  mainAxisMargin: 6,
                  thumbColor: WidgetStatePropertyAll(
                    (isDark ? Colors.white : Colors.black).withValues(alpha: 0.28),
                  ),
                ),
              ),
              child: Stack(
                children: [
                  Scrollbar(
                    controller: _scrollCtrl,
                    thumbVisibility: true,
                    child: ListView(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(16, 14, 18, 16),
                      children: [
                        if (phase == DayStartPhase.preparing)
                          const _PreparingBody()
                        else if (briefing != null) ...[
                          if (phase == DayStartPhase.streaming)
                            AiStreamingText(
                              key: ValueKey(briefing.narrative),
                              text: briefing.narrative,
                              showThinkingRobot: false,
                              thinkingDelay: const Duration(milliseconds: 180),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.45),
                              onComplete: () =>
                                  ref.read(dayStartSessionProvider.notifier).markReady(),
                            )
                          else
                            Text(
                              briefing.narrative,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.45),
                            ),
                          if (showSections) ...[
                            const SizedBox(height: 16),
                            StaggerFade(
                              index: 0,
                              child: DayGlanceStrip(
                                metrics: briefing.glance,
                                dense: MediaQuery.sizeOf(context).width < 400,
                                beforeNavigate: () => widget.onDismiss(),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ..._buildSections(context, briefing),
                            const SizedBox(height: 16),
                            ConfidiaGlowButton(
                              label: 'Fermer',
                              icon: Icons.close_rounded,
                              primary: false,
                              expand: true,
                              onPressed: () => widget.onDismiss(),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                  if (_showTopFade)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: IgnorePointer(
                        child: Container(
                          height: 28,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                fill.withValues(alpha: 0.92),
                                fill.withValues(alpha: 0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (_showBottomFade)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: IgnorePointer(
                        child: Container(
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                fill.withValues(alpha: 0.95),
                                fill.withValues(alpha: 0),
                              ],
                            ),
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
    );
  }

  List<Widget> _buildSections(BuildContext context, DayBriefing briefing) {
    var index = 1;
    final widgets = <Widget>[];
    final sectionAccent = ConfidiaColors.textSecondary(Theme.of(context).brightness == Brightness.dark);

    if (briefing.priorities.isNotEmpty) {
      widgets.add(StaggerFade(
        index: index++,
        child: DayPriorityCarousel(
          priorities: briefing.priorities,
          totalGain: briefing.totalGain,
          onSelect: (priority) {
            widget.onDismiss();
            context.go(priority.route);
          },
        ),
      ));
    }

    widgets.add(StaggerFade(
      index: index++,
      child: _ProjectionBand(
        current: briefing.currentScore,
        projected: briefing.projectedScore,
        valueMessage: briefing.valueMessage,
      ),
    ));

    if (briefing.urgentPayments.isNotEmpty) {
      widgets.add(StaggerFade(
        index: index++,
        child: _SectionBlock(
          title: 'Paiements urgents',
          child: Column(
            children: [
              for (var i = 0; i < briefing.urgentPayments.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                _ActionRow(
                  icon: Icons.payments_rounded,
                  accent: ConfidiaColors.success,
                  title: briefing.urgentPayments[i].creditor,
                  subtitle:
                      '${briefing.urgentPayments[i].amountFormatted} · ${DateFormat('d MMM', 'fr_FR').format(briefing.urgentPayments[i].dueDate)}',
                  onTap: () {
                    widget.onDismiss();
                    context.go('/payments/${briefing.urgentPayments[i].id}');
                  },
                ),
              ],
            ],
          ),
        ),
      ));
    }

    if (briefing.todaysAppointments.isNotEmpty) {
      widgets.add(StaggerFade(
        index: index++,
        child: _SectionBlock(
          title: 'Rendez-vous',
          child: Column(
            children: [
              for (var i = 0; i < briefing.todaysAppointments.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                _ActionRow(
                  icon: Icons.event_rounded,
                  accent: sectionAccent,
                  title: briefing.todaysAppointments[i].title,
                  subtitle: DateFormat('HH:mm', 'fr_FR').format(briefing.todaysAppointments[i].start) +
                      (briefing.todaysAppointments[i].location != null
                          ? ' · ${briefing.todaysAppointments[i].location}'
                          : ''),
                  onTap: () {
                    widget.onDismiss();
                    context.go('/calendar');
                  },
                ),
              ],
            ],
          ),
        ),
      ));
    }

    if (briefing.newDocuments.isNotEmpty) {
      widgets.add(StaggerFade(
        index: index++,
        child: _SectionBlock(
          title: 'Nouveaux documents',
          child: Column(
            children: [
              for (var i = 0; i < briefing.newDocuments.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                _ActionRow(
                  icon: Icons.description_outlined,
                  accent: sectionAccent,
                  title: briefing.newDocuments[i].title,
                  subtitle: briefing.newDocuments[i].correspondent ??
                      briefing.newDocuments[i].documentType ??
                      'Document',
                  onTap: () {
                    widget.onDismiss();
                    context.go('/documents/${briefing.newDocuments[i].id}');
                  },
                ),
              ],
            ],
          ),
        ),
      ));
    }

    return widgets;
  }
}

class _PreparingBody extends StatelessWidget {
  const _PreparingBody();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          ConfidiaAiRobot(size: 56, speaking: true),
          SizedBox(height: 16),
          Text(
            'Confid•IA prépare votre briefing…',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SectionBlock extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionBlock({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: accent.withValues(alpha: 0.14),
                ),
                child: Icon(icon, size: 18, color: accent),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: ConfidiaColors.textSecondary(isDark),
                          ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 18, color: ConfidiaColors.textSecondary(isDark)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectionBand extends StatelessWidget {
  final int current;
  final int projected;
  final String? valueMessage;

  const _ProjectionBand({
    required this.current,
    required this.projected,
    this.valueMessage,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final projectedColor = SerenityPalette.forScore(projected, palette: context.palette);
    final delta = projected - current;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            (isDark ? Colors.white : Colors.black).withValues(alpha: isDark ? 0.08 : 0.05),
            (isDark ? Colors.white : Colors.black).withValues(alpha: isDark ? 0.04 : 0.03),
          ],
        ),
        border: Border.all(color: projectedColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Projection sérénité',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '$current',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: ConfidiaColors.textSecondary(isDark),
                    ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward_rounded, size: 18, color: projectedColor),
              ),
              Text(
                '$projected',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: projectedColor,
                    ),
              ),
              const Spacer(),
              if (delta > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: SerenityPalette.excellent.withValues(alpha: 0.18),
                  ),
                  child: Text(
                    '+$delta pts',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: SerenityPalette.excellent,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
            ],
          ),
          if (valueMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              valueMessage!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ConfidiaColors.textSecondary(isDark),
                    height: 1.35,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
