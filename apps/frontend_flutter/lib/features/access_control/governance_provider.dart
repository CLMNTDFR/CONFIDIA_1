import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_error_message.dart';
import '../../core/auth/auth_provider.dart';
import '../../shared/models/access_control_models.dart';
import 'governance_api_service.dart';
import 'governance_models.dart';
import 'widgets/org_chart_layout.dart';

final governanceApiProvider = Provider<GovernanceApiService>(
  (ref) => GovernanceApiService(ref.watch(apiClientProvider)),
);

const liveGovernanceRoles = <AccessRoleTemplate>[
  AccessRoleTemplate(
    id: 'owner',
    label: 'Propriétaire',
    description: 'Titulaire de l\'espace',
    level: 0,
  ),
  AccessRoleTemplate(
    id: 'admin',
    label: 'Administrateur',
    description: 'Peut inviter et organiser',
    level: 1,
  ),
  AccessRoleTemplate(
    id: 'member',
    label: 'Membre',
    description: 'Accès standard',
    level: 3,
  ),
];

class GovernanceState {
  final GovernanceWorkspace? workspace;
  final bool loading;
  final List<GovernancePerson> results;

  const GovernanceState({
    this.workspace,
    this.loading = true,
    this.results = const [],
  });

  GovernanceState copyWith({
    GovernanceWorkspace? workspace,
    bool? loading,
    List<GovernancePerson>? results,
  }) {
    return GovernanceState(
      workspace: workspace ?? this.workspace,
      loading: loading ?? this.loading,
      results: results ?? this.results,
    );
  }
}

List<OrgNode> governanceNodes(GovernanceWorkspace workspace) {
  return [
    for (var index = 0; index < workspace.members.length; index++)
      OrgNode(
        id: workspace.members[index].id,
        label: workspace.members[index].name,
        subtitle: governanceRoleLabel(workspace.members[index].role),
        roleId: workspace.members[index].role,
        parentId: workspace.members[index].parentId,
        memberId: workspace.members[index].id,
        sortOrder: index,
        hierarchyLinkType: _link(workspace.members[index].linkType),
        avatarInitials: _initials(workspace.members[index].name),
      ),
  ];
}

List<AccessMember> governanceMembers(GovernanceWorkspace workspace) {
  return [
    for (final member in workspace.members)
      AccessMember(
        id: member.id,
        name: member.name,
        email: member.email,
        roleId: member.role,
        nodeId: member.id,
        permissions: member.permissions,
      ),
  ];
}

OrgHierarchyLinkType _link(String value) {
  for (final type in OrgHierarchyLinkType.values) {
    if (type.name == value) return type;
  }
  return OrgHierarchyLinkType.reportsTo;
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
  if (parts.length >= 2) return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  if (parts.isNotEmpty) return parts.first.substring(0, 1).toUpperCase();
  return '?';
}

class GovernanceNotifier extends StateNotifier<GovernanceState> {
  final GovernanceApiService _api;
  final AuthNotifier _auth;

  GovernanceNotifier(this._api, this._auth) : super(const GovernanceState()) {
    Future.microtask(refresh);
  }

  Future<void> refresh() async {
    try {
      final workspace = await _api.workspace();
      state = state.copyWith(workspace: workspace, loading: false);
    } catch (_) {
      state = state.copyWith(loading: false);
    }
  }

  Future<String?> updateWorkspace({
    String? name,
    String? icon,
    String? kind,
    Map<String, String>? levelLabels,
  }) async {
    final body = <String, dynamic>{
      if (name != null) 'name': name,
      if (icon != null) 'icon': icon,
      if (kind != null) 'kind': kind,
      if (levelLabels != null) 'level_labels': levelLabels,
    };
    final error = await _apply(() => _api.updateWorkspace(body));
    if (error == null && name != null) {
      final user = _auth.state.user;
      if (user != null) {
        _auth.updateLocalUser(user.copyWith(organization: name));
      }
    }
    return error;
  }

  Future<String?> setLevelLabel(int depth, String label) async {
    final workspace = state.workspace;
    if (workspace == null) return null;
    final labels = Map<String, String>.from(workspace.levelLabels);
    final trimmed = label.trim();
    if (trimmed.isEmpty) {
      labels.remove('$depth');
    } else {
      labels['$depth'] = trimmed;
    }
    return updateWorkspace(levelLabels: labels);
  }

