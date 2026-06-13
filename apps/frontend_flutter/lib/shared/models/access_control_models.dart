import 'package:flutter/material.dart';

enum StructureTemplate { family, club, enterprise, blank }

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
}

class OrgNode {
  final String id;
  final String label;
  final String? subtitle;
  final String roleId;
  final String? parentId;
  final String? avatarInitials;

  const OrgNode({
    required this.id,
    required this.label,
    this.subtitle,
    required this.roleId,
    this.parentId,
    this.avatarInitials,
  });

  OrgNode copyWith({String? parentId, String? label, String? subtitle, String? roleId}) => OrgNode(
        id: id,
        label: label ?? this.label,
        subtitle: subtitle ?? this.subtitle,
        roleId: roleId ?? this.roleId,
        parentId: parentId ?? this.parentId,
        avatarInitials: avatarInitials,
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

  AccessMember copyWith({String? roleId, List<String>? permissions, bool? inheritsFromHierarchy}) =>
      AccessMember(
        id: id,
        name: name,
        email: email,
        roleId: roleId ?? this.roleId,
        nodeId: nodeId,
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

  const StructureData({required this.nodes, required this.members});

  StructureData copyWith({List<OrgNode>? nodes, List<AccessMember>? members}) =>
      StructureData(nodes: nodes ?? this.nodes, members: members ?? this.members);
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
