from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status
from fastapi.responses import Response

from api.deps import get_identity_service
from application.dto.user_dto import UserListResponse, UserProfileDTO, UserProfileUpdateDTO
from application.services.identity_service import IdentityService
from application.services.user_service import UserService
from core.security import Role, TokenPayload, decode_token, require_roles
from core.uploads import AVATAR_TOO_LARGE, MAX_AVATAR_BYTES, read_limited, upload_error_status
from infrastructure.avatar_files import delete_avatar, read_avatar, save_avatar

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


@router.get("/me/avatar")
async def get_my_avatar(token: TokenPayload = Depends(decode_token)):
    stored = read_avatar(token.sub)
    if stored is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Aucune photo de profil")
    payload, mime_type = stored
    return Response(content=payload, media_type=mime_type)


@router.post("/me/avatar", response_model=UserProfileDTO)
async def upload_my_avatar(
    file: UploadFile = File(...),
    token: TokenPayload = Depends(decode_token),
    users: UserService = Depends(get_user_service),
    identity: IdentityService = Depends(get_identity_service),
):
    try:
        payload = await read_limited(file, MAX_AVATAR_BYTES, too_large=AVATAR_TOO_LARGE)
        url = save_avatar(token.sub, payload)
    except ValueError as exc:
        detail = str(exc)
        raise HTTPException(status_code=upload_error_status(detail), detail=detail) from exc
    await identity.ensure_from_token_claims(token.raw)
    await identity.update_profile(token.sub, avatar_url=url)
    return await users.get_profile(token)


@router.delete("/me/avatar", response_model=UserProfileDTO)
async def delete_my_avatar(
    token: TokenPayload = Depends(decode_token),
    users: UserService = Depends(get_user_service),
    identity: IdentityService = Depends(get_identity_service),
):
    delete_avatar(token.sub)
    await identity.ensure_from_token_claims(token.raw)
    await identity.update_profile(token.sub, avatar_url=None)
    return await users.get_profile(token)


@router.get("/", response_model=UserListResponse)
async def list_users(
    token: TokenPayload = Depends(require_roles(Role.ADMIN)),
    users: UserService = Depends(get_user_service),
):
    return await users.list_users()
