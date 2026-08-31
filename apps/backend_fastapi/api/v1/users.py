from fastapi import APIRouter, Depends

from api.deps import get_identity_service
from application.dto.user_dto import UserListResponse, UserProfileDTO, UserProfileUpdateDTO
from application.services.identity_service import IdentityService
from application.services.user_service import UserService
from core.security import Role, TokenPayload, decode_token, require_roles

router = APIRouter()


def get_user_service(identity: IdentityService = Depends(get_identity_service)) -> UserService:
    return UserService(identity)


@router.get("/me", response_model=UserProfileDTO)
async def get_my_profile(
    token: TokenPayload = Depends(decode_token),
    users: UserService = Depends(get_user_service),
):
    return await users.get_profile(token)


@router.put("/me", response_model=UserProfileDTO)
async def update_my_profile(
    data: UserProfileUpdateDTO,
    token: TokenPayload = Depends(decode_token),
    users: UserService = Depends(get_user_service),
):
    return await users.update_profile(token, data)


@router.get("/", response_model=UserListResponse)
async def list_users(
    token: TokenPayload = Depends(require_roles(Role.ADMIN)),
    users: UserService = Depends(get_user_service),
):
    return await users.list_users()
