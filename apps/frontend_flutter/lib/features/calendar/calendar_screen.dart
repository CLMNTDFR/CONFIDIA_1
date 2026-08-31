import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/theme_context.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/tokens/tokens.dart';
import '../../shared/brands/brand_assets.dart';
import '../../shared/data/mock_ecosystem.dart';
import '../../shared/models/calendar_event_model.dart';
import '../../shared/widgets/brand_icon.dart';
import '../../shared/widgets/confidia_confirm_dialog.dart';
import '../../shared/widgets/confidia_demo_badge.dart';
import '../../shared/widgets/confidia_glow_button.dart';
import '../../shared/widgets/confidia_glow_chip.dart';
import '../../shared/widgets/confidia_tappable.dart';
import '../../shared/widgets/mobile_shell_insets.dart';
import '../../shared/widgets/confidia_glow_segmented.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/provider_chip.dart';
import '../../shared/widgets/confidia_snackbar.dart';
import '../../shared/widgets/planning_ai_panel.dart';
import 'calendar_provider.dart';
import 'event_form_sheet.dart';
import 'event_type_config.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  CalendarView _view = CalendarView.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();
  bool _filtersOpen = false;

  void _shiftDay(int delta) {
    setState(() {
      final base = _selectedDay ?? DateTime.now();
      final next = DateTime(base.year, base.month, base.day + delta);
      _selectedDay = next;
      _focusedDay = next;
    });
  }

  List<CalendarEventModel> _eventsForDay(DateTime day, List<CalendarEventModel> events) {
    return events
        .where((e) => e.start.year == day.year && e.start.month == day.month && e.start.day == day.day)
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
  }

  List<CalendarEventModel> _visibleEvents(WidgetRef ref) {
    ref.watch(calendarProvider);
    final groups = ref.watch(activeCalendarGroupsProvider);
    final filter = ref.watch(calendarFilterProvider);
    return ref.read(calendarProvider.notifier).filtered(type: filter, groups: groups);
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    final filter = ref.watch(calendarFilterProvider);
    final events = _visibleEvents(ref);
    final selectedEvents = _eventsForDay(_selectedDay ?? DateTime.now(), events);
    final planning = ref.watch(calendarPlanningProvider);
    final planningNotifier = ref.read(calendarPlanningProvider.notifier);
    final isMobileShell = ConfidiaMobileShell.isMobileShell(context);

    return Stack(
      children: [
        LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: ConfidiaInsets.pageWithExtra(
              context,
              extraBottom: isMobileShell ? ConfidiaMobileShell.fabScrollClearance() : 0,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - ConfidiaSpacing.lg * 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    _ViewSelector(
                      view: _view,
                      onChanged: (v) {
                        setState(() => _view = v);
                        ref.read(calendarViewProvider.notifier).state = v;
                      },
                    ),
                    Row(
                      children: [
                        const Spacer(),
                        Semantics(
                          button: true,
                          label: 'Filtres',
                          child: ConfidiaGlowChip(
                            label: '',
                            icon: _filtersOpen
                                ? Icons.expand_less_rounded
                                : Icons.filter_list_rounded,
                            selected: _filtersOpen || filter != null,
                            onTap: () => setState(() => _filtersOpen = !_filtersOpen),
                          ),
                        ),
                        if (!isMobileShell) ...[
                          const SizedBox(width: ConfidiaSpacing.sm),
                          ConfidiaGlowButton(
                            label: 'Événement',
                            icon: Icons.add_rounded,
                            onPressed: () => showEventFormSheet(context, initialDay: _selectedDay),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                AnimatedSize(
                  duration: AppDurations.medium,
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: _filtersOpen
                      ? Padding(
                          padding: const EdgeInsets.only(top: ConfidiaSpacing.sm),
                          child: _CalendarFiltersPanel(
                            selectedType: filter,
                            onTypeSelected: (t) =>
                                ref.read(calendarFilterProvider.notifier).state = t,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                  const SizedBox(height: ConfidiaSpacing.md),
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _buildCalendarWidget()),
                        const SizedBox(width: ConfidiaSpacing.md),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _EventList(
                                events: selectedEvents,
                                title: 'Événements',
                                onEdit: (e) => showEventDetailSheet(context, event: e),
                                onDelete: (e) => _confirmDelete(e),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  else ...[
                    _buildCalendarWidget(),
                    if (_view != CalendarView.day) ...[
                      const SizedBox(height: ConfidiaSpacing.md),
                      _EventList(
                        events: selectedEvents,
                        title: _view == CalendarView.week ? 'Événements de la semaine' : 'Événements',
                        onEdit: (e) => showEventDetailSheet(context, event: e),
                        onDelete: (e) => _confirmDelete(e),
                      ),
                    ],
                  ],
                  if (filter != null) ...[
                    const SizedBox(height: ConfidiaSpacing.md),
                    Text(
                      '${events.length} événement(s) de type « ${configFor(filter, context.palette).label} »',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: ConfidiaSpacing.lg),
                  PlanningAiPanel(
                    proposal: planning.proposal,
                    loading: planning.loading,
                    analyzeLabel: planningNotifier.analyzeLabelFor(_view),
                    onAnalyze: planningNotifier.analyze,
                    onRegenerate: planningNotifier.regenerate,
                    onAccept: () {
                      context.showConfidiaSnack('Proposition appliquée au calendrier', type: ConfidiaSnackType.success);
                      planningNotifier.clear();
                    },
                    onReject: planningNotifier.clear,
                    onRefine: planningNotifier.refine,
                  ),
                ],
              ),
            ),
          );
        },
        ),
        if (isMobileShell)
          Positioned(
            right: ConfidiaSpacing.lg,
            bottom: ConfidiaMobileShell.fabBottom(context),
            child: ConfidiaGlowButton(
              label: 'Événement',
              icon: Icons.add_rounded,
              onPressed: () => showEventFormSheet(context, initialDay: _selectedDay),
            ),
          ),
      ],
    );
  }

  Future<void> _confirmDelete(CalendarEventModel event) async {
    final ok = await showConfidiaConfirmDialog(
      context,
      title: 'Supprimer l\'événement ?',
      message: '« ${event.title} » sera définitivement supprimé.',
      confirmLabel: 'Supprimer',
      icon: Icons.delete_outline_rounded,
      destructive: true,
    );
    if (ok == true) ref.read(calendarProvider.notifier).delete(event.id);
  }

  Widget _buildCalendarWidget() {
    return switch (_view) {
      CalendarView.month => _buildMonthView(),
      CalendarView.week => _buildWeekView(),
      CalendarView.day => _buildDayView(),
    };
  }

  Widget _buildMonthView() {
    final events = _visibleEvents(ref);

    return GlassCard(
      padding: const EdgeInsets.all(ConfidiaSpacing.md),
      child: TableCalendar(
        firstDay: DateTime.utc(2020),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        eventLoader: (day) {
          final dayEvents = events.where((e) =>
              e.start.year == day.year && e.start.month == day.month && e.start.day == day.day).toList();
          return dayEvents;
        },
        locale: 'fr_FR',
        rowHeight: 52,
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: context.palette.accent.withValues(alpha: 0.25),
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            gradient: context.palette.primaryGradient,
            shape: BoxShape.circle,
          ),
          markersMaxCount: 4,
          markerSize: 6,
          markerMargin: const EdgeInsets.symmetric(horizontal: 4),
          outsideDaysVisible: false,
        ),
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, day, events) {
            if (events.isEmpty) return const SizedBox.shrink();
            return _DayEventMarkers(events: events.cast<CalendarEventModel>());
          },
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: Theme.of(context).textTheme.titleLarge!,
        ),
        onDaySelected: (selected, focused) => setState(() {
          _selectedDay = selected;
          _focusedDay = focused;
        }),
        onPageChanged: (focused) => _focusedDay = focused,
      ),
    );
  }

  Widget _buildWeekView() {
    final events = _visibleEvents(ref);
    final startOfWeek = _focusedDay.subtract(Duration(days: _focusedDay.weekday - 1));
    final days = List.generate(7, (i) => startOfWeek.add(Duration(days: i)));

    return GlassCard(
      padding: const EdgeInsets.all(ConfidiaSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () => setState(() => _focusedDay = _focusedDay.subtract(const Duration(days: 7))),
              ),
              Text('Semaine du ${DateFormat('d MMM', 'fr_FR').format(startOfWeek)}', style: Theme.of(context).textTheme.titleMedium),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: () => setState(() => _focusedDay = _focusedDay.add(const Duration(days: 7))),
              ),
            ],
          ),
          SizedBox(
            height: 220,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: days.map((day) {
                final dayEvents = events.where((e) =>
                    e.start.year == day.year && e.start.month == day.month && e.start.day == day.day).toList();
                final isToday = isSameDay(day, DateTime.now());
                final isSelected = isSameDay(day, _selectedDay);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Material(
                      color: isSelected ? context.palette.primary.withValues(alpha: 0.08) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => setState(() => _selectedDay = day),
                        mouseCursor: SystemMouseCursors.click,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isToday ? context.palette.primary : ConfidiaColors.border(Theme.of(context).brightness == Brightness.dark),
                            ),
                          ),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  DateFormat('E\nd', 'fr_FR').format(day),
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: isToday ? context.palette.primary : null,
                                        fontWeight: isToday ? FontWeight.w700 : null,
                                      ),
                                ),
                              ),
                              Expanded(
                                child: ListView(
                                  padding: const EdgeInsets.all(4),
                                  children: dayEvents
                                      .map((e) {
                                        final typeColor = eventColor(e, context.palette);
                                        final chipRadius = BorderRadius.circular(8);
                                        return ConfidiaTappable(
                                          onTap: () => showEventDetailSheet(context, event: e),
                                          pressScale: 0.97,
                                          borderRadius: chipRadius,
                                          child: Container(
                                            margin: const EdgeInsets.only(bottom: 4),
                                            padding: const EdgeInsets.only(left: 4, right: 4, top: 4, bottom: 4),
                                            decoration: BoxDecoration(
                                              color: typeColor.withValues(alpha: 0.14),
                                              borderRadius: chipRadius,
                                              border: Border(left: BorderSide(color: typeColor, width: 2)),
                                            ),
                                            child: Text(
                                              e.title,
                                              style: TextStyle(fontSize: 9, color: typeColor.withValues(alpha: 0.95), fontWeight: FontWeight.w600),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        );
                                      })
                                      .toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayView() {
    final day = _selectedDay ?? DateTime.now();
    final events = _visibleEvents(ref);
    final dayEvents = _eventsForDay(day, events);

    return GlassCard(
      padding: const EdgeInsets.all(ConfidiaSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () => _shiftDay(-1),
                tooltip: 'Jour précédent',
              ),
              Expanded(
                child: Text(
                  DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(day),
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: () => _shiftDay(1),
                tooltip: 'Jour suivant',
              ),
            ],
          ),
          const SizedBox(height: ConfidiaSpacing.md),
          if (dayEvents.isEmpty)
            const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('Aucun événement ce jour')))
          else
            ...dayEvents.map((e) => _EventTile(
                  event: e,
                  onTap: () => showEventDetailSheet(context, event: e),
                  onDelete: () => _confirmDelete(e),
                )),
        ],
      ),
    );
  }
}

