from uuid import UUID

from application.dto.governance_dto import (
    InvitationDTO,
    MemberDTO,
    PersonDTO,
    PersonListDTO,
    WorkspaceDTO,
)
from application.services.identity_service import IdentityService
from domain.governance import (
    ASSIGNABLE_ROLES,
    ICONS,
    KINDS,
    LINK_TYPES,
    MEMBER_PERMISSIONS,
    GovernanceError,
    clean_level_labels,
    clean_permissions,
    displayed_permissions,
    would_cycle,
)
from domain.interfaces.governance_repository import (
    GovernanceRepository,
    InvitationRecord,
    MemberRecord,
    WorkspaceRecord,
)
from domain.interfaces.identity_repository import StoredUser


def _member_dto(row: MemberRecord) -> MemberDTO:
    return MemberDTO(
        id=row.id,
        user_id=row.user_id,
        name=row.name,
        email=row.email,
        role=row.role,
        parent_id=row.parent_id,
        permissions=displayed_permissions(row.role, row.permissions),
        link_type=row.link_type,
    )


def _invite_dto(row: InvitationRecord) -> InvitationDTO:
    return InvitationDTO(
        id=row.id,
        organization_id=row.organization_id,
        organization_name=row.organization_name,
        inviter_id=row.inviter_id,
        inviter_name=row.inviter_name,
        invitee_id=row.invitee_id,
        invitee_name=row.invitee_name,
        invitee_email=row.invitee_email,
        status=row.status,
    )


def _workspace_dto(row: WorkspaceRecord) -> WorkspaceDTO:
    return WorkspaceDTO(
        id=row.id,
        name=row.name,
        kind=row.kind,
        icon=row.icon,
        level_labels=row.level_labels,
        my_role=row.my_role,
        can_manage=row.my_role in {"owner", "admin"},
        members=[_member_dto(member) for member in row.members],
        sent_invitations=[_invite_dto(item) for item in row.sent],
        received_invitations=[_invite_dto(item) for item in row.received],
    )


