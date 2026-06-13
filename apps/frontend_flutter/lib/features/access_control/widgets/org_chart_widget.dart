import 'package:flutter/material.dart';

import '../../../core/theme/spacing.dart';
import '../../../core/theme/theme_context.dart';
import '../../../shared/models/access_control_models.dart';
import '../../../shared/widgets/glass_card.dart';

/// Organigramme interactif : glisser une carte et la déposer sur une autre.
class OrgChartWidget extends StatelessWidget {
  final List<OrgNode> nodes;
  final ValueChanged<(String nodeId, String? parentId)> onReparent;

  const OrgChartWidget({super.key, required this.nodes, required this.onReparent});

  List<OrgNode> _children(String? parentId) => nodes.where((n) => n.parentId == parentId).toList();

  bool _wouldCreateCycle(String draggedId, String? newParentId) {
    if (newParentId == null) return false;
    if (draggedId == newParentId) return true;
    var cursor = newParentId;
    while (true) {
      if (cursor == draggedId) return true;
      final matches = nodes.where((n) => n.id == cursor);
      if (matches.isEmpty) return false;
      final parentId = matches.first.parentId;
      if (parentId == null) return false;
      cursor = parentId;
    }
  }

  bool _canDropAsRoot(String draggedId) {
    final matches = nodes.where((n) => n.id == draggedId);
    if (matches.isEmpty) return false;
    return matches.first.parentId != null;
  }

  @override
  Widget build(BuildContext context) {
    final roots = _children(null);
    if (roots.isEmpty) {
      return const Center(child: Text('Aucun membre dans l\'organigramme'));
    }

    final palette = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      padding: const EdgeInsets.all(ConfidiaSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.account_tree_rounded, size: 16, color: palette.secondary),
              const SizedBox(width: 6),
              Text('Organigramme', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('Glisser · déposer', style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
          const SizedBox(height: ConfidiaSpacing.sm),
          DragTarget<String>(
            onWillAcceptWithDetails: (d) => _canDropAsRoot(d.data),
            onAcceptWithDetails: (d) => onReparent((d.data, null)),
            builder: (context, candidate, _) {
              final active = candidate.isNotEmpty;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(bottom: ConfidiaSpacing.sm),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: palette.primary.withValues(alpha: active ? 0.55 : 0.2),
                    width: active ? 1.5 : 1,
                  ),
                  color: palette.primary.withValues(alpha: isDark ? (active ? 0.14 : 0.06) : (active ? 0.08 : 0.03)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.vertical_align_top_rounded, size: 16, color: palette.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Déposer ici pour placer à la racine',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              );
            },
          ),
          ...roots.map(
            (root) => _OrgBranch(
              node: root,
              nodes: nodes,
              depth: 0,
              wouldCreateCycle: _wouldCreateCycle,
              onReparent: onReparent,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrgBranch extends StatelessWidget {
  final OrgNode node;
  final List<OrgNode> nodes;
  final int depth;
  final bool Function(String draggedId, String? newParentId) wouldCreateCycle;
  final ValueChanged<(String, String?)> onReparent;

  const _OrgBranch({
    required this.node,
    required this.nodes,
    required this.depth,
    required this.wouldCreateCycle,
    required this.onReparent,
  });

  List<OrgNode> get _children => nodes.where((n) => n.parentId == node.id).toList();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: depth * 20.0),
          child: _OrgNodeCard(
            node: node,
            canAcceptDrop: (draggedId) => draggedId != node.id && !wouldCreateCycle(draggedId, node.id),
            onDrop: (draggedId) => onReparent((draggedId, node.id)),
          ),
        ),
        ..._children.map(
          (child) => Padding(
            padding: const EdgeInsets.only(top: 6),
            child: _OrgBranch(
              node: child,
              nodes: nodes,
              depth: depth + 1,
              wouldCreateCycle: wouldCreateCycle,
              onReparent: onReparent,
            ),
          ),
        ),
      ],
    );
  }
}

class _OrgNodeCard extends StatelessWidget {
  final OrgNode node;
  final bool Function(String draggedId) canAcceptDrop;
  final ValueChanged<String> onDrop;

  const _OrgNodeCard({
    required this.node,
    required this.canAcceptDrop,
    required this.onDrop,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = context.palette;

    Widget cardBody({bool dragging = false}) {
      return Row(
        children: [
          Icon(Icons.drag_indicator_rounded, size: 18, color: palette.primary.withValues(alpha: dragging ? 1 : 0.7)),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 14,
            backgroundColor: palette.secondary.withValues(alpha: 0.2),
            child: Text(
              node.avatarInitials ?? node.label.characters.first,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: palette.primary),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(node.label, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
                if (node.subtitle != null) Text(node.subtitle!, style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
          Icon(roleIcon(node.roleId), size: 16, color: palette.accent),
        ],
      );
    }

    Widget buildCard({bool highlight = false, double opacity = 1}) {
      return Opacity(
        opacity: opacity,
        child: Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: palette.primary.withValues(alpha: isDark ? (highlight ? 0.2 : 0.1) : (highlight ? 0.1 : 0.05)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: palette.primary.withValues(alpha: highlight ? 0.55 : 0.25), width: highlight ? 1.5 : 1),
          ),
          child: cardBody(),
        ),
      );
    }

    return DragTarget<String>(
      onWillAcceptWithDetails: (d) => canAcceptDrop(d.data),
      onAcceptWithDetails: (d) => onDrop(d.data),
      builder: (context, candidate, rejected) {
        final highlight = candidate.isNotEmpty;
        final card = buildCard(highlight: highlight);

        return Draggable<String>(
          data: node.id,
          dragAnchorStrategy: pointerDragAnchorStrategy,
          rootOverlay: true,
          maxSimultaneousDrags: 1,
          feedback: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(10),
            color: Colors.transparent,
            child: Opacity(
              opacity: 0.95,
              child: SizedBox(width: 280, child: buildCard(highlight: true)),
            ),
          ),
          childWhenDragging: buildCard(opacity: 0.35),
          child: MouseRegion(
            cursor: SystemMouseCursors.grab,
            child: card,
          ),
        );
      },
    );
  }
}