class _CalendarFiltersPanel extends ConsumerWidget {
  final EventType? selectedType;
  final ValueChanged<EventType?> onTypeSelected;

  const _CalendarFiltersPanel({
    required this.selectedType,
    required this.onTypeSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final active = ref.watch(activeCalendarGroupsProvider);
    final secondary = AppColors.textSecondary(isDark);
    final typeLabel = selectedType == null
        ? 'Tous les types'
        : configFor(selectedType!, context.palette).label;
    final agendaLabel = active.length == 1
        ? calendarGroups.firstWhere((g) => g.id == active.first).label
        : '${active.length} agendas';

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Filtres',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$agendaLabel · $typeLabel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: secondary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
              if (selectedType != null || active.length != 1 || !active.contains('family'))
                ConfidiaTappable(
                  onTap: () {
                    ref.read(calendarFilterProvider.notifier).state = null;
                    ref.read(activeCalendarGroupsProvider.notifier).state = {'family'};
                    ref.read(calendarPlanningProvider.notifier).clear();
                  },
                  borderRadius: AppRadius.smAll,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      'Réinitialiser',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: context.palette.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          _FilterHairline(isDark: isDark),
          const SizedBox(height: 16),
          _FilterSectionLabel(label: 'Agendas Confidia', icon: Icons.calendar_month_rounded),
          const SizedBox(height: 10),
          const _AgendaSelector(),
          if (active.length > 1) ...[
            const SizedBox(height: 8),
            Text(
              'Analyse IA sur les ${active.length} agendas sélectionnés',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: secondary),
            ),
          ],
          const SizedBox(height: 18),
          _FilterHairline(isDark: isDark),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(
                child: _FilterSectionLabel(
                  label: 'Sources connectées',
                  icon: Icons.cloud_sync_rounded,
                  demo: true,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: AppRadius.smAll,
                  color: ConfidiaColors.success.withValues(alpha: isDark ? 0.14 : 0.1),
                  border: Border.all(
                    color: ConfidiaColors.success.withValues(alpha: 0.28),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: ConfidiaColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Vue fusionnée',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: ConfidiaColors.success,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                            letterSpacing: 0.2,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _ConnectedSourcesRow(),
          const SizedBox(height: 18),
          _FilterHairline(isDark: isDark),
          const SizedBox(height: 16),
          const _FilterSectionLabel(label: 'Type d\'événement', icon: Icons.tune_rounded),
          const SizedBox(height: 12),
          _TypeFilterRow(selected: selectedType, onSelected: onTypeSelected),
        ],
      ),
    );
  }
}

class _FilterHairline extends StatelessWidget {
  final bool isDark;

