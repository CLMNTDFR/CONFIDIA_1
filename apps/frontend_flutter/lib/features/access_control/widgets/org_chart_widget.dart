import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/theme_context.dart';
import '../../../shared/models/access_control_models.dart';
import '../../../shared/widgets/confidia_button.dart';
import '../../../shared/widgets/glass_card.dart';
import 'org_chart_layout.dart';
import 'org_chart_sheets.dart';

/// Organigramme par niveaux horizontaux avec grille, toolbar et drag-and-drop.
class OrgChartWidget extends StatefulWidget {
  final List<OrgNode> nodes;
  final List<AccessMember> members;
  final List<AccessRoleTemplate> roles;
  final Map<int, String> levelLabels;
  final ValueChanged<(String nodeId, int targetDepth)> onReparentToLevel;
  final ValueChanged<String> onReparentAboveTop;
  final ValueChanged<(String nodeId, OrgHierarchyLinkType type)> onLinkTypeChanged;
  final ValueChanged<(String childId, String parentId, OrgHierarchyLinkType type)> onUpdateLink;
  final void Function(int depth, String label) onLevelLabelChanged;
  final ValueChanged<(String nodeId, String roleId)> onNodeRoleChanged;
  final ValueChanged<AccessRoleTemplate> onUpsertRole;
  final ValueChanged<String> onDeleteRole;
  final bool Function(String roleId) isBuiltInRole;
  final bool enablePinchZoom;
  final bool showFullscreenAction;

  const OrgChartWidget({
    super.key,
    required this.nodes,
    required this.members,
    required this.roles,
    this.levelLabels = const {},
    required this.onReparentToLevel,
    required this.onReparentAboveTop,
    required this.onLinkTypeChanged,
    required this.onUpdateLink,
    required this.onLevelLabelChanged,
    required this.onNodeRoleChanged,
    required this.onUpsertRole,
    required this.onDeleteRole,
    required this.isBuiltInRole,
    this.enablePinchZoom = false,
    this.showFullscreenAction = true,
  });

  @override
  State<OrgChartWidget> createState() => _OrgChartWidgetState();
}

class _OrgChartWidgetState extends State<OrgChartWidget> {
  String? _draggingId;
  int? _hoverLevel;
  late final ScrollController _verticalScroll;
  late final ScrollController _horizontalScroll;

  @override
  void initState() {
    super.initState();
    _verticalScroll = ScrollController();
    _horizontalScroll = ScrollController();
  }

  @override
  void dispose() {
    _verticalScroll.dispose();
    _horizontalScroll.dispose();
    super.dispose();
  }

  AccessMember? _memberFor(OrgNode node) {
    if (node.memberId != null) {
      for (final m in widget.members) {
        if (m.id == node.memberId) return m;
      }
    }
    for (final m in widget.members) {
      if (m.nodeId == node.id) return m;
    }
    return null;
  }

  OrgNode? _nodeById(String? id) {
    if (id == null) return null;
    for (final n in widget.nodes) {
      if (n.id == id) return n;
    }
    return null;
  }

  String _initials(OrgNode node, AccessMember? member) {
    if (node.avatarInitials != null && node.avatarInitials!.isNotEmpty) {
      return node.avatarInitials!;
    }
    if (member != null) {
      final parts = member.name.trim().split(RegExp(r'\s+'));
      if (parts.length >= 2) return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
      if (parts.isNotEmpty) return parts.first.substring(0, 1).toUpperCase();
    }
    return node.firstName.isNotEmpty ? node.firstName[0].toUpperCase() : '?';
  }

  AccessRoleTemplate? _roleFor(String roleId) {
    for (final r in widget.roles) {
      if (r.id == roleId) return r;
    }
    return null;
  }

  String _levelLabel(int depth, int maxDepth) {
    if (depth == -1) return '+ Créer un niveau supérieur';
    if (depth > maxDepth) return '+ Créer un niveau inférieur';
    return widget.levelLabels[depth] ?? 'Niveau ${depth + 1}';
  }

  bool _canDropOnBand(String draggedId, OrgLevelBand band, int maxDepth) {
    if (band.isExtension) {
      if (band.depth == -1) return true;
      if (band.depth == maxDepth + 1) {
        return OrgChartHierarchy.pickParentAtDepth(widget.nodes, maxDepth, excludeId: draggedId) != null;
      }
      return false;
    }
    final depths = OrgChartLayout.computeDepths(widget.nodes);
    final currentDepth = depths[draggedId] ?? 0;
    if (currentDepth == band.depth) return false;
    if (band.depth == 0) return true;
    return OrgChartHierarchy.parentIdForLevel(widget.nodes, draggedId, band.depth) != null;
  }

