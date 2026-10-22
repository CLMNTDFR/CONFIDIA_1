from abc import ABC, abstractmethod
from dataclasses import dataclass
from uuid import UUID


@dataclass
class MemberRecord:
    id: UUID
    user_id: str
    name: str
    email: str
    role: str
    parent_id: UUID | None
    permissions: list[str]
    link_type: str


@dataclass
class InvitationRecord:
    id: UUID
    organization_id: UUID
    organization_name: str
    inviter_id: str
    inviter_name: str
    invitee_id: str
    invitee_name: str
    invitee_email: str
    status: str


@dataclass
class WorkspaceRecord:
    id: UUID
    name: str
    kind: str
    icon: str
    level_labels: dict[str, str]
    my_role: str
    members: list[MemberRecord]
    sent: list[InvitationRecord]
    received: list[InvitationRecord]


@dataclass
class PersonRecord:
    id: str
    name: str
    email: str


@dataclass
class InvitationState:
    id: UUID
    organization_id: UUID
    inviter_id: str
    invitee_id: str
    status: str
    invitee_alive: bool = False


class GovernanceRepository(ABC):
    @abstractmethod
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
        ...

    @abstractmethod
    async def get_workspace(self, user_id: str) -> WorkspaceRecord | None:
        ...

    @abstractmethod
    async def update_organization(
        self,
        organization_id: UUID,
        *,
        name: str | None = None,
        icon: str | None = None,
        kind: str | None = None,
        level_labels: dict[str, str] | None = None,
    ) -> None:
        ...

    @abstractmethod
    async def update_member(
        self,
        organization_id: UUID,
        membership_id: UUID,
        **fields: object,
    ) -> bool:
        ...

    @abstractmethod
    async def soft_delete_member(self, organization_id: UUID, membership_id: UUID) -> bool:
        ...

    @abstractmethod
    async def search_people(
        self, query: str, exclude_user_id: str, limit: int
    ) -> list[PersonRecord]:
        ...

    @abstractmethod
    async def person_exists(self, user_id: str) -> bool:
        ...

    @abstractmethod
    async def alive_member(self, organization_id: UUID, user_id: str) -> bool:
        ...

    @abstractmethod
    async def member_id_for(self, organization_id: UUID, user_id: str) -> UUID | None:
        ...

    @abstractmethod
    async def invitation_between(
        self, organization_id: UUID, invitee_id: str
    ) -> InvitationState | None:
        ...

    @abstractmethod
    async def create_invitation(
        self, *, organization_id: UUID, inviter_id: str, invitee_id: str
    ) -> UUID:
        ...

    @abstractmethod
    async def reopen_invitation(self, invitation_id: UUID, inviter_id: str) -> None:
        ...

    @abstractmethod
    async def get_invitation(self, invitation_id: UUID) -> InvitationState | None:
        ...

    @abstractmethod
    async def claim_pending(self, invitation_id: UUID, status: str) -> bool:
        ...

    @abstractmethod
    async def add_member(
        self,
        *,
        organization_id: UUID,
        user_id: str,
        role: str,
        parent_id: UUID | None,
        permissions: list[str],
    ) -> UUID:
        ...
