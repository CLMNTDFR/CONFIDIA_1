from __future__ import annotations

import copy
from datetime import datetime, timezone

from application.dto.access_control_dto import (
    HierarchyLinkType,
    MemberDTO,
    MemberUpdateDTO,
    OrgNodeDTO,
    OrgNodeReparentDTO,
    OrganizationDTO,
    OrganizationUpdateDTO,
    PermissionDTO,
    PlanningConflictDTO,
    PlanningProposalDTO,
    PlanningRefineDTO,
    RoleTemplateDTO,
    ScenarioDTO,
    SharingRequestCreateDTO,
    SharingRequestDTO,
    SharingRespondDTO,
)

_PERMISSIONS: list[PermissionDTO] = [
    PermissionDTO(id="calendar.read", label="Lire le calendrier", category="Calendrier", description="Voir les événements partagés"),
    PermissionDTO(id="calendar.write", label="Modifier le calendrier", category="Calendrier", description="Créer et éditer des événements"),
    PermissionDTO(id="documents.read", label="Consulter les documents", category="Documents", description="Accès lecture aux documents partagés"),
    PermissionDTO(id="documents.id_card", label="Pièces d'identité", category="Documents", description="Accès aux CNI, passeports, etc."),
    PermissionDTO(id="documents.payslip", label="Bulletins de salaire", category="Documents", description="Accès aux fiches de paie"),
    PermissionDTO(id="documents.medical", label="Documents médicaux", category="Documents", description="Ordonnances, attestations"),
    PermissionDTO(id="payments.read", label="Voir les paiements", category="Paiements", description="Consulter factures et échéances"),
    PermissionDTO(id="payments.write", label="Gérer les paiements", category="Paiements", description="Valider et planifier des règlements"),
    PermissionDTO(id="members.manage", label="Gérer les membres", category="Organisation", description="Inviter, retirer, modifier les rôles"),
    PermissionDTO(id="hierarchy.edit", label="Modifier l'organigramme", category="Organisation", description="Réorganiser la hiérarchie"),
]

_ROLES: list[RoleTemplateDTO] = [
    RoleTemplateDTO(id="admin", label="Administrateur", description="Contrôle total du groupe", level=0, default_permissions=[p.id for p in _PERMISSIONS]),
    RoleTemplateDTO(id="director", label="Directeur", description="Pilotage stratégique", level=1, default_permissions=["calendar.read", "calendar.write", "documents.read", "documents.id_card", "documents.payslip", "payments.read", "members.manage", "hierarchy.edit"]),
    RoleTemplateDTO(id="parent", label="Parent", description="Co-gestion familiale", level=1, default_permissions=["calendar.read", "calendar.write", "documents.read", "documents.medical", "payments.read"]),
    RoleTemplateDTO(id="coach", label="Entraîneur", description="Gestion sportive", level=2, default_permissions=["calendar.read", "calendar.write", "documents.read"]),
    RoleTemplateDTO(id="treasurer", label="Trésorier", description="Finances du club", level=2, default_permissions=["calendar.read", "payments.read", "payments.write", "documents.read", "documents.payslip"]),
    RoleTemplateDTO(id="secretary", label="Secrétaire", description="Administration", level=2, default_permissions=["calendar.read", "calendar.write", "documents.read", "documents.id_card"]),
    RoleTemplateDTO(id="member", label="Membre", description="Accès standard", level=3, default_permissions=["calendar.read", "documents.read"]),
    RoleTemplateDTO(id="child", label="Enfant", description="Profil limité", level=4, default_permissions=["calendar.read"]),
]

_FAMILY_ORG = OrganizationDTO(
    id="org_family",
    name="Famille Martin",
    scenario="family",
    description="Partage conjoint  -  calendrier familial et assistant IA de planning",
    nodes=[
        OrgNodeDTO(id="n_sophie", label="Sophie Martin", subtitle="Mère · Admin", role_id="admin", parent_id=None, avatar_initials="SM"),
        OrgNodeDTO(id="n_marc", label="Marc Martin", subtitle="Père", role_id="parent", parent_id="n_sophie", avatar_initials="MM"),
        OrgNodeDTO(id="n_lea", label="Léa Martin", subtitle="12 ans", role_id="child", parent_id="n_sophie", avatar_initials="LM"),
        OrgNodeDTO(id="n_tom", label="Tom Martin", subtitle="9 ans", role_id="child", parent_id="n_sophie", avatar_initials="TM"),
    ],
)

