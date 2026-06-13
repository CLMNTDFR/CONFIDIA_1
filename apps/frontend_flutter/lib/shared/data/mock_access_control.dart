import 'package:flutter/material.dart';

import '../models/access_control_models.dart';

/// Données démo, miroir du backend `AccessControlService`.
abstract final class MockAccessControl {
  static const permissions = [
    AccessPermission(id: 'calendar.read', label: 'Lire le calendrier', category: 'Calendrier', description: 'Voir les événements partagés'),
    AccessPermission(id: 'calendar.write', label: 'Modifier le calendrier', category: 'Calendrier', description: 'Créer et éditer des événements'),
    AccessPermission(id: 'documents.read', label: 'Consulter les documents', category: 'Documents', description: 'Accès lecture aux documents partagés'),
    AccessPermission(id: 'documents.id_card', label: 'Pièces d\'identité', category: 'Documents', description: 'CNI, passeports'),
    AccessPermission(id: 'documents.payslip', label: 'Bulletins de salaire', category: 'Documents', description: 'Fiches de paie'),
    AccessPermission(id: 'documents.medical', label: 'Documents médicaux', category: 'Documents', description: 'Ordonnances, attestations'),
    AccessPermission(id: 'payments.read', label: 'Voir les paiements', category: 'Paiements', description: 'Factures et échéances'),
    AccessPermission(id: 'payments.write', label: 'Gérer les paiements', category: 'Paiements', description: 'Valider des règlements'),
    AccessPermission(id: 'members.manage', label: 'Gérer les membres', category: 'Organisation', description: 'Inviter, retirer, modifier les rôles'),
    AccessPermission(id: 'hierarchy.edit', label: 'Modifier l\'organigramme', category: 'Organisation', description: 'Réorganiser la hiérarchie'),
  ];

  static const roles = [
    AccessRoleTemplate(id: 'admin', label: 'Administrateur', description: 'Contrôle total', level: 0, defaultPermissions: ['calendar.read', 'calendar.write', 'documents.read', 'documents.id_card', 'documents.payslip', 'documents.medical', 'payments.read', 'payments.write', 'members.manage', 'hierarchy.edit']),
    AccessRoleTemplate(id: 'director', label: 'Directeur', description: 'Pilotage stratégique', level: 1, defaultPermissions: ['calendar.read', 'calendar.write', 'documents.read', 'documents.id_card', 'documents.payslip', 'payments.read', 'members.manage', 'hierarchy.edit']),
    AccessRoleTemplate(id: 'ceo', label: 'PDG', description: 'Direction générale', level: 0, defaultPermissions: ['calendar.read', 'calendar.write', 'documents.read', 'documents.payslip', 'payments.read', 'payments.write', 'members.manage', 'hierarchy.edit']),
    AccessRoleTemplate(id: 'parent', label: 'Parent', description: 'Co-gestion familiale', level: 1, defaultPermissions: ['calendar.read', 'calendar.write', 'documents.read', 'documents.medical', 'payments.read']),
    AccessRoleTemplate(id: 'coach', label: 'Entraîneur', description: 'Gestion sportive', level: 2, defaultPermissions: ['calendar.read', 'calendar.write', 'documents.read']),
    AccessRoleTemplate(id: 'treasurer', label: 'Trésorier', description: 'Finances', level: 2, defaultPermissions: ['calendar.read', 'payments.read', 'payments.write', 'documents.read', 'documents.payslip']),
    AccessRoleTemplate(id: 'secretary', label: 'Secrétaire', description: 'Administration', level: 2, defaultPermissions: ['calendar.read', 'calendar.write', 'documents.read', 'documents.id_card']),
    AccessRoleTemplate(id: 'manager', label: 'Manager', description: 'Encadrement équipe', level: 2, defaultPermissions: ['calendar.read', 'calendar.write', 'documents.read', 'payments.read']),
    AccessRoleTemplate(id: 'member', label: 'Membre', description: 'Accès standard', level: 3, defaultPermissions: ['calendar.read', 'documents.read']),
    AccessRoleTemplate(id: 'child', label: 'Enfant', description: 'Profil limité', level: 4, defaultPermissions: ['calendar.read']),
  ];

  static const builtInProfiles = [
    StructureProfile(id: 'family', label: 'Famille partagée', description: 'Couple, enfants, assistant IA planning', icon: Icons.family_restroom_rounded),
    StructureProfile(id: 'club', label: 'Club / association', description: 'Organigramme sportif et consentements', icon: Icons.sports_soccer_rounded),
  ];

