import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/theme_context.dart';
import '../../core/theme/spacing.dart';
import '../../shared/data/mock_ecosystem.dart';
import '../../shared/models/ai_insight_model.dart';
import '../../shared/models/payment_model.dart';
import '../../shared/services/mock_ai_service.dart';
import '../../shared/widgets/provider_chip.dart';
import '../../shared/widgets/status_badge.dart';
import '../payments/payments_provider.dart';
import '../../shared/models/document_model.dart';
import '../../shared/widgets/cofid_ia_brand.dart';
import '../../shared/widgets/confidia_ai_robot.dart';
import '../../shared/widgets/confidia_button.dart';
import '../../shared/widgets/confidia_glow_button.dart';
import '../../shared/widgets/confidia_chart_card.dart';
import '../../shared/widgets/confidia_glow_chip.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/stat_card.dart';
import '../../shared/widgets/stagger_fade.dart';
import '../calendar/calendar_provider.dart';
import '../onboarding/guided_tour_provider.dart';
import '../onboarding/onboarding_targets.dart';
import '../../shared/widgets/mobile_shell_insets.dart';
import '../day_start/day_briefing_provider.dart';
import '../day_start/day_glance_strip.dart';
import 'dashboard_chart_widgets.dart';
import 'dashboard_grid.dart';
import 'dashboard_provider.dart';
import 'serenity_briefing_widget.dart';
import 'start_my_day_hero.dart';
import 'week_overview_widget.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 450), () {
        if (!mounted) return;
        ref.read(guidedTourProvider.notifier).startIfArmed();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final layout = ref.watch(dashboardLayoutProvider);
    final editActionsClearance = layout.editMode
        ? (layout.hidden.isNotEmpty ? _HiddenWidgetsPanel.panelHeight + 88.0 : 88.0)
        : 0.0;
    final padding = ConfidiaInsets.pageWithExtra(context, extraBottom: editActionsClearance);
    final visibleCount = layout.visible.length;
    final notifier = ref.read(dashboardLayoutProvider.notifier);

    Widget buildTile(DashboardWidgetType type, int index) => StaggerFade(
          index: index,
          child: _buildWidget(
            context,
            ref,
            type,
            index,
            layout.editMode,
            canMoveUp: index > 0,
            canMoveDown: index < visibleCount - 1,
            onMoveUp: () => notifier.moveVisible(index, index - 1),
            onMoveDown: () => notifier.moveVisible(index, index + 1),
          ),
        );

    final listPadding = padding.copyWith(top: ConfidiaSpacing.sm);
    final glanceStrip = DayGlanceStrip(
      metrics: ref.watch(dayBriefingProvider).glance,
      dense: MediaQuery.sizeOf(context).width < 400,
      layout: DayGlanceLayout.row,
      showSerenity: false,
    );

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                padding.left,
                padding.top,
                padding.right,
                ConfidiaSpacing.sm,
              ),
              child: const StartMyDayHero(),
            ),
            Expanded(
              child: layout.editMode
                  ? _EditModeDashboardList(
                      padding: listPadding,
                      header: glanceStrip,
                      types: layout.visible,
                      buildTile: buildTile,
                      onReorderSegment: (oldIndex, newIndex, segments) =>
                          notifier.reorderSegments(oldIndex, newIndex, segments),
                    )
                  : ListView(
                      padding: listPadding,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(bottom: ConfidiaSpacing.md),
                          child: glanceStrip,
                        ),
                        ...DashboardGrid.buildRows(
                          context: context,
                          types: layout.visible,
                          builder: buildTile,
                        ),
                      ],
                    ),
            ),
          ],
        ),
        if (layout.editMode) ...[
          Positioned(
            left: ConfidiaSpacing.lg,
            right: ConfidiaSpacing.lg,
            bottom: ConfidiaMobileShell.bottomScrollInset(context) +
                (layout.hidden.isNotEmpty ? _HiddenWidgetsPanel.panelHeight : ConfidiaSpacing.lg),
            child: _EditModeActions(
              onReset: () => ref.read(dashboardLayoutProvider.notifier).reset(),
              onDone: () => ref.read(dashboardLayoutProvider.notifier).toggleEditMode(),
            ),
          ),
          if (layout.hidden.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: ConfidiaMobileShell.bottomScrollInset(context),
              child: _HiddenWidgetsPanel(
                hidden: layout.hidden.toList(),
                onRestore: (type) => ref.read(dashboardLayoutProvider.notifier).toggleWidget(type),
              ),
            ),
        ] else
          Positioned(
            right: ConfidiaSpacing.lg,
            bottom: ConfidiaMobileShell.fabBottom(context),
            child: _CustomizeFab(onPressed: () => ref.read(dashboardLayoutProvider.notifier).toggleEditMode()),
          ),
      ],
    );
  }

  Widget _buildWidget(
    BuildContext context,
    WidgetRef ref,
    DashboardWidgetType type,
    int index,
    bool editMode, {
    bool canMoveUp = false,
    bool canMoveDown = false,
    VoidCallback? onMoveUp,
    VoidCallback? onMoveDown,
  }) {
    final docs = MockEcosystem.documents;
    final notifications = MockEcosystem.notifications;

    final content = switch (type) {
      DashboardWidgetType.greeting => const SizedBox.shrink(),
      DashboardWidgetType.serenityBriefing => KeyedSubtree(
            key: OnboardingTargets.serenity,
            child: const SerenityBriefingWidget(),
          ),
      DashboardWidgetType.weekOverview => KeyedSubtree(
            key: OnboardingTargets.weekOverview,
            child: const WeekOverviewWidget(),
          ),
      DashboardWidgetType.stats => const _StatsWidget(),
      DashboardWidgetType.expensesTrend => const ExpensesTrendChartWidget(),
      DashboardWidgetType.paymentsOverview => const PaymentsOverviewChartWidget(),
      DashboardWidgetType.documentsBreakdown => const DocumentsCategoryChartWidget(),
      DashboardWidgetType.hubActivity => const HubActivityChartWidget(),
      DashboardWidgetType.quickActions => const _QuickActionsWidget(),
      DashboardWidgetType.pendingPayments => const _PendingPaymentsWidget(),
      DashboardWidgetType.recentDocs => _RecentDocsWidget(docs: docs),
      DashboardWidgetType.deadlines => const _DeadlinesWidget(),
      DashboardWidgetType.importantDocs => _ImportantDocsWidget(docs: docs.where((d) => d.isImportant).toList()),
      DashboardWidgetType.activity => _ActivityWidget(notifications: notifications),
      DashboardWidgetType.connectedAccounts => const _ConnectedAccountsWidget(),
      DashboardWidgetType.aiAnalyzed => const _AiAnalyzedWidget(),
    };

    if (!editMode) return content;

    final body = Opacity(opacity: 0.92, child: content);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _WidgetEditBar(
          label: type.label,
          icon: _iconForType(type),
          onHide: () => ref.read(dashboardLayoutProvider.notifier).toggleWidget(type),
          canMoveUp: canMoveUp,
          canMoveDown: canMoveDown,
          onMoveUp: onMoveUp,
          onMoveDown: onMoveDown,
        ),
        if (type.isHalfWidth) Expanded(child: body) else body,
      ],
    );
  }
}

