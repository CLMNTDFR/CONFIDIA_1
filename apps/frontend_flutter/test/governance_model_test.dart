import 'package:confidia/features/access_control/governance_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('workspace json keeps the chart, the rights and the invitation status', () {
    final workspace = GovernanceWorkspace.fromJson({
      'id': 'org-1',
      'name': 'Famille',
      'kind': 'family',
      'icon': 'family',
      'level_labels': {'0': 'Foyer'},
      'my_role': 'owner',
      'can_manage': true,
      'members': [
        {
          'id': 'mem-1',
          'user_id': 'kc-1',
          'name': 'Alice Martin',
          'email': 'alice@confidia.local',
          'role': 'owner',
          'parent_id': null,
          'permissions': ['members.manage'],
          'link_type': 'reportsTo',
        },
      ],
      'sent_invitations': [
        {
          'id': 'inv-1',
          'organization_id': 'org-1',
          'organization_name': 'Famille',
          'inviter_id': 'kc-1',
          'inviter_name': 'Alice Martin',
          'invitee_id': 'kc-2',
          'invitee_name': 'Bob Bernard',
          'invitee_email': 'bob@confidia.local',
          'status': 'pending',
        },
      ],
      'received_invitations': [],
    });

    expect(workspace.levels[0], 'Foyer');
    expect(workspace.members.single.parentId, isNull);
    expect(workspace.sentInvitations.single.status, 'pending');
    expect(governanceRoleLabel('owner'), 'Propriétaire');
    expect(invitationStatusLabel('refused'), 'Refusée');
  });
}