  const _FilterHairline({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: AppColors.borderInk(isDark).withValues(alpha: AppOpacity.borderSubtle),
    );
  }
}

class _FilterSectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool demo;

  const _FilterSectionLabel({required this.label, required this.icon, this.demo = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary = AppColors.textSecondary(isDark);

    return Row(
      children: [
        Icon(icon, size: 14, color: secondary.withValues(alpha: 0.85)),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: secondary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.15,
                fontSize: 11,
              ),
        ),
        if (demo) ...[
          const SizedBox(width: 8),
          const ConfidiaDemoBadge(compact: true),
        ],
      ],
    );
  }
}

class _AgendaSelector extends ConsumerWidget {
  const _AgendaSelector();

  IconData _iconFor(String id) => switch (id) {
        'family' => Icons.family_restroom_rounded,
        'club' => Icons.sports_soccer_rounded,
        _ => Icons.calendar_today_rounded,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final active = ref.watch(activeCalendarGroupsProvider);
    final ink = isDark ? Colors.white : Colors.black;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: AppRadius.mdAll,
        color: ink.withValues(alpha: isDark ? 0.05 : 0.04),
        border: Border.fromBorderSide(AppBorders.standard(isDark)),
      ),
      child: Row(
        children: calendarGroups.map((g) {
          final selected = active.contains(g.id);
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Material(
                color: Colors.transparent,
                borderRadius: AppRadius.smAll,
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    final next = Set<String>.from(active);
                    if (selected) {
                      if (next.length > 1) next.remove(g.id);
                    } else {
                      next.add(g.id);
                    }
                    ref.read(activeCalendarGroupsProvider.notifier).state = next;
                    ref.read(calendarPlanningProvider.notifier).clear();
                  },
                  borderRadius: AppRadius.smAll,
                  hoverColor: ink.withValues(
                    alpha: isDark ? AppOpacity.hoverInkDark : AppOpacity.hoverInkLight,
                  ),
                  child: AnimatedContainer(
                    duration: AppDurations.quick,
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.smAll,
                      color: selected ? AppColors.surface2(isDark) : Colors.transparent,
                      border: Border.all(
                        color: selected
                            ? AppColors.borderInk(isDark).withValues(alpha: AppOpacity.borderMedium)
                            : Colors.transparent,
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _iconFor(g.id),
                          size: 16,
                          color: selected
                              ? AppColors.textPrimary(isDark)
                              : AppColors.textSecondary(isDark),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          g.label,
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                color: selected
                                    ? AppColors.textPrimary(isDark)
                                    : AppColors.textSecondary(isDark),
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ConnectedSourcesRow extends ConsumerWidget {
  const _ConnectedSourcesRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demo = ref.watch(authStateProvider).isDemoSession;
    final sources = demo ? MockEcosystem.connectedCalendars : const <(CalendarSource, bool, int)>[];

    if (sources.isEmpty) {
      return Text(
        'Aucun agenda externe. Le calendrier CONFIDIA est interne : ajoutez vos rendez-vous ici.',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = 8.0;
        final tileWidth = ((constraints.maxWidth - gap * (sources.length - 1)) / sources.length)
            .clamp(72.0, 120.0);

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < sources.length; i++) ...[
                if (i > 0) SizedBox(width: gap),
                SizedBox(
                  width: tileWidth,
                  child: _ConnectedSourceTile(
                    source: sources[i].$1,
                    eventCount: sources[i].$3,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ConnectedSourceTile extends StatelessWidget {
  final CalendarSource source;
  final int eventCount;

  const _ConnectedSourceTile({
    required this.source,
    required this.eventCount,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = source.themeColor(context.palette);
    final secondary = AppColors.textSecondary(isDark);

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
      decoration: BoxDecoration(
        borderRadius: AppRadius.mdAll,
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: isDark ? 0.04 : 0.03),
        border: Border.fromBorderSide(AppBorders.standard(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: AppRadius.smAll,
              color: color.withValues(alpha: isDark ? 0.16 : 0.1),
            ),
            child: BrandIcon(
              assetPath: source.logoAsset,
              fallbackIcon: Icons.calendar_month_rounded,
              fallbackColor: color,
              size: 14,
              borderRadius: 4,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            source.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary(isDark),
                ),
          ),
          const SizedBox(height: 2),
          Text(
            '$eventCount évts',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  color: secondary,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}

class _TypeFilterRow extends StatelessWidget {
  final EventType? selected;
  final ValueChanged<EventType?> onSelected;

  const _TypeFilterRow({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final configs = eventTypeConfigs(context.palette);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          _TypeFilterChip(
            label: 'Tous',
            selected: selected == null,
            onTap: () => onSelected(null),
          ),
          const SizedBox(width: 8),
          for (var i = 0; i < configs.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            _TypeFilterChip(
              label: configs[i].label,
              icon: configs[i].icon,
              accent: configs[i].color,
              selected: selected == configs[i].type,
              onTap: () => onSelected(configs[i].type),
            ),
          ],
        ],
      ),
    );
  }
}

class _TypeFilterChip extends StatefulWidget {
  final String label;
  final IconData? icon;
  final Color? accent;
  final bool selected;
  final VoidCallback onTap;

  const _TypeFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.accent,
  });

  @override
  State<_TypeFilterChip> createState() => _TypeFilterChipState();
}

class _TypeFilterChipState extends State<_TypeFilterChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? Colors.white : Colors.black;
    final accent = widget.accent;
    final selected = widget.selected;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.mdAll,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: AppRadius.mdAll,
          hoverColor: ink.withValues(
            alpha: isDark ? AppOpacity.hoverInkDark : AppOpacity.hoverInkLight,
          ),
          child: AnimatedContainer(
            duration: AppDurations.quick,
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: AppRadius.mdAll,
              color: selected
                  ? AppColors.surface2(isDark)
                  : _hovered
                      ? ink.withValues(alpha: isDark ? 0.06 : 0.04)
                      : (isDark ? AppColors.darkSurface0 : AppColors.lightSurface1),
              border: Border.fromBorderSide(
                selected
                    ? AppBorders.standard(isDark, alpha: AppOpacity.borderMedium)
                    : AppBorders.standard(isDark),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (accent != null) ...[
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                ] else if (widget.icon != null) ...[
                  Icon(widget.icon, size: 14, color: AppColors.textSecondary(isDark)),
                  const SizedBox(width: 6),
                ],
                Text(
                  widget.label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected
                            ? AppColors.textPrimary(isDark)
                            : AppColors.textSecondary(isDark),
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

class _ViewSelector extends StatelessWidget {
  final CalendarView view;
  final ValueChanged<CalendarView> onChanged;

  const _ViewSelector({required this.view, required this.onChanged});

  static const _segments = [
    ConfidiaGlowSegment(value: CalendarView.month, label: 'Mois', icon: Icons.calendar_view_month_rounded),
    ConfidiaGlowSegment(value: CalendarView.week, label: 'Semaine', icon: Icons.calendar_view_week_rounded),
    ConfidiaGlowSegment(value: CalendarView.day, label: 'Jour', icon: Icons.calendar_today_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return ConfidiaGlowSegmentedControl<CalendarView>(
      value: view,
      segments: _segments,
      onChanged: onChanged,
    );
  }
}

class _EventList extends StatelessWidget {
  final List<CalendarEventModel> events;
  final String title;
  final ValueChanged<CalendarEventModel> onEdit;
  final ValueChanged<CalendarEventModel> onDelete;

  const _EventList({required this.events, required this.title, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: ConfidiaSpacing.md),
          if (events.isEmpty)
            Text('Aucun événement', style: Theme.of(context).textTheme.bodySmall)
          else
            ...events.map((e) => _EventTile(event: e, onTap: () => onEdit(e), onDelete: () => onDelete(e))),
        ],
      ),
    );
  }
}

class _DayEventMarkers extends StatelessWidget {
  final List<CalendarEventModel> events;

  const _DayEventMarkers({required this.events});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final visible = events.take(3).toList();
    final overflow = events.length - visible.length;

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final event in visible)
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: eventColor(event, context.palette),
                shape: BoxShape.circle,
              ),
            ),
          if (overflow > 0)
            Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Text(
                '+$overflow',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 7,
                      fontWeight: FontWeight.w700,
                      color: ConfidiaColors.textSecondary(isDark),
                    ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  final CalendarEventModel event;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const _EventTile({required this.event, this.onTap, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cfg = configFor(event.eventType, context.palette);
    final fill = isDark ? AppColors.darkSurface0 : AppColors.lightSurface1;

    return Padding(
      padding: const EdgeInsets.only(bottom: ConfidiaSpacing.sm),
      child: Material(
        color: fill,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.mdAll,
          side: AppBorders.standard(isDark),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          mouseCursor: onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
          borderRadius: AppRadius.mdAll,
          child: Padding(
            padding: EdgeInsets.fromLTRB(8, 8, onDelete != null ? 4 : 8, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4,
                  height: 52,
                  decoration: BoxDecoration(color: cfg.color, borderRadius: BorderRadius.circular(8)),
                ),
                const SizedBox(width: ConfidiaSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Icon(cfg.icon, size: 14, color: cfg.color),
                          Text(
                            cfg.label,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: cfg.color,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          if (event.source != CalendarSource.confidia)
                            CalendarSourceChip(source: event.source, compact: true),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(event.title, style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 4),
                      Text(
                        event.allDay
                            ? 'Toute la journée'
                            : '${DateFormat('HH:mm').format(event.start)} · ${DateFormat('HH:mm').format(event.end)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (event.location != null) Text('• ${event.location!}', style: Theme.of(context).textTheme.bodySmall),
                      if (event.description != null && event.description!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(event.description!, style: Theme.of(context).textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                  ),
                ),
                if (onDelete != null)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    onPressed: onDelete,
                    tooltip: 'Supprimer',
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
