from dependency_injector.wiring import Provide, inject
from fastapi import APIRouter, Depends, File, HTTPException, Query, UploadFile, status

from application.dto.document_dto import (
    DocumentCreateDTO,
    DocumentDTO,
    DocumentListResponse,
    DocumentSearchDTO,
)
from application.services.document_service import DocumentService
from core.security import Role, TokenPayload, decode_token, require_roles
from domain.interfaces.document_repository import DocumentRepository
from infrastructure.paperless.paperless_client import PaperlessClient

router = APIRouter()


def _get_document_service(
    repository: DocumentRepository = Depends(lambda: PaperlessClient(
        base_url=get_settings_paperless_url(),
        token=get_settings_paperless_token(),
    )),
) -> DocumentService:
    return DocumentService(repository)


def get_settings_paperless_url() -> str:
    from core.config import get_settings
    return get_settings().paperless_url


def get_settings_paperless_token() -> str:
    from core.config import get_settings
    return get_settings().paperless_token


@router.get("/", response_model=DocumentListResponse)
async def list_documents(
    page: int = Query(1, ge=1),
    page_size: int = Query(25, ge=1, le=100),
    query: str | None = None,
    token: TokenPayload = Depends(decode_token),
):
    service = _get_document_service()
    return await service.list_documents(page, page_size, query)


@router.get("/{document_id}", response_model=DocumentDTO)
async def get_document(
    document_id: int,
    token: TokenPayload = Depends(decode_token),
):
    service = _get_document_service()
    doc = await service.get_document(document_id)
    if not doc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Document not found")
    return doc


@router.post("/upload", response_model=DocumentDTO, status_code=status.HTTP_201_CREATED)
async def upload_document(
    file: UploadFile = File(...),
    title: str | None = None,
    category: str | None = None,
    tags: str | None = None,
    token: TokenPayload = Depends(decode_token),
):
    metadata = DocumentCreateDTO(
        title=title,
        category=category,
        tags=tags.split(",") if tags else [],
    )
    service = _get_document_service()
    return await service.upload_document(file.file, file.filename or "document", metadata)


@router.delete("/{document_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_document(
    document_id: int,
    token: TokenPayload = Depends(require_roles(Role.ADMIN, Role.MANAGER)),
):
    service = _get_document_service()
    deleted = await service.delete_document(document_id)
    if not deleted:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Document not found")


@router.post("/search", response_model=list[DocumentDTO])
async def search_documents(
    search: DocumentSearchDTO,
    token: TokenPayload = Depends(decode_token),
):
    service = _get_document_service()
    return await service.search_documents(search)