_CLUB_ORG = OrganizationDTO(
    id="org_club",
    name="FC CONFIDIA",
    scenario="club",
    description="Club de football  -  organigramme et droits fins par rôle",
    nodes=[
        OrgNodeDTO(id="n_dir", label="Pierre Lambert", subtitle="Directeur", role_id="director", parent_id=None, avatar_initials="PL"),
        OrgNodeDTO(id="n_coach", label="Karim Benali", subtitle="Entraîneur U17", role_id="coach", parent_id="n_dir", avatar_initials="KB"),
        OrgNodeDTO(id="n_treas", label="Nadia Roche", subtitle="Trésorier", role_id="treasurer", parent_id="n_dir", avatar_initials="NR"),
        OrgNodeDTO(id="n_sec", label="Julie Moreau", subtitle="Secrétaire", role_id="secretary", parent_id="n_dir", avatar_initials="JM", member_id="m_sec", sort_order=2, hierarchy_link_type=HierarchyLinkType.DOTTED_LINE),
        OrgNodeDTO(id="n_u17", label="Licenciés U17", subtitle="18 joueurs", role_id="member", parent_id="n_coach", avatar_initials="U17"),
        OrgNodeDTO(id="n_staff", label="Staff technique", subtitle="4 personnes", role_id="member", parent_id="n_coach", avatar_initials="ST"),
    ],
)

_FAMILY_MEMBERS = [
    MemberDTO(id="m_sophie", name="Sophie Martin", email="sophie@demo.local", role_id="admin", node_id="n_sophie", permissions=[p.id for p in _PERMISSIONS]),
    MemberDTO(id="m_marc", name="Marc Martin", email="marc@demo.local", role_id="parent", node_id="n_marc", permissions=["calendar.read", "calendar.write", "documents.read", "payments.read"]),
    MemberDTO(id="m_lea", name="Léa Martin", email="lea@demo.local", role_id="child", node_id="n_lea", permissions=["calendar.read"]),
    MemberDTO(id="m_tom", name="Tom Martin", email="tom@demo.local", role_id="child", node_id="n_tom", permissions=["calendar.read"]),
]

_CLUB_MEMBERS = [
    MemberDTO(id="m_dir", name="Pierre Lambert", email="directeur@fc-confidia.local", role_id="director", node_id="n_dir", permissions=_role_perms("director")),
    MemberDTO(id="m_coach", name="Karim Benali", email="coach@fc-confidia.local", role_id="coach", node_id="n_coach", permissions=_role_perms("coach")),
    MemberDTO(id="m_treas", name="Nadia Roche", email="tresorier@fc-confidia.local", role_id="treasurer", node_id="n_treas", permissions=_role_perms("treasurer")),
    MemberDTO(id="m_sec", name="Julie Moreau", email="secretaire@fc-confidia.local", role_id="secretary", node_id="n_sec", permissions=_role_perms("secretary")),
    MemberDTO(id="m_u17", name="Licenciés U17", email="u17@fc-confidia.local", role_id="member", node_id="n_u17", permissions=_role_perms("member")),
]


def _role_perms(role_id: str) -> list[str]:
    role = next((r for r in _ROLES if r.id == role_id), None)
    return list(role.default_permissions) if role else []


