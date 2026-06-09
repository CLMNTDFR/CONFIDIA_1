import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';

const _avatarStorageKey = 'profile_avatar_base64';

final profileAvatarProvider = StateNotifierProvider<ProfileAvatarNotifier, String?>(
  (ref) => ProfileAvatarNotifier(),
);

class ProfileAvatarNotifier extends StateNotifier<String?> {
  final _storage = const FlutterSecureStorage();

  ProfileAvatarNotifier() : super(null) {
    _load();
  }

  Future<void> _load() async {
    state = await _storage.read(key: _avatarStorageKey);
  }

  Future<void> pickAndSave(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, maxWidth: 512, maxHeight: 512, imageQuality: 85);
    if (file == null) return;

    final bytes = await file.readAsBytes();
    final encoded = base64Encode(bytes);
    await _storage.write(key: _avatarStorageKey, value: encoded);
    state = encoded;
  }

  Future<void> remove() async {
    await _storage.delete(key: _avatarStorageKey);
    state = null;
  }
}
