import 'package:equatable/equatable.dart';

enum WorkloadLevel { calm, medium, busy }

enum WeekCalendarScope { personal, family, professional }

extension WorkloadLevelX on WorkloadLevel {
  String get label => switch (this) {
        WorkloadLevel.calm => 'Calme',
        WorkloadLevel.medium => 'Moyenne',
        WorkloadLevel.busy => 'Chargée',
      };
}

extension WeekCalendarScopeX on WeekCalendarScope {
  String get label => switch (this) {
        WeekCalendarScope.personal => 'Personnel',
        WeekCalendarScope.family => 'Familial',
        WeekCalendarScope.professional => 'Professionnel',
      };
}

class WeekDayOverview extends Equatable {
  final DateTime date;
  final String dayLabel;
  final String dateLabel;
  final WorkloadLevel workloadLevel;
  final int totalAppointments;
  final int meetingCount;
  final int deadlineCount;
  final int taskCount;
  final double loadScore;

  const WeekDayOverview({
    required this.date,
    required this.dayLabel,
    required this.dateLabel,
    required this.workloadLevel,
    required this.totalAppointments,
    required this.meetingCount,
    required this.deadlineCount,
    required this.taskCount,
    required this.loadScore,
  });

  factory WeekDayOverview.fromJson(Map<String, dynamic> json) {
    return WeekDayOverview(
      date: DateTime.parse(json['date'] as String),
      dayLabel: json['day_label'] as String,
      dateLabel: json['date_label'] as String,
      workloadLevel: WorkloadLevel.values.firstWhere(
        (l) => l.name == json['workload_level'],
        orElse: () => WorkloadLevel.calm,
      ),
      totalAppointments: json['total_appointments'] as int,
      meetingCount: json['meeting_count'] as int,
      deadlineCount: json['deadline_count'] as int,
      taskCount: json['task_count'] as int,
      loadScore: (json['load_score'] as num).toDouble(),
    );
  }

  @override
  List<Object?> get props => [date, workloadLevel, totalAppointments];
}

class WeekOverview extends Equatable {
  final DateTime weekStart;
  final DateTime weekEnd;
  final List<WeekDayOverview> days;
  final Set<WeekCalendarScope> activeScopes;

  const WeekOverview({
    required this.weekStart,
    required this.weekEnd,
    required this.days,
    required this.activeScopes,
  });

  factory WeekOverview.fromJson(Map<String, dynamic> json) {
    return WeekOverview(
      weekStart: DateTime.parse(json['week_start'] as String),
      weekEnd: DateTime.parse(json['week_end'] as String),
      days: (json['days'] as List<dynamic>)
          .map((d) => WeekDayOverview.fromJson(d as Map<String, dynamic>))
          .toList(),
      activeScopes: (json['active_scopes'] as List<dynamic>)
          .map((s) => WeekCalendarScope.values.firstWhere((v) => v.name == s))
          .toSet(),
    );
  }

  @override
  List<Object?> get props => [weekStart, days, activeScopes];
}
