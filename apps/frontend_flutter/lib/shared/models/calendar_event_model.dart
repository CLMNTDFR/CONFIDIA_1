import 'package:confidia/core/theme/palette.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import 'week_overview_model.dart';

enum EventType { deadline, meeting, reminder, appointment }

enum CalendarSource { confidia, google, outlook, apple, microsoft365 }

extension CalendarSourceX on CalendarSource {
  String get label => switch (this) {
        CalendarSource.confidia => 'CONFIDIA',
        CalendarSource.google => 'Google',
        CalendarSource.outlook => 'Outlook',
        CalendarSource.apple => 'Apple',
        CalendarSource.microsoft365 => 'Microsoft 365',
      };

  Color themeColor(ConfidiaPalette palette) => switch (this) {
        CalendarSource.confidia => palette.primary,
        CalendarSource.google => const Color(0xFF4285F4),
        CalendarSource.outlook => const Color(0xFF0078D4),
        CalendarSource.apple => const Color(0xFF555555),
        CalendarSource.microsoft365 => const Color(0xFF7B83EB),
      };
}

class CalendarEventModel extends Equatable {
  final String id;
  final String title;
  final String? description;
  final DateTime start;
  final DateTime end;
  final EventType eventType;
  final String? location;
  final bool allDay;
  final Color? color;
  final int? documentId;
  final CalendarSource source;
  final String? paymentId;
  final String? emailId;
  final String calendarGroup;
  final WeekCalendarScope? weekScope;

  const CalendarEventModel({
    required this.id,
    required this.title,
    this.description,
    required this.start,
    required this.end,
    this.eventType = EventType.reminder,
    this.location,
    this.allDay = false,
    this.color,
    this.documentId,
    this.source = CalendarSource.confidia,
    this.paymentId,
    this.emailId,
    this.calendarGroup = 'family',
    this.weekScope,
  });

  factory CalendarEventModel.fromJson(Map<String, dynamic> json) {
    return CalendarEventModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      start: DateTime.parse(json['start'] as String),
      end: DateTime.parse(json['end'] as String),
      eventType: EventType.values.firstWhere(
        (e) => e.name == json['event_type'],
        orElse: () => EventType.reminder,
      ),
      location: json['location'] as String?,
      allDay: json['all_day'] as bool? ?? false,
      color: json['color'] != null ? Color(int.parse(json['color'].toString().replaceFirst('#', '0xFF'))) : null,
      documentId: json['document_id'] as int?,
      source: CalendarSource.values.firstWhere(
        (s) => s.name == json['source'],
        orElse: () => CalendarSource.confidia,
      ),
      paymentId: json['payment_id'] as String?,
      emailId: json['email_id'] as String?,
      calendarGroup: json['calendar_group'] as String? ?? 'family',
      weekScope: json['calendar_scope'] != null
          ? WeekCalendarScope.values.firstWhere((s) => s.name == json['calendar_scope'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
        'event_type': eventType.name,
        'location': location,
        'all_day': allDay,
        'color': color != null ? '#${color!.toARGB32().toRadixString(16).substring(2)}' : null,
        'document_id': documentId,
        'source': source.name,
        'payment_id': paymentId,
        'email_id': emailId,
        'calendar_group': calendarGroup,
        'calendar_scope': weekScope?.name,
      };

  CalendarEventModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? start,
    DateTime? end,
    EventType? eventType,
    String? location,
    bool? allDay,
    Color? color,
    int? documentId,
    CalendarSource? source,
    String? paymentId,
    String? emailId,
    String? calendarGroup,
    WeekCalendarScope? weekScope,
  }) {
    return CalendarEventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      start: start ?? this.start,
      end: end ?? this.end,
      eventType: eventType ?? this.eventType,
      location: location ?? this.location,
      allDay: allDay ?? this.allDay,
      color: color ?? this.color,
      documentId: documentId ?? this.documentId,
      source: source ?? this.source,
      paymentId: paymentId ?? this.paymentId,
      emailId: emailId ?? this.emailId,
      calendarGroup: calendarGroup ?? this.calendarGroup,
      weekScope: weekScope ?? this.weekScope,
    );
  }

  @override
  List<Object?> get props => [id, title, start, end, eventType, calendarGroup];
}
