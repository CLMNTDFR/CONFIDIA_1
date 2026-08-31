from dataclasses import dataclass, replace
from uuid import UUID, uuid4

from domain.interfaces.identity_repository import IdentityRepository, StoredUser


@dataclass
class _Row:
    stored: StoredUser
    org_id: UUID | None


class InMemoryIdentityRepository(IdentityRepository):
    def __init__(self) -> None:
        self.rows: dict[str, _Row] = {}

    async def get_user(self, user_id: str) -> StoredUser | None:
        row = self.rows.get(user_id)
        return row.stored if row else None

    async def upsert_user(
        self,
        *,
        user_id: str,
        email: str,
        first_name: str,
        last_name: str,
    ) -> StoredUser:
        existing = self.rows.get(user_id)
        if existing is None:
            stored = StoredUser(
                id=user_id,
                email=email,
                first_name=first_name,
                last_name=last_name,
                phone=None,
                avatar_url=None,
                locale="fr-FR",
                timezone="Europe/Paris",
                organization_id=None,
                organization_name=None,
                membership_role=None,
            )
            self.rows[user_id] = _Row(stored=stored, org_id=None)
            return stored
        stored = replace(
            existing.stored,
            email=email,
            first_name=first_name or existing.stored.first_name,
            last_name=last_name or existing.stored.last_name,
        )
        self.rows[user_id] = _Row(stored=stored, org_id=existing.org_id)
        return stored

    async def ensure_default_workspace(self, user_id: str) -> StoredUser:
        row = self.rows[user_id]
        if row.stored.organization_id is not None:
            return row.stored
        org_id = uuid4()
        stored = replace(
            row.stored,
            organization_id=org_id,
            organization_name="Famille",
            membership_role="owner",
        )
        self.rows[user_id] = _Row(stored=stored, org_id=org_id)
        return stored

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
        row = self.rows[user_id]
        stored = row.stored
        stored = replace(
            stored,
            first_name=stored.first_name if first_name is None else first_name,
            last_name=stored.last_name if last_name is None else last_name,
            phone=stored.phone if phone is None else phone,
            locale=stored.locale if locale is None else locale,
            timezone=stored.timezone if timezone is None else timezone,
            organization_name=(
                stored.organization_name if organization_name is None else organization_name
            ),
        )
        self.rows[user_id] = _Row(stored=stored, org_id=row.org_id)
        return stored

    async def list_users(self) -> list[StoredUser]:
        return [row.stored for row in self.rows.values()]
