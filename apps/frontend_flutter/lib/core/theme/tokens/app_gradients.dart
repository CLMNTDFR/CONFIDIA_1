import 'package:flutter/material.dart';

import '../palette.dart';
import 'app_opacity.dart';

/// Dégradés : façade mince sur [ConfidiaPalette] (pas de fork de couleurs).
abstract final class AppGradients {
  static LinearGradient primary(ConfidiaPalette palette) => palette.primaryGradient;

  static LinearGradient brand(ConfidiaPalette palette) => palette.brandGradient;

  static LinearGradient accent(ConfidiaPalette palette) => palette.accentGradient;

  static LinearGradient hero(ConfidiaPalette palette, {required bool isDark}) =>
      palette.heroGradient(isDark: isDark);

  static LinearGradient meshDark(ConfidiaPalette palette) => palette.meshGradientDark;

  /// Lavis radial discret (overlays). Compose la palette, n'invente pas de hex.
  static RadialGradient ambientWash(ConfidiaPalette palette, {required bool isDark}) {
    return RadialGradient(
      center: const Alignment(-0.4, -0.55),
      radius: 1.15,
      colors: [
        palette.primary.withValues(alpha: isDark ? AppOpacity.glowSoft : AppOpacity.tintSoft),
        palette.secondary.withValues(alpha: isDark ? AppOpacity.tintFaint : AppOpacity.tintQuiet),
        Colors.transparent,
      ],
      stops: const [0.0, 0.45, 1.0],
    );
  }
}
