from fastapi import APIRouter, Depends, File, UploadFile

from application.dto.storage_dto import FileInfoDTO, ShareLinkDTO
from core.config import get_settings
from core.security import TokenPayload, decode_token
from infrastructure.nextcloud.nextcloud_client import NextcloudStorageProvider

router = APIRouter()


def _get_storage() -> NextcloudStorageProvider:
    settings = get_settings()
    return NextcloudStorageProvider(
        base_url=settings.nextcloud_url,
        username=settings.nextcloud_user,
        password=settings.nextcloud_password,
    )


@router.get("/files", response_model=list[FileInfoDTO])
async def list_files(
    directory: str = "/",
    token: TokenPayload = Depends(decode_token),
):
    storage = _get_storage()
    return await storage.list_files(directory)


@router.post("/upload", response_model=FileInfoDTO)
async def upload_file(
    file: UploadFile = File(...),
    path: str = "/Documents/",
    token: TokenPayload = Depends(decode_token),
):
    storage = _get_storage()
    full_path = f"{path.rstrip('/')}/{file.filename}"
    return await storage.upload_file(
        full_path, file.file, file.content_type or "application/octet-stream"
    )


@router.post("/share", response_model=ShareLinkDTO)
async def create_share(
    path: str,
    token: TokenPayload = Depends(decode_token),
):
    storage = _get_storage()
    return await storage.create_share_link(path)