class _EditModeDashboardList extends StatelessWidget {
  final EdgeInsets padding;
  final Widget? header;
  final List<DashboardWidgetType> types;
  final Widget Function(DashboardWidgetType type, int index) buildTile;
  final void Function(int oldIndex, int newIndex, List<List<DashboardWidgetType>> segments) onReorderSegment;

  const _EditModeDashboardList({
    required this.padding,
    this.header,
    required this.types,
    required this.buildTile,
    required this.onReorderSegment,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = DashboardGrid.isWideLayout(context);
    final segments = DashboardGrid.buildSegments(types, isWide: isWide);
    final segmentTypes = segments.map((s) => List<DashboardWidgetType>.from(s.types)).toList();

    return ReorderableListView.builder(
      padding: padding,
      header: header == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(bottom: ConfidiaSpacing.md),
              child: header,
            ),
      buildDefaultDragHandles: false,
      onReorder: (oldIndex, newIndex) => onReorderSegment(oldIndex, newIndex, segmentTypes),
      itemCount: segments.length,
      itemBuilder: (context, segmentIndex) {
        final segment = segments[segmentIndex];
        final startIndex = segments.take(segmentIndex).fold<int>(0, (sum, s) => sum + s.types.length);

        return Padding(
          key: ValueKey(segment.key),
          padding: const EdgeInsets.only(bottom: DashboardGrid.rowGap),
          child: _EditSegmentRow(
            segmentIndex: segmentIndex,
            segment: segment,
            isWide: isWide,
            startIndex: startIndex,
            buildTile: buildTile,
          ),
        );
      },
    );
  }
}

