import 'package:dio/dio.dart';

import '../models/calendar_event_model.dart';

/// Calendrier CONFIDIA : HTTP live, sans événements inventés.
class CalendarApiService {
  final Dio _dio;

  CalendarApiService(this._dio);

  Future<List<CalendarEventModel>> listEvents() async {
    final response = await _dio.get('/calendar/events');
    final items = response.data['items'] as List<dynamic>? ?? const [];
    return items.map((e) => CalendarEventModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<CalendarEventModel> create(CalendarEventModel event) async {
    final response = await _dio.post('/calendar/events', data: _payload(event));
    return CalendarEventModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CalendarEventModel> update(CalendarEventModel event) async {
    final response = await _dio.patch('/calendar/events/${event.id}', data: _payload(event));
    return CalendarEventModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _dio.delete('/calendar/events/$id');
  }

  Map<String, dynamic> _payload(CalendarEventModel event) {
    return {
      'title': event.title,
      'description': event.description,
      'start': event.start.toUtc().toIso8601String(),
      'end': event.end.toUtc().toIso8601String(),
      'event_type': event.eventType.name,
      'location': event.location,
      'all_day': event.allDay,
      if (event.color != null)
        'color': '#${event.color!.toARGB32().toRadixString(16).substring(2)}',
      'calendar_scope': event.weekScope?.name ?? 'family',
    };
  }
}
