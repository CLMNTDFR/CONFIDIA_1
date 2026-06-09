from application.dto.user_dto import UserListResponse, UserProfileDTO, UserProfileUpdateDTO
from core.security import TokenPayload


class UserService:
    """User profile service. Profiles are derived from Keycloak tokens + local extensions."""

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

    async def get_profile(self, token: TokenPayload) -> UserProfileDTO:
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

    async def update_profile(
        self, token: TokenPayload, data: UserProfileUpdateDTO
    ) -> UserProfileDTO:
        profile = await self.get_profile(token)
        update_data = data.model_dump(exclude_unset=True)
        return profile.model_copy(update=update_data)

    async def list_users(self) -> UserListResponse:
        users = list(self._MOCK_USERS.values())
        return UserListResponse(items=users, total=len(users))