class _EditSegmentRow extends StatelessWidget {
  final int segmentIndex;
  final DashboardGridSegment segment;
  final bool isWide;
  final int startIndex;
  final Widget Function(DashboardWidgetType type, int index) buildTile;

  const _EditSegmentRow({
    required this.segmentIndex,
    required this.segment,
    required this.isWide,
    required this.startIndex,
    required this.buildTile,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rowBody = segment.types.length == 2
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: buildTile(segment.types[0], startIndex)),
              const SizedBox(width: ConfidiaSpacing.md),
              Expanded(child: buildTile(segment.types[1], startIndex + 1)),
            ],
          )
        : isWide && segment.types.single.isHalfWidth
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: buildTile(segment.types.single, startIndex)),
                  const SizedBox(width: ConfidiaSpacing.md),
                  const Expanded(child: SizedBox()),
                ],
              )
            : buildTile(segment.types.single, startIndex);

    final fixedHeight = segment.rowHeight(editMode: true);
    final content = fixedHeight > DashboardGrid.editChromeHeight
        ? SizedBox(height: fixedHeight, child: rowBody)
        : rowBody;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ReorderableDragStartListener(
          index: segmentIndex,
          child: Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: isDark ? 0.06 : 0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: ConfidiaColors.border(isDark).withValues(alpha: 0.45)),
            ),
            child: Row(
              children: [
                Icon(Icons.drag_indicator_rounded, size: 18, color: ConfidiaColors.textSecondary(isDark)),
                const SizedBox(width: 8),
                Text(
                  segment.types.length == 2 ? 'Déplacer la ligne' : 'Déplacer le bloc',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
        content,
      ],
    );
  }
}

IconData _iconForType(DashboardWidgetType type) => switch (type) {
      DashboardWidgetType.greeting => Icons.waving_hand_rounded,
      DashboardWidgetType.serenityBriefing => Icons.psychology_rounded,
      DashboardWidgetType.weekOverview => Icons.calendar_view_week_rounded,
      DashboardWidgetType.stats => Icons.insights_rounded,
      DashboardWidgetType.expensesTrend => Icons.trending_up_rounded,
      DashboardWidgetType.paymentsOverview => Icons.bar_chart_rounded,
      DashboardWidgetType.documentsBreakdown => Icons.pie_chart_rounded,
      DashboardWidgetType.hubActivity => Icons.stacked_bar_chart_rounded,
      DashboardWidgetType.quickActions => Icons.bolt_rounded,
      DashboardWidgetType.pendingPayments => Icons.payments_rounded,
      DashboardWidgetType.recentDocs => Icons.folder_copy_rounded,
      DashboardWidgetType.deadlines => Icons.event_rounded,
      DashboardWidgetType.importantDocs => Icons.star_rounded,
      DashboardWidgetType.activity => Icons.history_rounded,
      DashboardWidgetType.connectedAccounts => Icons.hub_rounded,
      DashboardWidgetType.aiAnalyzed => Icons.smart_toy_rounded,
    };

class _WidgetEditBar extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onHide;
  final bool canMoveUp;
  final bool canMoveDown;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  const _WidgetEditBar({
    required this.label,
    required this.icon,
    required this.onHide,
    this.canMoveUp = false,
    this.canMoveDown = false,
    this.onMoveUp,
    this.onMoveDown,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: isDark ? 0.07 : 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ConfidiaColors.border(isDark).withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: context.palette.secondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.labelMedium, overflow: TextOverflow.ellipsis),
          ),
          _EditIconButton(
            icon: Icons.keyboard_arrow_up_rounded,
            tooltip: 'Monter',
            enabled: canMoveUp,
            onTap: onMoveUp,
          ),
          _EditIconButton(
            icon: Icons.keyboard_arrow_down_rounded,
            tooltip: 'Descendre',
            enabled: canMoveDown,
            onTap: onMoveDown,
          ),
          const SizedBox(width: 4),
          _EditActionChip(icon: Icons.visibility_off_outlined, label: 'Masquer', onTap: onHide),
        ],
      ),
    );
  }
}

