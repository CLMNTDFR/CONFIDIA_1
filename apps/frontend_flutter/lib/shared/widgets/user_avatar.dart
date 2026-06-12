import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/theme/theme_context.dart';
import '../models/user_model.dart';

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
    final hasPhoto = imageBase64 != null && imageBase64!.isNotEmpty;

    if (hasPhoto) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: MemoryImage(base64Decode(imageBase64!)),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: context.palette.primary.withValues(alpha: 0.15),
      child: Text(
        user.initials,
        style: TextStyle(
          color: context.palette.primary,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.7,
        ),
      ),
    );
  }
}

/// Variante avec bordure pour la page profil.
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
    final hasPhoto = imageBase64 != null && imageBase64!.isNotEmpty;

    Widget avatar = Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: context.palette.secondary.withValues(alpha: 0.4), width: 2),
        boxShadow: [
          BoxShadow(
            color: context.palette.primary.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: hasPhoto
          ? CircleAvatar(
              radius: radius,
              backgroundImage: MemoryImage(Uint8List.fromList(base64Decode(imageBase64!))),
            )
          : CircleAvatar(
              radius: radius,
              backgroundColor: context.palette.primary.withValues(alpha: 0.12),
              child: Text(
                user.initials,
                style: TextStyle(
                  fontSize: radius * 0.55,
                  fontWeight: FontWeight.w800,
                  color: context.palette.primary,
                ),
              ),
            ),
    );

    if (onTap != null) {
      avatar = Material(
        color: Colors.transparent,
        child: InkWell(onTap: onTap, customBorder: const CircleBorder(), child: avatar),
      );
    }

    return avatar;
  }
}