class GovernanceService:
    def __init__(self, repository: GovernanceRepository, identity: IdentityService) -> None:
        self._repository = repository
        self._identity = identity

    async def _stored(self, claims: dict) -> StoredUser:
        stored = await self._identity.ensure_from_token_claims(claims)
        await self._repository.adopt_owner(
            user_id=stored.id,
            email=stored.email,
            first_name=stored.first_name,
            last_name=stored.last_name,
            organization_id=stored.organization_id,
            organization_name=stored.organization_name or "Famille",
        )
        if stored.organization_id is None:
            raise GovernanceError(404, "Espace introuvable")
        return stored

    async def _workspace(self, user_id: str) -> WorkspaceRecord:
        workspace = await self._repository.get_workspace(user_id)
        if workspace is None:
            raise GovernanceError(404, "Espace introuvable")
        return workspace

    async def _manager(self, claims: dict) -> tuple[StoredUser, WorkspaceRecord]:
        stored = await self._stored(claims)
        workspace = await self._workspace(stored.id)
        if workspace.my_role not in {"owner", "admin"}:
            raise GovernanceError(403, "Action non autorisée")
        return stored, workspace

    async def workspace(self, claims: dict) -> WorkspaceDTO:
        stored = await self._stored(claims)
        return _workspace_dto(await self._workspace(stored.id))

    async def update_workspace(self, claims: dict, fields: dict) -> WorkspaceDTO:
        stored, workspace = await self._manager(claims)
        if not fields:
            raise GovernanceError(400, "Rien à modifier")
        name = fields.get("name")
        icon = fields.get("icon")
        kind = fields.get("kind")
        labels = fields.get("level_labels")
        if name is not None:
            name = str(name).strip()
            if not name:
                raise GovernanceError(400, "Le nom de l'espace est requis")
            name = name[:80]
        if icon is not None and icon not in ICONS:
            raise GovernanceError(400, "Icône inconnue")
        if kind is not None and kind not in KINDS:
            raise GovernanceError(400, "Type d'espace inconnu")
        cleaned = clean_level_labels(labels) if labels is not None else None
        await self._repository.update_organization(
            workspace.id,
            name=name,
            icon=icon,
            kind=kind,
            level_labels=cleaned,
        )
        if name is not None:
            await self._identity.update_profile(stored.id, organization_name=name)
        return _workspace_dto(await self._workspace(stored.id))

    async def update_member(self, claims: dict, membership_id: UUID, fields: dict) -> WorkspaceDTO:
        stored, workspace = await self._manager(claims)
        target = next((row for row in workspace.members if row.id == membership_id), None)
        if target is None:
            raise GovernanceError(404, "Membre introuvable")
        changes: dict = {}
        if "role" in fields and fields["role"] is not None:
            role = str(fields["role"])
            if target.role == "owner" or role == "owner":
                raise GovernanceError(400, "Le rôle du propriétaire ne change pas")
            if role not in ASSIGNABLE_ROLES:
                raise GovernanceError(400, "Rôle inconnu")
            changes["role"] = role
        if "link_type" in fields and fields["link_type"] is not None:
            link_type = str(fields["link_type"])
            if link_type not in LINK_TYPES:
                raise GovernanceError(400, "Type de lien inconnu")
            changes["link_type"] = link_type
        if "permissions" in fields and fields["permissions"] is not None:
            changes["permissions"] = clean_permissions(list(fields["permissions"]))
        if "parent_id" in fields:
            parent_id = fields["parent_id"]
            if parent_id == membership_id or would_cycle(
                {row.id: row.parent_id for row in workspace.members},
                membership_id,
                parent_id,
            ):
                raise GovernanceError(400, "Ce rattachement n'est pas possible")
            if parent_id is not None and all(row.id != parent_id for row in workspace.members):
                raise GovernanceError(400, "Ce rattachement n'est pas possible")
            changes["parent_id"] = parent_id
        if not changes:
            raise GovernanceError(400, "Rien à modifier")
        await self._repository.update_member(workspace.id, membership_id, **changes)
        return _workspace_dto(await self._workspace(stored.id))

    async def remove_member(self, claims: dict, membership_id: UUID) -> WorkspaceDTO:
        stored, workspace = await self._manager(claims)
        target = next((row for row in workspace.members if row.id == membership_id), None)
        if target is None:
            raise GovernanceError(404, "Membre introuvable")
        if target.role == "owner":
            raise GovernanceError(400, "Le propriétaire reste dans l'espace")
        for child in workspace.members:
            if child.parent_id == membership_id:
                await self._repository.update_member(
                    workspace.id, child.id, parent_id=target.parent_id
                )
        await self._repository.soft_delete_member(workspace.id, membership_id)
        return _workspace_dto(await self._workspace(stored.id))

    async def search(self, claims: dict, query: str) -> PersonListDTO:
        stored = await self._stored(claims)
        needle = query.strip()
        if len(needle) < 2:
            return PersonListDTO(items=[])
        rows = await self._repository.search_people(needle, stored.id, 8)
        items = [PersonDTO(id=row.id, name=row.name, email=row.email) for row in rows]
        return PersonListDTO(items=items)

    async def invite(self, claims: dict, invitee_id: str) -> WorkspaceDTO:
        stored, workspace = await self._manager(claims)
        invitee_id = invitee_id.strip()
        if invitee_id == stored.id:
            raise GovernanceError(400, "Vous ne pouvez pas vous inviter")
        if not await self._repository.person_exists(invitee_id):
            raise GovernanceError(404, "Profil introuvable")
        if await self._repository.alive_member(workspace.id, invitee_id):
            raise GovernanceError(409, "Cette personne fait déjà partie de l'espace")
        existing = await self._repository.invitation_between(workspace.id, invitee_id)
        if existing is None:
            await self._repository.create_invitation(
                organization_id=workspace.id,
                inviter_id=stored.id,
                invitee_id=invitee_id,
            )
        elif existing.status == "pending" or existing.invitee_alive:
            detail = (
                "Une invitation est déjà en attente"
                if existing.status == "pending"
                else "Cette personne fait déjà partie de l'espace"
            )
            raise GovernanceError(409, detail)
        else:
            await self._repository.reopen_invitation(existing.id, stored.id)
        return _workspace_dto(await self._workspace(stored.id))

    async def _act(self, invitation_id: UUID, status: str, actor_id: str, *, invitee: bool) -> None:
        current = await self._repository.get_invitation(invitation_id)
        if current is None:
            raise GovernanceError(404, "Invitation introuvable")
        if invitee and current.invitee_id != actor_id:
            raise GovernanceError(403, "Action non autorisée")
        if not invitee:
            workspace = await self._workspace(actor_id)
            manages = workspace.my_role in {"owner", "admin"}
            if current.organization_id != workspace.id or not manages:
                raise GovernanceError(403, "Action non autorisée")
        if not await self._repository.claim_pending(invitation_id, status):
            raise GovernanceError(409, "Cette invitation n'est plus en attente")
        if status == "accepted":
            parent = await self._repository.member_id_for(
                current.organization_id, current.inviter_id
            )
            await self._repository.add_member(
                organization_id=current.organization_id,
                user_id=current.invitee_id,
                role="member",
                parent_id=parent,
                permissions=list(MEMBER_PERMISSIONS),
            )

    async def accept(self, claims: dict, invitation_id: UUID) -> WorkspaceDTO:
        stored = await self._stored(claims)
        await self._act(invitation_id, "accepted", stored.id, invitee=True)
        return _workspace_dto(await self._workspace(stored.id))

    async def refuse(self, claims: dict, invitation_id: UUID) -> WorkspaceDTO:
        stored = await self._stored(claims)
        await self._act(invitation_id, "refused", stored.id, invitee=True)
        return _workspace_dto(await self._workspace(stored.id))

    async def cancel(self, claims: dict, invitation_id: UUID) -> WorkspaceDTO:
        stored = await self._stored(claims)
        await self._act(invitation_id, "cancelled", stored.id, invitee=False)
        return _workspace_dto(await self._workspace(stored.id))
