import 'dart:ui';

/// Flous du Design System. Chrome discret ; contenu sans flou.
abstract final class AppBlur {
  /// Chrome flottant (nav, app bar, sheets, dialogs, popup IA).
  static const double chrome = 6;

  /// Voile d'auth uniquement.
  static const double veil = 20;

  static ImageFilter filter(double sigma) => ImageFilter.blur(sigmaX: sigma, sigmaY: sigma);

  static ImageFilter get chromeFilter => filter(chrome);
  static ImageFilter get veilFilter => filter(veil);
}
