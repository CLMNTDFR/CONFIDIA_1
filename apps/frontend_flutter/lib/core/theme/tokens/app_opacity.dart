/// Opacités réutilisables (glass, hovers, glows). Style Cursor / Arc / macOS.
abstract final class AppOpacity {
  static const double invisible = 0;
  static const double faint = 0.04;
  static const double quiet = 0.08;
  static const double soft = 0.12;
  static const double muted = 0.18;
  static const double medium = 0.28;
  static const double strong = 0.4;
  static const double heavy = 0.55;
  static const double solid = 0.75;
  static const double opaque = 1;

  // Glass / surfaces
  static const double glassDark = 0.72;
  static const double glassLight = 0.82;
  static const double veilDark = 0.42;
  static const double veilLight = 0.38;
  static const double inputFillDark = 0.5;
  static const double inputFillLight = 0.92;
  static const double chromeDark = 0.92;
  static const double chromeLight = 0.94;

  // Borders: quasi invisibles (max ~0.1 hors focus)
  static const double borderSubtle = 0.04;
  static const double borderHairline = 0.06;
  static const double borderMedium = 0.08;
  static const double borderStrong = 0.1;
  static const double borderFocus = 0.32;

  // Accents / glow (discrets)
  static const double tintFaint = 0.05;
  static const double tintQuiet = 0.07;
  static const double tintSoft = 0.1;
  static const double glowSoft = 0.12;
  static const double glowMedium = 0.2;
  static const double indicator = 0.1;
  static const double shadowDark = 0.18;
  static const double shadowLight = 0.04;
}
