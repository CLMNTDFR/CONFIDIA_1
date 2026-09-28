import 'package:flutter/material.dart';

import '../../core/theme/palette.dart';
import '../../core/theme/theme_context.dart';

abstract final class ConfidiaLogoAssets {
  static const blue128 = 'assets/logo/confidia-logo-blue-128.png';
  static const blue256 = 'assets/logo/confidia-logo-blue-256.png';
  static const pink128 = 'assets/logo/confidia-logo-pink-128.png';
  static const pink256 = 'assets/logo/confidia-logo-pink-256.png';

  /// Integrated wordmark (mark = « o ») · blue / pink theme.
  static const wordmarkBlue = 'assets/logo/confidia-wordmark-blue.png';
  static const wordmarkPink = 'assets/logo/confidia-wordmark-pink.png';

  /// Intrinsic wordmark aspect ratio (~998×208).
  static const wordmarkAspect = 998 / 208;

  static String markForPalette(ConfidiaPalette palette, {required double displaySize}) {
    final isRose = palette.id == ConfidiaPaletteId.rose;
    final hiRes = displaySize >= 36;
    return switch ((isRose, hiRes)) {
      (false, false) => blue128,
      (false, true) => blue256,
      (true, false) => pink128,
      (true, true) => pink256,
    };
  }

  static String wordmarkForPalette(ConfidiaPalette palette) {
    return palette.id == ConfidiaPaletteId.rose ? wordmarkPink : wordmarkBlue;
  }

  /// Legacy alias kept for existing call sites.
  static String forPalette(ConfidiaPalette palette, {required double displaySize}) =>
      markForPalette(palette, displaySize: displaySize);
}

/// Brand block metrics (wordmark or mark only).
abstract final class ConfidiaBrandMetrics {
  static double wordmarkWidth(double height) => height * ConfidiaLogoAssets.wordmarkAspect;

  static double brandBlockWidth(double logoSize, {bool showText = true}) {
    if (showText) return wordmarkWidth(logoSize);
    return logoSize;
  }

  static double brandBlockHeight(double logoSize, {bool showText = true}) => logoSize;
}

/// Graphic mark only (transparent background).
class ConfidiaLogoMark extends StatelessWidget {
  final double size;

  const ConfidiaLogoMark({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return Image.asset(
      ConfidiaLogoAssets.markForPalette(palette, displaySize: size),
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

/// Confidia wordmark (mark integrated in the « o »), blue or pink theme.
class ConfidiaWordmark extends StatelessWidget {
  final double height;

  const ConfidiaWordmark({super.key, required this.height});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final width = ConfidiaBrandMetrics.wordmarkWidth(height);

    return Image.asset(
      ConfidiaLogoAssets.wordmarkForPalette(palette),
      width: width,
      height: height,
      fit: BoxFit.contain,
      alignment: Alignment.centerLeft,
      cacheWidth: (width * dpr).round().clamp(1, 2048),
      filterQuality: FilterQuality.high,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConfidiaLogoMark(size: height),
          const SizedBox(width: 8),
          Text(
            'Confidia',
            style: TextStyle(
              fontSize: height * 0.55,
              fontWeight: FontWeight.w800,
              color: palette.primary,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// CONFIDIA logo: wordmark if [showText], mark only otherwise.
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
    if (showText) {
      return ConfidiaWordmark(height: size);
    }
    return ConfidiaLogoMark(size: size);
  }
}
