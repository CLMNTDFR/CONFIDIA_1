import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/theme_context.dart';

abstract final class ConfidiaLogoAssets {
  static const blue128 = 'assets/logo/confidia-logo-blue-128.png';
  static const blue256 = 'assets/logo/confidia-logo-blue-256.png';
  static const pink128 = 'assets/logo/confidia-logo-pink-128.png';
  static const pink256 = 'assets/logo/confidia-logo-pink-256.png';

  static String forPalette(ConfidiaPalette palette, {required double displaySize}) {
    final isRose = palette.id == ConfidiaPaletteId.rose;
    final hiRes = displaySize >= 36;
    return switch ((isRose, hiRes)) {
      (false, false) => blue128,
      (false, true) => blue256,
      (true, false) => pink128,
      (true, true) => pink256,
    };
  }
}

/// Espacement et typo partagés logo + texte (login, sidebar, top bar).
abstract final class ConfidiaBrandMetrics {
  static const gap = 6.0;

  static double titleSize(double logoSize) => logoSize * 0.42;
  static double taglineSize(double logoSize) => logoSize * 0.2;
  static double titleTracking(double logoSize) => logoSize >= 40 ? 1.8 : 1.4;

  static double brandBlockWidth(double logoSize) {
    final titleWidth = titleSize(logoSize) * 0.58 * 8;
    return logoSize + gap + titleWidth;
  }

  static double brandBlockHeight(double logoSize) {
    return logoSize > titleSize(logoSize) + 2 + taglineSize(logoSize)
        ? logoSize
        : titleSize(logoSize) + 2 + taglineSize(logoSize);
  }
}

/// Marque graphique seule (fond transparent).
class ConfidiaLogoMark extends StatelessWidget {
  final double size;

  const ConfidiaLogoMark({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return Image.asset(
      ConfidiaLogoAssets.forPalette(palette, displaySize: size),
      width: size,
      height: size,
      fit: BoxFit.contain,
      cacheWidth: (size * dpr).round().clamp(1, 512),
      filterQuality: size >= 36 ? FilterQuality.high : FilterQuality.medium,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => Icon(Icons.shield_rounded, size: size * 0.72, color: palette.primary),
    );
  }
}

/// Texte CONFIDIA + tagline aligné sur le logo.
class ConfidiaBrandText extends StatelessWidget {
  final double logoSize;

  const ConfidiaBrandText({super.key, required this.logoSize});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => palette.brandGradient.createShader(bounds),
          child: Text(
            'CONFIDIA',
            style: TextStyle(
              fontSize: ConfidiaBrandMetrics.titleSize(logoSize),
              fontWeight: FontWeight.w800,
              letterSpacing: ConfidiaBrandMetrics.titleTracking(logoSize),
              color: Colors.white,
              height: 1,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Hub numérique',
          style: TextStyle(
            fontSize: ConfidiaBrandMetrics.taglineSize(logoSize),
            fontWeight: FontWeight.w500,
            color: ConfidiaColors.textSecondary(isDark),
            letterSpacing: 0.25,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}

/// Logo CONFIDIA statique  -  utilisé partout dans l'application.
class ConfidiaLogo extends StatelessWidget {
  final double size;
  final bool showText;

  const ConfidiaLogo({
    super.key,
    this.size = 32,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ConfidiaLogoMark(size: size),
        if (showText) ...[
          const SizedBox(width: ConfidiaBrandMetrics.gap),
          ConfidiaBrandText(logoSize: size),
        ],
      ],
    );
  }
}
