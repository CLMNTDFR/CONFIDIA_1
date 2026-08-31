from domain.interfaces.identity_repository import IdentityRepository, StoredUser


def names_from_claims(claims: dict) -> tuple[str, str]:
    given = str(claims.get("given_name") or "").strip()
    family = str(claims.get("family_name") or "").strip()
    if given or family:
        return given, family
    name = str(claims.get("name") or "").strip()
    if name:
        parts = name.split(None, 1)
        return parts[0], parts[1] if len(parts) > 1 else ""
    preferred = str(claims.get("preferred_username") or "").strip()
    return preferred, ""


def email_from_claims(claims: dict) -> str:
    email = str(claims.get("email") or "").strip()
    if email:
        return email
    preferred = str(claims.get("preferred_username") or claims.get("sub") or "user").strip()
    return f"{preferred}@confidia.local"


class IdentityService:
    """Creates the CONFIDIA user + default Famille workspace after Keycloak login."""

    def __init__(self, repository: IdentityRepository):
        self._repository = repository

    async def ensure_from_token_claims(self, claims: dict) -> StoredUser:
        sub = str(claims.get("sub") or "").strip()
        if not sub:
            raise ValueError("Keycloak token is missing sub")
        first_name, last_name = names_from_claims(claims)
        await self._repository.upsert_user(
            user_id=sub,
            email=email_from_claims(claims),
            first_name=first_name,
            last_name=last_name,
        )
        return await self._repository.ensure_default_workspace(sub)

    async def get_user(self, user_id: str) -> StoredUser | None:
        return await self._repository.get_user(user_id)

    async def update_profile(self, user_id: str, **fields: str | None) -> StoredUser:
        return await self._repository.update_profile(user_id, **fields)

    async def list_users(self) -> list[StoredUser]:
        return await self._repository.list_users()
