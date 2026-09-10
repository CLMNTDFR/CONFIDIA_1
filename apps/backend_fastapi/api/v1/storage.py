from io import BytesIO
from pathlib import Path
from urllib.parse import unquote

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status

from application.dto.storage_dto import FileInfoDTO, ShareLinkDTO
from core.config import get_settings
from core.security import TokenPayload, decode_token
from core.uploads import DOCUMENT_TOO_LARGE, MAX_DOCUMENT_BYTES, read_limited
from infrastructure.nextcloud.nextcloud_client import NextcloudStorageProvider

router = APIRouter()


def _get_storage() -> NextcloudStorageProvider:
    settings = get_settings()
    return NextcloudStorageProvider(
        base_url=settings.nextcloud_url,
        username=settings.nextcloud_user,
        password=settings.nextcloud_password,
    )


def _safe_path(path: str) -> str:
    cleaned = unquote(unquote(path.strip())).replace("\\", "/")
    parts = [part for part in cleaned.split("/") if part not in ("", ".")]
    if any(part == ".." for part in parts):
        raise ValueError("Chemin de stockage invalide")
    return "/" + "/".join(parts) if parts else "/"


def _safe_filename(name: str | None) -> str:
    cleaned = Path(unquote(unquote(name or "fichier"))).name
    if cleaned in ("", ".", ".."):
        raise ValueError("Nom de fichier invalide")
    return cleaned


@router.get("/files", response_model=list[FileInfoDTO])
async def list_files(
    directory: str = "/",
    _token: TokenPayload = Depends(decode_token),
):
    try:
        directory = _safe_path(directory)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)) from exc
    storage = _get_storage()
    return await storage.list_files(directory)


@router.post("/upload", response_model=FileInfoDTO)
async def upload_file(
    file: UploadFile = File(...),
    path: str = "/Documents/",
    _token: TokenPayload = Depends(decode_token),
):
    try:
        directory = _safe_path(path)
        filename = _safe_filename(file.filename)
        payload = await read_limited(file, MAX_DOCUMENT_BYTES, too_large=DOCUMENT_TOO_LARGE)
    except ValueError as exc:
        detail = str(exc)
        code = (
            status.HTTP_413_REQUEST_ENTITY_TOO_LARGE
            if "volumineux" in detail
            else status.HTTP_400_BAD_REQUEST
        )
        raise HTTPException(status_code=code, detail=detail) from exc
    storage = _get_storage()
    full_path = f"{directory.rstrip('/')}/{filename}"
    return await storage.upload_file(
        full_path, BytesIO(payload), file.content_type or "application/octet-stream"
    )


@router.post("/share", response_model=ShareLinkDTO)
async def create_share(
    path: str,
    _token: TokenPayload = Depends(decode_token),
):
    try:
        path = _safe_path(path)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)) from exc
    storage = _get_storage()
    return await storage.create_share_link(path)
