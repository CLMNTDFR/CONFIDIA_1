import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'premium_chart_motion.dart';

/// Barre à deux plans  -  socle large atténué + tige lumineuse au premier plan.
BarChartRodData premiumBarRod({
  required double toY,
  required Color color,
  required bool isActive,
  required PremiumChartMotionValues motion,
  double width = 12,
  BorderRadius? borderRadius,
}) {
  final radius = borderRadius ?? const BorderRadius.vertical(top: Radius.circular(8));
  final visible = motion.dimOpacity(isActive: isActive, dimmed: 0.42);
  final baseAlpha = isActive ? 0.92 * visible : 0.55 * visible;
  final glowAlpha = (isActive ? 0.2 : 0.1) * visible;
  final scaledY = motion.scaleY(toY);

  return BarChartRodData(
    fromY: 0,
    toY: scaledY,
    width: width + (isActive ? 2 * motion.focus.clamp(0, 1) : 0),
    borderRadius: radius,
    backDrawRodData: BackgroundBarChartRodData(
      show: true,
      toY: scaledY,
      color: color.withValues(alpha: glowAlpha),
    ),
    gradient: LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [
        color.withValues(alpha: baseAlpha * 0.45),
        color.withValues(alpha: baseAlpha),
      ],
    ),
  );
}

/// Barre groupée (activité hub) avec socle et surbrillance au survol.
BarChartRodData premiumGroupedBarRod({
  required double toY,
  required Color color,
  required bool isGroupActive,
  required bool isRodActive,
  required PremiumChartMotionValues motion,
  double width = 8,
}) {
  final active = isGroupActive && isRodActive && motion.focus > 0;
  final visible = motion.dimOpacity(isActive: isGroupActive, dimmed: 0.42);
  final scaledY = motion.scaleY(toY);

  return BarChartRodData(
    toY: scaledY,
    width: width + (active ? 2 : 0),
    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
    backDrawRodData: BackgroundBarChartRodData(
      show: true,
      toY: scaledY,
      color: color.withValues(alpha: 0.12 * visible),
    ),
    gradient: LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [
        color.withValues(alpha: 0.4 * visible),
        color.withValues(alpha: (active ? 1.0 : 0.72) * visible),
      ],
    ),
  );
}
