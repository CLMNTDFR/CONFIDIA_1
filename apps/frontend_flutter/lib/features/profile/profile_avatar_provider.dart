import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/api/api_error_message.dart';

const _avatarStoragePrefix = 'profile_avatar_base64_';

final profileAvatarProvider = StateNotifierProvider<ProfileAvatarNotifier, String?>(
  (ref) => ProfileAvatarNotifier(ref),
);

class ProfileAvatarNotifier extends StateNotifier<String?> {
  ProfileAvatarNotifier(this._ref) : super(null) {
    _bind();
    _ref.listen(authStateProvider, (prev, next) {
      if (prev?.user?.id == next.user?.id && prev?.isAuthenticated == next.isAuthenticated) {
        return;
      }
      _bind();
    });
  }

  final Ref _ref;
  final _storage = const FlutterSecureStorage();

  Future<void> _bind() async {
    final auth = _ref.read(authStateProvider);
    final user = auth.user;
    if (!auth.isAuthenticated || user == null) {
      state = null;
      return;
    }
    if (auth.isDemoSession) {
      state = await _storage.read(key: '$_avatarStoragePrefix${user.id}');
      return;
    }
    try {
      final bytes = await _ref.read(profileApiServiceProvider).fetchAvatar();
      state = bytes == null ? null : base64Encode(bytes);
    } catch (_) {
      // Keep the photo already shown if the server does not respond.
    }
  }

  Future<String?> pickAndSave(ImageSource source) async {
    final auth = _ref.read(authStateProvider);
    final user = auth.user;
    if (user == null) return 'Session expirée';

    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (file == null) return null;

    final bytes = await file.readAsBytes();
    final encoded = base64Encode(bytes);
    final filename = file.name.trim().isEmpty ? 'avatar.jpg' : file.name;

    if (auth.isDemoSession) {
      await _storage.write(key: '$_avatarStoragePrefix${user.id}', value: encoded);
      state = encoded;
      return null;
    }
    try {
      final saved = await _ref.read(profileApiServiceProvider).uploadAvatar(bytes, filename);
      _ref.read(authStateProvider.notifier).updateLocalUser(saved);
      state = encoded;
      return null;
    } catch (error) {
      return apiErrorMessage(error, fallback: 'Impossible d\'enregistrer la photo');
    }
  }

  Future<String?> remove() async {
    final auth = _ref.read(authStateProvider);
    final user = auth.user;
    if (user == null) return 'Session expirée';

    if (auth.isDemoSession) {
      await _storage.delete(key: '$_avatarStoragePrefix${user.id}');
      state = null;
      return null;
    }
    try {
      final saved = await _ref.read(profileApiServiceProvider).deleteAvatar();
      _ref.read(authStateProvider.notifier).updateLocalUser(saved);
      state = null;
      return null;
    } catch (error) {
      return apiErrorMessage(error, fallback: 'Impossible de supprimer la photo');
    }
  }
}
