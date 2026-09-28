import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/theme_context.dart';
import '../../../shared/models/access_control_models.dart';
import '../../../shared/widgets/confidia_dropdown_field.dart';
import '../../../shared/widgets/confidia_modal_sheet.dart';
import 'org_chart_layout.dart';

typedef OrgNodePicker = String? Function(List<OrgNode> nodes, {String? excludeId});

/// Shared modals for the org chart (CONFIDIA style + mobile safe area).
abstract final class OrgChartSheets {
  static void showNodeDetail({
    required BuildContext context,
    required OrgNode node,
    required AccessMember? member,
    required AccessRoleTemplate? role,
    required OrgNode? parentNode,
    required List<AccessRoleTemplate> roles,
    required ValueChanged<String> onRoleChanged,
    required ValueChanged<OrgHierarchyLinkType> onLinkTypeChanged,
  }) {
    showConfidiaSheet(
      context: context,
      title: node.label,
      child: _NodeDetailBody(
        node: node,
        member: member,
        role: role,
        parentNode: parentNode,
        roles: roles,
        onRoleChanged: onRoleChanged,
        onLinkTypeChanged: onLinkTypeChanged,
      ),
    );
  }

  static void showEditLink({
    required BuildContext context,
    required List<OrgNode> nodes,
    required ValueChanged<(String childId, String parentId, OrgHierarchyLinkType type)> onSave,
  }) {
    showConfidiaSheet(
      context: context,
      title: 'Modifier un lien',
      child: _EditLinkBody(nodes: nodes, onSave: onSave),
    );
  }

  static void showManageLevels({
    required BuildContext context,
    required List<OrgNode> nodes,
    required Map<int, String> levelLabels,
    required void Function(int depth, String label) onLabelChanged,
  }) {
    showConfidiaSheet(
      context: context,
      title: 'Gérer les niveaux',
      child: _ManageLevelsBody(
        nodes: nodes,
        levelLabels: levelLabels,
        onLabelChanged: onLabelChanged,
      ),
    );
  }

  static void showManageRoles({
    required BuildContext context,
    required List<AccessRoleTemplate> roles,
    required bool Function(String roleId) isBuiltIn,
    required ValueChanged<AccessRoleTemplate> onUpsert,
    required ValueChanged<String> onDelete,
  }) {
    showConfidiaSheet(
      context: context,
      title: 'Gérer les rôles',
      child: _ManageRolesBody(
        roles: roles,
        isBuiltIn: isBuiltIn,
        onUpsert: onUpsert,
        onDelete: onDelete,
      ),
    );
  }
}

class _NodeDetailBody extends StatefulWidget {
  final OrgNode node;
  final AccessMember? member;
  final AccessRoleTemplate? role;
  final OrgNode? parentNode;
  final List<AccessRoleTemplate> roles;
  final ValueChanged<String> onRoleChanged;
  final ValueChanged<OrgHierarchyLinkType> onLinkTypeChanged;

  const _NodeDetailBody({
    required this.node,
    required this.member,
    required this.role,
    required this.parentNode,
    required this.roles,
    required this.onRoleChanged,
    required this.onLinkTypeChanged,
  });

  @override
  State<_NodeDetailBody> createState() => _NodeDetailBodyState();
}

