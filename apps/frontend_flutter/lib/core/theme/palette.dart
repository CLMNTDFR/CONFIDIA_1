import 'package:flutter/material.dart';

import 'colors.dart';

/// Identifiant du thème couleur de marque.
enum ConfidiaPaletteId {
  blue,
  rose;

  String get label => switch (this) {
        ConfidiaPaletteId.blue => 'Thème bleu',
        ConfidiaPaletteId.rose => 'Thème rose',
      };
}

/// Couleurs et dégradés de marque — source unique pour les deux thèmes.
@immutable
class ConfidiaPalette {
  final ConfidiaPaletteId id;
  final Color primary;
  final Color primaryLight;
  final Color secondary;
  final Color accent;

  const ConfidiaPalette({
    required this.id,
    required this.primary,
    required this.primaryLight,
    required this.secondary,
    required this.accent,
  });

  static const blue = ConfidiaPalette(
    id: ConfidiaPaletteId.blue,
    primary: Color(0xFF015AAB),
    primaryLight: Color(0xFF1A7FD4),
    secondary: Color(0xFF06E5EF),
    accent: Color(0xFF3B9AE8),
  );

  static const rose = ConfidiaPalette(
    id: ConfidiaPaletteId.rose,
    primary: Color(0xFFD20050),
    primaryLight: Color(0xFFFF4D8A),
    secondary: Color(0xFFAF73F7),
    accent: Color(0xFF4B96B4),
  );

  static ConfidiaPalette byId(ConfidiaPaletteId id) => switch (id) {
        ConfidiaPaletteId.blue => blue,
        ConfidiaPaletteId.rose => rose,
      };

  LinearGradient get primaryGradient => LinearGradient(
        colors: [primary, primaryLight],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  LinearGradient get brandGradient => LinearGradient(
        colors: [primary, secondary, accent],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  LinearGradient get accentGradient => LinearGradient(
        colors: [secondary, accent],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  LinearGradient heroGradient({required bool isDark}) {
    if (id == ConfidiaPaletteId.blue) {
      return LinearGradient(
        colors: [
          const Color(0xFF021A3A),
          const Color(0xFF0A0A18),
          isDark ? ConfidiaColors.darkBackground : ConfidiaColors.lightBackground,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    return LinearGradient(
      colors: [
        const Color(0xFF1A0828),
        const Color(0xFF0A0A18),
        isDark ? ConfidiaColors.darkBackground : ConfidiaColors.lightBackground,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  LinearGradient get meshGradientDark => LinearGradient(
        colors: [
          primary.withValues(alpha: 0.2),
          secondary.withValues(alpha: 0.14),
          accent.withValues(alpha: 0.08),
          Colors.transparent,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  /// Palette étendue pour graphiques (donut, barres, légendes).
  List<Color> get chartColors => [
        primary,
        secondary,
        accent,
        ConfidiaColors.success,
        primaryLight,
        const Color(0xFF6366F1),
        const Color(0xFF14B8A6),
      ];
}

/// Extension Riverpod / thème — exposée via [ThemeData.extensions].
@immutable
class ConfidiaPaletteTheme extends ThemeExtension<ConfidiaPaletteTheme> {
  final ConfidiaPalette palette;

  const ConfidiaPaletteTheme({required this.palette});

  @override
  ConfidiaPaletteTheme copyWith({ConfidiaPalette? palette}) {
    return ConfidiaPaletteTheme(palette: palette ?? this.palette);
  }

  @override
  ConfidiaPaletteTheme lerp(ConfidiaPaletteTheme? other, double t) {
    if (other == null) return this;
    return t < 0.5 ? this : other;
  }
}
