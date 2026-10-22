from datetime import UTC, datetime
from uuid import UUID, uuid4

from sqlalchemy import func, or_, select, update
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from domain.interfaces.governance_repository import (
    GovernanceRepository,
    InvitationRecord,
    InvitationState,
    MemberRecord,
    PersonRecord,
    WorkspaceRecord,
)
from infrastructure.db.models import Invitation, Membership, Organization, User


def _person_name(first_name: str, last_name: str, email: str) -> str:
    full = f"{first_name} {last_name}".strip()
    return full or email


def _labels(raw: object) -> dict[str, str]:
    if not isinstance(raw, dict):
        return {}
    return {str(key): str(value) for key, value in raw.items()}


class PostgresGovernanceRepository(GovernanceRepository):
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

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
        # The identity repository already created the Famille row in this session.
        return

    async def _default_membership(self, user_id: str) -> Membership | None:
        stmt = (
            select(Membership)
            .options(selectinload(Membership.organization))
            .where(Membership.user_id == user_id, Membership.deleted_at.is_(None))
        )
        rows = list((await self._session.execute(stmt)).scalars().all())
        if not rows:
            return None
        rows.sort(key=lambda row: (not row.is_default,))
        return rows[0]

    async def get_workspace(self, user_id: str) -> WorkspaceRecord | None:
        mine = await self._default_membership(user_id)
        if mine is None or mine.organization.deleted_at is not None:
            return None
        org = mine.organization
        members = await self._members(org.id)
        sent = await self._invitations(Invitation.organization_id == org.id)
        received = await self._invitations(
            Invitation.invitee_id == user_id,
            Invitation.status != "cancelled",
        )
        return WorkspaceRecord(
            id=org.id,
            name=org.name,
            kind=org.kind,
            icon=org.icon,
            level_labels=_labels(org.level_labels),
            my_role=mine.role,
            members=members,
            sent=sent,
            received=received,
        )

    async def _members(self, organization_id: UUID) -> list[MemberRecord]:
        stmt = (
            select(Membership)
            .options(selectinload(Membership.user))
            .where(
                Membership.organization_id == organization_id,
                Membership.deleted_at.is_(None),
            )
        )
        rows = list((await self._session.execute(stmt)).scalars().all())
        rows.sort(key=lambda row: (row.role != "owner", row.created_at))
        return [
            MemberRecord(
                id=row.id,
                user_id=row.user_id,
                name=_person_name(row.user.first_name, row.user.last_name, str(row.user.email)),
                email=str(row.user.email),
                role=row.role,
                parent_id=row.parent_id,
                permissions=list(row.permissions or []),
                link_type=row.link_type,
            )
            for row in rows
        ]

    async def _invitations(self, *criteria: object) -> list[InvitationRecord]:
        stmt = (
            select(Invitation)
            .options(
                selectinload(Invitation.organization),
                selectinload(Invitation.inviter),
                selectinload(Invitation.invitee),
            )
            .where(*criteria)
            .order_by(Invitation.created_at.desc())
        )
        rows = list((await self._session.execute(stmt)).scalars().all())
        return [
            InvitationRecord(
                id=row.id,
                organization_id=row.organization_id,
                organization_name=row.organization.name,
                inviter_id=row.inviter_id,
                inviter_name=_person_name(
                    row.inviter.first_name, row.inviter.last_name, str(row.inviter.email)
                ),
                invitee_id=row.invitee_id,
                invitee_name=_person_name(
                    row.invitee.first_name, row.invitee.last_name, str(row.invitee.email)
                ),
                invitee_email=str(row.invitee.email),
                status=row.status,
            )
            for row in rows
        ]

    async def update_organization(
        self,
        organization_id: UUID,
        *,
        name: str | None = None,
        icon: str | None = None,
        kind: str | None = None,
        level_labels: dict[str, str] | None = None,
    ) -> None:
        mine = await self._default_membership_org(organization_id)
        if mine is None:
            return
        if name is not None:
            mine.name = name
        if icon is not None:
            mine.icon = icon
        if kind is not None:
            mine.kind = kind
        if level_labels is not None:
            mine.level_labels = level_labels
        await self._session.flush()

    async def _default_membership_org(self, organization_id: UUID):
        return await self._session.get(Organization, organization_id)

    async def update_member(
        self,
        organization_id: UUID,
        membership_id: UUID,
        **fields: object,
    ) -> bool:
        row = await self._membership(organization_id, membership_id, alive_only=True)
        if row is None:
            return False
        if "parent_id" in fields:
            row.parent_id = fields["parent_id"]  # type: ignore[assignment]
        if "role" in fields and fields["role"] is not None:
            row.role = str(fields["role"])
        if "permissions" in fields and fields["permissions"] is not None:
            row.permissions = list(fields["permissions"])  # type: ignore[arg-type]
        if "link_type" in fields and fields["link_type"] is not None:
            row.link_type = str(fields["link_type"])
        await self._session.flush()
        return True

    async def soft_delete_member(self, organization_id: UUID, membership_id: UUID) -> bool:
        row = await self._membership(organization_id, membership_id, alive_only=True)
        if row is None:
            return False
        row.deleted_at = datetime.now(UTC)
        row.parent_id = None
        await self._session.flush()
        return True

    async def _membership(
        self, organization_id: UUID, membership_id: UUID, *, alive_only: bool
    ) -> Membership | None:
        stmt = select(Membership).where(
            Membership.id == membership_id,
            Membership.organization_id == organization_id,
        )
        if alive_only:
            stmt = stmt.where(Membership.deleted_at.is_(None))
        return (await self._session.execute(stmt)).scalar_one_or_none()

    async def search_people(
        self, query: str, exclude_user_id: str, limit: int
    ) -> list[PersonRecord]:
        escaped = query.strip().replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_")
        like = f"%{escaped}%"
        full_name = func.concat(User.first_name, " ", User.last_name)
        stmt = (
            select(User)
            .where(
                User.deleted_at.is_(None),
                User.id != exclude_user_id,
                or_(
                    User.email.ilike(like, escape="\\"),
                    User.first_name.ilike(like, escape="\\"),
                    User.last_name.ilike(like, escape="\\"),
                    full_name.ilike(like, escape="\\"),
                ),
            )
            .order_by(User.first_name, User.last_name)
            .limit(limit)
        )
        rows = list((await self._session.execute(stmt)).scalars().all())
        return [
            PersonRecord(
                id=row.id,
                name=_person_name(row.first_name, row.last_name, str(row.email)),
                email=str(row.email),
            )
            for row in rows
        ]

    async def person_exists(self, user_id: str) -> bool:
        stmt = select(User.id).where(User.id == user_id, User.deleted_at.is_(None))
        return (await self._session.execute(stmt)).scalar_one_or_none() is not None

    async def alive_member(self, organization_id: UUID, user_id: str) -> bool:
        return await self.member_id_for(organization_id, user_id) is not None

    async def member_id_for(self, organization_id: UUID, user_id: str) -> UUID | None:
        stmt = select(Membership.id).where(
            Membership.organization_id == organization_id,
            Membership.user_id == user_id,
            Membership.deleted_at.is_(None),
        )
        return (await self._session.execute(stmt)).scalar_one_or_none()

    async def invitation_between(
        self, organization_id: UUID, invitee_id: str
    ) -> InvitationState | None:
        stmt = select(Invitation).where(
            Invitation.organization_id == organization_id,
            Invitation.invitee_id == invitee_id,
        )
        row = (await self._session.execute(stmt)).scalar_one_or_none()
        if row is None:
            return None
        return await self._state(row)

    async def create_invitation(
        self, *, organization_id: UUID, inviter_id: str, invitee_id: str
    ) -> UUID:
        row = Invitation(
            id=uuid4(),
            organization_id=organization_id,
            inviter_id=inviter_id,
            invitee_id=invitee_id,
            status="pending",
        )
        self._session.add(row)
        await self._session.flush()
        return row.id

    async def reopen_invitation(self, invitation_id: UUID, inviter_id: str) -> None:
        await self._session.execute(
            update(Invitation)
            .where(Invitation.id == invitation_id)
            .values(status="pending", inviter_id=inviter_id)
        )
        await self._session.flush()

    async def get_invitation(self, invitation_id: UUID) -> InvitationState | None:
        row = await self._session.get(Invitation, invitation_id)
        if row is None:
            return None
        return await self._state(row)

    async def _state(self, row: Invitation) -> InvitationState:
        alive = await self.alive_member(row.organization_id, row.invitee_id)
        return InvitationState(
            id=row.id,
            organization_id=row.organization_id,
            inviter_id=row.inviter_id,
            invitee_id=row.invitee_id,
            status=row.status,
            invitee_alive=alive,
        )

    async def claim_pending(self, invitation_id: UUID, status: str) -> bool:
        result = await self._session.execute(
            update(Invitation)
            .where(Invitation.id == invitation_id, Invitation.status == "pending")
            .values(status=status)
        )
        await self._session.flush()
        return result.rowcount == 1

    async def add_member(
        self,
        *,
        organization_id: UUID,
        user_id: str,
        role: str,
        parent_id: UUID | None,
        permissions: list[str],
    ) -> UUID:
        stmt = select(Membership).where(
            Membership.organization_id == organization_id,
            Membership.user_id == user_id,
        )
        row = (await self._session.execute(stmt)).scalar_one_or_none()
        if row is None:
            row = Membership(
                id=uuid4(),
                organization_id=organization_id,
                user_id=user_id,
                role=role,
                parent_id=parent_id,
                permissions=permissions,
                link_type="reportsTo",
                is_default=False,
            )
            self._session.add(row)
        else:
            row.deleted_at = None
            row.role = role
            row.parent_id = parent_id
            row.permissions = permissions
            row.link_type = "reportsTo"
        await self._session.flush()
        return row.id