  Future<String?> reparentToLevel(String nodeId, int targetDepth) async {
    final workspace = state.workspace;
    if (workspace == null || !workspace.canManage) return null;
    final nodes = governanceNodes(workspace);
    final depths = OrgChartLayout.computeDepths(nodes);
    final currentDepth = depths[nodeId] ?? 0;
    if (currentDepth == targetDepth) return null;
    final maxDepth = depths.values.isEmpty ? 0 : depths.values.reduce(math.max);
    final String? parentId;
    if (targetDepth <= 0) {
      parentId = null;
    } else if (targetDepth > maxDepth) {
      parentId = OrgChartHierarchy.pickParentAtDepth(nodes, maxDepth, excludeId: nodeId);
    } else {
      parentId = OrgChartHierarchy.parentIdForLevel(nodes, nodeId, targetDepth);
    }
    if (targetDepth > 0 && parentId == null) return null;
    if (OrgChartHierarchy.wouldCreateCycle(nodes, nodeId, parentId)) return null;
    return _apply(() => _api.updateMember(nodeId, {'parent_id': parentId}));
  }

  Future<String?> reparentAboveTop(String nodeId) async {
    final workspace = state.workspace;
    if (workspace == null || !workspace.canManage) return null;
    final nodes = governanceNodes(workspace);
    final depth = OrgChartLayout.computeDepths(nodes)[nodeId] ?? 0;
    if (depth > 0 || OrgChartHierarchy.roots(nodes).length <= 1) {
      return reparentToLevel(nodeId, 0);
    }
    for (final root in OrgChartHierarchy.roots(nodes)) {
      if (root.id == nodeId) continue;
      final error = await _apply(() => _api.updateMember(root.id, {'parent_id': nodeId}));
      if (error != null) return error;
    }
    return null;
  }

  Future<String?> updateLink({
    required String childId,
    required String parentId,
    required OrgHierarchyLinkType linkType,
  }) async {
    final workspace = state.workspace;
    if (workspace == null || !workspace.canManage || childId == parentId) return null;
    if (OrgChartHierarchy.wouldCreateCycle(governanceNodes(workspace), childId, parentId)) {
      return 'Ce rattachement n\'est pas possible';
    }
    return _apply(
      () => _api.updateMember(childId, {
        'parent_id': parentId,
        'link_type': linkType.name,
      }),
    );
  }

  Future<String?> changeLinkType(String memberId, OrgHierarchyLinkType linkType) async {
    final workspace = state.workspace;
    if (workspace == null || !workspace.canManage) return null;
    return _apply(() => _api.updateMember(memberId, {'link_type': linkType.name}));
  }

  Future<String?> changeRole(String memberId, String roleId) async {
    final workspace = state.workspace;
    if (workspace == null || !workspace.canManage) return null;
    final member = _member(workspace, memberId);
    if (member == null || member.role == 'owner' || roleId == 'owner') {
      return 'Le rôle du propriétaire ne change pas';
    }
    return _apply(() => _api.updateMember(memberId, {'role': roleId}));
  }

  Future<String?> togglePermission(String memberId, String permissionId) async {
    final workspace = state.workspace;
    if (workspace == null || !workspace.canManage) return null;
    final member = _member(workspace, memberId);
    if (member == null) return 'Membre introuvable';
    final next = List<String>.from(member.permissions);
    if (next.contains(permissionId)) {
      next.remove(permissionId);
    } else {
      next.add(permissionId);
    }
    return _apply(() => _api.updateMember(memberId, {'permissions': next}));
  }

  Future<String?> removeMember(String memberId) {
    return _apply(() => _api.removeMember(memberId));
  }

  Future<void> search(String query) async {
    final needle = query.trim();
    if (needle.length < 2) {
      state = state.copyWith(results: const []);
      return;
    }
    try {
      final results = await _api.searchPeople(needle);
      state = state.copyWith(results: results);
    } catch (_) {
      state = state.copyWith(results: const []);
    }
  }

  Future<String?> invite(String inviteeId) {
    return _apply(() => _api.invite(inviteeId), clearResults: true);
  }

  Future<String?> invitationAction(String invitationId, String action) {
    return _apply(() => _api.invitationAction(invitationId, action));
  }

  GovernanceMember? _member(GovernanceWorkspace workspace, String id) {
    for (final member in workspace.members) {
      if (member.id == id) return member;
    }
    return null;
  }

  Future<String?> _apply(
    Future<GovernanceWorkspace> Function() action, {
    bool clearResults = false,
  }) async {
    try {
      final workspace = await action();
      state = state.copyWith(
        workspace: workspace,
        loading: false,
        results: clearResults ? const [] : null,
      );
      return null;
    } catch (error) {
      return apiErrorMessage(error, fallback: 'Modification impossible');
    }
  }
}

final governanceProvider = StateNotifierProvider.autoDispose<GovernanceNotifier, GovernanceState>((ref) {
  return GovernanceNotifier(ref.watch(governanceApiProvider), ref.read(authStateProvider.notifier));
});
