import 'package:confidia/core/api/api_client.dart';
import 'package:confidia/core/auth/auth_provider.dart';
import 'package:confidia/shared/models/user_model.dart';
import 'package:confidia/shared/services/profile_api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

AuthNotifier demoAuthNotifier() {
  final notifier = AuthNotifier(ApiClient(), restoreSession: false);
  notifier.debugSetSession(
    const AuthState(isAuthenticated: true, user: ProfileApiService.mockDemoUser),
  );
  return notifier;
}

AuthNotifier liveAuthNotifier({
  UserModel user = const UserModel(
    id: 'live-user-1',
    email: 'ada@confidia.local',
    firstName: 'Ada',
    lastName: 'Lovelace',
  ),
}) {
  final notifier = AuthNotifier(ApiClient(), restoreSession: false);
  notifier.debugSetSession(AuthState(isAuthenticated: true, user: user));
  return notifier;
}

ProviderContainer sessionContainer(AuthNotifier auth) {
  return ProviderContainer(
    overrides: [
      authStateProvider.overrideWith((ref) => auth),
    ],
  );
}
