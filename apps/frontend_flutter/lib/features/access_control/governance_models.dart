class GovernanceMember {
  final String id;
  final String userId;
  final String name;
  final String email;
  final String role;
  final String? parentId;
  final List<String> permissions;
  final String linkType;

  const GovernanceMember({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    required this.parentId,
    required this.permissions,
    required this.linkType,
  });

  factory GovernanceMember.fromJson(Map<String, dynamic> json) {
    return GovernanceMember(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'member',
      parentId: json['parent_id'] as String?,
      permissions: [
        for (final item in json['permissions'] as List<dynamic>? ?? const []) item.toString(),
      ],
      linkType: json['link_type'] as String? ?? 'reportsTo',
    );
  }
}

class GovernanceInvitation {
  final String id;
  final String organizationId;
  final String organizationName;
  final String inviterName;
  final String inviteeId;
  final String inviteeName;
  final String inviteeEmail;
  final String status;

  const GovernanceInvitation({
    required this.id,
    required this.organizationId,
    required this.organizationName,
    required this.inviterName,
    required this.inviteeId,
    required this.inviteeName,
    required this.inviteeEmail,
    required this.status,
  });

  factory GovernanceInvitation.fromJson(Map<String, dynamic> json) {
    return GovernanceInvitation(
      id: json['id'].toString(),
      organizationId: json['organization_id'].toString(),
      organizationName: json['organization_name'] as String? ?? '',
      inviterName: json['inviter_name'] as String? ?? '',
      inviteeId: json['invitee_id'].toString(),
      inviteeName: json['invitee_name'] as String? ?? '',
      inviteeEmail: json['invitee_email'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
    );
  }
}

class GovernancePerson {
  final String id;
  final String name;
  final String email;

  const GovernancePerson({required this.id, required this.name, required this.email});

  factory GovernancePerson.fromJson(Map<String, dynamic> json) {
    return GovernancePerson(
      id: json['id'].toString(),
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );
  }
}

class GovernanceWorkspace {
  final String id;
  final String name;
  final String kind;
  final String icon;
  final Map<String, String> levelLabels;
  final String myRole;
  final bool canManage;
  final List<GovernanceMember> members;
  final List<GovernanceInvitation> sentInvitations;
  final List<GovernanceInvitation> receivedInvitations;

  const GovernanceWorkspace({
    required this.id,
    required this.name,
    required this.kind,
    required this.icon,
    required this.levelLabels,
    required this.myRole,
    required this.canManage,
    required this.members,
    required this.sentInvitations,
    required this.receivedInvitations,
  });

  Map<int, String> get levels {
    final labels = <int, String>{};
    for (final entry in levelLabels.entries) {
      final depth = int.tryParse(entry.key);
      if (depth != null && entry.value.trim().isNotEmpty) {
        labels[depth] = entry.value;
      }
    }
    return labels;
  }

  factory GovernanceWorkspace.fromJson(Map<String, dynamic> json) {
    final rawLabels = json['level_labels'];
    final labels = <String, String>{};
    if (rawLabels is Map) {
      for (final entry in rawLabels.entries) {
        labels[entry.key.toString()] = entry.value.toString();
      }
    }
    List<T> readList<T>(String key, T Function(Map<String, dynamic>) parse) {
      final raw = json[key];
      if (raw is! List) return <T>[];
      return [
        for (final item in raw)
          if (item is Map) parse(Map<String, dynamic>.from(item)),
      ];
    }

    return GovernanceWorkspace(
      id: json['id'].toString(),
      name: json['name'] as String? ?? 'Famille',
      kind: json['kind'] as String? ?? 'family',
      icon: json['icon'] as String? ?? 'family',
      levelLabels: labels,
      myRole: json['my_role'] as String? ?? 'member',
      canManage: json['can_manage'] as bool? ?? false,
      members: readList('members', GovernanceMember.fromJson),
      sentInvitations: readList('sent_invitations', GovernanceInvitation.fromJson),
      receivedInvitations: readList('received_invitations', GovernanceInvitation.fromJson),
    );
  }
}

String governanceRoleLabel(String role) => switch (role) {
      'owner' => 'Propriétaire',
      'admin' => 'Administrateur',
      'member' => 'Membre',
      _ => role,
    };

String governanceKindLabel(String kind) => switch (kind) {
      'family' => 'Famille',
      'personal' => 'Personnel',
      'club' => 'Club',
      'org' => 'Organisation',
      _ => kind,
    };

String invitationStatusLabel(String status) => switch (status) {
      'pending' => 'En attente',
      'accepted' => 'Acceptée',
      'refused' => 'Refusée',
      'cancelled' => 'Annulée',
      _ => status,
    };
