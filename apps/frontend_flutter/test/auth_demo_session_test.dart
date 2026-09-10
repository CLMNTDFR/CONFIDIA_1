import 'package:confidia/core/api/api_client.dart';
import 'package:confidia/core/auth/auth_provider.dart';
import 'package:confidia/shared/services/profile_api_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({
      'access_token': 'leftover-access',
      'refresh_token': 'leftover-refresh',
    });
  });

  test('loginDemo drops leftover live tokens', () async {
    final storage = FlutterSecureStorage();
    final notifier = AuthNotifier(
      ApiClient(storage: storage),
      restoreSession: false,
      storage: storage,
    );
    addTearDown(notifier.dispose);

    await notifier.loginDemo();

    expect(await storage.read(key: 'access_token'), isNull);
    expect(await storage.read(key: 'refresh_token'), isNull);
    expect(notifier.state.isDemoSession, isTrue);
    expect(notifier.state.user?.id, ProfileApiService.mockDemoUser.id);
  });

  test('loginDemoGuidedTour drops leftover live tokens', () async {
    final storage = FlutterSecureStorage();
    final notifier = AuthNotifier(
      ApiClient(storage: storage),
      restoreSession: false,
      storage: storage,
    );
    addTearDown(notifier.dispose);

    await notifier.loginDemoGuidedTour();

    expect(await storage.read(key: 'access_token'), isNull);
    expect(await storage.read(key: 'refresh_token'), isNull);
    expect(notifier.state.isDemoSession, isTrue);
    expect(notifier.state.user?.id, ProfileApiService.mockGuidedTourUser.id);
  });
}
