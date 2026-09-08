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
        keep_first = (existing.stored.first_name or "").strip()
        keep_last = (existing.stored.last_name or "").strip()
        stored = replace(
            existing.stored,
            email=email,
            first_name=existing.stored.first_name if keep_first else first_name,
            last_name=existing.stored.last_name if keep_last else last_name,
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

    async def update_profile(self, user_id: str, **fields: str | None) -> StoredUser:
        row = self.rows[user_id]
        stored = row.stored
        updates: dict = {}
        if "first_name" in fields and fields["first_name"]:
            updates["first_name"] = fields["first_name"]
        if "last_name" in fields and fields["last_name"]:
            updates["last_name"] = fields["last_name"]
        if "phone" in fields:
            updates["phone"] = fields["phone"] or None
        if "locale" in fields and fields["locale"]:
            updates["locale"] = fields["locale"]
        if "timezone" in fields and fields["timezone"]:
            updates["timezone"] = fields["timezone"]
        if "avatar_url" in fields:
            updates["avatar_url"] = fields["avatar_url"] or None
        if "organization_name" in fields and fields["organization_name"]:
            updates["organization_name"] = fields["organization_name"]
        stored = replace(stored, **updates)
        self.rows[user_id] = _Row(stored=stored, org_id=row.org_id)
        return stored

    async def list_users(self) -> list[StoredUser]:
        return [row.stored for row in self.rows.values()]
