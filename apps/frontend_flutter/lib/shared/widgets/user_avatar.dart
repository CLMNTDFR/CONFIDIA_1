import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/tokens/tokens.dart';
import '../models/user_model.dart';

final Map<String, Uint8List> _avatarBytesCache = {};

Uint8List? decodeAvatarBase64(String? imageBase64) {
  if (imageBase64 == null || imageBase64.isEmpty) return null;
  return _avatarBytesCache.putIfAbsent(imageBase64, () => base64Decode(imageBase64));
}

class UserAvatar extends StatelessWidget {
  final UserModel user;
  final double radius;
  final String? imageBase64;

  const UserAvatar({
    super.key,
    required this.user,
    this.radius = 16,
    this.imageBase64,
  });

  @override
  Widget build(BuildContext context) {
    final bytes = decodeAvatarBase64(imageBase64);

    if (bytes != null) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: MemoryImage(bytes),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.surface2(isDark),
      child: Text(
        user.initials,
        style: TextStyle(
          color: ConfidiaColors.textSecondary(isDark),
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.7,
        ),
      ),
    );
  }
}

/// Bordered variant for the profile page.
class UserAvatarLarge extends StatelessWidget {
  final UserModel user;
  final double radius;
  final String? imageBase64;
  final VoidCallback? onTap;

  const UserAvatarLarge({
    super.key,
    required this.user,
    this.radius = 44,
    this.imageBase64,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bytes = decodeAvatarBase64(imageBase64);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget avatar = Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ConfidiaColors.textSecondary(isDark).withValues(alpha: 0.35), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: bytes != null
          ? CircleAvatar(
              radius: radius,
              backgroundImage: MemoryImage(bytes),
            )
          : CircleAvatar(
              radius: radius,
              backgroundColor: AppColors.surface2(isDark),
              child: Text(
                user.initials,
                style: TextStyle(
                  fontSize: radius * 0.55,
                  fontWeight: FontWeight.w800,
                  color: ConfidiaColors.textSecondary(isDark),
                ),
              ),
            ),
    );

    if (onTap != null) {
      avatar = Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          mouseCursor: SystemMouseCursors.click,
          customBorder: const CircleBorder(),
          child: avatar,
        ),
      );
    }

    return avatar;
  }
}
