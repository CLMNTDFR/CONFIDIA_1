import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/data/mock_ecosystem.dart';
import '../../shared/models/calendar_event_model.dart';
import 'event_type_config.dart';

class CalendarNotifier extends StateNotifier<List<CalendarEventModel>> {
  CalendarNotifier() : super(List.from(MockEcosystem.calendarEvents));

  List<CalendarEventModel> eventsForDay(DateTime day) {
    return state.where((e) =>
        e.start.year == day.year && e.start.month == day.month && e.start.day == day.day).toList()
      ..sort((a, b) => a.start.compareTo(b.start));
  }

  List<CalendarEventModel> filtered({EventType? type}) {
    if (type == null) return List.from(state);
    return state.where((e) => e.eventType == type).toList();
  }

  void add(CalendarEventModel event) => state = [...state, event];

  void update(CalendarEventModel event) {
    state = [for (final e in state) if (e.id == event.id) event else e];
  }

  void delete(String id) => state = state.where((e) => e.id != id).toList();

  String nextId() => 'evt-${DateTime.now().millisecondsSinceEpoch}';

  CalendarEventModel buildEvent({
    String? id,
    required String title,
    String? description,
    required DateTime start,
    required DateTime end,
    required EventType eventType,
    String? location,
    bool allDay = false,
    int? documentId,
  }) {
    return CalendarEventModel(
      id: id ?? nextId(),
      title: title,
      description: description,
      start: start,
      end: end,
      eventType: eventType,
      location: location,
      allDay: allDay,
      color: colorForEventType(eventType),
      documentId: documentId,
    );
  }
}

final calendarProvider = StateNotifierProvider<CalendarNotifier, List<CalendarEventModel>>((ref) {
  return CalendarNotifier();
});

final calendarFilterProvider = StateProvider<EventType?>((ref) => null);