class AccessControlService:
    def __init__(self) -> None:
        self._scenario = "family"
        self._orgs: dict[str, OrganizationDTO] = {
            "family": copy.deepcopy(_FAMILY_ORG),
            "club": copy.deepcopy(_CLUB_ORG),
        }
        self._members: dict[str, list[MemberDTO]] = {
            "family": copy.deepcopy(_FAMILY_MEMBERS),
            "club": copy.deepcopy(_CLUB_MEMBERS),
        }
        self._sharing: list[SharingRequestDTO] = [
            SharingRequestDTO(
                id="sr_1",
                requester_name="Pierre Lambert",
                requester_role="Directeur",
                target_name="Nadia Roche",
                document_type="Bulletins de salaire",
                permission="documents.payslip",
                message="Accès requis pour le contrôle budgétaire annuel du staff.",
                status="pending",
                created_at=datetime.now(timezone.utc).isoformat(),
            ),
            SharingRequestDTO(
                id="sr_2",
                requester_name="Pierre Lambert",
                requester_role="Directeur",
                target_name="Licenciés U17",
                document_type="Pièces d'identité",
                permission="documents.id_card",
                message="Obligation fédérale  -  vérification des pièces pour la saison.",
                status="pending",
                created_at=datetime.now(timezone.utc).isoformat(),
            ),
        ]

    def list_scenarios(self) -> list[ScenarioDTO]:
        return [
            ScenarioDTO(id="family", label="Famille partagée", description="Couple, enfants, assistant IA planning", icon="family"),
            ScenarioDTO(id="club", label="Club / association", description="Organigramme, rôles et demandes de partage", icon="sports_soccer"),
        ]

    def list_permissions(self) -> list[PermissionDTO]:
        return _PERMISSIONS

    def list_roles(self) -> list[RoleTemplateDTO]:
        return _ROLES

    def get_organization(self, scenario: str | None = None) -> OrganizationDTO:
        key = scenario or self._scenario
        return copy.deepcopy(self._orgs[key])

    def update_organization(self, data: OrganizationUpdateDTO) -> OrganizationDTO:
        self._scenario = data.scenario
        self._orgs[data.scenario] = OrganizationDTO(
            **self._orgs[data.scenario].model_dump(exclude={"nodes"}),
            nodes=data.nodes,
        )
        return copy.deepcopy(self._orgs[data.scenario])

    def reparent_node(self, node_id: str, data: OrgNodeReparentDTO, scenario: str | None = None) -> OrganizationDTO:
        key = scenario or self._scenario
        org = self._orgs[key]
        nodes = []
        found = False
        for node in org.nodes:
            if node.id != node_id:
                nodes.append(node)
                continue
            found = True
            nodes.append(
                node.model_copy(
                    update={
                        k: v
                        for k, v in {
                            "parent_id": data.parent_id,
                            "hierarchy_link_type": data.hierarchy_link_type,
                        }.items()
                        if v is not None
                    }
                )
            )
        if not found:
            raise ValueError(f"Node {node_id} not found")
        self._orgs[key] = org.model_copy(update={"nodes": nodes})
        return copy.deepcopy(self._orgs[key])

    def list_members(self, scenario: str | None = None) -> list[MemberDTO]:
        key = scenario or self._scenario
        return copy.deepcopy(self._members[key])

    def update_member(self, member_id: str, data: MemberUpdateDTO, scenario: str | None = None) -> MemberDTO:
        key = scenario or self._scenario
        members = self._members[key]
        for i, m in enumerate(members):
            if m.id == member_id:
                updated = m.model_copy(
                    update={
                        k: v
                        for k, v in {
                            "role_id": data.role_id,
                            "permissions": data.permissions,
                            "inherits_from_hierarchy": data.inherits_from_hierarchy,
                        }.items()
                        if v is not None
                    }
                )
                members[i] = updated
                return copy.deepcopy(updated)
        raise ValueError(f"Member {member_id} not found")

    def list_sharing_requests(self) -> list[SharingRequestDTO]:
        return copy.deepcopy(self._sharing)

    def create_sharing_request(self, data: SharingRequestCreateDTO) -> SharingRequestDTO:
        req = SharingRequestDTO(
            id=f"sr_{len(self._sharing) + 1}",
            requester_name="Vous",
            requester_role="Administrateur",
            target_name=data.target_member_id,
            document_type=data.document_type,
            permission=data.permission,
            message=data.message,
            status="pending",
            created_at=datetime.now(timezone.utc).isoformat(),
        )
        self._sharing.append(req)
        return copy.deepcopy(req)

    def respond_sharing(self, request_id: str, data: SharingRespondDTO) -> SharingRequestDTO:
        for i, req in enumerate(self._sharing):
            if req.id == request_id:
                updated = req.model_copy(update={"status": "accepted" if data.accept else "refused"})
                self._sharing[i] = updated
                return copy.deepcopy(updated)
        raise ValueError(f"Request {request_id} not found")

    def analyze_planning(self, scenario: str) -> PlanningProposalDTO:
        if scenario == "club":
            return PlanningProposalDTO(
                conflicts=[
                    PlanningConflictDTO(
                        id="c1",
                        title="Double réservation terrain",
                        severity="high",
                        events=["Entraînement U17 · 18h00", "Réunion staff · 18h00"],
                    ),
                ],
                proposal=(
                    "L'IA détecte un chevauchement sur le terrain synthétique à 18h00. "
                    "Proposition : décaler la réunion staff à 19h30 (après l'entraînement) "
                    "ou déplacer l'entraînement U17 au créneau 16h30-17h45."
                ),
                alternatives=["Décaler réunion staff → 19h30", "Entraînement U17 → 16h30"],
            )
        return PlanningProposalDTO(
            conflicts=[
                PlanningConflictDTO(
                    id="c1",
                    title="Chevauchement créneaux parents",
                    severity="high",
                    events=["Sophie · RDV pédiatre 14h00", "Marc · Réunion client 14h00"],
                ),
                PlanningConflictDTO(
                    id="c2",
                    title="Trajet impossible avant récupération",
                    severity="medium",
                    events=["Marc · Bureau La Défense 14h30", "Léa · Sortie école 15h30 · Versailles"],
                ),
            ],
            proposal=(
                "Conflit détecté : Sophie et Marc sont tous deux indisponibles à 14h00, "
                "et Marc ne peut pas rejoindre Léa à l'école de Versailles avant 15h30 "
                "(45 min de trajet depuis La Défense en heure de pointe).\n\n"
                "Proposition : Marc décale sa réunion client à 15h00 en visio. "
                "Sophie conserve le RDV pédiatre pour Tom à 14h00. "
                "Marc récupère Léa à 15h30  -  trajet réaliste si la réunion se termine à 15h00."
            ),
            alternatives=[
                "Sophie récupère Léa, Marc garde son RDV client",
                "Marc prend un taxi depuis La Défense à 15h00",
            ],
        )

    def refine_planning(self, data: PlanningRefineDTO) -> PlanningProposalDTO:
        base = self.analyze_planning(data.scenario)
        refined = (
            f"{base.proposal}\n\n"
            f"Ajustement demandé : « {data.prompt} »\n\n"
            "Nouvelle proposition : Sophie récupère Léa à 15h30 pendant que Marc "
            "termine sa réunion en visio jusqu'à 15h15, puis rejoint le domicile pour "
            "prendre en charge Tom au retour du pédiatre."
        )
        return PlanningProposalDTO(
            conflicts=base.conflicts,
            proposal=refined,
            alternatives=base.alternatives + ["Notifier Marc et Sophie par notification push"],
        )
