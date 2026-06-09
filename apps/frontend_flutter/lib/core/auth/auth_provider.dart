import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../api/api_client.dart';
import '../../shared/models/user_model.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(apiClientProvider));
});

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final UserModel? user;
  final String? error;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.user,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    UserModel? user,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _apiClient;
  final _storage = const FlutterSecureStorage();

  AuthNotifier(this._apiClient) : super(const AuthState()) {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final token = await _storage.read(key: 'access_token');
    if (token != null) {
      state = state.copyWith(isAuthenticated: true);
      await _loadUser();
    }
  }

  Future<void> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiClient.dio.post('/auth/login', data: {
        'username': username,
        'password': password,
      });

      await _storage.write(
        key: 'access_token',
        value: response.data['access_token'] as String,
      );
      await _storage.write(
        key: 'refresh_token',
        value: response.data['refresh_token'] as String,
      );

      state = state.copyWith(isAuthenticated: true, isLoading: false);
      await _loadUser();
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data?['detail']?.toString() ?? 'Échec de connexion',
      );
    }
  }

  Future<void> _loadUser() async {
    try {
      final response = await _apiClient.dio.get('/auth/me');
      final data = response.data as Map<String, dynamic>;
      state = state.copyWith(
        user: UserModel(
          id: data['sub'] as String,
          email: data['email'] as String,
          firstName: data['given_name'] as String? ?? '',
          lastName: data['family_name'] as String? ?? '',
          roles: List<String>.from(data['roles'] ?? []),
        ),
      );
    } catch (_) {
      // Use mock user when API unavailable
      state = state.copyWith(
        user: const UserModel(
          id: 'demo',
          email: 'demo@confidia.local',
          firstName: 'Jean',
          lastName: 'Dupont',
          roles: ['USER'],
        ),
      );
    }
  }

  Future<void> loginDemo() async {
    state = state.copyWith(
      isAuthenticated: true,
      user: const UserModel(
        id: 'demo',
        email: 'demo@confidia.local',
        firstName: 'Jean',
        lastName: 'Dupont',
        roles: ['USER'],
        organization: 'Particulier',
      ),
    );
  }

  Future<void> logout() async {
    await _storage.deleteAll();
    state = const AuthState();
  }

  bool hasRole(String role) => state.user?.roles.contains(role) ?? false;
}
