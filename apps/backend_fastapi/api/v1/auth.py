from fastapi import APIRouter, Depends

from api.deps import get_identity_service
from application.dto.auth_dto import (
    ChangePasswordRequest,
    RefreshTokenRequest,
    RegisterRequest,
    TokenRequest,
    TokenResponse,
    UserInfoResponse,
)
from application.services.auth_service import AuthService
from application.services.identity_service import IdentityService
from core.config import Settings, get_settings
from core.security import TokenPayload, decode_token

router = APIRouter()


@router.post("/register", response_model=TokenResponse, status_code=201)
async def register(
    request: RegisterRequest,
    settings: Settings = Depends(get_settings),
    identity: IdentityService = Depends(get_identity_service),
):
    service = AuthService(settings, identity)
    return await service.register(request)


@router.post("/login", response_model=TokenResponse)
async def login(
    request: TokenRequest,
    settings: Settings = Depends(get_settings),
    identity: IdentityService = Depends(get_identity_service),
):
    service = AuthService(settings, identity)
    return await service.login(request)


@router.post("/refresh", response_model=TokenResponse)
async def refresh_token(
    request: RefreshTokenRequest,
    settings: Settings = Depends(get_settings),
):
    service = AuthService(settings)
    return await service.refresh_token(request.refresh_token)


@router.get("/me", response_model=UserInfoResponse)
async def get_current_user(
    token: TokenPayload = Depends(decode_token),
    identity: IdentityService = Depends(get_identity_service),
):
    await identity.ensure_from_token_claims(token.raw)
    service = AuthService(get_settings())
    return service.get_user_info(token.raw)


@router.post("/change-password")
async def change_password(
    request: ChangePasswordRequest,
    token: TokenPayload = Depends(decode_token),
    settings: Settings = Depends(get_settings),
):
    service = AuthService(settings)
    await service.change_password(token, request)
    return {"message": "Mot de passe mis à jour"}


@router.post("/logout")
async def logout(token: TokenPayload = Depends(decode_token)):
    return {"message": "Logged out successfully"}
