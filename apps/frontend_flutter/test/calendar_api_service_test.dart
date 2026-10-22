import 'dart:convert';
import 'dart:typed_data';

import 'package:confidia/shared/models/calendar_event_model.dart';
import 'package:confidia/shared/services/calendar_api_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Dio dio;
  late _RecordingAdapter adapter;
  late CalendarApiService api;

  setUp(() {
    adapter = _RecordingAdapter();
    dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'));
    dio.httpClientAdapter = adapter;
    api = CalendarApiService(dio);
  });

  test('listEvents maps items from GET /calendar/events', () async {
    adapter.statusCode = 200;
    adapter.body = jsonEncode({
      'items': [
        {
          'id': '11111111-1111-1111-1111-111111111111',
          'title': 'RDV',
          'start': '2026-09-10T08:00:00Z',
          'end': '2026-09-10T09:00:00Z',
          'event_type': 'appointment',
          'all_day': false,
          'calendar_scope': 'family',
          'source': 'confidia',
        },
      ],
      'total': 1,
    });

    final items = await api.listEvents();
    expect(adapter.method, 'GET');
    expect(adapter.path, '/calendar/events');
    expect(items, hasLength(1));
    expect(items.first.title, 'RDV');
    expect(items.first.calendarGroup, 'family');
    expect(items.first.documentId, isNull);
  });

  test('create posts payload without client id', () async {
    adapter.statusCode = 201;
    adapter.body = jsonEncode({
      'id': '22222222-2222-2222-2222-222222222222',
      'title': 'Dentiste',
      'start': '2026-09-11T08:00:00.000Z',
      'end': '2026-09-11T09:00:00.000Z',
      'event_type': 'appointment',
      'all_day': false,
      'calendar_scope': 'family',
      'source': 'confidia',
    });

    final created = await api.create(
      CalendarEventModel(
        id: 'local',
        title: 'Dentiste',
        start: DateTime.utc(2026, 9, 11, 8),
        end: DateTime.utc(2026, 9, 11, 9),
        eventType: EventType.appointment,
      ),
    );
    expect(adapter.method, 'POST');
    expect(adapter.path, '/calendar/events');
    final sent = jsonDecode(adapter.bodySent!) as Map<String, dynamic>;
    expect(sent.containsKey('id'), isFalse);
    expect(sent['title'], 'Dentiste');
    expect(sent['start'], DateTime.utc(2026, 9, 11, 8).toIso8601String());
    expect(sent['end'], DateTime.utc(2026, 9, 11, 9).toIso8601String());
    expect(sent['calendar_scope'], 'family');
    expect(created.id, '22222222-2222-2222-2222-222222222222');
  });

  test('update and delete hit the event id', () async {
    adapter.statusCode = 200;
    adapter.body = jsonEncode({
      'id': '33333333-3333-3333-3333-333333333333',
      'title': 'Maj',
      'start': '2026-09-11T08:00:00Z',
      'end': '2026-09-11T09:00:00Z',
      'event_type': 'reminder',
      'all_day': false,
      'source': 'confidia',
    });
    final event = CalendarEventModel(
      id: '33333333-3333-3333-3333-333333333333',
      title: 'Maj',
      start: DateTime.utc(2026, 9, 11, 8),
      end: DateTime.utc(2026, 9, 11, 9),
    );
    await api.update(event);
    expect(adapter.method, 'PATCH');
    expect(adapter.path, '/calendar/events/33333333-3333-3333-3333-333333333333');

    adapter.statusCode = 204;
    adapter.body = '';
    await api.delete(event.id);
    expect(adapter.method, 'DELETE');
    expect(adapter.path, '/calendar/events/33333333-3333-3333-3333-333333333333');
  });

  test('HTTP errors are not swallowed', () async {
    adapter.statusCode = 500;
    adapter.body = '{"detail":"boom"}';
    expect(api.listEvents(), throwsA(isA<DioException>()));
  });
}

class _RecordingAdapter implements HttpClientAdapter {
  String? method;
  String? path;
  String? bodySent;
  int statusCode = 200;
  String body = '{}';

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    method = options.method;
    path = options.path;
    if (requestStream != null) {
      final chunks = await requestStream.toList();
      bodySent = utf8.decode(chunks.expand((c) => c).toList());
    } else if (options.data is Map) {
      bodySent = jsonEncode(options.data);
    }
    return ResponseBody.fromString(
      body,
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
