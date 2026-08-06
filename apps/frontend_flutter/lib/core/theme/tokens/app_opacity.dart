/// Opacités réutilisables. Style Cursor / Arc / macOS.
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

  // Contenu (cartes) : presque opaque
  static const double contentDark = 0.96;
  static const double contentLight = 0.98;

  // Chrome matière : très légère transparence (pas de vitre)
  static const double chromeDark = 0.92;
  static const double chromeLight = 0.94;

  // Lumière interne discrète (haut de panneau)
  static const double innerLight = 0.04;

  static const double veilDark = 0.38;
  static const double veilLight = 0.32;
  static const double inputFillDark = 0.5;
  static const double inputFillLight = 0.92;

  // Borders
  static const double borderSubtle = 0.04;
  static const double borderHairline = 0.06;
  static const double borderMedium = 0.08;
  static const double borderStrong = 0.1;
  static const double borderFocus = 0.32;

  // Accents
  static const double tintFaint = 0.05;
  static const double tintQuiet = 0.07;
  static const double tintSoft = 0.1;
  static const double glowSoft = 0.1;
  static const double glowMedium = 0.16;
  static const double indicator = 0.1;
  static const double shadowDark = 0.1;
  static const double shadowLight = 0.04;
  static const double chromeShadowDark = 0.12;
  static const double chromeShadowLight = 0.05;

  // Compat contenu
  static const double glassDark = contentDark;
  static const double glassLight = contentLight;
}