  static List<OrgNode> familyNodes() => const [
        OrgNode(id: 'n_sophie', label: 'Sophie Martin', subtitle: 'Mère · Admin', roleId: 'admin', avatarInitials: 'SM'),
        OrgNode(id: 'n_marc', label: 'Marc Martin', subtitle: 'Père', roleId: 'parent', parentId: 'n_sophie', avatarInitials: 'MM'),
        OrgNode(id: 'n_lea', label: 'Léa Martin', subtitle: '12 ans', roleId: 'child', parentId: 'n_sophie', avatarInitials: 'LM'),
        OrgNode(id: 'n_tom', label: 'Tom Martin', subtitle: '9 ans', roleId: 'child', parentId: 'n_sophie', avatarInitials: 'TM'),
      ];

  static List<OrgNode> clubNodes() => const [
        OrgNode(id: 'n_dir', label: 'Pierre Lambert', subtitle: 'Directeur', roleId: 'director', avatarInitials: 'PL'),
        OrgNode(id: 'n_coach', label: 'Karim Benali', subtitle: 'Entraîneur U17', roleId: 'coach', parentId: 'n_dir', avatarInitials: 'KB'),
        OrgNode(id: 'n_treas', label: 'Nadia Roche', subtitle: 'Trésorier', roleId: 'treasurer', parentId: 'n_dir', avatarInitials: 'NR'),
        OrgNode(id: 'n_sec', label: 'Julie Moreau', subtitle: 'Secrétaire', roleId: 'secretary', parentId: 'n_dir', avatarInitials: 'JM'),
        OrgNode(id: 'n_u17', label: 'Licenciés U17', subtitle: '18 joueurs', roleId: 'member', parentId: 'n_coach', avatarInitials: 'U17'),
        OrgNode(id: 'n_staff', label: 'Staff technique', subtitle: '4 personnes', roleId: 'member', parentId: 'n_coach', avatarInitials: 'ST'),
      ];

  static List<OrgNode> enterpriseNodes(String rootName) => [
        OrgNode(id: 'n_ceo', label: rootName, subtitle: 'PDG · Admin', roleId: 'ceo', avatarInitials: rootName.isNotEmpty ? rootName.substring(0, 1) : 'E'),
        OrgNode(id: 'n_mgr', label: 'Direction RH', subtitle: 'Manager', roleId: 'manager', parentId: 'n_ceo', avatarInitials: 'RH'),
        OrgNode(id: 'n_team', label: 'Équipe commerciale', subtitle: '8 collaborateurs', roleId: 'member', parentId: 'n_mgr', avatarInitials: 'EC'),
      ];

  static List<AccessMember> familyMembers() => const [
        AccessMember(id: 'm_sophie', name: 'Sophie Martin', email: 'sophie@demo.local', roleId: 'admin', nodeId: 'n_sophie', permissions: ['calendar.read', 'calendar.write', 'documents.read', 'documents.medical', 'payments.read', 'members.manage', 'hierarchy.edit']),
        AccessMember(id: 'm_marc', name: 'Marc Martin', email: 'marc@demo.local', roleId: 'parent', nodeId: 'n_marc', permissions: ['calendar.read', 'calendar.write', 'documents.read', 'payments.read']),
        AccessMember(id: 'm_lea', name: 'Léa Martin', email: 'lea@demo.local', roleId: 'child', nodeId: 'n_lea'),
        AccessMember(id: 'm_tom', name: 'Tom Martin', email: 'tom@demo.local', roleId: 'child', nodeId: 'n_tom'),
      ];

  static List<AccessMember> clubMembers() => const [
        AccessMember(id: 'm_dir', name: 'Pierre Lambert', email: 'directeur@fc-confidia.local', roleId: 'director', nodeId: 'n_dir'),
        AccessMember(id: 'm_coach', name: 'Karim Benali', email: 'coach@fc-confidia.local', roleId: 'coach', nodeId: 'n_coach'),
        AccessMember(id: 'm_treas', name: 'Nadia Roche', email: 'tresorier@fc-confidia.local', roleId: 'treasurer', nodeId: 'n_treas'),
        AccessMember(id: 'm_sec', name: 'Julie Moreau', email: 'secretaire@fc-confidia.local', roleId: 'secretary', nodeId: 'n_sec'),
        AccessMember(id: 'm_u17', name: 'Licenciés U17', email: 'u17@fc-confidia.local', roleId: 'member', nodeId: 'n_u17'),
      ];

