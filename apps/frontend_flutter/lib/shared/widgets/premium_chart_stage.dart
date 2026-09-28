import 'package:flutter/material.dart';

import '../../core/theme/theme_context.dart';
import '../../core/theme/tokens/tokens.dart';

/// Layered chart stage: ambient glow plus foreground content.
class PremiumChartStage extends StatelessWidget {
  final Widget child;
  final List<Color> accentColors;
  final Alignment primaryGlowAlignment;
  final Alignment? secondaryGlowAlignment;
  final bool clipChart;

  const PremiumChartStage({
    super.key,
    required this.child,
    required this.accentColors,
    this.primaryGlowAlignment = const Alignment(-0.85, -0.65),
    this.secondaryGlowAlignment = const Alignment(0.9, 0.75),
    this.clipChart = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = context.palette;
    const radius = BorderRadius.all(Radius.circular(12));

    final background = ClipRRect(
      borderRadius: radius,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: _ChartAmbientPainter(
              colors: accentColors,
              fallbackPrimary: palette.primary,
              fallbackSecondary: palette.secondary,
              isDark: isDark,
              primaryAlignment: primaryGlowAlignment,
              secondaryAlignment: secondaryGlowAlignment,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.fromBorderSide(AppBorders.standard(isDark)),
              ),
            ),
          ),
        ],
      ),
    );

    if (clipChart) {
      return ClipRRect(
        borderRadius: radius,
        child: Stack(
          fit: StackFit.expand,
          children: [background, child],
        ),
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: [
        background,
        child,
      ],
    );
  }
}

class _ChartAmbientPainter extends CustomPainter {
  final List<Color> colors;
  final Color fallbackPrimary;
  final Color fallbackSecondary;
  final bool isDark;
  final Alignment primaryAlignment;
  final Alignment? secondaryAlignment;

  const _ChartAmbientPainter({
    required this.colors,
    required this.fallbackPrimary,
    required this.fallbackSecondary,
    required this.isDark,
    required this.primaryAlignment,
    this.secondaryAlignment,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final primary = colors.isNotEmpty ? colors.first : fallbackPrimary;
    final secondary = colors.length > 1 ? colors[1] : fallbackSecondary;

    _drawGlow(
      canvas,
      size,
      primaryAlignment,
      primary,
      radius: size.shortestSide * 0.62,
      alpha: isDark ? 0.14 : 0.1,
    );

    if (secondaryAlignment != null) {
      _drawGlow(
        canvas,
        size,
        secondaryAlignment!,
        secondary,
        radius: size.shortestSide * 0.48,
        alpha: isDark ? 0.1 : 0.07,
      );
    }

    final grid = Paint()
      ..color = AppBorders.standard(
        isDark,
        alpha: isDark ? AppOpacity.borderMedium : AppOpacity.borderSubtle,
      ).color
      ..strokeWidth = 1;
    const bands = 4;
    for (var i = 1; i < bands; i++) {
      final y = size.height * i / bands;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
  }

  void _drawGlow(Canvas canvas, Size size, Alignment alignment, Color color, {required double radius, required double alpha}) {
    final center = alignment.alongSize(size);
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: alpha),
          color.withValues(alpha: 0),
        ],
      ).createShader(rect);
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _ChartAmbientPainter oldDelegate) =>
      oldDelegate.colors != colors || oldDelegate.isDark != isDark;
}

/// Series opacity based on focus (active plane / background).
double premiumSeriesOpacity({
  required int index,
  required int? activeIndex,
  required double baseOpacity,
  double dimmedOpacity = 0.22,
}) {
  if (activeIndex == null) return baseOpacity;
  return activeIndex == index ? 1.0 : dimmedOpacity;
}
