import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../shared/data/mock_ecosystem.dart';
import '../../shared/models/calendar_event_model.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/provider_chip.dart';
import 'calendar_provider.dart';
import 'event_form_sheet.dart';
import 'event_type_config.dart';

enum CalendarView { month, week, day }

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  CalendarView _view = CalendarView.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();

  List<CalendarEventModel> _eventsForDay(DateTime day, List<CalendarEventModel> events) {
    return events
        .where((e) => e.start.year == day.year && e.start.month == day.month && e.start.day == day.day)
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    final filter = ref.watch(calendarFilterProvider);
    final allEvents = ref.watch(calendarProvider);
    final events = filter == null ? allEvents : allEvents.where((e) => e.eventType == filter).toList();
    final selectedEvents = _eventsForDay(_selectedDay ?? DateTime.now(), events);

    return Stack(
      children: [
        LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(ConfidiaSpacing.lg),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - ConfidiaSpacing.lg * 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                _ViewSelector(view: _view, onChanged: (v) => setState(() => _view = v)),
                const SizedBox(height: ConfidiaSpacing.sm),
                const _ConnectedCalendarsBar(),
                const SizedBox(height: ConfidiaSpacing.sm),
                _TypeLegend(
                    selected: filter,
                    onSelected: (t) => ref.read(calendarFilterProvider.notifier).state = t,
                  ),
                  const SizedBox(height: ConfidiaSpacing.md),
                  if (isWide)
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: _buildCalendarWidget()),
                          const SizedBox(width: ConfidiaSpacing.md),
                          Expanded(
                            flex: 2,
                            child: _EventList(
                              events: selectedEvents,
                              title: 'Événements',
                              onEdit: (e) => showEventFormSheet(context, event: e),
                              onDelete: (e) => _confirmDelete(e),
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    _buildCalendarWidget(),
                    const SizedBox(height: ConfidiaSpacing.md),
                    _EventList(
                      events: selectedEvents,
                      title: 'Événements du jour',
                      onEdit: (e) => showEventFormSheet(context, event: e),
                      onDelete: (e) => _confirmDelete(e),
                    ),
                  ],
                  if (filter != null) ...[
                    const SizedBox(height: ConfidiaSpacing.md),
                    Text(
                      '${events.length} événement(s) de type « ${configFor(filter).label} »',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
        ),
        Positioned(
          right: ConfidiaSpacing.lg,
          bottom: ConfidiaSpacing.lg,
          child: FloatingActionButton.extended(
            onPressed: () => showEventFormSheet(context, initialDay: _selectedDay),
            backgroundColor: ConfidiaColors.primary,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text('Événement', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(CalendarEventModel event) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer l\'événement ?'),
        content: Text('« ${event.title} » sera définitivement supprimé.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: ConfidiaColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
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
    final filter = ref.watch(calendarFilterProvider);
    final allEvents = ref.watch(calendarProvider);
    final events = filter == null ? allEvents : allEvents.where((e) => e.eventType == filter).toList();

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
        rowHeight: 48,
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: ConfidiaColors.accent.withValues(alpha: 0.25),
            shape: BoxShape.circle,
          ),
          selectedDecoration: const BoxDecoration(
            gradient: ConfidiaColors.primaryGradient,
            shape: BoxShape.circle,
          ),
          markerDecoration: const BoxDecoration(
            color: ConfidiaColors.secondary,
            shape: BoxShape.circle,
          ),
          outsideDaysVisible: false,
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
    final filter = ref.watch(calendarFilterProvider);
    final allEvents = ref.watch(calendarProvider);
    final events = filter == null ? allEvents : allEvents.where((e) => e.eventType == filter).toList();
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
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Material(
                      color: isSelected ? ConfidiaColors.primary.withValues(alpha: 0.08) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        onTap: () => setState(() => _selectedDay = day),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isToday ? ConfidiaColors.primary : ConfidiaColors.border(Theme.of(context).brightness == Brightness.dark),
                            ),
                          ),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(6),
                                child: Text(
                                  DateFormat('E\nd', 'fr_FR').format(day),
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: isToday ? ConfidiaColors.primary : null,
                                        fontWeight: isToday ? FontWeight.w700 : null,
                                      ),
                                ),
                              ),
                              Expanded(
                                child: ListView(
                                  padding: const EdgeInsets.all(2),
                                  children: dayEvents
                                      .map((e) => GestureDetector(
                                            onTap: () => showEventFormSheet(context, event: e),
                                            child: Container(
                                              margin: const EdgeInsets.only(bottom: 2),
                                              padding: const EdgeInsets.all(3),
                                              decoration: BoxDecoration(
                                                color: (e.color ?? ConfidiaColors.primary).withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(e.title, style: const TextStyle(fontSize: 9), maxLines: 2, overflow: TextOverflow.ellipsis),
                                            ),
                                          ))
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
    final filter = ref.watch(calendarFilterProvider);
    final allEvents = ref.watch(calendarProvider);
    final events = filter == null ? allEvents : allEvents.where((e) => e.eventType == filter).toList();
    final dayEvents = _eventsForDay(day, events);

    return GlassCard(
      padding: const EdgeInsets.all(ConfidiaSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(day), style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: ConfidiaSpacing.lg),
          if (dayEvents.isEmpty)
            const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('Aucun événement ce jour')))
          else
            ...dayEvents.map((e) => _EventTile(
                  event: e,
                  onTap: () => showEventFormSheet(context, event: e),
                  onDelete: () => _confirmDelete(e),
                )),
        ],
      ),
    );
  }
}

