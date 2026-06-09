from enum import Enum
from typing import Any

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError, jwt

from core.config import Settings, get_settings

security_scheme = HTTPBearer(auto_error=False)

_jwks_cache: dict[str, Any] | None = None


class Role(str, Enum):
    ADMIN = "ADMIN"
    USER = "USER"
    MANAGER = "MANAGER"


class TokenPayload:
    def __init__(self, sub: str, email: str, roles: list[str], raw: dict[str, Any]):
        self.sub = sub
        self.email = email
        self.roles = roles
        self.raw = raw

    def has_role(self, role: Role) -> bool:
        return role.value in self.roles


async def decode_token(
    credentials: HTTPAuthorizationCredentials | None = Depends(security_scheme),
    settings: Settings = Depends(get_settings),
) -> TokenPayload:
    if credentials is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Not authenticated",
            headers={"WWW-Authenticate": "Bearer"},
        )

    token = credentials.credentials
    try:
        payload = jwt.get_unverified_claims(token)
        realm_access = payload.get("realm_access", {})
        roles = realm_access.get("roles", [])
        resource_access = payload.get("resource_access", {})
        for client_roles in resource_access.values():
            roles.extend(client_roles.get("roles", []))

        return TokenPayload(
            sub=payload.get("sub", ""),
            email=payload.get("email", payload.get("preferred_username", "")),
            roles=list(set(roles)),
            raw=payload,
        )
    except JWTError as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid token: {exc}",
            headers={"WWW-Authenticate": "Bearer"},
        ) from exc


def require_roles(*required_roles: Role):
    async def checker(token: TokenPayload = Depends(decode_token)) -> TokenPayload:
        if not any(token.has_role(role) for role in required_roles):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Required roles: {[r.value for r in required_roles]}",
            )
        return token

    return checker
