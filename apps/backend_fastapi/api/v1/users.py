from fastapi import APIRouter, Depends

from application.dto.user_dto import UserListResponse, UserProfileDTO, UserProfileUpdateDTO
from application.services.user_service import UserService
from core.security import Role, TokenPayload, decode_token, require_roles

router = APIRouter()
_user_service = UserService()


@router.get("/me", response_model=UserProfileDTO)
async def get_my_profile(token: TokenPayload = Depends(decode_token)):
    return await _user_service.get_profile(token)


@router.put("/me", response_model=UserProfileDTO)
async def update_my_profile(
    data: UserProfileUpdateDTO,
    token: TokenPayload = Depends(decode_token),
):
    return await _user_service.update_profile(token, data)


@router.get("/", response_model=UserListResponse)
async def list_users(token: TokenPayload = Depends(require_roles(Role.ADMIN))):
    return await _user_service.list_users()
