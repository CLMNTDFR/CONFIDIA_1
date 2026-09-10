from enum import StrEnum
from typing import Any

import httpx
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError, jwt

from core.config import Settings, get_settings

security_scheme = HTTPBearer(auto_error=False)

_jwks_cache: dict[str, Any] | None = None
_HTTP_TIMEOUT = 5.0


class Role(StrEnum):
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


def clear_jwks_cache() -> None:
    global _jwks_cache
    _jwks_cache = None


def _payload_to_token(payload: dict[str, Any]) -> TokenPayload:
    sub = str(payload.get("sub") or "").strip()
    if not sub:
        raise JWTError("Token is missing sub")
    realm_access = payload.get("realm_access") or {}
    roles = list(realm_access.get("roles") or [])
    resource_access = payload.get("resource_access") or {}
    for client_roles in resource_access.values():
        if isinstance(client_roles, dict):
            roles.extend(client_roles.get("roles") or [])
    return TokenPayload(
        sub=sub,
        email=str(payload.get("email") or payload.get("preferred_username") or ""),
        roles=list(set(roles)),
        raw=payload,
    )


def _unauthorized(detail: str = "Invalid token") -> HTTPException:
    return HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail=detail,
        headers={"WWW-Authenticate": "Bearer"},
    )


def _decode_hs256(token: str, settings: Settings) -> dict[str, Any]:
    return jwt.decode(
        token,
        settings.jwt_test_secret,
        algorithms=["HS256"],
        options={"verify_aud": False},
    )


def _decode_rs256(token: str, jwks: dict[str, Any], kid: str | None) -> dict[str, Any]:
    keys = [k for k in (jwks.get("keys") or []) if isinstance(k, dict)]
    if kid:
        keys = [k for k in keys if k.get("kid") == kid]
    if not keys:
        raise JWTError("Unknown signing key")
    last_error: JWTError | None = None
    for key in keys:
        try:
            return jwt.decode(
                token,
                key,
                algorithms=["RS256"],
                options={"verify_aud": False},
            )
        except JWTError as exc:
            last_error = exc
    raise last_error or JWTError("Invalid token")


async def _load_jwks(settings: Settings, force: bool = False) -> dict[str, Any]:
    global _jwks_cache
    if _jwks_cache is not None and not force:
        return _jwks_cache
    async with httpx.AsyncClient(timeout=_HTTP_TIMEOUT) as client:
        response = await client.get(settings.keycloak_certs_url)
        response.raise_for_status()
        data = response.json()
    if not isinstance(data, dict) or not data.get("keys"):
        raise JWTError("JWKS unavailable")
    _jwks_cache = data
    return data


async def verified_claims(token: str, settings: Settings) -> dict[str, Any]:
    try:
        header = jwt.get_unverified_header(token)
    except JWTError as exc:
        raise _unauthorized() from exc
    alg = header.get("alg")
    try:
        if settings.app_env == "test" and alg == "HS256":
            return _decode_hs256(token, settings)
        if alg != "RS256":
            raise JWTError("Unsupported algorithm")
        jwks = await _load_jwks(settings)
        kid = header.get("kid") if isinstance(header.get("kid"), str) else None
        try:
            return _decode_rs256(token, jwks, kid)
        except JWTError:
            jwks = await _load_jwks(settings, force=True)
            return _decode_rs256(token, jwks, kid)
    except HTTPException:
        raise
    except Exception as exc:
        raise _unauthorized() from exc


async def decode_token(
    credentials: HTTPAuthorizationCredentials | None = Depends(security_scheme),
    settings: Settings = Depends(get_settings),
) -> TokenPayload:
    if credentials is None:
        raise _unauthorized("Not authenticated")
    try:
        payload = await verified_claims(credentials.credentials, settings)
        return _payload_to_token(payload)
    except HTTPException:
        raise
    except JWTError as exc:
        raise _unauthorized() from exc


def require_roles(*required_roles: Role):
    async def checker(token: TokenPayload = Depends(decode_token)) -> TokenPayload:
        if not any(token.has_role(role) for role in required_roles):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Required roles: {[r.value for r in required_roles]}",
            )
        return token

    return checker
