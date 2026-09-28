import 'package:flutter/material.dart';

/// Allowed radii only: 8 · 12 · 16 · 20 · 24 · 28 · 32.
abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 28;
  static const double huge = 32;

  /// Fields / buttons / chips (= [md]).
  static const double control = md;
  static const double button = md;
  static const double chip = md;

  /// Cards (= [lg]).
  static const double card = lg;

  /// Former « pill »: largest allowed radius (no 999).
  static const double pill = huge;

  static BorderRadius get smAll => BorderRadius.circular(sm);
  static BorderRadius get mdAll => BorderRadius.circular(md);
  static BorderRadius get lgAll => BorderRadius.circular(lg);
  static BorderRadius get xlAll => BorderRadius.circular(xl);
  static BorderRadius get xxlAll => BorderRadius.circular(xxl);
  static BorderRadius get xxxlAll => BorderRadius.circular(xxxl);
  static BorderRadius get hugeAll => BorderRadius.circular(huge);
  static BorderRadius get controlAll => BorderRadius.circular(control);
  static BorderRadius get buttonAll => BorderRadius.circular(button);
  static BorderRadius get chipAll => BorderRadius.circular(chip);
  static BorderRadius get cardAll => BorderRadius.circular(card);
  static BorderRadius get pillAll => BorderRadius.circular(pill);
}
