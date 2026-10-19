import 'dart:convert';
import 'dart:typed_data';

import 'package:confidia/core/api/api_client.dart';
import 'package:confidia/core/auth/auth_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('login stores tokens and loads GET /users/me', () async {
    final storage = FlutterSecureStorage();
    final client = ApiClient(storage: storage);
    await client.configureBaseUrl('http://localhost/api/v1');
    client.dio.httpClientAdapter = _LoginAdapter();

    final notifier = AuthNotifier(
      client,
      restoreSession: false,
      storage: storage,
    );
    addTearDown(notifier.dispose);

    await notifier.login('user', 'user');

    expect(notifier.state.isAuthenticated, isTrue);
    expect(notifier.state.error, isNull);
    expect(notifier.state.user?.id, 'kc-live-1');
    expect(notifier.state.user?.firstName, 'Ada');
    expect(await storage.read(key: 'access_token'), 'access-live');
    expect(await storage.read(key: 'refresh_token'), 'refresh-live');
  });

  test('login after demo replaces the demo user', () async {
    final storage = FlutterSecureStorage();
    final client = ApiClient(storage: storage);
    await client.configureBaseUrl('http://localhost/api/v1');
    client.dio.httpClientAdapter = _LoginAdapter();

    final notifier = AuthNotifier(
      client,
      restoreSession: false,
      storage: storage,
    );
    addTearDown(notifier.dispose);

    await notifier.loginDemo();
    expect(notifier.state.isDemoSession, isTrue);

    await notifier.login('user', 'user');

    expect(notifier.state.isDemoSession, isFalse);
    expect(notifier.state.user?.id, 'kc-live-1');
    expect(notifier.state.user?.firstName, 'Ada');
  });

  test('login keeps an error when credentials are rejected', () async {
    final storage = FlutterSecureStorage();
    final client = ApiClient(storage: storage);
    await client.configureBaseUrl('http://localhost/api/v1');
    client.dio.httpClientAdapter = _LoginAdapter(failLogin: true);

    final notifier = AuthNotifier(
      client,
      restoreSession: false,
      storage: storage,
    );
    addTearDown(notifier.dispose);

    await notifier.login('user', 'wrong');

    expect(notifier.state.isAuthenticated, isFalse);
    expect(notifier.state.user, isNull);
    expect(notifier.state.error, isNotNull);
    expect(await storage.read(key: 'access_token'), isNull);
  });

  test('logout calls the API then clears tokens and session', () async {
    final storage = FlutterSecureStorage();
    final client = ApiClient(storage: storage);
    await client.configureBaseUrl('http://localhost/api/v1');
    final adapter = _LoginAdapter();
    client.dio.httpClientAdapter = adapter;

    final notifier = AuthNotifier(
      client,
      restoreSession: false,
      storage: storage,
    );
    addTearDown(notifier.dispose);

    await notifier.login('user', 'user');
    await notifier.logout();

    expect(adapter.logoutCalls, 1);
    expect(notifier.state.isAuthenticated, isFalse);
    expect(notifier.state.user, isNull);
    expect(await storage.read(key: 'access_token'), isNull);
    expect(await storage.read(key: 'refresh_token'), isNull);
  });

  test('logout still clears the local session when revoke fails', () async {
    final storage = FlutterSecureStorage();
    final client = ApiClient(storage: storage);
    await client.configureBaseUrl('http://localhost/api/v1');
    client.dio.httpClientAdapter = _LoginAdapter(failLogout: true);

    final notifier = AuthNotifier(
      client,
      restoreSession: false,
      storage: storage,
    );
    addTearDown(notifier.dispose);

    await notifier.login('user', 'user');
    await notifier.logout();

    expect(notifier.state.isAuthenticated, isFalse);
    expect(await storage.read(key: 'access_token'), isNull);
    expect(await storage.read(key: 'refresh_token'), isNull);
  });
}

class _LoginAdapter implements HttpClientAdapter {
  _LoginAdapter({this.failLogin = false, this.failLogout = false});

  final bool failLogin;
  final bool failLogout;
  int logoutCalls = 0;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path.contains('/auth/logout')) {
      logoutCalls += 1;
      if (failLogout) {
        return ResponseBody.fromString(
          '{"detail":"Keycloak unreachable"}',
          503,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      }
      return ResponseBody.fromString(
        '{"message":"Logged out successfully"}',
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    if (options.path.contains('/auth/login')) {
      if (failLogin) {
        return ResponseBody.fromString(
          '{"detail":"Invalid credentials"}',
          401,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      }
      return ResponseBody.fromString(
        jsonEncode({
          'access_token': 'access-live',
          'refresh_token': 'refresh-live',
          'token_type': 'bearer',
          'expires_in': 300,
        }),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    if (options.path.contains('/users/me')) {
      return ResponseBody.fromString(
        jsonEncode({
          'id': 'kc-live-1',
          'email': 'ada@confidia.local',
          'first_name': 'Ada',
          'last_name': 'Lovelace',
          'roles': ['USER'],
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