class _NodeDetailBodyState extends State<_NodeDetailBody> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InfoTile(
          icon: Icons.email_outlined,
          label: 'Contact',
          value: widget.member?.email ?? 'Non renseigné',
        ),
        if (widget.node.subtitle != null) ...[
          const SizedBox(height: 8),
          _InfoTile(icon: Icons.info_outline_rounded, label: 'Profil', value: widget.node.subtitle!),
        ],
        if (widget.parentNode != null) ...[
          const SizedBox(height: 8),
          _InfoTile(
            icon: Icons.arrow_upward_rounded,
            label: 'Rattaché à',
            value: widget.parentNode!.label,
          ),
        ],
        const SizedBox(height: 16),
        Text('Rôle', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        ConfidiaDropdownField<String>(
          value: widget.roles.any((r) => r.id == widget.node.roleId) ? widget.node.roleId : widget.roles.first.id,
          prefixIcon: Icons.badge_outlined,
          items: widget.roles.map((r) => r.id).toList(),
          itemLabel: (id) {
            final r = widget.roles.firstWhere((role) => role.id == id);
            return '${r.label} • ${r.description}';
          },
          onChanged: (id) {
            if (id != null) widget.onRoleChanged(id);
          },
        ),
        if (widget.role != null) ...[
          const SizedBox(height: 8),
          Text(widget.role!.description, style: Theme.of(context).textTheme.labelSmall),
        ],
        const SizedBox(height: 16),
        Text('Type de lien hiérarchique', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        ...OrgHierarchyLinkType.values.map(
          (type) => _LinkTypeTile(
            type: type,
            selected: widget.node.hierarchyLinkType == type,
            enabled: widget.node.parentId != null,
            onTap: () => widget.onLinkTypeChanged(type),
          ),
        ),
        if (widget.node.parentId == null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Les racines n\'ont pas de lien ascendant.',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: ConfidiaColors.textSecondary(isDark)),
            ),
          ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: ConfidiaColors.textSecondary(isDark).withValues(alpha: isDark ? 0.1 : 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: ConfidiaColors.border(isDark)),
          ),
          child: Row(
            children: [
              Icon(Icons.touch_app_rounded, size: 16, color: ConfidiaColors.textSecondary(isDark)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Utilisez la poignée sur la carte pour déplacer ce membre vers un autre niveau.',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EditLinkBody extends StatefulWidget {
  final List<OrgNode> nodes;
  final ValueChanged<(String childId, String parentId, OrgHierarchyLinkType type)> onSave;

  const _EditLinkBody({required this.nodes, required this.onSave});

  @override
  State<_EditLinkBody> createState() => _EditLinkBodyState();
}

class _EditLinkBodyState extends State<_EditLinkBody> {
  String? _parentId;
  String? _childId;
  OrgHierarchyLinkType _linkType = OrgHierarchyLinkType.reportsTo;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final parentCandidates = widget.nodes;
    final childCandidates = widget.nodes.where((n) => n.id != _parentId).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Personne supérieure', style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ConfidiaDropdownField<String>(
          value: _parentId,
          hintText: 'Choisir…',
          prefixIcon: Icons.person_outline_rounded,
          items: parentCandidates.map((n) => n.id).toList(),
          itemLabel: (id) => parentCandidates.firstWhere((n) => n.id == id).label,
          onChanged: (v) => setState(() {
            _parentId = v;
            if (_childId == v) _childId = null;
          }),
        ),
        const SizedBox(height: 16),
        Text('Personne subordonnée', style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ConfidiaDropdownField<String>(
          value: _childId,
          hintText: 'Choisir…',
          prefixIcon: Icons.person_outline_rounded,
          items: childCandidates.map((n) => n.id).toList(),
          itemLabel: (id) => childCandidates.firstWhere((n) => n.id == id).label,
          onChanged: (v) => setState(() => _childId = v),
        ),
        const SizedBox(height: 16),
        Text('Type de lien', style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ...OrgHierarchyLinkType.values.map(
          (type) => _LinkTypeTile(
            type: type,
            selected: _linkType == type,
            enabled: true,
            onTap: () => setState(() => _linkType = type),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: FilledButton.icon(
            onPressed: _parentId != null && _childId != null
                ? () {
                    widget.onSave((_childId!, _parentId!, _linkType));
                    Navigator.pop(context);
                  }
                : null,
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('Appliquer le lien'),
            style: FilledButton.styleFrom(backgroundColor: palette.primary),
          ),
        ),
      ],
    );
  }
}

class _ManageLevelsBody extends StatelessWidget {
  final List<OrgNode> nodes;
  final Map<int, String> levelLabels;
  final void Function(int depth, String label) onLabelChanged;

  const _ManageLevelsBody({
    required this.nodes,
    required this.levelLabels,
    required this.onLabelChanged,
  });

  @override
  Widget build(BuildContext context) {
    final depths = OrgChartLayout.computeDepths(nodes);
    final maxDepth = depths.values.isEmpty ? 0 : depths.values.reduce((a, b) => a > b ? a : b);
    final maxBand = maxDepth + 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Renommez les niveaux pour clarifier votre organigramme. '
          'Glissez une carte au-dessus ou en dessous pour créer un niveau supplémentaire.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        for (var d = 0; d <= maxBand; d++) ...[
          _LevelLabelField(
            depth: d,
            defaultLabel: 'Niveau ${d + 1}',
            initial: levelLabels[d] ?? '',
            onSubmitted: (v) => onLabelChanged(d, v),
          ),
          if (d < maxBand) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _LevelLabelField extends StatefulWidget {
  final int depth;
  final String defaultLabel;
  final String initial;
  final ValueChanged<String> onSubmitted;

  const _LevelLabelField({
    required this.depth,
    required this.defaultLabel,
    required this.initial,
    required this.onSubmitted,
  });

  @override
  State<_LevelLabelField> createState() => _LevelLabelFieldState();
}

class _LevelLabelFieldState extends State<_LevelLabelField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(widget.defaultLabel, style: Theme.of(context).textTheme.labelSmall),
        ),
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: _fieldDecoration(context).copyWith(hintText: widget.defaultLabel),
            onSubmitted: widget.onSubmitted,
            onEditingComplete: () => widget.onSubmitted(_controller.text),
          ),
        ),
      ],
    );
  }
}

