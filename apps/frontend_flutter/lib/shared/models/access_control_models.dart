import 'package:flutter/material.dart';

enum StructureTemplate { family, club, enterprise, custom }

/// Type de lien hiérarchique entre un nœud et son parent.
enum OrgHierarchyLinkType {
  reportsTo,
  dottedLine,
  delegate,
}

extension OrgHierarchyLinkTypeX on OrgHierarchyLinkType {
  String get label => switch (this) {
        OrgHierarchyLinkType.reportsTo => 'Rattachement direct',
        OrgHierarchyLinkType.dottedLine => 'Lien fonctionnel',
        OrgHierarchyLinkType.delegate => 'Délégation',
      };

  bool get isDashed => this == OrgHierarchyLinkType.dottedLine;

  bool get isDelegate => this == OrgHierarchyLinkType.delegate;

  IconData get icon => switch (this) {
        OrgHierarchyLinkType.reportsTo => Icons.arrow_downward_rounded,
        OrgHierarchyLinkType.dottedLine => Icons.device_hub_rounded,
        OrgHierarchyLinkType.delegate => Icons.swap_horiz_rounded,
      };
}

class StructureProfile {
  final String id;
  final String label;
  final String description;
  final IconData icon;
  final bool isCustom;

  const StructureProfile({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
    this.isCustom = false,
  });
}

class AccessPermission {
  final String id;
  final String label;
  final String category;
  final String description;

  const AccessPermission({
    required this.id,
    required this.label,
    required this.category,
    required this.description,
  });
}

class AccessRoleTemplate {
  final String id;
  final String label;
  final String description;
  final int level;
  final List<String> defaultPermissions;

  const AccessRoleTemplate({
    required this.id,
    required this.label,
    required this.description,
    required this.level,
    this.defaultPermissions = const [],
  });

  AccessRoleTemplate copyWith({
    String? label,
    String? description,
    int? level,
    List<String>? defaultPermissions,
  }) =>
      AccessRoleTemplate(
        id: id,
        label: label ?? this.label,
        description: description ?? this.description,
        level: level ?? this.level,
        defaultPermissions: defaultPermissions ?? this.defaultPermissions,
      );
}

class OrgNode {
  final String id;
  final String label;
  final String? subtitle;
  final String roleId;
  final String? parentId;
  final String? avatarInitials;
  final String? memberId;
  final int sortOrder;
  final OrgHierarchyLinkType hierarchyLinkType;

  const OrgNode({
    required this.id,
    required this.label,
    this.subtitle,
    required this.roleId,
    this.parentId,
    this.avatarInitials,
    this.memberId,
    this.sortOrder = 0,
    this.hierarchyLinkType = OrgHierarchyLinkType.reportsTo,
  });

  String get firstName {
    final parts = label.trim().split(RegExp(r'\s+'));
    return parts.isNotEmpty ? parts.first : label;
  }

  static const _unset = Object();

  OrgNode copyWith({
    Object? parentId = _unset,
    String? label,
    String? subtitle,
    String? roleId,
    String? avatarInitials,
    String? memberId,
    int? sortOrder,
    OrgHierarchyLinkType? hierarchyLinkType,
  }) =>
      OrgNode(
        id: id,
        label: label ?? this.label,
        subtitle: subtitle ?? this.subtitle,
        roleId: roleId ?? this.roleId,
        parentId: parentId == _unset ? this.parentId : parentId as String?,
        avatarInitials: avatarInitials ?? this.avatarInitials,
        memberId: memberId ?? this.memberId,
        sortOrder: sortOrder ?? this.sortOrder,
        hierarchyLinkType: hierarchyLinkType ?? this.hierarchyLinkType,
      );
}

class AccessMember {
  final String id;
  final String name;
  final String email;
  final String roleId;
  final String nodeId;
  final List<String> permissions;
  final bool inheritsFromHierarchy;

  const AccessMember({
    required this.id,
    required this.name,
    required this.email,
    required this.roleId,
    required this.nodeId,
    this.permissions = const [],
    this.inheritsFromHierarchy = true,
  });

  AccessMember copyWith({String? roleId, String? nodeId, List<String>? permissions, bool? inheritsFromHierarchy}) =>
      AccessMember(
        id: id,
        name: name,
        email: email,
        roleId: roleId ?? this.roleId,
        nodeId: nodeId ?? this.nodeId,
        permissions: permissions ?? this.permissions,
        inheritsFromHierarchy: inheritsFromHierarchy ?? this.inheritsFromHierarchy,
      );
}

class SharingRequest {
  final String id;
  final String requesterName;
  final String requesterRole;
  final String targetName;
  final String documentType;
  final String permission;
  final String message;
  final String status;
  final DateTime createdAt;

  const SharingRequest({
    required this.id,
    required this.requesterName,
    required this.requesterRole,
    required this.targetName,
    required this.documentType,
    required this.permission,
    required this.message,
    required this.status,
    required this.createdAt,
  });

  bool get isPending => status == 'pending';

  SharingRequest copyWith({String? status}) => SharingRequest(
        id: id,
        requesterName: requesterName,
        requesterRole: requesterRole,
        targetName: targetName,
        documentType: documentType,
        permission: permission,
        message: message,
        status: status ?? this.status,
        createdAt: createdAt,
      );
}

class PlanningConflict {
  final String id;
  final String title;
  final String severity;
  final List<String> events;

  const PlanningConflict({
    required this.id,
    required this.title,
    required this.severity,
    required this.events,
  });
}

class PlanningProposal {
  final List<PlanningConflict> conflicts;
  final String proposal;
  final List<String> alternatives;

  const PlanningProposal({
    required this.conflicts,
    required this.proposal,
    this.alternatives = const [],
  });
}

class StructureData {
  final List<OrgNode> nodes;
  final List<AccessMember> members;
  final Map<int, String> levelLabels;
  final List<AccessRoleTemplate> customRoles;

  const StructureData({
    required this.nodes,
    required this.members,
    this.levelLabels = const {},
    this.customRoles = const [],
  });

  StructureData copyWith({
    List<OrgNode>? nodes,
    List<AccessMember>? members,
    Map<int, String>? levelLabels,
    List<AccessRoleTemplate>? customRoles,
  }) =>
      StructureData(
        nodes: nodes ?? this.nodes,
        members: members ?? this.members,
        levelLabels: levelLabels ?? this.levelLabels,
        customRoles: customRoles ?? this.customRoles,
      );

  String levelLabel(int depth) => levelLabels[depth] ?? 'Niveau ${depth + 1}';
}

IconData roleIcon(String roleId) => switch (roleId) {
      'admin' || 'director' || 'ceo' => Icons.shield_rounded,
      'parent' => Icons.family_restroom_rounded,
      'coach' => Icons.sports_soccer_rounded,
      'treasurer' => Icons.account_balance_wallet_rounded,
      'secretary' => Icons.edit_note_rounded,
      'manager' => Icons.badge_rounded,
      'child' => Icons.child_care_rounded,
      _ => Icons.person_outline_rounded,
    };

IconData structureIcon(String id) => switch (id) {
      'family' => Icons.family_restroom_rounded,
      'club' => Icons.sports_soccer_rounded,
      _ => Icons.apartment_rounded,
    };
