import 'package:flutter/material.dart';

import '../../core/theme/palette.dart';
import '../../core/theme/tokens/app_colors.dart';
import '../models/serenity_briefing_model.dart';

/// Couleurs sémantiques sérénité : rouge 0-40, orange 41-60, vert >60 (toast success).
abstract final class SerenityPalette {
  static const excellent = AppColors.success;
  static const good = AppColors.success;
  static const moderate = Color(0xFFFB8C00);
  static const attention = Color(0xFFE53935);

  /// [palette] conservé pour compatibilité d'appel ; non utilisé dans les seuils.
  static Color forScore(int score, {ConfidiaPalette? palette}) {
    if (score > 60) return excellent;
    if (score >= 41) return moderate;
    return attention;
  }

  /// [palette] conservé pour compatibilité d'appel ; excellent/good partagent le vert succès.
  static Color forLevel(SerenityLevel level, ConfidiaPalette palette) {
    return switch (level) {
      SerenityLevel.excellent || SerenityLevel.good => excellent,
      SerenityLevel.moderate => moderate,
      SerenityLevel.attention => attention,
    };
  }

  static String serenityHeadline(SerenityLevel level, int score, int priorityToday) {
    final base = switch (level) {
      SerenityLevel.excellent => 'Excellente sérénité administrative',
      SerenityLevel.good => 'Bonne sérénité administrative',
      SerenityLevel.moderate => 'Sérénité modérée',
      SerenityLevel.attention => 'Sérénité fragile',
    };
    final suffix = priorityToday > 0 ? ' · $priorityToday action(s) prioritaire(s)' : '';
    return '$base ($score/100)$suffix';
  }

  static String calendarLoadLabel(int busyDays) {
    if (busyDays >= 4) return 'agenda chargé';
    if (busyDays >= 2) return 'agenda modérément chargé';
    return 'agenda plutôt calme';
  }
}
