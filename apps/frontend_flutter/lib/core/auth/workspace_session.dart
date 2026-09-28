import 'auth_provider.dart';

/// Identifies the current account so local data can be reloaded (or cleared).
String workspaceSessionKey(AuthState? state) {
  if (state == null || !state.isAuthenticated) return 'anon';
  if (state.isDemoSession) return 'demo:${state.user?.id ?? 'demo'}';
  final id = state.user?.id;
  if (id == null || id.isEmpty) return 'live:pending';
  return 'live:$id';
}

bool workspaceSessionChanged(AuthState? previous, AuthState next) {
  return workspaceSessionKey(previous) != workspaceSessionKey(next);
}

List<T> demoSeedOrEmpty<T>(AuthState auth, List<T> mocks) {
  if (auth.isDemoSession) return List<T>.from(mocks);
  return <T>[];
}

String sessionFirstName(AuthState auth) => auth.user?.firstName.trim() ?? '';
