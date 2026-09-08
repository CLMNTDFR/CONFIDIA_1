import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../api/api_client.dart';
import '../api/api_error_message.dart';
import '../../shared/models/user_model.dart';
import '../../shared/services/calendar_api_service.dart';
import '../../shared/services/profile_api_service.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final profileApiServiceProvider = Provider<ProfileApiService>((ref) {
  return ProfileApiService(ref.read(apiClientProvider).dio);
});

final calendarApiServiceProvider = Provider<CalendarApiService>((ref) {
  return CalendarApiService(ref.read(apiClientProvider).dio);
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

  bool get isDemoSession =>
      user?.id == 'demo' || user?.id == 'demo-first-visit';

  @override
  List<Object?> get props => [isAuthenticated, isLoading, user, error];
}

class AuthNotifier extends StateNotifier<AuthState> {
  static const _firstLoginKey = 'first_login_pending';

  final ApiClient _apiClient;
  final FlutterSecureStorage _storage;

  AuthNotifier(this._apiClient, {bool restoreSession = true, FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(),
        super(const AuthState()) {
    if (restoreSession) {
      _checkAuth();
    }
  }

  Future<void> _checkAuth() async {
    final token = await _storage.read(key: 'access_token');
    if (token != null) {
      state = state.copyWith(isAuthenticated: true, isLoading: true);
      await _loadUser();
      state = state.copyWith(isLoading: false);
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
      await _storeTokens(response.data as Map<String, dynamic>);
      state = state.copyWith(isAuthenticated: true);
      await _loadUser();
      state = state.copyWith(isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: apiErrorMessage(e, fallback: 'Échec de connexion'),
      );
    }
  }

  Future<void> register({
    required String email,
    required String emailConfirm,
    required String username,
    required String firstName,
    required String lastName,
    required String password,
    required String passwordConfirm,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiClient.ensureConfigured();
      final response = await _apiClient.dio.post('/auth/register', data: {
        'email': email.trim(),
        'email_confirm': emailConfirm.trim(),
        'username': username.trim(),
        'first_name': firstName.trim(),
        'last_name': lastName.trim(),
        'password': password,
        'password_confirm': passwordConfirm,
      });
      await _storeTokens(response.data as Map<String, dynamic>);
      await _storage.write(key: _firstLoginKey, value: '1');
      state = state.copyWith(isAuthenticated: true);
      await _loadUser();
      state = state.copyWith(isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: apiErrorMessage(e, fallback: 'Impossible de créer le compte'),
      );
    }
  }

  Future<void> _storeTokens(Map<String, dynamic> data) async {
    await _storage.write(key: 'access_token', value: data['access_token'] as String);
    await _storage.write(key: 'refresh_token', value: data['refresh_token'] as String);
  }

  Future<void> _loadUser() async {
    try {
      await _apiClient.ensureConfigured();
      final response = await _apiClient.dio.get('/users/me');
      state = state.copyWith(user: UserModel.fromJson(response.data as Map<String, dynamic>));
    } catch (_) {
      // L'écran Profil propose un nouvel essai.
    }
  }

  Future<void> reloadUser() async {
    state = state.copyWith(isLoading: true, error: null);
    await _loadUser();
    state = state.copyWith(isLoading: false);
  }

  Future<bool> isFirstLoginPending() async {
    return await _storage.read(key: _firstLoginKey) == '1';
  }

  Future<void> clearFirstLoginPending() async {
    await _storage.delete(key: _firstLoginKey);
  }

  @visibleForTesting
  void debugSetSession(AuthState value) {
    state = value;
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

  /// Met à jour l'utilisateur en mémoire après un PUT profil réussi.
  void updateLocalUser(UserModel user) {
    state = state.copyWith(user: user);
  }

  Future<void> logout() async {
    await _storage.deleteAll();
    state = const AuthState();
  }

  bool hasRole(String role) => state.user?.roles.contains(role) ?? false;
}
