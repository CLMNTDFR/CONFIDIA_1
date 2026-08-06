import 'package:dio/dio.dart';

import '../models/user_model.dart';
import '../data/mock_access_control.dart';

/// API profil - HTTP quand le backend est là, mock fiable en fallback.
class ProfileApiService {
  final Dio _dio;

  ProfileApiService(this._dio);

  /// Mock de référence (demo Jean Dupont).
  static const UserModel mockDemoUser = UserModel(
    id: 'demo',
    email: 'demo@confidia.local',
    firstName: 'Jean',
    lastName: 'Dupont',
    roles: ['USER'],
    phone: '+33 6 12 34 56 78',
    organization: 'Particulier',
    locale: 'fr_FR',
    timezone: 'Europe/Paris',
  );

  static const UserModel mockGuidedTourUser = UserModel(
    id: 'demo-first-visit',
    email: 'premiere.visite@confidia.local',
    firstName: 'Camille',
    lastName: 'Martin',
    roles: ['USER'],
    organization: 'Particulier',
    locale: 'fr_FR',
    timezone: 'Europe/Paris',
  );

  Future<UserModel> updateProfile(UserModel user) async {
    try {
      final response = await _dio.patch('/auth/me', data: user.toJson());
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      // Mock : renvoie la charge utile comme si le serveur avait persisté.
      return user;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _dio.post('/auth/change-password', data: {
        'current_password': currentPassword,
        'new_password': newPassword,
      });
      return true;
    } catch (_) {
      // Mock : accepte tout mot de passe actuel non vide.
      return currentPassword.isNotEmpty && newPassword.length >= 8;
    }
  }

  /// Structures auxquelles l'utilisateur appartient (mock gouvernance).
  Future<List<ProfileMembership>> fetchMemberships() async {
    try {
      final response = await _dio.get('/auth/me/memberships');
      final list = response.data as List<dynamic>;
      return list.map((e) => ProfileMembership.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return mockMemberships();
    }
  }

  static List<ProfileMembership> mockMemberships() {
    return [
      for (final p in MockAccessControl.builtInProfiles)
        ProfileMembership(
          structureId: p.id,
          label: p.label,
          roleLabel: p.id == 'family' ? 'Administrateur' : 'Membre',
          iconName: switch (p.id) {
            'family' => 'family_restroom',
            'club' => 'sports_soccer',
            _ => 'groups',
          },
        ),
    ];
  }
}
