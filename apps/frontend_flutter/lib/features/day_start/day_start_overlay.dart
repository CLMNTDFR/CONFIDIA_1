import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/theme_context.dart';
import '../../shared/utils/serenity_palette.dart';
import '../../shared/widgets/ai_streaming_text.dart';
import '../../shared/widgets/cofid_ia_brand.dart';
import '../../shared/widgets/confidia_ai_robot.dart';
import '../../shared/widgets/confidia_glow_button.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/stagger_fade.dart';
import 'day_briefing_model.dart';
import 'day_glance_strip.dart';
import 'day_priority_carousel.dart';
import 'day_start_provider.dart';

/// Overlay immersif du rituel « Commencer ma journée ».
class DayStartOverlay extends ConsumerWidget {
  const DayStartOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(dayStartSessionProvider);
    if (!session.isOpen) return const SizedBox.shrink();

    final wide = MediaQuery.sizeOf(context).width >= 720;

    return Positioned.fill(
      child: Material(
        color: Colors.black.withValues(alpha: 0.58),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: wide ? 560 : 440),
              child: Padding(
                padding: const EdgeInsets.all(ConfidiaSpacing.lg),
                child: _DayStartCard(session: session),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DayStartCard extends ConsumerWidget {
  final DayStartSession session;

  const _DayStartCard({required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final briefing = session.briefing;
    final phase = session.phase;
    final showSections = phase == DayStartPhase.ready && briefing != null;
    final streaming = phase == DayStartPhase.streaming && briefing != null;

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      borderRadius: 22,
      highlighted: true,
      clipContent: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.86,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const ConfidiaAiRobot(size: 32, speaking: true),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CofidIaBrand(fontSize: 15),
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
                    TextButton(
                      onPressed: () => ref.read(dayStartSessionProvider.notifier).markReady(),
                      child: const Text('Passer'),
                    )
                  else
                    IconButton(
                      tooltip: 'Fermer',
                      onPressed: () => ref.read(dayStartSessionProvider.notifier).dismiss(),
                      icon: const Icon(Icons.close_rounded, size: 20),
                    ),
                ],
              ),
              const SizedBox(height: 14),
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
                    onComplete: () => ref.read(dayStartSessionProvider.notifier).markReady(),
                  )
                else
                  Text(
                    briefing.narrative,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.45),
                  ),
                if (showSections) ...[
                  const SizedBox(height: 18),
                  StaggerFade(
                    index: 0,
                    child: DayGlanceStrip(
                      metrics: briefing.glance,
                      dense: MediaQuery.sizeOf(context).width < 400,
                      beforeNavigate: () => ref.read(dayStartSessionProvider.notifier).dismiss(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._buildSections(context, ref, briefing),
                  const SizedBox(height: 14),
                  _FooterActions(),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSections(BuildContext context, WidgetRef ref, DayBriefing briefing) {
    var index = 1;
    final widgets = <Widget>[];

    if (briefing.priorities.isNotEmpty) {
      widgets.add(StaggerFade(
        index: index++,
        child: DayPriorityCarousel(
          priorities: briefing.priorities,
          totalGain: briefing.totalGain,
          onSelect: (priority) {
            ref.read(dayStartSessionProvider.notifier).dismiss();
            context.go(priority.route);
          },
        ),
      ));
    }

    // Projection tôt : visible juste après les actions qui font monter l'indice.
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
                if (i > 0) const SizedBox(height: 6),
                _ActionRow(
                  icon: Icons.payments_rounded,
                  accent: ConfidiaColors.success,
                  title: briefing.urgentPayments[i].creditor,
                  subtitle:
                      '${briefing.urgentPayments[i].amountFormatted} · ${DateFormat('d MMM', 'fr_FR').format(briefing.urgentPayments[i].dueDate)}',
                  onTap: () {
                    ref.read(dayStartSessionProvider.notifier).dismiss();
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
                if (i > 0) const SizedBox(height: 6),
                _ActionRow(
                  icon: Icons.event_rounded,
                  accent: context.palette.secondary,
                  title: briefing.todaysAppointments[i].title,
                  subtitle: DateFormat('HH:mm', 'fr_FR').format(briefing.todaysAppointments[i].start) +
                      (briefing.todaysAppointments[i].location != null
                          ? ' · ${briefing.todaysAppointments[i].location}'
                          : ''),
                  onTap: () {
                    ref.read(dayStartSessionProvider.notifier).dismiss();
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
                if (i > 0) const SizedBox(height: 6),
                _ActionRow(
                  icon: Icons.description_outlined,
                  accent: context.palette.primary,
                  title: briefing.newDocuments[i].title,
                  subtitle: briefing.newDocuments[i].correspondent ??
                      briefing.newDocuments[i].documentType ??
                      'Document',
                  onTap: () {
                    ref.read(dayStartSessionProvider.notifier).dismiss();
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
      padding: const EdgeInsets.only(top: 14),
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: accent.withValues(alpha: 0.14),
                ),
                child: Icon(icon, size: 18, color: accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
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
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.palette.primary.withValues(alpha: isDark ? 0.18 : 0.1),
            context.palette.secondary.withValues(alpha: isDark ? 0.12 : 0.08),
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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

class _FooterActions extends ConsumerWidget {
  const _FooterActions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Pas de CTA primaire : les priorités sont déjà listées au-dessus.
    return ConfidiaGlowButton(
      label: 'Fermer',
      icon: Icons.close_rounded,
      primary: false,
      expand: true,
      onPressed: () => ref.read(dayStartSessionProvider.notifier).dismiss(),
    );
  }
}
