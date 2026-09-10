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
