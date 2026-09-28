import 'dart:ui';

/// Design System blurs. Subtle chrome; content has no blur.
abstract final class AppBlur {
  /// Floating chrome (nav, app bar, sheets, dialogs, AI popup).
  static const double chrome = 6;

  /// Auth veil only.
  static const double veil = 20;

  static ImageFilter filter(double sigma) => ImageFilter.blur(sigmaX: sigma, sigmaY: sigma);

  static ImageFilter get chromeFilter => filter(chrome);
  static ImageFilter get veilFilter => filter(veil);
}
