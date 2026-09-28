import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../shared/models/access_control_models.dart';

class OrgChartConnector {
  final String parentId;
  final String childId;
  final OrgHierarchyLinkType linkType;
  final Path path;

  const OrgChartConnector({
    required this.parentId,
    required this.childId,
    required this.linkType,
    required this.path,
  });
}

class OrgLevelBand {
  final int depth;
  final Rect rect;
  final bool isExtension;

  const OrgLevelBand({
    required this.depth,
    required this.rect,
    this.isExtension = false,
  });
}

class OrgChartLayoutResult {
  final Map<String, Rect> nodeRects;
  final List<OrgChartConnector> connectors;
  final List<OrgLevelBand> levelBands;
  final Size canvasSize;
  final int maxDepth;

  const OrgChartLayoutResult({
    required this.nodeRects,
    required this.connectors,
    required this.levelBands,
    required this.canvasSize,
    required this.maxDepth,
  });
}

/// Layout by horizontal levels - each depth is a centered row.
abstract final class OrgChartLayout {
  static const nodeWidth = 128.0;
  static const nodeHeight = 118.0;
  static const horizontalGap = 20.0;
  static const levelGap = 52.0;
  static const padding = 28.0;
  static const minCanvasWidth = 540.0;
  static const extensionBandHeight = 44.0;

  static Map<String, int> computeDepths(List<OrgNode> nodes) {
    final byId = {for (final n in nodes) n.id: n};
    final depths = <String, int>{};

    int depthOf(String id) {
      if (depths.containsKey(id)) return depths[id]!;
      final node = byId[id];
      if (node == null) return 0;
      if (node.parentId == null || !byId.containsKey(node.parentId)) {
        depths[id] = 0;
        return 0;
      }
      final d = depthOf(node.parentId!) + 1;
      depths[id] = d;
      return d;
    }

    for (final node in nodes) {
      depthOf(node.id);
    }
    return depths;
  }

  static OrgChartLayoutResult compute(
    List<OrgNode> nodes, {
    bool showTopExtension = false,
    bool showBottomExtension = false,
  }) {
    if (nodes.isEmpty) {
      return const OrgChartLayoutResult(
        nodeRects: {},
        connectors: [],
        levelBands: [],
        canvasSize: Size.zero,
        maxDepth: 0,
      );
    }

    final depths = computeDepths(nodes);
    final maxDepth = depths.values.fold(0, math.max);

    final byLevel = <int, List<OrgNode>>{};
    for (final node in nodes) {
      final d = depths[node.id] ?? 0;
      byLevel.putIfAbsent(d, () => []).add(node);
    }
    for (final list in byLevel.values) {
      list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    }

    var maxRowWidth = 0.0;
    for (var d = 0; d <= maxDepth; d++) {
      final row = byLevel[d] ?? [];
      if (row.isEmpty) continue;
      final w = row.length * nodeWidth + (row.length - 1) * horizontalGap;
      maxRowWidth = math.max(maxRowWidth, w);
    }

    final canvasWidth = math.max(maxRowWidth + padding * 2, minCanvasWidth);
    final rowStride = nodeHeight + levelGap;
    final topOffset = padding + (showTopExtension ? extensionBandHeight : 0);
    final canvasHeight = topOffset +
        (maxDepth + 1) * nodeHeight +
        maxDepth * levelGap +
        (showBottomExtension ? extensionBandHeight : 0) +
        padding;

    final rects = <String, Rect>{};
    final bands = <OrgLevelBand>[];

    if (showTopExtension) {
      bands.add(OrgLevelBand(
        depth: -1,
        rect: Rect.fromLTWH(0, padding, canvasWidth, extensionBandHeight),
        isExtension: true,
      ));
    }

    for (var d = 0; d <= maxDepth; d++) {
      final row = byLevel[d] ?? [];
      final rowWidth = row.isEmpty ? 0.0 : row.length * nodeWidth + (row.length - 1) * horizontalGap;
      final startX = (canvasWidth - rowWidth) / 2;
      final topY = topOffset + d * rowStride;

      bands.add(OrgLevelBand(
        depth: d,
        rect: Rect.fromLTWH(0, topY - 6, canvasWidth, nodeHeight + levelGap),
      ));

      for (var i = 0; i < row.length; i++) {
        final x = startX + i * (nodeWidth + horizontalGap);
        rects[row[i].id] = Rect.fromLTWH(x, topY, nodeWidth, nodeHeight);
      }
    }

    if (showBottomExtension) {
      final bottomY = topOffset + maxDepth * rowStride + nodeHeight + levelGap * 0.5;
      bands.add(OrgLevelBand(
        depth: maxDepth + 1,
        rect: Rect.fromLTWH(0, bottomY, canvasWidth, extensionBandHeight),
        isExtension: true,
      ));
    }

    final connectors = _buildConnectors(nodes, rects);

    return OrgChartLayoutResult(
      nodeRects: rects,
      connectors: connectors,
      levelBands: bands,
      canvasSize: Size(canvasWidth, canvasHeight),
      maxDepth: maxDepth,
    );
  }

