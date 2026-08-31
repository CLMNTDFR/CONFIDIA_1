import httpx
from fastapi import HTTPException, status
from jose import jwt

from application.dto.auth_dto import RegisterRequest, TokenRequest, TokenResponse, UserInfoResponse
from application.services.identity_service import IdentityService
from core.config import Settings
from infrastructure.keycloak.admin_client import (
    KeycloakAdminClient,
    KeycloakAdminError,
    KeycloakUserExistsError,
)


class AuthService:
    def __init__(self, settings: Settings, identity: IdentityService | None = None):
        self._settings = settings
        self._identity = identity

    async def register(self, request: RegisterRequest) -> TokenResponse:
        admin = KeycloakAdminClient(self._settings)
        try:
            await admin.create_user(
                username=request.username,
                email=request.email,
                first_name=request.first_name,
                last_name=request.last_name,
                password=request.password,
            )
        except KeycloakUserExistsError as exc:
            raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=exc.message) from exc
        except KeycloakAdminError as exc:
            raise HTTPException(status_code=exc.status_code, detail=exc.message) from exc
        return await self.login(
            TokenRequest(username=request.username, password=request.password)
        )

    async def login(self, request: TokenRequest) -> TokenResponse:
        async with httpx.AsyncClient() as client:
            response = await client.post(
                self._settings.keycloak_token_url,
                data={
                    "grant_type": "password",
                    "client_id": self._settings.keycloak_client_id,
                    "client_secret": self._settings.keycloak_client_secret,
                    "username": request.username,
                    "password": request.password,
                },
            )
            if response.status_code != 200:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Invalid credentials",
                )
            data = response.json()

        tokens = TokenResponse(
            access_token=data["access_token"],
            refresh_token=data["refresh_token"],
            token_type=data.get("token_type", "bearer"),
            expires_in=data.get("expires_in", 300),
        )
        await self._persist_identity(tokens.access_token)
        return tokens

    async def refresh_token(self, refresh_token: str) -> TokenResponse:
        async with httpx.AsyncClient() as client:
            response = await client.post(
                self._settings.keycloak_token_url,
                data={
                    "grant_type": "refresh_token",
                    "client_id": self._settings.keycloak_client_id,
                    "client_secret": self._settings.keycloak_client_secret,
                    "refresh_token": refresh_token,
                },
            )
            if response.status_code != 200:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Invalid refresh token",
                )
            data = response.json()

        return TokenResponse(
            access_token=data["access_token"],
            refresh_token=data.get("refresh_token", refresh_token),
            token_type=data.get("token_type", "bearer"),
            expires_in=data.get("expires_in", 300),
        )

    def get_user_info(self, token_payload: dict) -> UserInfoResponse:
        realm_access = token_payload.get("realm_access", {})
        roles = realm_access.get("roles", [])
        return UserInfoResponse(
            sub=token_payload.get("sub", ""),
            email=token_payload.get("email", ""),
            name=token_payload.get("name"),
            given_name=token_payload.get("given_name"),
            family_name=token_payload.get("family_name"),
            roles=roles,
        )

    async def _persist_identity(self, access_token: str) -> None:
        if self._identity is None:
            return
        claims = jwt.get_unverified_claims(access_token)
        await self._identity.ensure_from_token_claims(claims)
