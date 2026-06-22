import 'package:intl/intl.dart';

import '../models/calendar_event_model.dart';
import '../models/week_overview_model.dart';
import '../data/mock_week_overview_events.dart';

abstract final class WeekOverviewService {
  static const _dayLabels = ['LUNDI', 'MARDI', 'MERCREDI', 'JEUDI', 'VENDREDI', 'SAMEDI', 'DIMANCHE'];
  static final _monthLabels = DateFormat('MMM', 'fr_FR');

  static WeekOverview compute({
    required List<CalendarEventModel> events,
    required Set<WeekCalendarScope> scopes,
    DateTime? reference,
  }) {
    final today = reference ?? DateTime.now();
    final weekStart = DateTime(today.year, today.month, today.day - (today.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));

    final scoped = events.where((e) => scopes.contains(MockWeekOverviewEvents.scopeFor(e))).toList();
    final days = List.generate(7, (offset) {
      final day = weekStart.add(Duration(days: offset));
      final dayEvents = scoped.where((e) => _isSameDay(e.start, day)).toList();
      return _buildDay(day, dayEvents);
    });

    return WeekOverview(
      weekStart: weekStart,
      weekEnd: weekEnd,
      days: days,
      activeScopes: scopes,
    );
  }

  static WeekOverview demo({Set<WeekCalendarScope>? scopes}) {
    return compute(
      events: MockWeekOverviewEvents.events,
      scopes: scopes ?? WeekCalendarScope.values.toSet(),
    );
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static WeekDayOverview _buildDay(DateTime day, List<CalendarEventModel> events) {
    final meetings = events.where((e) => e.eventType == EventType.meeting).length;
    final deadlines = events.where((e) => e.eventType == EventType.deadline).length;
    final tasks = events
        .where((e) => e.eventType == EventType.reminder || e.eventType == EventType.appointment)
        .length;
    final total = events.length;
    final score = meetings * 2 + deadlines * 2 + tasks;
    final (level, loadScore) = _resolveWorkload(score, total);

    final month = _monthLabels.format(day).toUpperCase().replaceAll('.', '');

    return WeekDayOverview(
      date: day,
      dayLabel: _dayLabels[day.weekday - 1],
      dateLabel: '${day.day} $month',
      workloadLevel: level,
      totalAppointments: total,
      meetingCount: meetings,
      deadlineCount: deadlines,
      taskCount: tasks,
      loadScore: loadScore,
    );
  }

  static (WorkloadLevel, double) _resolveWorkload(int score, int total) {
    if (score >= 9 || total >= 7) {
      return (WorkloadLevel.busy, (0.72 + total * 0.03).clamp(0.0, 1.0));
    }
    if (score >= 4 || total >= 3) {
      return (WorkloadLevel.medium, (0.38 + total * 0.04).clamp(0.0, 0.68));
    }
    return (WorkloadLevel.calm, (total * 0.08 + 0.1).clamp(0.12, 0.32));
  }
}
