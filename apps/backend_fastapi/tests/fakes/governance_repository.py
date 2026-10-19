from dataclasses import dataclass, field
from uuid import UUID, uuid4

from domain.governance import PERMISSIONS
from domain.interfaces.governance_repository import (
    GovernanceRepository,
    InvitationRecord,
    InvitationState,
    MemberRecord,
    PersonRecord,
    WorkspaceRecord,
)


def _name(first_name: str, last_name: str, email: str) -> str:
    full = f"{first_name} {last_name}".strip()
    return full or email


@dataclass
class _Person:
    id: str
    name: str
    email: str
    first_name: str
    last_name: str


@dataclass
class _Org:
    id: UUID
    name: str
    kind: str = "family"
    icon: str = "family"
    level_labels: dict[str, str] = field(default_factory=dict)


@dataclass
class _Member:
    id: UUID
    organization_id: UUID
    user_id: str
    role: str
    parent_id: UUID | None = None
    permissions: list[str] = field(default_factory=list)
    link_type: str = "reportsTo"
    deleted: bool = False


@dataclass
class _Invite:
    id: UUID
    organization_id: UUID
    inviter_id: str
    invitee_id: str
    status: str = "pending"


class InMemoryGovernanceRepository(GovernanceRepository):
    """Same rules as Postgres, without a database. HTTP tests use this."""

    def __init__(self) -> None:
        self.people: dict[str, _Person] = {}
        self.orgs: dict[UUID, _Org] = {}
        self.members: list[_Member] = []
        self.invites: list[_Invite] = []

    async def adopt_owner(
        self,
        *,
        user_id: str,
        email: str,
        first_name: str,
        last_name: str,
        organization_id: UUID | None,
        organization_name: str,
    ) -> None:
        self.people[user_id] = _Person(
            id=user_id,
            name=_name(first_name, last_name, email),
            email=email,
            first_name=first_name,
            last_name=last_name,
        )
        if organization_id is None or organization_id in self.orgs:
            return
        self.orgs[organization_id] = _Org(id=organization_id, name=organization_name)
        self.members.append(
            _Member(
                id=uuid4(),
                organization_id=organization_id,
                user_id=user_id,
                role="owner",
                permissions=list(PERMISSIONS),
            )
        )

    def _default_member(self, user_id: str) -> _Member | None:
        alive = [
            row
            for row in self.members
            if row.user_id == user_id and not row.deleted
        ]
        if not alive:
            return None
        owners = [row for row in alive if row.role == "owner"]
        return owners[0] if owners else alive[0]

    async def get_workspace(self, user_id: str) -> WorkspaceRecord | None:
        mine = self._default_member(user_id)
        if mine is None:
            return None
        org = self.orgs[mine.organization_id]
        members = [self._member_record(row) for row in self._alive(org.id)]
        sent = [self._invite_record(row) for row in self.invites if row.organization_id == org.id]
        received = [
            self._invite_record(row)
            for row in self.invites
            if row.invitee_id == user_id and row.status != "cancelled"
        ]
        return WorkspaceRecord(
            id=org.id,
            name=org.name,
            kind=org.kind,
            icon=org.icon,
            level_labels=dict(org.level_labels),
            my_role=mine.role,
            members=members,
            sent=sent,
            received=received,
        )

    def _alive(self, organization_id: UUID) -> list[_Member]:
        rows = [
            row
            for row in self.members
            if row.organization_id == organization_id and not row.deleted
        ]
        rows.sort(key=lambda row: (row.role != "owner", str(row.id)))
        return rows

    def _member_record(self, row: _Member) -> MemberRecord:
        person = self.people[row.user_id]
        return MemberRecord(
            id=row.id,
            user_id=row.user_id,
            name=person.name,
            email=person.email,
            role=row.role,
            parent_id=row.parent_id,
            permissions=list(row.permissions),
            link_type=row.link_type,
        )

    def _invite_record(self, row: _Invite) -> InvitationRecord:
        org = self.orgs[row.organization_id]
        inviter = self.people[row.inviter_id]
        invitee = self.people[row.invitee_id]
        return InvitationRecord(
            id=row.id,
            organization_id=row.organization_id,
            organization_name=org.name,
            inviter_id=row.inviter_id,
            inviter_name=inviter.name,
            invitee_id=row.invitee_id,
            invitee_name=invitee.name,
            invitee_email=invitee.email,
            status=row.status,
        )

    async def update_organization(
        self,
        organization_id: UUID,
        *,
        name: str | None = None,
        icon: str | None = None,
        kind: str | None = None,
        level_labels: dict[str, str] | None = None,
    ) -> None:
        org = self.orgs[organization_id]
        if name is not None:
            org.name = name
        if icon is not None:
            org.icon = icon
        if kind is not None:
            org.kind = kind
        if level_labels is not None:
            org.level_labels = dict(level_labels)

    async def update_member(
        self,
        organization_id: UUID,
        membership_id: UUID,
        **fields: object,
    ) -> bool:
        row = self._find(organization_id, membership_id, alive_only=True)
        if row is None:
            return False
        if "parent_id" in fields:
            parent = fields["parent_id"]
            row.parent_id = parent if isinstance(parent, UUID) or parent is None else row.parent_id
        if "role" in fields and isinstance(fields["role"], str):
            row.role = fields["role"]
        if "permissions" in fields and isinstance(fields["permissions"], list):
            row.permissions = list(fields["permissions"])
        if "link_type" in fields and isinstance(fields["link_type"], str):
            row.link_type = fields["link_type"]
        return True

    async def soft_delete_member(self, organization_id: UUID, membership_id: UUID) -> bool:
        row = self._find(organization_id, membership_id, alive_only=True)
        if row is None:
            return False
        row.deleted = True
        row.parent_id = None
        return True

    def _find(
        self, organization_id: UUID, membership_id: UUID, *, alive_only: bool
    ) -> _Member | None:
        for row in self.members:
            if row.id != membership_id or row.organization_id != organization_id:
                continue
            if alive_only and row.deleted:
                return None
            return row
        return None

    async def search_people(
        self, query: str, exclude_user_id: str, limit: int
    ) -> list[PersonRecord]:
        needle = query.strip().casefold()
        found: list[PersonRecord] = []
        for person in self.people.values():
            if person.id == exclude_user_id:
                continue
            haystack = f"{person.first_name} {person.last_name} {person.email}".casefold()
            if needle in haystack:
                found.append(PersonRecord(id=person.id, name=person.name, email=person.email))
        found.sort(key=lambda row: row.name.casefold())
        return found[:limit]

    async def person_exists(self, user_id: str) -> bool:
        return user_id in self.people

    async def alive_member(self, organization_id: UUID, user_id: str) -> bool:
        return await self.member_id_for(organization_id, user_id) is not None

    async def member_id_for(self, organization_id: UUID, user_id: str) -> UUID | None:
        for row in self._alive(organization_id):
            if row.user_id == user_id:
                return row.id
        return None

    async def invitation_between(
        self, organization_id: UUID, invitee_id: str
    ) -> InvitationState | None:
        for row in self.invites:
            if row.organization_id == organization_id and row.invitee_id == invitee_id:
                return await self._state(row)
        return None

    async def create_invitation(
        self, *, organization_id: UUID, inviter_id: str, invitee_id: str
    ) -> UUID:
        row = _Invite(
            id=uuid4(),
            organization_id=organization_id,
            inviter_id=inviter_id,
            invitee_id=invitee_id,
        )
        self.invites.append(row)
        return row.id

    async def reopen_invitation(self, invitation_id: UUID, inviter_id: str) -> None:
        for row in self.invites:
            if row.id == invitation_id:
                row.status = "pending"
                row.inviter_id = inviter_id
                return

    async def get_invitation(self, invitation_id: UUID) -> InvitationState | None:
        for row in self.invites:
            if row.id == invitation_id:
                return await self._state(row)
        return None

    async def _state(self, row: _Invite) -> InvitationState:
        return InvitationState(
            id=row.id,
            organization_id=row.organization_id,
            inviter_id=row.inviter_id,
            invitee_id=row.invitee_id,
            status=row.status,
            invitee_alive=await self.alive_member(row.organization_id, row.invitee_id),
        )

    async def claim_pending(self, invitation_id: UUID, status: str) -> bool:
        for row in self.invites:
            if row.id == invitation_id and row.status == "pending":
                row.status = status
                return True
        return False

    async def add_member(
        self,
        *,
        organization_id: UUID,
        user_id: str,
        role: str,
        parent_id: UUID | None,
        permissions: list[str],
    ) -> UUID:
        for row in self.members:
            if row.organization_id == organization_id and row.user_id == user_id:
                row.deleted = False
                row.role = role
                row.parent_id = parent_id
                row.permissions = list(permissions)
                row.link_type = "reportsTo"
                return row.id
        created = _Member(
            id=uuid4(),
            organization_id=organization_id,
            user_id=user_id,
            role=role,
            parent_id=parent_id,
            permissions=list(permissions),
        )
        self.members.append(created)
        return created.id
