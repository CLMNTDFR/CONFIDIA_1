import 'dart:ui';

/// Flous déjà présents dans le chrome partagé (glass / sheets / nav).
abstract final class AppBlur {
  /// GlassCard
  static const double glass = 12;

  /// Panneaux / dashboard ambient
  static const double panel = 16;

  /// Modal sheet / confirm dialog
  static const double sheet = 20;

  /// Navigation / auth veil
  static const double heavy = 28;

  static ImageFilter filter(double sigma) => ImageFilter.blur(sigmaX: sigma, sigmaY: sigma);

  static ImageFilter get glassFilter => filter(glass);
  static ImageFilter get panelFilter => filter(panel);
  static ImageFilter get sheetFilter => filter(sheet);
  static ImageFilter get heavyFilter => filter(heavy);
}
