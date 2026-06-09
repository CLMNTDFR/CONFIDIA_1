import 'package:flutter/material.dart';

import '../../core/theme/spacing.dart';
import 'dashboard_provider.dart';

/// Compose les widgets du tableau de bord en lignes pleine ou demi-largeur.
abstract final class DashboardGrid {
  static const double breakpoint = 720;
  static const double rowGap = ConfidiaSpacing.md;

  static List<Widget> buildRows({
    required BuildContext context,
    required List<DashboardWidgetType> types,
    required Widget Function(DashboardWidgetType type, int index) builder,
  }) {
    final isWide = MediaQuery.sizeOf(context).width >= breakpoint;
    final rows = <Widget>[];
    var listIndex = 0;
    var i = 0;

    while (i < types.length) {
      final current = types[i];
      final next = i + 1 < types.length ? types[i + 1] : null;
      final pair = isWide && current.isHalfWidth && next != null && next.isHalfWidth;

      if (pair) {
        final rowHeight = _pairHeight(types[i], types[i + 1]);
        rows.add(
          Padding(
            padding: const EdgeInsets.only(bottom: rowGap),
            child: SizedBox(
              height: rowHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: builder(types[i], listIndex++)),
                  const SizedBox(width: ConfidiaSpacing.md),
                  Expanded(child: builder(types[i + 1], listIndex++)),
                ],
              ),
            ),
          ),
        );
        i += 2;
        continue;
      }

      if (isWide && current.isHalfWidth) {
        rows.add(
          Padding(
            padding: const EdgeInsets.only(bottom: rowGap),
            child: SizedBox(
              height: current.fixedHeight ?? 228,
              child: Row(
                children: [
                  Expanded(child: builder(current, listIndex++)),
                  const SizedBox(width: ConfidiaSpacing.md),
                  const Expanded(child: SizedBox()),
                ],
              ),
            ),
          ),
        );
      } else {
        rows.add(
          Padding(
            padding: const EdgeInsets.only(bottom: rowGap),
            child: builder(current, listIndex++),
          ),
        );
      }
      i += 1;
    }

    return rows;
  }

  static double _pairHeight(DashboardWidgetType a, DashboardWidgetType b) {
    final ha = a.fixedHeight ?? 228;
    final hb = b.fixedHeight ?? 228;
    return ha > hb ? ha : hb;
  }
}
