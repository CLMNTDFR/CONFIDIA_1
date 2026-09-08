from abc import ABC, abstractmethod
from dataclasses import dataclass
from uuid import UUID


@dataclass(frozen=True)
class StoredUser:
    id: str
    email: str
    first_name: str
    last_name: str
    phone: str | None
    avatar_url: str | None
    locale: str
    timezone: str
    organization_id: UUID | None
    organization_name: str | None
    membership_role: str | None


class IdentityRepository(ABC):
    @abstractmethod
    async def get_user(self, user_id: str) -> StoredUser | None:
        ...

    @abstractmethod
    async def upsert_user(
        self,
        *,
        user_id: str,
        email: str,
        first_name: str,
        last_name: str,
    ) -> StoredUser:
        ...

    @abstractmethod
    async def ensure_default_workspace(self, user_id: str) -> StoredUser:
        ...

    @abstractmethod
    async def update_profile(self, user_id: str, **fields: str | None) -> StoredUser:
        ...

    @abstractmethod
    async def list_users(self) -> list[StoredUser]:
        ...
