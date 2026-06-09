from dependency_injector.wiring import Provide, inject
from fastapi import APIRouter, Depends

from application.dto.auth_dto import (
    RefreshTokenRequest,
    TokenRequest,
    TokenResponse,
    UserInfoResponse,
)
from application.services.auth_service import AuthService
from core.config import Settings, get_settings
from core.security import TokenPayload, decode_token

router = APIRouter()


@router.post("/login", response_model=TokenResponse)
async def login(
    request: TokenRequest,
    settings: Settings = Depends(get_settings),
):
    service = AuthService(settings)
    return await service.login(request)


@router.post("/refresh", response_model=TokenResponse)
async def refresh_token(
    request: RefreshTokenRequest,
    settings: Settings = Depends(get_settings),
):
    service = AuthService(settings)
    return await service.refresh_token(request.refresh_token)


@router.get("/me", response_model=UserInfoResponse)
async def get_current_user(token: TokenPayload = Depends(decode_token)):
    service = AuthService(get_settings())
    return service.get_user_info(token.raw)


@router.post("/logout")
async def logout(token: TokenPayload = Depends(decode_token)):
    return {"message": "Logged out successfully"}