  static List<OrgChartConnector> _buildConnectors(List<OrgNode> nodes, Map<String, Rect> rects) {
    final connectors = <OrgChartConnector>[];
    for (final node in nodes) {
      final parentId = node.parentId;
      if (parentId == null) continue;
      final parent = rects[parentId];
      final child = rects[node.id];
      if (parent == null || child == null) continue;

      final parentBottom = Offset(parent.center.dx, parent.bottom);
      final childTop = Offset(child.center.dx, child.top);
      final midY = parentBottom.dy + (childTop.dy - parentBottom.dy) / 2;

      final path = Path()
        ..moveTo(parentBottom.dx, parentBottom.dy)
        ..lineTo(parentBottom.dx, midY)
        ..lineTo(childTop.dx, midY)
        ..lineTo(childTop.dx, childTop.dy);

      connectors.add(OrgChartConnector(
        parentId: parentId,
        childId: node.id,
        linkType: node.hierarchyLinkType,
        path: path,
      ));
    }
    return connectors;
  }
}

/// Business rules for level-based repositioning.
abstract final class OrgChartHierarchy {
  static const _rolePriority = ['admin', 'ceo', 'director', 'parent', 'manager', 'coach'];

  static bool wouldCreateCycle(List<OrgNode> nodes, String draggedId, String? newParentId) {
    if (newParentId == null) return false;
    if (draggedId == newParentId) return true;
    var cursor = newParentId;
    while (true) {
      if (cursor == draggedId) return true;
      final parent = nodes.where((n) => n.id == cursor).firstOrNull;
      if (parent == null) return false;
      if (parent.parentId == null) return false;
      cursor = parent.parentId!;
    }
  }

  static bool isDescendant(List<OrgNode> nodes, String ancestorId, String nodeId) {
    var cursor = nodeId;
    while (true) {
      final node = nodes.where((n) => n.id == cursor).firstOrNull;
      if (node == null || node.parentId == null) return false;
      if (node.parentId == ancestorId) return true;
      cursor = node.parentId!;
    }
  }

  static String? pickParentAtDepth(List<OrgNode> nodes, int depth, {required String excludeId}) {
    final depths = OrgChartLayout.computeDepths(nodes);
    final candidates = nodes
        .where(
          (n) =>
              (depths[n.id] ?? 0) == depth &&
              n.id != excludeId &&
              !isDescendant(nodes, excludeId, n.id),
        )
        .toList();
    if (candidates.isEmpty) return null;

    candidates.sort((a, b) {
      final ai = _rolePriority.indexOf(a.roleId);
      final bi = _rolePriority.indexOf(b.roleId);
      final ap = ai == -1 ? 99 : ai;
      final bp = bi == -1 ? 99 : bi;
      if (ap != bp) return ap.compareTo(bp);
      return a.sortOrder.compareTo(b.sortOrder);
    });
    return candidates.first.id;
  }

  /// [targetDepth] = target depth (0 = displayed level 1).
  static String? parentIdForLevel(List<OrgNode> nodes, String nodeId, int targetDepth) {
    if (targetDepth <= 0) return null;
    return pickParentAtDepth(nodes, targetDepth - 1, excludeId: nodeId);
  }

  static List<OrgNode> roots(List<OrgNode> nodes) => nodes.where((n) => n.parentId == null).toList();
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