  static List<AccessMember> enterpriseMembers() => const [
        AccessMember(id: 'm_ceo', name: 'Direction', email: 'ceo@entreprise.local', roleId: 'ceo', nodeId: 'n_ceo', permissions: ['calendar.read', 'calendar.write', 'documents.read', 'documents.payslip', 'payments.read', 'payments.write', 'members.manage', 'hierarchy.edit']),
        AccessMember(id: 'm_mgr', name: 'Direction RH', email: 'rh@entreprise.local', roleId: 'manager', nodeId: 'n_mgr', permissions: ['calendar.read', 'documents.read', 'documents.payslip']),
        AccessMember(id: 'm_team', name: 'Équipe commerciale', email: 'team@entreprise.local', roleId: 'member', nodeId: 'n_team'),
      ];

  static StructureData dataFor(String structureId, {String? customName}) {
    return switch (structureId) {
      'club' => StructureData(nodes: clubNodes(), members: clubMembers()),
      'family' => StructureData(nodes: familyNodes(), members: familyMembers()),
      _ => StructureData(nodes: enterpriseNodes(customName ?? 'Mon entreprise'), members: enterpriseMembers()),
    };
  }

  static StructureData dataForTemplate(StructureTemplate template, {String? name}) {
    return switch (template) {
      StructureTemplate.family => dataFor('family'),
      StructureTemplate.club => dataFor('club'),
      StructureTemplate.enterprise => dataFor('custom', customName: name ?? 'Mon entreprise'),
      StructureTemplate.blank => StructureData(
          nodes: [OrgNode(id: 'n_root', label: name ?? 'Nouvelle structure', subtitle: 'Admin', roleId: 'admin', avatarInitials: 'N')],
          members: [AccessMember(id: 'm_root', name: name ?? 'Admin', email: 'admin@structure.local', roleId: 'admin', nodeId: 'n_root')],
        ),
    };
  }

  static List<SharingRequest> sharingRequests() => [
        SharingRequest(
          id: 'sr_1',
          requesterName: 'Pierre Lambert',
          requesterRole: 'Directeur',
          targetName: 'Nadia Roche',
          documentType: 'Bulletins de salaire',
          permission: 'documents.payslip',
          message: 'Accès requis pour le contrôle budgétaire annuel du staff.',
          status: 'pending',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        SharingRequest(
          id: 'sr_2',
          requesterName: 'Pierre Lambert',
          requesterRole: 'Directeur',
          targetName: 'Licenciés U17',
          documentType: 'Pièces d\'identité',
          permission: 'documents.id_card',
          message: 'Obligation fédérale : vérification des pièces pour la saison.',
          status: 'pending',
          createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        ),
      ];

  static List<PlanningProposal> familyPlanningVariants() => const [
        PlanningProposal(
          conflicts: [
            PlanningConflict(id: 'c1', title: 'Chevauchement créneaux parents', severity: 'high', events: ['Sophie · RDV pédiatre 14h00', 'Marc · Réunion client 14h00']),
            PlanningConflict(id: 'c2', title: 'Trajet impossible avant récupération', severity: 'medium', events: ['Marc · Bureau La Défense 14h30', 'Léa · Sortie école 15h30 · Versailles']),
          ],
          proposal:
              'Conflit détecté : Sophie et Marc sont tous deux indisponibles à 14h00, et Marc ne peut pas rejoindre Léa à l\'école de Versailles avant 15h30.\n\n'
              'Proposition : Marc décale sa réunion client à 15h00 en visio. Sophie conserve le RDV pédiatre pour Tom à 14h00. Marc récupère Léa à 15h30.',
          alternatives: ['Sophie récupère Léa, Marc garde son RDV client', 'Marc prend un taxi depuis La Défense à 15h00'],
        ),
        PlanningProposal(
          conflicts: [
            PlanningConflict(id: 'c1', title: 'Chevauchement créneaux parents', severity: 'high', events: ['Sophie · RDV pédiatre 14h00', 'Marc · Réunion client 14h00']),
          ],
          proposal:
              'Alternative : Sophie récupère Léa à 15h30 pendant que Marc garde sa réunion client en présentiel. '
              'Tom est accompagné au pédiatre par Sophie avant 14h00, puis elle enchaîne directement vers l\'école.',
          alternatives: ['Demander à un grand-parent pour la récupération', 'Activer le mode garde partagée dans CONFIDIA'],
        ),
        PlanningProposal(
          conflicts: [
            PlanningConflict(id: 'c2', title: 'Trajet impossible avant récupération', severity: 'medium', events: ['Marc · Bureau La Défense 14h30', 'Léa · Sortie école 15h30 · Versailles']),
          ],
          proposal:
              'Nouvelle option : Marc quitte La Défense à 14h45 en visio depuis le taxi. '
              'Arrivée estimée à Versailles à 15h25, récupération de Léa sans retard.',
          alternatives: ['Réserver un créneau de co-voiturage via l\'app', 'Notifier l\'école d\'un léger retard'],
        ),
      ];
}
