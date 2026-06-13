import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/data/mock_access_control.dart';
import '../../shared/models/access_control_models.dart';

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

  void addStructure({required String name, required String description, required StructureTemplate template}) {
    final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    final data = MockAccessControl.dataForTemplate(template, name: name);
    final profile = StructureProfile(
      id: id,
      label: name,
      description: description.isEmpty ? 'Structure personnalisée' : description,
      icon: Icons.apartment_rounded,
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
    final nodes = state.activeData.nodes.map((n) => n.id == nodeId ? n.copyWith(parentId: newParentId) : n).toList();
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
final accessRolesProvider = Provider((ref) => MockAccessControl.roles);
