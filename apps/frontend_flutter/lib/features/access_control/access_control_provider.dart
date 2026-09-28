import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;

import '../../shared/data/mock_access_control.dart';
import '../../shared/models/access_control_models.dart';
import 'widgets/org_chart_layout.dart';

class AccessControlState {
  final String activeStructureId;
  final List<StructureProfile> customStructures;
  final Map<String, StructureData> structures;
  final Map<String, List<AccessMember>> savedMembers;
  final List<SharingRequest> sharingRequests;
  final PlanningProposal? planningProposal;
  final bool planningLoading;
  final int planningVariantIndex;
  final bool membersDirty;

  const AccessControlState({
    this.activeStructureId = 'family',
    this.customStructures = const [],
    this.structures = const {},
    this.savedMembers = const {},
    this.sharingRequests = const [],
    this.planningProposal,
    this.planningLoading = false,
    this.planningVariantIndex = 0,
    this.membersDirty = false,
  });

  List<StructureProfile> get allProfiles => [...MockAccessControl.builtInProfiles, ...customStructures];

  StructureProfile get activeProfile =>
      allProfiles.firstWhere((p) => p.id == activeStructureId, orElse: () => MockAccessControl.builtInProfiles.first);

  StructureData get activeData => structures[activeStructureId] ?? MockAccessControl.dataFor('family');

  AccessControlState copyWith({
    String? activeStructureId,
    List<StructureProfile>? customStructures,
    Map<String, StructureData>? structures,
    Map<String, List<AccessMember>>? savedMembers,
    List<SharingRequest>? sharingRequests,
    PlanningProposal? planningProposal,
    bool? planningLoading,
    int? planningVariantIndex,
    bool? membersDirty,
    bool clearProposal = false,
  }) =>
      AccessControlState(
        activeStructureId: activeStructureId ?? this.activeStructureId,
        customStructures: customStructures ?? this.customStructures,
        structures: structures ?? this.structures,
        savedMembers: savedMembers ?? this.savedMembers,
        sharingRequests: sharingRequests ?? this.sharingRequests,
        planningProposal: clearProposal ? null : (planningProposal ?? this.planningProposal),
        planningLoading: planningLoading ?? this.planningLoading,
        planningVariantIndex: planningVariantIndex ?? this.planningVariantIndex,
        membersDirty: membersDirty ?? this.membersDirty,
      );
}

class AccessControlNotifier extends StateNotifier<AccessControlState> {
  AccessControlNotifier() : super(const AccessControlState()) {
    _initStructure('family');
    state = state.copyWith(sharingRequests: MockAccessControl.sharingRequests());
  }

  void _initStructure(String id) {
    final data = MockAccessControl.dataFor(id);
    final structures = Map<String, StructureData>.from(state.structures)..[id] = data;
    final saved = Map<String, List<AccessMember>>.from(state.savedMembers)
      ..[id] = data.members.map((m) => _copyMember(m)).toList();
    state = state.copyWith(
      activeStructureId: id,
      structures: structures,
      savedMembers: saved,
      membersDirty: false,
      clearProposal: true,
    );
  }

  AccessMember _copyMember(AccessMember m) => AccessMember(
        id: m.id,
        name: m.name,
        email: m.email,
        roleId: m.roleId,
        nodeId: m.nodeId,
        permissions: List<String>.from(m.permissions),
        inheritsFromHierarchy: m.inheritsFromHierarchy,
      );

  void setStructure(String id) {
    if (!state.structures.containsKey(id)) {
      final data = MockAccessControl.dataFor(id);
      final structures = Map<String, StructureData>.from(state.structures)..[id] = data;
      final saved = Map<String, List<AccessMember>>.from(state.savedMembers)
        ..[id] = data.members.map((m) => _copyMember(m)).toList();
      state = state.copyWith(structures: structures, savedMembers: saved);
    }
    state = state.copyWith(activeStructureId: id, membersDirty: false, clearProposal: true);
  }

  void addStructure({
    required String name,
    required String description,
    required StructureTemplate template,
    IconData? icon,
  }) {
    final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    final data = MockAccessControl.dataForTemplate(template, name: name);
    final profile = StructureProfile(
      id: id,
      label: name,
      description: description.isEmpty ? 'Structure personnalisée' : description,
      icon: icon ?? Icons.apartment_rounded,
      isCustom: true,
    );
    state = state.copyWith(
      customStructures: [...state.customStructures, profile],
      structures: {...state.structures, id: data},
      savedMembers: {
        ...state.savedMembers,
        id: data.members.map((m) => _copyMember(m)).toList(),
      },
      activeStructureId: id,
      membersDirty: false,
      clearProposal: true,
    );
  }

