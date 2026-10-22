import 'dart:convert';
import 'dart:typed_data';

import 'package:confidia/core/api/api_client.dart';
import 'package:confidia/core/auth/auth_provider.dart';
import 'package:confidia/features/documents/documents_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/session_containers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('live documentsProvider maps GET /documents/ items', () async {
    final storage = FlutterSecureStorage();
    final client = ApiClient(storage: storage);
    await client.configureBaseUrl('http://localhost/api/v1');
    client.dio.httpClientAdapter = _DocumentsAdapter();

    final container = ProviderContainer(
      overrides: [
        authStateProvider.overrideWith((ref) => liveAuthNotifier()),
        apiClientProvider.overrideWith((ref) => client),
      ],
    );
    addTearDown(container.dispose);

    await container.read(documentsProvider.notifier).refresh();
    final items = container.read(documentsProvider).items;
    expect(items, hasLength(1));
    expect(items.first.id, '11111111-1111-1111-1111-111111111111');
    expect(items.first.title, 'Facture EDF');
    expect(container.read(documentsProvider).error, isNull);
  });

  test('delete lists the document in trash until purge', () async {
    final storage = FlutterSecureStorage();
    final client = ApiClient(storage: storage);
    await client.configureBaseUrl('http://localhost/api/v1');
    final adapter = _TrashAdapter();
    client.dio.httpClientAdapter = adapter;

    final container = ProviderContainer(
      overrides: [
        authStateProvider.overrideWith((ref) => liveAuthNotifier()),
        apiClientProvider.overrideWith((ref) => client),
      ],
    );
    addTearDown(container.dispose);

    await container.read(documentsProvider.notifier).refresh();
    const id = '11111111-1111-1111-1111-111111111111';
    expect(await container.read(documentsProvider.notifier).deleteDocument(id), isNull);
    expect(container.read(documentsProvider).items, isEmpty);

    await container.read(documentsProvider.notifier).refreshTrash();
    final trashed = container.read(documentsProvider).trash.single;
    expect(trashed.id, id);
    expect(trashed.deletedAt, isNotNull);

    final links = await container.read(documentsProvider.notifier).eventLinks(id);
    expect(links.error, isNull);
    expect(links.links, hasLength(1));
    expect(
      await container.read(documentsProvider.notifier).purgeDocument(id, [
        const DocumentPurgeDecision(eventId: 'evt-1', action: 'keep'),
      ]),
      isNull,
    );
    expect(container.read(documentsProvider).trash, isEmpty);
    expect(adapter.purgeDecisions, [
      {'event_id': 'evt-1', 'action': 'keep'},
    ]);
  });
}

class _DocumentsAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.method == 'GET' && options.path.contains('/documents')) {
      return ResponseBody.fromString(
        jsonEncode({
          'items': [
            {
              'id': '11111111-1111-1111-1111-111111111111',
              'title': 'Facture EDF',
              'created': '2026-03-01T00:00:00.000Z',
              'modified': '2026-03-01T00:00:00.000Z',
              'category': 'Énergie',
              'file_size': 12,
            },
          ],
          'total': 1,
        }),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    return ResponseBody.fromString('{"detail":"not found"}', 404);
  }
}

class _TrashAdapter implements HttpClientAdapter {
  List<dynamic>? purgeDecisions;

  ResponseBody _json(Object body, int status) {
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.path;
    if (options.method == 'POST' && path.endsWith('/purge')) {
      final data = options.data;
      if (data is Map) purgeDecisions = data['decisions'] as List<dynamic>?;
      return ResponseBody.fromString('', 204);
    }
    if (options.method == 'DELETE') {
      return ResponseBody.fromString('', 204);
    }
    if (path.endsWith('/links')) {
      return _json([
        {
          'event_id': 'evt-1',
          'title': 'Signature',
          'start': '2026-10-18T08:30:00.000Z',
          'deleted': false,
        },
      ], 200);
    }
    if (path.endsWith('/trash')) {
      return _json({
        'items': [
          {
            'id': '11111111-1111-1111-1111-111111111111',
            'title': 'Facture EDF',
            'created': '2026-03-01T00:00:00.000Z',
            'modified': '2026-03-02T00:00:00.000Z',
            'deleted_at': '2026-10-18T10:00:00.000Z',
          },
        ],
        'total': 1,
        'page': 1,
        'page_size': 100,
      }, 200);
    }
    if (options.method == 'GET' && path.contains('/documents')) {
      return _json({
        'items': [
          {
            'id': '11111111-1111-1111-1111-111111111111',
            'title': 'Facture EDF',
            'created': '2026-03-01T00:00:00.000Z',
            'modified': '2026-03-01T00:00:00.000Z',
          },
        ],
        'total': 1,
        'page': 1,
        'page_size': 25,
      }, 200);
    }
    return _json({'items': [], 'total': 0}, 200);
  }
}
