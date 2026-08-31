from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from domain.interfaces.identity_repository import IdentityRepository, StoredUser
from infrastructure.db.models import Calendar, Membership, Organization, User


def _slug_for(user_id: str) -> str:
    compact = user_id.replace("-", "").lower()
    return f"famille-{compact[:16]}"


def _to_stored(user: User, membership: Membership | None) -> StoredUser:
    org = membership.organization if membership else None
    return StoredUser(
        id=user.id,
        email=str(user.email),
        first_name=user.first_name,
        last_name=user.last_name,
        phone=user.phone,
        avatar_url=user.avatar_url,
        locale=user.locale,
        timezone=user.timezone,
        organization_id=org.id if org else None,
        organization_name=org.name if org else None,
        membership_role=membership.role if membership else None,
    )


class PostgresIdentityRepository(IdentityRepository):
    def __init__(self, session: AsyncSession):
        self._session = session

    async def _load_user(self, user_id: str) -> User | None:
        stmt = (
            select(User)
            .options(
                selectinload(User.memberships).selectinload(Membership.organization),
            )
            .where(User.id == user_id, User.deleted_at.is_(None))
        )
        result = await self._session.execute(stmt)
        return result.scalar_one_or_none()

    async def _reload_user(self, user_id: str) -> User:
        cached = await self._session.get(User, user_id)
        if cached is not None:
            self._session.expire(cached)
        loaded = await self._load_user(user_id)
        assert loaded is not None
        return loaded

    def _default_membership(self, user: User) -> Membership | None:
        alive = [m for m in user.memberships if m.deleted_at is None]
        for membership in alive:
            if membership.is_default:
                return membership
        return alive[0] if alive else None

    async def get_user(self, user_id: str) -> StoredUser | None:
        user = await self._load_user(user_id)
        if user is None:
            return None
        return _to_stored(user, self._default_membership(user))

    async def upsert_user(
        self,
        *,
        user_id: str,
        email: str,
        first_name: str,
        last_name: str,
    ) -> StoredUser:
        user = await self._load_user(user_id)
        if user is None:
            user = User(
                id=user_id,
                email=email,
                first_name=first_name,
                last_name=last_name,
            )
            self._session.add(user)
        else:
            user.email = email
            if first_name:
                user.first_name = first_name
            if last_name:
                user.last_name = last_name
        await self._session.flush()
        loaded = await self._reload_user(user_id)
        return _to_stored(loaded, self._default_membership(loaded))

    async def ensure_default_workspace(self, user_id: str) -> StoredUser:
        user = await self._load_user(user_id)
        if user is None:
            raise ValueError(f"User {user_id} must exist before creating a workspace")

        membership = self._default_membership(user)
        if membership is not None:
            return _to_stored(user, membership)

        org = Organization(name="Famille", slug=_slug_for(user_id), kind="family")
        self._session.add(org)
        await self._session.flush()

        membership = Membership(
            organization_id=org.id,
            user_id=user.id,
            role="owner",
            is_default=True,
        )
        self._session.add(membership)
        self._session.add(
            Calendar(
                organization_id=org.id,
                name="Famille",
                slug="family",
                is_default=True,
            )
        )
        await self._session.flush()
        user = await self._reload_user(user_id)
        return _to_stored(user, self._default_membership(user))

    async def update_profile(
        self,
        user_id: str,
        *,
        first_name: str | None = None,
        last_name: str | None = None,
        phone: str | None = None,
        locale: str | None = None,
        timezone: str | None = None,
        organization_name: str | None = None,
    ) -> StoredUser:
        user = await self._load_user(user_id)
        if user is None:
            raise ValueError(f"User {user_id} not found")
        if first_name is not None:
            user.first_name = first_name
        if last_name is not None:
            user.last_name = last_name
        if phone is not None:
            user.phone = phone
        if locale is not None:
            user.locale = locale
        if timezone is not None:
            user.timezone = timezone
        membership = self._default_membership(user)
        if organization_name is not None and membership is not None:
            membership.organization.name = organization_name
        await self._session.flush()
        user = await self._reload_user(user_id)
        return _to_stored(user, self._default_membership(user))

    async def list_users(self) -> list[StoredUser]:
        stmt = (
            select(User)
            .options(selectinload(User.memberships).selectinload(Membership.organization))
            .where(User.deleted_at.is_(None))
            .order_by(User.created_at)
        )
        result = await self._session.execute(stmt)
        users = result.scalars().unique().all()
        return [_to_stored(user, self._default_membership(user)) for user in users]
