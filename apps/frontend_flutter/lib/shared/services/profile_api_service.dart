import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../models/user_model.dart';

/// CONFIDIA profile: live HTTP, no phantom success.
class ProfileApiService {
  final Dio _dio;

  ProfileApiService(this._dio);

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
    final response = await _dio.put('/users/me', data: user.toProfileUpdateJson());
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _dio.post('/auth/change-password', data: {
      'current_password': currentPassword,
      'new_password': newPassword,
    });
  }

  Future<Uint8List?> fetchAvatar() async {
    try {
      final response = await _dio.get<List<int>>(
        '/users/me/avatar',
        options: Options(responseType: ResponseType.bytes),
      );
      final data = response.data;
      if (data == null || data.isEmpty) return null;
      return Uint8List.fromList(data);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<UserModel> uploadAvatar(Uint8List bytes, String filename) async {
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });
    final response = await _dio.post('/users/me/avatar', data: form);
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<UserModel> deleteAvatar() async {
    final response = await _dio.delete('/users/me/avatar');
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }
}
