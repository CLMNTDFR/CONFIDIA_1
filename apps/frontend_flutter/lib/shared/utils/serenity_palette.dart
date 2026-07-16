import 'package:flutter/material.dart';

import '../../core/theme/palette.dart';
import '../models/serenity_briefing_model.dart';

/// Couleurs sémantiques sérénité : vert ≥80, bleu ≥65, orange ≥50, rouge <50.
abstract final class SerenityPalette {
  static const excellent = Color(0xFF43A047);
  static const good = Color(0xFF4B96B4);
  static const moderate = Color(0xFFFB8C00);
  static const attention = Color(0xFFE53935);

  static Color forScore(int score, {ConfidiaPalette? palette}) {
    if (score >= 80) return excellent;
    if (score >= 65) return palette?.primary ?? good;
    if (score >= 50) return moderate;
    return attention;
  }

  static Color forLevel(SerenityLevel level, ConfidiaPalette palette) {
    return switch (level) {
      SerenityLevel.excellent => excellent,
      SerenityLevel.good => palette.primary,
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
