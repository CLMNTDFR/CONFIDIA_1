import 'package:confidia/core/theme/palette.dart';
import 'package:confidia/features/calendar/event_type_config.dart';
import 'package:confidia/shared/models/calendar_event_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('each EventType has a config for blue and rose palettes', () {
    for (final palette in [ConfidiaPalette.blue, ConfidiaPalette.rose]) {
      for (final type in EventType.values) {
        final config = configFor(type, palette);
        expect(config.type, type);
        expect(config.label, isNotEmpty);
        expect(colorForEventType(type, palette), config.color);
      }
    }
  });

  test('deadline uses brand primary', () {
    expect(colorForEventType(EventType.deadline, ConfidiaPalette.blue), ConfidiaPalette.blue.primary);
    expect(colorForEventType(EventType.deadline, ConfidiaPalette.rose), ConfidiaPalette.rose.primary);
  });

  test('fromJson accepts UUID document_id without crashing', () {
    final event = CalendarEventModel.fromJson({
      'id': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      'title': 'Lié',
      'start': '2026-09-10T08:00:00Z',
      'end': '2026-09-10T09:00:00Z',
      'event_type': 'reminder',
      'document_id': 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
      'calendar_scope': 'family',
      'source': 'confidia',
    });
    expect(event.documentId, isNull);
    expect(event.calendarGroup, 'family');
  });

  test('toJson sends the UTC instant with a Z suffix', () {
    final local = DateTime(2026, 10, 18, 15);
    final event = CalendarEventModel(
      id: 'evt',
      title: 'Heure',
      start: local,
      end: local.add(const Duration(hours: 1)),
      eventType: EventType.reminder,
    );
    final json = event.toJson();
    expect(json['start'], local.toUtc().toIso8601String());
    expect(json['end'], local.add(const Duration(hours: 1)).toUtc().toIso8601String());
    expect((json['start'] as String).endsWith('Z'), isTrue);
  });

  test('fromJson keeps a UTC instant on the same local clock time', () {
    final local = DateTime(2026, 10, 18, 15);
    final event = CalendarEventModel.fromJson({
      'id': 'evt-offset',
      'title': 'Offset',
      'start': local.toUtc().toIso8601String(),
      'end': local.add(const Duration(hours: 1)).toUtc().toIso8601String(),
      'event_type': 'reminder',
    });
    expect(event.start, local);
    expect(event.end, local.add(const Duration(hours: 1)));
    expect(event.start.isUtc, isFalse);
  });

  test('fromJson converts UTC instants to local civil time', () {
    final event = CalendarEventModel.fromJson({
      'id': 'evt-local',
      'title': 'Local',
      'start': '2026-09-08T00:00:00Z',
      'end': '2026-09-08T01:00:00Z',
      'event_type': 'reminder',
    });
    expect(event.start.isUtc, isFalse);
    expect(event.end.isUtc, isFalse);
  });

  test('fromJson keeps integer document_id from mocks', () {
    final event = CalendarEventModel.fromJson({
      'id': 'evt-1',
      'title': 'Mock',
      'start': '2026-09-10T08:00:00Z',
      'end': '2026-09-10T09:00:00Z',
      'event_type': 'deadline',
      'document_id': 1,
      'calendar_group': 'club',
    });
    expect(event.documentId, 1);
    expect(event.calendarGroup, 'club');
  });
}