class _EditIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback? onTap;

  const _EditIconButton({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IconButton(
      onPressed: enabled ? onTap : null,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      iconSize: 18,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      color: enabled ? ConfidiaColors.textPrimary(isDark) : ConfidiaColors.textSecondary(isDark).withValues(alpha: 0.35),
      icon: Icon(icon),
    );
  }
}

class _EditActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _EditActionChip({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16),
              const SizedBox(width: 4),
              Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _HiddenWidgetsPanel extends StatelessWidget {
  static const double panelHeight = 104;

  final List<DashboardWidgetType> hidden;
  final ValueChanged<DashboardWidgetType> onRestore;

  const _HiddenWidgetsPanel({required this.hidden, required this.onRestore});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: SizedBox(
        height: panelHeight,
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    (isDark ? const Color(0xFF14141E) : Colors.white).withValues(alpha: 0.92),
                    (isDark ? const Color(0xFF0E0E16) : const Color(0xFFF8F6FC)).withValues(alpha: 0.98),
                  ],
                ),
                border: Border(top: BorderSide(color: context.palette.secondary.withValues(alpha: 0.35))),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.widgets_outlined, size: 16, color: context.palette.secondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('Blocs masqués · à réactiver', style: Theme.of(context).textTheme.labelLarge),
                        ),
                        Text(
                          '${hidden.length}',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: context.palette.secondary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: hidden.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final type = hidden[index];
                          return ActionChip(
                            avatar: Icon(_iconForType(type), size: 16, color: context.palette.primary),
                            label: Text(type.label),
                            labelStyle: Theme.of(context).textTheme.labelMedium,
                            backgroundColor: isDark
                                ? context.palette.primary.withValues(alpha: 0.18)
                                : context.palette.primary.withValues(alpha: 0.12),
                            side: BorderSide(color: context.palette.primary.withValues(alpha: 0.35)),
                            onPressed: () => onRestore(type),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EditModeActions extends StatelessWidget {
  final VoidCallback onReset;
  final VoidCallback onDone;

  const _EditModeActions({required this.onReset, required this.onDone});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : Colors.white;
    final fgColor = isDark ? Colors.white : Colors.black;

    return Row(
      children: [
        Expanded(
          child: Material(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            elevation: isDark ? 0 : 1,
            shadowColor: Colors.black.withValues(alpha: 0.08),
            child: InkWell(
              onTap: onReset,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: ConfidiaColors.border(isDark)),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.restore_rounded, size: 18, color: fgColor),
                    const SizedBox(width: 8),
                    Text(
                      'Réinitialiser',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: fgColor,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ConfidiaButton(label: 'Terminer', icon: Icons.check_rounded, compact: true, onPressed: onDone),
        ),
      ],
    );
  }
}

class _CustomizeFab extends StatefulWidget {
  final VoidCallback onPressed;

  const _CustomizeFab({required this.onPressed});

  @override
  State<_CustomizeFab> createState() => _CustomizeFabState();
}

class _CustomizeFabState extends State<_CustomizeFab> {
  bool _pressed = false;
  bool _hovered = false;

  static const _duration = Duration(milliseconds: 450);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final supportsHover = MediaQuery.sizeOf(context).width >= 600;
    final expanded = !supportsHover || _hovered;

    // Clé sur le bouton réel (pas le Align) pour un spotlight juste en desktop.
    return Align(
      alignment: Alignment.centerRight,
      child: MouseRegion(
        onEnter: supportsHover ? (_) => setState(() => _hovered = true) : null,
        onExit: supportsHover ? (_) => setState(() => _hovered = false) : null,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.onPressed,
          child: KeyedSubtree(
            key: OnboardingTargets.customizeFab,
            child: AnimatedScale(
              scale: _pressed ? 0.97 : 1,
              duration: const Duration(milliseconds: 120),
              child: AnimatedSize(
                duration: _duration,
                curve: Curves.easeInOutCubic,
                alignment: Alignment.centerRight,
                child: AnimatedContainer(
                  duration: _duration,
                  curve: Curves.easeInOutCubic,
                  height: 44,
                  padding: EdgeInsets.symmetric(horizontal: expanded ? 16 : 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    color: isDark ? ConfidiaColors.darkSurfaceElevated : Colors.white,
                    border: Border.all(color: ConfidiaColors.border(isDark)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.dashboard_customize_outlined,
                        size: 20,
                        color: expanded ? context.palette.primary : ConfidiaColors.textSecondary(isDark),
                      ),
                      AnimatedSize(
                        duration: _duration,
                        curve: Curves.easeInOutCubic,
                        alignment: Alignment.centerLeft,
                        child: expanded
                            ? Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Text(
                                  'Personnaliser',
                                  maxLines: 1,
                                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: ConfidiaColors.textPrimary(isDark),
                                        letterSpacing: 0.1,
                                      ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatsWidget extends ConsumerWidget {
  const _StatsWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docs = MockEcosystem.documents;
    final notifications = MockEcosystem.notifications;
    final pendingCount = ref.watch(paymentsProvider.select((list) => list
        .where((p) => p.status == PaymentStatus.pending || p.status == PaymentStatus.waiting)
        .length));

    return StatsRow(stats: [
      CompactStat(label: 'Documents', value: '${docs.length}', icon: Icons.folder_copy_rounded, color: context.palette.primary),
      CompactStat(label: 'Paiements', value: '$pendingCount', icon: Icons.payments_rounded, color: context.palette.accent),
      CompactStat(label: 'Alertes', value: '${notifications.where((n) => !n.read).length}', icon: Icons.notifications_rounded, color: context.palette.secondary),
      CompactStat(label: 'Emails', value: '${MockEcosystem.emails.length}', icon: Icons.mail_rounded, color: ConfidiaColors.success),
    ]);
  }
}

class _QuickActionsWidget extends StatelessWidget {
  const _QuickActionsWidget();

  @override
  Widget build(BuildContext context) {
    return ConfidiaGlowChipBar(
      centered: true,
      children: [
        ConfidiaGlowChip(
          label: 'Messagerie',
          icon: Icons.mail_rounded,
          selected: false,
          onTap: () => context.go('/messaging'),
        ),
        ConfidiaGlowChip(
          label: 'Paiements',
          icon: Icons.payments_rounded,
          selected: false,
          onTap: () => context.go('/payments'),
        ),
        ConfidiaGlowChip(
          label: 'Scanner',
          icon: Icons.document_scanner_rounded,
          selected: false,
          onTap: () => context.go('/scan'),
        ),
      ],
    );
  }
}

class _PendingPaymentsWidget extends ConsumerWidget {
  const _PendingPaymentsWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(paymentsProvider);
    final paymentsNotifier = ref.read(paymentsProvider.notifier);
    final payments = paymentsNotifier.pending;
    final total = paymentsNotifier.totalPending;
    final next = paymentsNotifier.nextDue;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: 'Paiements en attente', onTap: () => context.go('/payments')),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${total.toStringAsFixed(2)} € à régler', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    if (next != null)
                      Text('Prochaine · ${next.creditor} · ${DateFormat('d MMM', 'fr_FR').format(next.dueDate)}', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              if (next != null)
                ConfidiaGlowButton(
                  label: 'Payer',
                  icon: Icons.payment_rounded,
                  onPressed: () => context.go('/payments/${next.id}'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ...payments.take(3).map((p) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(p.icon, color: p.status.themeColor(context.palette), size: 20),
                title: Text(p.creditor, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(p.label, style: Theme.of(context).textTheme.labelSmall),
                trailing: Text(p.amountFormatted, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
                onTap: () => context.go('/payments/${p.id}'),
              )),
        ],
      ),
    );
  }
}

class _DashboardCardShell extends StatelessWidget {
  final Widget header;
  final Widget body;
  final Widget? footer;

  const _DashboardCardShell({required this.header, required this.body, this.footer});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fillHeight = constraints.hasBoundedHeight && constraints.maxHeight.isFinite;

        return GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              header,
              if (fillHeight) Expanded(child: body) else body,
              if (footer != null) ...[
                const SizedBox(height: 6),
                footer!,
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ConnectedAccountsWidget extends StatelessWidget {
  const _ConnectedAccountsWidget();

  @override
  Widget build(BuildContext context) {
    final accounts = MockEcosystem.connectedAccounts.take(4);
    return _DashboardCardShell(
      header: _SectionHeader(title: 'Comptes connectés', onTap: () => context.go('/settings')),
      body: Align(
        alignment: Alignment.topLeft,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: accounts.map((a) => MailProviderChip(provider: a.provider)).toList(),
        ),
      ),
      footer: Text(
        '${MockEcosystem.connectedAccounts.length} comptes · Synchronisation active',
        style: Theme.of(context).textTheme.bodySmall,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _AiAnalyzedWidget extends StatelessWidget {
  const _AiAnalyzedWidget();

  @override
  Widget build(BuildContext context) {
    const ai = MockAiService();
    final docs = MockEcosystem.documents.take(3);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: Theme.of(context).textTheme.titleSmall,
                    children: [
                      const TextSpan(text: 'Documents analysés par '),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: CofidIaBrand(
                          fontSize: Theme.of(context).textTheme.titleSmall?.fontSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: ConfidiaSpacing.md),
              StatusBadge(label: '${MockEcosystem.analyzedDocumentsCount} docs', color: context.palette.secondary),
              const SizedBox(width: ConfidiaSpacing.sm),
              ConfidiaSeeAllButton(onTap: () => context.go('/documents')),
            ],
          ),
          const SizedBox(height: 8),
          ...docs.map((d) {
            final insight = ai.analyzeDocument(d);
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const ConfidiaAiRobot(size: 28),
              title: Text(d.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(insight.summary, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelSmall),
              trailing: StatusBadge(label: insight.priority.label, color: insight.priority.themeColor(context.palette)),
              onTap: () => context.go('/documents/${d.id}'),
            );
          }),
        ],
      ),
    );
  }
}

class _RecentDocsWidget extends StatelessWidget {
  final List<DocumentModel> docs;
  const _RecentDocsWidget({required this.docs});

  @override
  Widget build(BuildContext context) {
    return _DashboardCardShell(
      header: _SectionHeader(title: 'Documents récents', onTap: () => context.go('/documents')),
      body: ListView(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: docs.take(3).map((d) => _DocRow(doc: d)).toList(),
      ),
    );
  }
}

class _DeadlinesWidget extends ConsumerWidget {
  const _DeadlinesWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(calendarProvider);
    final sorted = List.from(events)..sort((a, b) => a.start.compareTo(b.start));

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: 'Prochaines échéances', onTap: () => context.go('/calendar')),
          ...sorted.take(3).map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(width: 3, height: 32, decoration: BoxDecoration(color: e.color ?? context.palette.primary, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 10),
                    Expanded(child: Text(e.title, style: Theme.of(context).textTheme.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
                    Text(DateFormat('d MMM', 'fr_FR').format(e.start), style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _ImportantDocsWidget extends StatelessWidget {
  final List<DocumentModel> docs;
  const _ImportantDocsWidget({required this.docs});

  @override
  Widget build(BuildContext context) {
    return _DashboardCardShell(
      header: _SectionHeader(title: 'Documents importants', onTap: () => context.go('/documents')),
      body: ListView(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: docs.take(4).map((d) => _DocRow(doc: d)).toList(),
      ),
    );
  }
}

class _ActivityWidget extends StatelessWidget {
  final List notifications;
  const _ActivityWidget({required this.notifications});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: 'Activité', onTap: () => context.go('/notifications')),
          ...notifications.take(3).map((n) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.bolt_rounded, size: 18, color: context.palette.primary),
                title: Text(n.title, style: Theme.of(context).textTheme.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(n.message, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
              )),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  const _SectionHeader({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const Spacer(),
          ConfidiaSeeAllButton(onTap: onTap),
        ],
      ),
    );
  }
}

class _DocRow extends StatelessWidget {
  final DocumentModel doc;
  const _DocRow({required this.doc});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.picture_as_pdf_rounded, color: context.palette.primary, size: 20),
      title: Text(doc.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('${doc.category ?? 'Non classé'} · ${doc.fileSizeFormatted}', style: Theme.of(context).textTheme.labelSmall),
      trailing: doc.isImportant ? Icon(Icons.star_rounded, color: context.palette.secondary, size: 16) : null,
      onTap: () => context.go('/documents/${doc.id}'),
    );
  }
}