  void _updateActiveData(StructureData data, {bool? membersDirty}) {
    state = state.copyWith(
      structures: {...state.structures, state.activeStructureId: data},
      membersDirty: membersDirty ?? state.membersDirty,
    );
  }

  void reparentNode(String nodeId, String? newParentId) {
    if (nodeId == newParentId) return;
    final nodes = state.activeData.nodes;
    if (OrgChartHierarchy.wouldCreateCycle(nodes, nodeId, newParentId)) return;
    final updated = nodes.map((n) => n.id == nodeId ? n.copyWith(parentId: newParentId) : n).toList();
    _updateActiveData(state.activeData.copyWith(nodes: updated));
  }

  /// Repositions a node onto a hierarchy level (0 = root / displayed level 1).
  void reparentToLevel(String nodeId, int targetDepth) {
    final nodes = state.activeData.nodes;
    final depths = OrgChartLayout.computeDepths(nodes);
    final currentDepth = depths[nodeId] ?? 0;
    if (currentDepth == targetDepth) return;

    final maxDepth = depths.values.isEmpty ? 0 : depths.values.reduce(math.max);
    String? newParentId;
    if (targetDepth <= 0) {
      newParentId = null;
    } else if (targetDepth > maxDepth) {
      newParentId = OrgChartHierarchy.pickParentAtDepth(nodes, maxDepth, excludeId: nodeId);
    } else {
      newParentId = OrgChartHierarchy.parentIdForLevel(nodes, nodeId, targetDepth);
    }

    if (targetDepth > 0 && newParentId == null) return;
    if (OrgChartHierarchy.wouldCreateCycle(nodes, nodeId, newParentId)) return;

    reparentNode(nodeId, newParentId);
  }

  /// Creates a higher level: the node becomes responsible for the other roots.
  void reparentAboveTop(String nodeId) {
    final nodes = state.activeData.nodes;
    final depths = OrgChartLayout.computeDepths(nodes);
    final depth = depths[nodeId] ?? 0;
    final roots = OrgChartHierarchy.roots(nodes);

    if (depth > 0) {
      reparentToLevel(nodeId, 0);
      return;
    }

    if (roots.length > 1) {
      final updated = nodes.map((n) {
        if (n.id == nodeId) return n.copyWith(parentId: null);
        if (n.parentId == null && n.id != nodeId) return n.copyWith(parentId: nodeId);
        return n;
      }).toList();
      _updateActiveData(state.activeData.copyWith(nodes: updated));
      return;
    }

    reparentToLevel(nodeId, 0);
  }

  void setLevelLabel(int depth, String label) {
    final trimmed = label.trim();
    final labels = Map<int, String>.from(state.activeData.levelLabels);
    if (trimmed.isEmpty) {
      labels.remove(depth);
    } else {
      labels[depth] = trimmed;
    }
    _updateActiveData(state.activeData.copyWith(levelLabels: labels));
  }

  void updateHierarchyLink({
    required String childId,
    required String parentId,
    required OrgHierarchyLinkType linkType,
  }) {
    if (childId == parentId) return;
    final nodes = state.activeData.nodes;
    if (OrgChartHierarchy.wouldCreateCycle(nodes, childId, parentId)) return;
    final updated = nodes
        .map((n) => n.id == childId ? n.copyWith(parentId: parentId, hierarchyLinkType: linkType) : n)
        .toList();
    _updateActiveData(state.activeData.copyWith(nodes: updated));
  }

  void updateNodeRole(String nodeId, String roleId) {
    final nodes = state.activeData.nodes.map((n) => n.id == nodeId ? n.copyWith(roleId: roleId) : n).toList();
    final members = state.activeData.members.map((m) {
      if (m.nodeId == nodeId) return m.copyWith(roleId: roleId);
      return m;
    }).toList();
    _updateActiveData(state.activeData.copyWith(nodes: nodes, members: members));
  }

  void upsertRole(AccessRoleTemplate role) {
    final custom = List<AccessRoleTemplate>.from(state.activeData.customRoles);
    final idx = custom.indexWhere((r) => r.id == role.id);
    if (idx >= 0) {
      custom[idx] = role;
    } else {
      custom.add(role);
    }
    _updateActiveData(state.activeData.copyWith(customRoles: custom));
  }

  void deleteCustomRole(String roleId) {
    if (MockAccessControl.roles.any((r) => r.id == roleId)) return;
    final custom = state.activeData.customRoles.where((r) => r.id != roleId).toList();
    final nodes = state.activeData.nodes
        .map((n) => n.roleId == roleId ? n.copyWith(roleId: 'member') : n)
        .toList();
    _updateActiveData(state.activeData.copyWith(customRoles: custom, nodes: nodes));
  }

