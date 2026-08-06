import 'package:flutter/material.dart';

/// Rayons de bordure du Design System (esthétique glass / macOS).
///
/// Échelle : sm 8 · md 12 · lg 16 · xl 24 (alignée sur l'historique ConfidiaSpacing).
abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double pill = 999;

  /// Chips / icon buttons / chrome compact (récurrent hors échelle sm).
  static const double compact = 10;

  /// Champs de formulaire.
  static const double control = 11;

  /// Boutons, snackbars, segmented.
  static const double button = 12;

  /// Chips Material du thème (= [compact]).
  static const double chip = compact;

  /// Cartes / panneaux glass (= [lg]).
  static const double card = lg;

  static BorderRadius get smAll => BorderRadius.circular(sm);
  static BorderRadius get mdAll => BorderRadius.circular(md);
  static BorderRadius get lgAll => BorderRadius.circular(lg);
  static BorderRadius get xlAll => BorderRadius.circular(xl);
  static BorderRadius get compactAll => BorderRadius.circular(compact);
  static BorderRadius get controlAll => BorderRadius.circular(control);
  static BorderRadius get buttonAll => BorderRadius.circular(button);
  static BorderRadius get chipAll => BorderRadius.circular(chip);
  static BorderRadius get cardAll => BorderRadius.circular(card);
  static BorderRadius get pillAll => BorderRadius.circular(pill);
}
