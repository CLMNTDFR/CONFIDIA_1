import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';

/// Styles d'info-bulles partagés pour les graphiques fl_chart.
abstract final class ConfidiaChartTooltips {
  static Color background(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? ConfidiaColors.darkSurfaceElevated : Colors.white;
  }

  static TextStyle label(BuildContext context, {Color? color, double fontSize = 12}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      color: color ?? ConfidiaColors.textPrimary(isDark),
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      height: 1.3,
    );
  }

  static TextStyle caption(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      color: ConfidiaColors.textSecondary(isDark),
      fontSize: 10,
      fontWeight: FontWeight.w500,
    );
  }

  static LineTouchTooltipData line(
    BuildContext context, {
    required String Function(int index, double value) labelBuilder,
    bool allowOverflow = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LineTouchTooltipData(
      getTooltipColor: (_) => background(context),
      tooltipBorder: BorderSide(color: ConfidiaColors.border(isDark)),
      tooltipRoundedRadius: 8,
      tooltipPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      tooltipMargin: 12,
      fitInsideHorizontally: !allowOverflow,
      fitInsideVertically: !allowOverflow,
      getTooltipItems: (spots) => spots
          .map(
            (spot) => LineTooltipItem(
              labelBuilder(spot.x.toInt(), spot.y),
              label(context),
              children: const [],
            ),
          )
          .toList(),
    );
  }

  static BarTouchTooltipData bar(
    BuildContext context, {
    required BarTooltipItem? Function(int groupIndex, int rodIndex) itemBuilder,
    bool allowOverflow = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BarTouchTooltipData(
      getTooltipColor: (_) => background(context),
      tooltipBorder: BorderSide(color: ConfidiaColors.border(isDark)),
      tooltipRoundedRadius: 8,
      tooltipPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      tooltipMargin: 12,
      fitInsideHorizontally: !allowOverflow,
      fitInsideVertically: !allowOverflow,
      direction: TooltipDirection.top,
      getTooltipItem: (group, groupIndex, rod, rodIndex) => itemBuilder(groupIndex, rodIndex),
    );
  }
}