  void _acceptDrop(String draggedId, OrgLevelBand band, int maxDepth) {
    if (band.isExtension && band.depth == -1) {
      widget.onReparentAboveTop(draggedId);
    } else if (band.isExtension && band.depth == maxDepth + 1) {
      widget.onReparentToLevel((draggedId, maxDepth + 1));
    } else {
      widget.onReparentToLevel((draggedId, band.depth));
    }
  }

  void _showNodeSheet(OrgNode node) {
    OrgChartSheets.showNodeDetail(
      context: context,
      node: node,
      member: _memberFor(node),
      role: _roleFor(node.roleId),
      parentNode: _nodeById(node.parentId),
      roles: widget.roles,
      onRoleChanged: (roleId) => widget.onNodeRoleChanged((node.id, roleId)),
      onLinkTypeChanged: (type) => widget.onLinkTypeChanged((node.id, type)),
    );
  }

  void _openFullscreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (ctx) => Scaffold(
          appBar: AppBar(
            title: const Text('Organigramme'),
            leading: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Center(
                child: ConfidiaCloseButton(onPressed: () => Navigator.of(ctx).pop()),
              ),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(ConfidiaSpacing.sm),
                  child: OrgChartWidget(
                nodes: widget.nodes,
                members: widget.members,
                roles: widget.roles,
                levelLabels: widget.levelLabels,
                onReparentToLevel: widget.onReparentToLevel,
                onReparentAboveTop: widget.onReparentAboveTop,
                onLinkTypeChanged: widget.onLinkTypeChanged,
                onUpdateLink: widget.onUpdateLink,
                onLevelLabelChanged: widget.onLevelLabelChanged,
                onNodeRoleChanged: widget.onNodeRoleChanged,
                onUpsertRole: widget.onUpsertRole,
                onDeleteRole: widget.onDeleteRole,
                isBuiltInRole: widget.isBuiltInRole,
                enablePinchZoom: true,
                showFullscreenAction: false,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dragging = _draggingId != null;
    final layout = OrgChartLayout.compute(
      widget.nodes,
      showTopExtension: dragging,
      showBottomExtension: dragging,
    );
    final palette = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (layout.nodeRects.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(ConfidiaSpacing.lg),
        child: const Center(child: Text('Aucun membre dans l\'organigramme')),
      );
    }

    final chartHeight = widget.enablePinchZoom
        ? layout.canvasSize.height + 48.0
        : math.min(520.0, layout.canvasSize.height + 24.0);

    Widget chartBody = SizedBox(
      height: widget.enablePinchZoom ? null : chartHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewportWidth = constraints.maxWidth;

          final scrollable = Scrollbar(
            controller: _verticalScroll,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _verticalScroll,
              primary: false,
              child: Scrollbar(
                controller: _horizontalScroll,
                thumbVisibility: true,
                notificationPredicate: (n) => n.depth == 1,
                child: SingleChildScrollView(
                  controller: _horizontalScroll,
                  scrollDirection: Axis.horizontal,
                  primary: false,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: viewportWidth),
                    child: Center(
                      child: SizedBox(
                        width: layout.canvasSize.width,
                        height: layout.canvasSize.height,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            CustomPaint(
                              size: layout.canvasSize,
                              painter: _OrgLevelGridPainter(
                                levelBands: layout.levelBands,
                                hoverDepth: _hoverLevel,
                                isDark: isDark,
                                lineColor: ConfidiaColors.border(isDark),
                                accentColor: palette.primary,
                              ),
                            ),
                            CustomPaint(
                              size: layout.canvasSize,
                              painter: _OrgConnectorPainter(
                                connectors: layout.connectors,
                                lineColor: ConfidiaColors.border(isDark),
                                primaryColor: palette.primary,
                                secondaryColor: palette.secondary,
                                accentColor: palette.accent,
                              ),
                            ),
                            ...layout.levelBands.where((b) => !b.isExtension).map(
                                  (band) => Positioned(
                                    left: 12,
                                    top: band.rect.top + 6,
                                    child: IgnorePointer(
                                      child: Text(
                                        _levelLabel(band.depth, layout.maxDepth),
                                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                              color: ConfidiaColors.textSecondary(isDark),
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                            ...layout.nodeRects.entries.map((entry) {
                              final node = widget.nodes.firstWhere((n) => n.id == entry.key);
                              final member = _memberFor(node);
                              final role = _roleFor(node.roleId);
                              final isDragging = _draggingId == node.id;

                              return Positioned.fromRect(
                                rect: entry.value,
                                child: _OrgNodeCard(
                                  node: node,
                                  initials: _initials(node, member),
                                  roleLabel: role?.label ?? node.roleId,
                                  roleColor: _roleColor(node.roleId, palette),
                                  isDragging: isDragging,
                                  onTap: () => _showNodeSheet(node),
                                  onDragStarted: () => setState(() => _draggingId = node.id),
                                  onDragEnded: () => setState(() {
                                    _draggingId = null;
                                    _hoverLevel = null;
                                  }),
                                ),
                              );
                            }),
                            if (dragging)
                              ...layout.levelBands.map(
                                (band) => Positioned.fromRect(
                                  rect: band.rect,
                                  child: _LevelDropZone(
                                    label: _levelLabel(band.depth, layout.maxDepth),
                                    isExtension: band.isExtension,
                                    active: _hoverLevel == band.depth,
                                    onWillAccept: (id) => _canDropOnBand(id, band, layout.maxDepth),
                                    onAccept: (id) => _acceptDrop(id, band, layout.maxDepth),
                                    onHover: (hover) => setState(() {
                                      _hoverLevel = hover ? band.depth : (_hoverLevel == band.depth ? null : _hoverLevel);
                                    }),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );

          if (widget.enablePinchZoom) {
            return InteractiveViewer(
              boundaryMargin: const EdgeInsets.all(120),
              minScale: 0.35,
              maxScale: 4,
              child: scrollable,
            );
          }
          return scrollable;
        },
      ),
    );

    if (widget.enablePinchZoom) {
      chartBody = Expanded(child: chartBody);
    }

    return GlassCard(
      clipContent: false,
      padding: const EdgeInsets.fromLTRB(ConfidiaSpacing.md, ConfidiaSpacing.md, ConfidiaSpacing.md, ConfidiaSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!widget.enablePinchZoom) ...[
            Row(
              children: [
                Icon(Icons.account_tree_rounded, size: 16, color: ConfidiaColors.textSecondary(isDark)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Organigramme',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                if (widget.showFullscreenAction)
                  IconButton(
                    icon: const Icon(Icons.fullscreen_rounded, size: 20),
                    tooltip: 'Plein écran',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: () => _openFullscreen(context),
                  ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          _OrgToolbar(
            onEditLink: () => OrgChartSheets.showEditLink(
              context: context,
              nodes: widget.nodes,
              onSave: widget.onUpdateLink,
            ),
            onManageLevels: () => OrgChartSheets.showManageLevels(
              context: context,
              nodes: widget.nodes,
              levelLabels: widget.levelLabels,
              onLabelChanged: widget.onLevelLabelChanged,
            ),
            onManageRoles: () => OrgChartSheets.showManageRoles(
              context: context,
              roles: widget.roles,
              isBuiltIn: widget.isBuiltInRole,
              onUpsert: widget.onUpsertRole,
              onDelete: widget.onDeleteRole,
            ),
          ),
          const SizedBox(height: ConfidiaSpacing.sm),
          _LinkLegend(isDark: isDark),
          const SizedBox(height: ConfidiaSpacing.sm),
          chartBody,
        ],
      ),
    );
  }

  Color _roleColor(String roleId, ConfidiaPalette palette) => switch (roleId) {
        'admin' || 'director' || 'ceo' => palette.primary,
        'parent' || 'manager' => palette.secondary,
        'coach' || 'treasurer' || 'secretary' => palette.accent,
        _ => palette.primary.withValues(alpha: 0.75),
      };
}

class _OrgToolbar extends StatelessWidget {
  final VoidCallback onEditLink;
  final VoidCallback onManageLevels;
  final VoidCallback onManageRoles;

  const _OrgToolbar({
    required this.onEditLink,
    required this.onManageLevels,
    required this.onManageRoles,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = ConfidiaColors.textSecondary(isDark);
    Widget chip({required IconData icon, required String label, required VoidCallback onTap}) {
      return ActionChip(
        avatar: Icon(icon, size: 16, color: muted),
        label: Text(label),
        labelStyle: Theme.of(context).textTheme.labelSmall,
        backgroundColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
        side: BorderSide(color: ConfidiaColors.border(isDark)),
        onPressed: onTap,
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip(icon: Icons.link_rounded, label: 'Lien', onTap: onEditLink),
          const SizedBox(width: 8),
          chip(icon: Icons.layers_rounded, label: 'Niveaux', onTap: onManageLevels),
          const SizedBox(width: 8),
          chip(icon: Icons.badge_outlined, label: 'Rôles', onTap: onManageRoles),
        ],
      ),
    );
  }
}

class _LinkLegend extends StatelessWidget {
  final bool isDark;

  const _LinkLegend({required this.isDark});

  @override
  Widget build(BuildContext context) {
    Widget item(IconData icon, String label, Color color) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: ConfidiaColors.textSecondary(isDark))),
          ],
        );

    final palette = context.palette;
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        item(Icons.remove_rounded, 'Direct', ConfidiaColors.border(isDark)),
        item(Icons.more_horiz_rounded, 'Fonctionnel', palette.primary),
        item(Icons.swap_horiz_rounded, 'Délégation', palette.secondary),
      ],
    );
  }
}

class _LevelDropZone extends StatelessWidget {
  final String label;
  final bool isExtension;
  final bool active;
  final bool Function(String draggedId) onWillAccept;
  final ValueChanged<String> onAccept;
  final ValueChanged<bool> onHover;

  const _LevelDropZone({
    required this.label,
    required this.isExtension,
    required this.active,
    required this.onWillAccept,
    required this.onAccept,
    required this.onHover,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DragTarget<String>(
      onWillAcceptWithDetails: (d) => onWillAccept(d.data),
      onAcceptWithDetails: (d) => onAccept(d.data),
      onMove: (_) => onHover(true),
      onLeave: (_) => onHover(false),
      builder: (context, candidate, _) {
        final highlight = active || candidate.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: palette.primary.withValues(alpha: isDark ? (highlight ? 0.2 : 0.05) : (highlight ? 0.12 : 0.03)),
            border: Border.all(
              color: palette.primary.withValues(alpha: highlight ? 0.6 : 0.15),
              width: highlight ? 2 : 1,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
            borderRadius: BorderRadius.circular(isExtension ? 12 : 8),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isExtension) Icon(Icons.add_rounded, size: 16, color: palette.primary),
                if (isExtension) const SizedBox(width: 8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: highlight ? palette.primary : ConfidiaColors.textSecondary(isDark),
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OrgNodeCard extends StatelessWidget {
  final OrgNode node;
  final String initials;
  final String roleLabel;
  final Color roleColor;
  final bool isDragging;
  final VoidCallback onTap;
  final VoidCallback onDragStarted;
  final VoidCallback onDragEnded;

  const _OrgNodeCard({
    required this.node,
    required this.initials,
    required this.roleLabel,
    required this.roleColor,
    required this.isDragging,
    required this.onTap,
    required this.onDragStarted,
    required this.onDragEnded,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = context.palette;
    final hasParent = node.parentId != null;

    Widget cardContent({bool feedback = false}) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        height: OrgChartLayout.nodeHeight,
        decoration: BoxDecoration(
          color: isDark ? ConfidiaColors.darkSurfaceElevated.withValues(alpha: 0.96) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDragging ? palette.secondary.withValues(alpha: 0.55) : ConfidiaColors.border(isDark),
            width: isDragging ? 1.5 : 1,
          ),
          boxShadow: feedback
              ? [BoxShadow(color: palette.primary.withValues(alpha: 0.22), blurRadius: 18, offset: const Offset(0, 6))]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.07),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 4,
                color: roleColor,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: roleColor.withValues(alpha: 0.14),
                            child: Text(
                              initials,
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: roleColor, height: 1),
                            ),
                          ),
                          const Spacer(),
                          if (hasParent)
                            Tooltip(
                              message: node.hierarchyLinkType.label,
                              child: Icon(
                                node.hierarchyLinkType.icon,
                                size: 13,
                                color: node.hierarchyLinkType.isDelegate
                                    ? palette.secondary
                                    : node.hierarchyLinkType.isDashed
                                        ? palette.primary
                                        : ConfidiaColors.textSecondary(isDark),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        node.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                              fontSize: 11,
                            ),
                      ),
                      if (node.subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          node.subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: ConfidiaColors.textSecondary(isDark),
                                fontSize: 9,
                                height: 1.1,
                              ),
                        ),
                      ],
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: roleColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: roleColor.withValues(alpha: 0.35)),
                        ),
                        child: Text(
                          roleLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: roleColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 9,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final dragHandle = Tooltip(
      message: 'Glisser vers un niveau',
      child: MouseRegion(
        cursor: isDragging ? SystemMouseCursors.grabbing : SystemMouseCursors.grab,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: ConfidiaColors.border(isDark)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 4, offset: const Offset(0, 1)),
            ],
          ),
          child: Icon(Icons.open_with_rounded, size: 13, color: ConfidiaColors.textSecondary(isDark)),
        ),
      ),
    );

    return Opacity(
      opacity: isDragging ? 0.42 : 1,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            cardContent(),
            Positioned(
              top: 8,
              right: 4,
              child: Draggable<String>(
                data: node.id,
                dragAnchorStrategy: pointerDragAnchorStrategy,
                rootOverlay: true,
                maxSimultaneousDrags: 1,
                onDragStarted: onDragStarted,
                onDragEnd: (_) => onDragEnded(),
                feedback: Material(
                  color: Colors.transparent,
                  elevation: 8,
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: OrgChartLayout.nodeWidth,
                    height: OrgChartLayout.nodeHeight,
                    child: cardContent(feedback: true),
                  ),
                ),
                childWhenDragging: Opacity(opacity: 0.35, child: dragHandle),
                child: dragHandle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrgLevelGridPainter extends CustomPainter {
  final List<OrgLevelBand> levelBands;
  final int? hoverDepth;
  final bool isDark;
  final Color lineColor;
  final Color accentColor;

  _OrgLevelGridPainter({
    required this.levelBands,
    required this.hoverDepth,
    required this.isDark,
    required this.lineColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = lineColor.withValues(alpha: isDark ? 0.32 : 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var i = 0; i <= 6; i++) {
      final x = size.width * i / 6;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    for (final band in levelBands) {
      if (band.isExtension) continue;
      final y = band.rect.top;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);

      final fill = Paint()
        ..color = (hoverDepth == band.depth ? accentColor : lineColor).withValues(alpha: isDark ? 0.06 : 0.04)
        ..style = PaintingStyle.fill;
      canvas.drawRect(band.rect, fill);
    }
  }

  @override
  bool shouldRepaint(covariant _OrgLevelGridPainter oldDelegate) =>
      oldDelegate.levelBands != levelBands || oldDelegate.hoverDepth != hoverDepth;
}

class _OrgConnectorPainter extends CustomPainter {
  final List<OrgChartConnector> connectors;
  final Color lineColor;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;

  _OrgConnectorPainter({
    required this.connectors,
    required this.lineColor,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final connector in connectors) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      switch (connector.linkType) {
        case OrgHierarchyLinkType.reportsTo:
          paint
            ..color = lineColor.withValues(alpha: 0.9)
            ..strokeWidth = 2;
          canvas.drawPath(connector.path, paint);
        case OrgHierarchyLinkType.dottedLine:
          paint
            ..color = primaryColor.withValues(alpha: 0.65)
            ..strokeWidth = 1.5;
          _drawDashedPath(canvas, connector.path, paint, dashWidth: 4, dashSpace: 5);
        case OrgHierarchyLinkType.delegate:
          paint
            ..color = secondaryColor.withValues(alpha: 0.8)
            ..strokeWidth = 2;
          _drawDotDashPath(canvas, connector.path, paint);
      }
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint, {required double dashWidth, required double dashSpace}) {
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(metric.extractPath(distance, next.clamp(0, metric.length)), paint);
        distance = next + dashSpace;
      }
    }
  }

  void _drawDotDashPath(Canvas canvas, Path path, Paint paint) {
    const dashWidth = 10.0;
    const dashSpace = 5.0;
    const dotRadius = 1.8;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final dashEnd = distance + dashWidth;
        canvas.drawPath(metric.extractPath(distance, dashEnd.clamp(0, metric.length)), paint);

        final dotPos = dashEnd + dashSpace / 2;
        if (dotPos < metric.length) {
          final tangent = metric.getTangentForOffset(dotPos);
          if (tangent != null) {
            canvas.drawCircle(tangent.position, dotRadius, paint..style = PaintingStyle.fill);
            paint.style = PaintingStyle.stroke;
          }
        }
        distance = dashEnd + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _OrgConnectorPainter oldDelegate) => oldDelegate.connectors != connectors;
}