class _ConnectedCalendarsBar extends StatelessWidget {
  const _ConnectedCalendarsBar();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.sync_rounded, size: 16, color: ConfidiaColors.secondary),
          const SizedBox(width: 8),
          Text('Calendriers connectés', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(width: 12),
          ...MockEcosystem.connectedCalendars.map((c) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: CalendarSourceChip(source: c.$1, compact: true),
              )),
          const Spacer(),
          Text('Vue fusionnée', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: ConfidiaColors.primary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ViewSelector extends StatelessWidget {
  final CalendarView view;
  final ValueChanged<CalendarView> onChanged;

  const _ViewSelector({required this.view, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<CalendarView>(
      segments: const [
        ButtonSegment(value: CalendarView.month, label: Text('Mois'), icon: Icon(Icons.calendar_view_month_rounded, size: 16)),
        ButtonSegment(value: CalendarView.week, label: Text('Semaine'), icon: Icon(Icons.calendar_view_week_rounded, size: 16)),
        ButtonSegment(value: CalendarView.day, label: Text('Jour'), icon: Icon(Icons.calendar_today_rounded, size: 16)),
      ],
      selected: {view},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}

class _TypeLegend extends StatelessWidget {
  final EventType? selected;
  final ValueChanged<EventType?> onSelected;

  const _TypeLegend({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          FilterChip(
            label: const Text('Tous'),
            selected: selected == null,
            onSelected: (_) => onSelected(null),
          ),
          const SizedBox(width: 6),
          ...eventTypeConfigs.map((cfg) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  avatar: Icon(cfg.icon, size: 14, color: selected == cfg.type ? Colors.white : cfg.color),
                  label: Text(cfg.label),
                  selected: selected == cfg.type,
                  selectedColor: cfg.color,
                  showCheckmark: false,
                  labelStyle: TextStyle(
                    color: selected == cfg.type ? Colors.white : null,
                    fontWeight: selected == cfg.type ? FontWeight.w600 : null,
                  ),
                  onSelected: (_) => onSelected(cfg.type),
                ),
              )),
        ],
      ),
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

class _EventTile extends StatelessWidget {
  final CalendarEventModel event;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const _EventTile({required this.event, this.onTap, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final cfg = configFor(event.eventType);

    return Padding(
      padding: const EdgeInsets.only(bottom: ConfidiaSpacing.sm),
      child: Material(
        color: cfg.color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4,
                  height: 52,
                  decoration: BoxDecoration(color: event.color ?? cfg.color, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(width: ConfidiaSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CalendarSourceChip(source: event.source, compact: true),
                          const SizedBox(width: 6),
                          Icon(cfg.icon, size: 14, color: cfg.color),
                          const SizedBox(width: 4),
                          Text(cfg.label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cfg.color, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(event.title, style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 2),
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
