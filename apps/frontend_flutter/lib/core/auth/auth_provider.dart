import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../api/api_client.dart';
import '../../shared/models/user_model.dart';
import '../../shared/services/profile_api_service.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final profileApiServiceProvider = Provider<ProfileApiService>((ref) {
  return ProfileApiService(ref.read(apiClientProvider).dio);
});

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(apiClientProvider));
});

class AuthState extends Equatable {
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

  @override
  List<Object?> get props => [isAuthenticated, isLoading, user, error];
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
      await _apiClient.ensureConfigured();
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
      final connectionFailed = e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout;
      state = state.copyWith(
        isLoading: false,
        error: connectionFailed
            ? 'Impossible de joindre le serveur. Vérifiez que le backend est démarré et accessible.'
            : e.response?.data?['detail']?.toString() ?? 'Échec de connexion',
      );
    }
  }

  Future<void> _loadUser() async {
    try {
      await _apiClient.ensureConfigured();
      final response = await _apiClient.dio.get('/auth/me');
      final data = response.data as Map<String, dynamic>;
      state = state.copyWith(user: UserModel.fromJson(data));
    } catch (_) {
      state = state.copyWith(user: ProfileApiService.mockDemoUser);
    }
  }

  Future<void> loginDemo() async {
    state = state.copyWith(
      isAuthenticated: true,
      user: ProfileApiService.mockDemoUser,
    );
  }

  /// Mode démo « Visite guidée » : simule une première connexion utilisateur.
  Future<void> loginDemoGuidedTour() async {
    state = state.copyWith(
      isAuthenticated: true,
      user: ProfileApiService.mockGuidedTourUser,
    );
  }

  /// Met à jour l'utilisateur local (après PATCH /auth/me ou mock).
  void updateLocalUser(UserModel user) {
    state = state.copyWith(user: user);
  }

  Future<void> logout() async {
    await _storage.deleteAll();
    state = const AuthState();
  }

  bool hasRole(String role) => state.user?.roles.contains(role) ?? false;
}