class _ManageRolesBody extends StatefulWidget {
  final List<AccessRoleTemplate> roles;
  final bool Function(String roleId) isBuiltIn;
  final ValueChanged<AccessRoleTemplate> onUpsert;
  final ValueChanged<String> onDelete;

  const _ManageRolesBody({
    required this.roles,
    required this.isBuiltIn,
    required this.onUpsert,
    required this.onDelete,
  });

  @override
  State<_ManageRolesBody> createState() => _ManageRolesBodyState();
}

class _ManageRolesBodyState extends State<_ManageRolesBody> {
  void _openEditor([AccessRoleTemplate? existing]) {
    final labelCtrl = TextEditingController(text: existing?.label ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final levelCtrl = TextEditingController(text: '${existing?.level ?? 3}');

    showConfidiaSheet(
      context: context,
      title: existing == null ? 'Nouveau rôle' : 'Modifier le rôle',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(controller: labelCtrl, decoration: _fieldDecoration(context).copyWith(labelText: 'Nom du rôle')),
          const SizedBox(height: 8),
          TextField(controller: descCtrl, decoration: _fieldDecoration(context).copyWith(labelText: 'Description')),
          const SizedBox(height: 8),
          TextField(
            controller: levelCtrl,
            keyboardType: TextInputType.number,
            decoration: _fieldDecoration(context).copyWith(labelText: 'Niveau hiérarchique (0 = sommet)'),
          ),
        ],
      ),
      actions: [
        Center(
          child: FilledButton(
            onPressed: () {
              final label = labelCtrl.text.trim();
              if (label.isEmpty) return;
              final id = existing?.id ?? 'role_${DateTime.now().millisecondsSinceEpoch}';
              widget.onUpsert(
                AccessRoleTemplate(
                  id: id,
                  label: label,
                  description: descCtrl.text.trim().isEmpty ? label : descCtrl.text.trim(),
                  level: int.tryParse(levelCtrl.text) ?? 3,
                ),
              );
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Enregistrer'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: OutlinedButton.icon(
            onPressed: () => _openEditor(),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Créer un rôle'),
          ),
        ),
        const SizedBox(height: 12),
        ...widget.roles.map((role) {
          final builtIn = widget.isBuiltIn(role.id);
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: ConfidiaColors.border(Theme.of(context).brightness == Brightness.dark)),
            ),
            child: ListTile(
              leading: Icon(
                roleIcon(role.id),
                color: ConfidiaColors.textSecondary(Theme.of(context).brightness == Brightness.dark),
                size: 20,
              ),
              title: Text(role.label, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${role.description} · niveau ${role.level}${builtIn ? ' · intégré' : ''}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    onPressed: () => _openEditor(role),
                  ),
                  if (!builtIn)
                    IconButton(
                      icon: Icon(Icons.delete_outline_rounded, size: 18, color: ConfidiaColors.error),
                      onPressed: () => widget.onDelete(role.id),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: ConfidiaColors.textSecondary(isDark)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
              Text(value, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _LinkTypeTile extends StatelessWidget {
  final OrgHierarchyLinkType type;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _LinkTypeTile({
    required this.type,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = context.palette;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      enabled: enabled,
      leading: Icon(
        type.icon,
        size: 18,
        color: selected ? palette.primary : ConfidiaColors.textSecondary(isDark),
      ),
      title: Text(type.label, style: Theme.of(context).textTheme.bodySmall),
      subtitle: Text(
        switch (type) {
          OrgHierarchyLinkType.reportsTo => 'Ligne pleine • autorité directe',
          OrgHierarchyLinkType.dottedLine => 'Pointillés • coordination transverse',
          OrgHierarchyLinkType.delegate => 'Tirets et points • pouvoir délégué',
        },
        style: Theme.of(context).textTheme.labelSmall,
      ),
      trailing: selected ? Icon(Icons.check_rounded, size: 18, color: palette.primary) : null,
      onTap: enabled ? onTap : null,
    );
  }
}

InputDecoration _fieldDecoration(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return InputDecoration(
    isDense: true,
    filled: true,
    fillColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  );
}
