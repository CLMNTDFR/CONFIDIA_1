import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum EventType { deadline, meeting, reminder, appointment }

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
    );
  }

  @override
  List<Object?> get props => [id, title, start];
}
