import 'package:flutter/material.dart';

import '../../core/theme/spacing.dart';
import 'dashboard_provider.dart';

/// Groupe de widgets affichés sur une même ligne (1 ou 2 colonnes).
class DashboardGridSegment {
  final List<DashboardWidgetType> types;

  const DashboardGridSegment(this.types);

  String get key => types.map((t) => t.name).join('|');

  double rowHeight({required bool editMode}) {
    final chrome = editMode ? DashboardGrid.editChromeHeight : 0.0;
    if (types.length == 2) {
      return DashboardGrid._pairHeight(types[0], types[1]) + chrome;
    }
    final single = types.single;
    if (single.isHalfWidth) {
      return (single.fixedHeight ?? 228) + chrome;
    }
    return chrome;
  }
}

/// Compose les widgets du tableau de bord en lignes pleine ou demi-largeur.
abstract final class DashboardGrid {
  static const double breakpoint = 720;
  static const double rowGap = ConfidiaSpacing.md;
  static const double editChromeHeight = 50;

  static bool isWideLayout(BuildContext context) => MediaQuery.sizeOf(context).width >= breakpoint;

  static List<DashboardGridSegment> buildSegments(List<DashboardWidgetType> types, {required bool isWide}) {
    final segments = <DashboardGridSegment>[];
    var i = 0;

    while (i < types.length) {
      final current = types[i];
      final next = i + 1 < types.length ? types[i + 1] : null;
      final pair = isWide && current.isHalfWidth && next != null && next.isHalfWidth;

      if (pair) {
        segments.add(DashboardGridSegment([current, next]));
        i += 2;
        continue;
      }

      segments.add(DashboardGridSegment([current]));
      i += 1;
    }

    return segments;
  }

  static List<Widget> buildRows({
    required BuildContext context,
    required List<DashboardWidgetType> types,
    required Widget Function(DashboardWidgetType type, int index) builder,
    bool editMode = false,
  }) {
    final isWide = isWideLayout(context);
    final segments = buildSegments(types, isWide: isWide);
    final rows = <Widget>[];
    var listIndex = 0;

    for (final segment in segments) {
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: rowGap),
          child: _buildSegmentRow(
            segment: segment,
            isWide: isWide,
            editMode: editMode,
            builder: builder,
            listIndex: listIndex,
            onBuilt: (count) => listIndex += count,
          ),
        ),
      );
    }

    return rows;
  }

  static Widget _buildSegmentRow({
    required DashboardGridSegment segment,
    required bool isWide,
    required bool editMode,
    required Widget Function(DashboardWidgetType type, int index) builder,
    required int listIndex,
    required void Function(int count) onBuilt,
  }) {
    if (segment.types.length == 2) {
      onBuilt(2);
      return SizedBox(
        height: segment.rowHeight(editMode: editMode),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: builder(segment.types[0], listIndex)),
            const SizedBox(width: ConfidiaSpacing.md),
            Expanded(child: builder(segment.types[1], listIndex + 1)),
          ],
        ),
      );
    }

    final single = segment.types.single;
    onBuilt(1);

    if (isWide && single.isHalfWidth) {
      return SizedBox(
        height: segment.rowHeight(editMode: editMode),
        child: Row(
          children: [
            Expanded(child: builder(single, listIndex)),
            const SizedBox(width: ConfidiaSpacing.md),
            const Expanded(child: SizedBox()),
          ],
        ),
      );
    }

    return builder(single, listIndex);
  }

  static double _pairHeight(DashboardWidgetType a, DashboardWidgetType b) {
    final ha = a.fixedHeight ?? 228;
    final hb = b.fixedHeight ?? 228;
    return ha > hb ? ha : hb;
  }
}