  bool isBuiltInRole(String roleId) => MockAccessControl.roles.any((r) => r.id == roleId);

  void updateNodeLinkType(String nodeId, OrgHierarchyLinkType type) {
    final nodes = state.activeData.nodes
        .map((n) => n.id == nodeId ? n.copyWith(hierarchyLinkType: type) : n)
        .toList();
    _updateActiveData(state.activeData.copyWith(nodes: nodes));
  }

  void togglePermission(String memberId, String permissionId) {
    final members = state.activeData.members.map((m) {
      if (m.id != memberId) return m;
      final perms = List<String>.from(m.permissions);
      if (perms.contains(permissionId)) {
        perms.remove(permissionId);
      } else {
        perms.add(permissionId);
      }
      return m.copyWith(permissions: perms, inheritsFromHierarchy: false);
    }).toList();
    _updateActiveData(state.activeData.copyWith(members: members), membersDirty: _isMembersDirty(members));
  }

  bool _isMembersDirty(List<AccessMember> current) {
    final saved = state.savedMembers[state.activeStructureId];
    if (saved == null) return false;
    return !listEquals(
      current.map((m) => '${m.id}:${m.permissions.join(',')}').toList(),
      saved.map((m) => '${m.id}:${m.permissions.join(',')}').toList(),
    );
  }

  void saveMembers() {
    final id = state.activeStructureId;
    final members = state.activeData.members.map((m) => _copyMember(m)).toList();
    state = state.copyWith(
      savedMembers: {...state.savedMembers, id: members},
      membersDirty: false,
    );
  }

  void respondSharing(String requestId, bool accept) {
    final requests = state.sharingRequests.map((r) {
      if (r.id == requestId) return r.copyWith(status: accept ? 'accepted' : 'refused');
      return r;
    }).toList();
    state = state.copyWith(sharingRequests: requests);
  }

  void clearPlanning() => state = state.copyWith(clearProposal: true);

  Future<void> analyzePlanning() async {
    state = state.copyWith(planningLoading: true, clearProposal: true, planningVariantIndex: 0);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    state = state.copyWith(
      planningLoading: false,
      planningProposal: _proposalForActive(0),
    );
  }

  Future<void> regeneratePlanning() async {
    final next = (state.planningVariantIndex + 1) % _variants.length;
    state = state.copyWith(planningLoading: true, planningVariantIndex: next, clearProposal: true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    state = state.copyWith(planningLoading: false, planningProposal: _proposalForActive(next));
  }

  List<PlanningProposal> get _variants {
    if (state.activeStructureId == 'club') {
      return const [
        PlanningProposal(
          conflicts: [PlanningConflict(id: 'c1', title: 'Double réservation terrain', severity: 'high', events: ['Entraînement U17 · 18h00', 'Réunion staff · 18h00'])],
          proposal: 'Chevauchement sur le terrain synthétique à 18h00. Proposition : décaler la réunion staff à 19h30.',
          alternatives: ['Réunion staff → 19h30', 'Entraînement → 16h30'],
        ),
        PlanningProposal(
          conflicts: [PlanningConflict(id: 'c1', title: 'Double réservation terrain', severity: 'high', events: ['Entraînement U17 · 18h00', 'Réunion staff · 18h00'])],
          proposal: 'Alternative : déplacer l\'entraînement U17 au créneau 16h30 et conserver la réunion staff à 18h00.',
          alternatives: ['Prévenir les parents par notification', 'Réserver le terrain annexe'],
        ),
      ];
    }
    return MockAccessControl.familyPlanningVariants();
  }

  PlanningProposal _proposalForActive(int index) {
    final variants = _variants;
    return variants[index % variants.length];
  }

  Future<void> refinePlanning(String prompt) async {
    if (state.planningProposal == null) return;
    state = state.copyWith(planningLoading: true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    final base = state.planningProposal!;
    state = state.copyWith(
      planningLoading: false,
      planningProposal: PlanningProposal(
        conflicts: base.conflicts,
        proposal:
            '${base.proposal}\n\nAjustement demandé : « $prompt »\n\n'
            'Nouvelle proposition intégrant votre consigne.',
        alternatives: [...base.alternatives, 'Notifier les membres concernés'],
      ),
    );
  }
}

final accessControlProvider = StateNotifierProvider<AccessControlNotifier, AccessControlState>(
  (ref) => AccessControlNotifier(),
);

final accessPermissionsProvider = Provider((ref) => MockAccessControl.permissions);

final accessRolesProvider = Provider((ref) {
  final data = ref.watch(accessControlProvider).activeData;
  final customIds = data.customRoles.map((r) => r.id).toSet();
  return [
    ...MockAccessControl.roles.where((r) => !customIds.contains(r.id)),
    ...data.customRoles,
  ];
});
