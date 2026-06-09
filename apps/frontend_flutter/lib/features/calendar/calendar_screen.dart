import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../shared/data/mock_data.dart';
import '../../shared/models/calendar_event_model.dart';
import '../../shared/widgets/glass_card.dart';

enum CalendarView { month, week, day }

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarView _view = CalendarView.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();

  List<CalendarEventModel> get _events => MockData.calendarEvents;

  List<CalendarEventModel> _eventsForDay(DateTime day) {
    return _events.where((e) =>
        e.start.year == day.year && e.start.month == day.month && e.start.day == day.day).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    final selectedEvents = _eventsForDay(_selectedDay ?? DateTime.now());

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(ConfidiaSpacing.lg),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - ConfidiaSpacing.lg * 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ViewSelector(
                  view: _view,
                  onChanged: (v) => setState(() => _view = v),
                ),
                const SizedBox(height: ConfidiaSpacing.md),
                if (isWide)
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _buildCalendarWidget()),
                        const SizedBox(width: ConfidiaSpacing.md),
                        Expanded(flex: 2, child: _EventList(events: selectedEvents, title: 'Événements')),
                      ],
                    ),
                  )
                else ...[
                  _buildCalendarWidget(),
                  const SizedBox(height: ConfidiaSpacing.md),
                  _EventList(events: selectedEvents, title: 'Événements du jour'),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCalendarWidget() {
    return switch (_view) {
      CalendarView.month => _buildMonthView(),
      CalendarView.week => _buildWeekView(),
      CalendarView.day => _buildDayView(),
    };
  }

  Widget _buildMonthView() {
    return GlassCard(
      padding: const EdgeInsets.all(ConfidiaSpacing.md),
      child: TableCalendar(
        firstDay: DateTime.utc(2020),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        eventLoader: _eventsForDay,
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
                final dayEvents = _eventsForDay(day);
                final isToday = isSameDay(day, DateTime.now());
                final isSelected = isSameDay(day, _selectedDay);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Material(
                      color: isSelected
                          ? ConfidiaColors.primary.withValues(alpha: 0.08)
                          : Colors.transparent,
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
                                      .map((e) => Container(
                                            margin: const EdgeInsets.only(bottom: 2),
                                            padding: const EdgeInsets.all(3),
                                            decoration: BoxDecoration(
                                              color: (e.color ?? ConfidiaColors.primary).withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(e.title, style: const TextStyle(fontSize: 9), maxLines: 2, overflow: TextOverflow.ellipsis),
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
    final dayEvents = _eventsForDay(day);

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
            ...dayEvents.map((e) => _EventTile(event: e)),
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

class _EventList extends StatelessWidget {
  final List<CalendarEventModel> events;
  final String title;

  const _EventList({required this.events, required this.title});

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
            ...events.map((e) => _EventTile(event: e)),
        ],
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  final CalendarEventModel event;

  const _EventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ConfidiaSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 52,
            decoration: BoxDecoration(
              color: event.color ?? ConfidiaColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: ConfidiaSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  event.allDay
                      ? 'Toute la journée'
                      : '${DateFormat('HH:mm').format(event.start)} · ${DateFormat('HH:mm').format(event.end)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (event.location != null)
                  Text('• ${event.location!}', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
