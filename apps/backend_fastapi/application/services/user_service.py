from application.dto.user_dto import UserListResponse, UserProfileDTO, UserProfileUpdateDTO
from application.services.identity_service import IdentityService
from core.security import TokenPayload
from domain.interfaces.identity_repository import StoredUser


class UserService:
    """Profile service: Keycloak token + CONFIDIA Postgres row."""

    _MOCK_USERS = {
        "admin": UserProfileDTO(
            id="admin",
            email="admin@confidia.local",
            first_name="Admin",
            last_name="CONFIDIA",
            roles=["ADMIN", "USER"],
            organization="CONFIDIA SAS",
            phone="+33 6 00 00 00 01",
        ),
        "user": UserProfileDTO(
            id="user",
            email="user@confidia.local",
            first_name="Jean",
            last_name="Dupont",
            roles=["USER"],
            organization="Particulier",
            phone="+33 6 12 34 56 78",
        ),
        "manager": UserProfileDTO(
            id="manager",
            email="manager@confidia.local",
            first_name="Marie",
            last_name="Martin",
            roles=["MANAGER", "USER"],
            organization="CONFIDIA SAS",
            phone="+33 6 98 76 54 32",
        ),
    }

    def __init__(self, identity: IdentityService | None = None):
        self._identity = identity

    def _to_dto(self, stored: StoredUser, token: TokenPayload) -> UserProfileDTO:
        return UserProfileDTO(
            id=stored.id,
            email=stored.email,
            first_name=stored.first_name,
            last_name=stored.last_name,
            roles=token.roles,
            avatar_url=stored.avatar_url,
            phone=stored.phone,
            organization=stored.organization_name,
            locale=stored.locale,
            timezone=stored.timezone,
        )

    def _mock_profile(self, token: TokenPayload) -> UserProfileDTO:
        username = token.email.split("@")[0] if token.email else token.sub
        profile = self._MOCK_USERS.get(username)
        if profile:
            return profile
        return UserProfileDTO(
            id=token.sub,
            email=token.email,
            first_name=token.raw.get("given_name", ""),
            last_name=token.raw.get("family_name", ""),
            roles=token.roles,
        )

    async def get_profile(self, token: TokenPayload) -> UserProfileDTO:
        if self._identity is not None:
            stored = await self._identity.ensure_from_token_claims(token.raw)
            return self._to_dto(stored, token)
        return self._mock_profile(token)

    async def update_profile(
        self, token: TokenPayload, data: UserProfileUpdateDTO
    ) -> UserProfileDTO:
        if self._identity is None:
            profile = await self.get_profile(token)
            return profile.model_copy(update=data.model_dump(exclude_unset=True))
        await self._identity.ensure_from_token_claims(token.raw)
        stored = await self._identity.update_profile(
            token.sub,
            first_name=data.first_name,
            last_name=data.last_name,
            phone=data.phone,
            locale=data.locale,
            timezone=data.timezone,
            organization_name=data.organization,
        )
        return self._to_dto(stored, token)

    async def list_users(self) -> UserListResponse:
        if self._identity is None:
            users = list(self._MOCK_USERS.values())
            return UserListResponse(items=users, total=len(users))
        stored = await self._identity.list_users()
        items = [
            UserProfileDTO(
                id=row.id,
                email=row.email,
                first_name=row.first_name,
                last_name=row.last_name,
                organization=row.organization_name,
                phone=row.phone,
                locale=row.locale,
                timezone=row.timezone,
                avatar_url=row.avatar_url,
            )
            for row in stored
        ]
        return UserListResponse(items=items, total=len(items))
