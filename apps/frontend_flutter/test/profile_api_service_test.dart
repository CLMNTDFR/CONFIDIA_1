import 'dart:convert';
import 'dart:typed_data';

import 'package:confidia/shared/models/user_model.dart';
import 'package:confidia/shared/services/profile_api_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Dio dio;
  late _RecordingAdapter adapter;
  late ProfileApiService api;

  setUp(() {
    adapter = _RecordingAdapter();
    dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'));
    dio.httpClientAdapter = adapter;
    api = ProfileApiService(dio);
  });

  test('updateProfile sends PUT /users/me without swallowing errors', () async {
    adapter.statusCode = 200;
    adapter.body = jsonEncode({
      'id': 'u1',
      'email': 'a@b.c',
      'first_name': 'Ada',
      'last_name': 'Lovelace',
      'roles': ['USER'],
      'phone': '+33 6 00 00 00 00',
      'organization': 'Famille',
      'locale': 'fr-FR',
      'timezone': 'Europe/Paris',
    });

    const user = UserModel(
      id: 'u1',
      email: 'a@b.c',
      firstName: 'Ada',
      lastName: 'Lovelace',
      phone: '+33 6 00 00 00 00',
      organization: 'Famille',
    );
    final saved = await api.updateProfile(user);
    expect(adapter.method, 'PUT');
    expect(adapter.path, '/users/me');
    expect(jsonDecode(adapter.bodySent!), isNot(contains('id')));
    expect(saved.firstName, 'Ada');
    expect(saved.phone, '+33 6 00 00 00 00');
  });

  test('updateProfile surfaces HTTP errors', () async {
    adapter.statusCode = 500;
    adapter.body = '{"detail":"boom"}';
    const user = UserModel(id: 'u1', email: 'a@b.c', firstName: 'A', lastName: 'B');
    expect(api.updateProfile(user), throwsA(isA<DioException>()));
  });

  test('changePassword posts to /auth/change-password', () async {
    adapter.statusCode = 200;
    adapter.body = '{"message":"ok"}';
    await api.changePassword(currentPassword: 'OldPassw0rd!', newPassword: 'NewPassw0rd!');
    expect(adapter.method, 'POST');
    expect(adapter.path, '/auth/change-password');
  });

  test('fetchAvatar returns null on 404', () async {
    adapter.statusCode = 404;
    adapter.body = '{"detail":"Aucune photo de profil"}';
    expect(await api.fetchAvatar(), isNull);
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
