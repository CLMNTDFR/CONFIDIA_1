from uuid import UUID
from urllib.parse import quote

from fastapi import APIRouter, Depends, File, Form, HTTPException, Query, UploadFile, status
from fastapi.responses import Response

from api.deps import get_identity_service, get_workspace_document_service
from application.dto.document_dto import (
    DocumentCreateDTO,
    DocumentDTO,
    DocumentListResponse,
    DocumentSearchDTO,
    DocumentUpdateDTO,
)
from application.services.identity_service import IdentityService
from application.services.workspace_document_service import WorkspaceDocumentService
from core.security import TokenPayload, decode_token

router = APIRouter()


async def _workspace(
    token: TokenPayload,
    identity: IdentityService,
) -> tuple[UUID, str]:
    stored = await identity.ensure_from_token_claims(token.raw)
    if stored.organization_id is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Aucun espace de travail n'est associé à ce compte",
        )
    return stored.organization_id, stored.id


@router.get("/", response_model=DocumentListResponse)
async def list_documents(
    page: int = Query(1, ge=1),
    page_size: int = Query(25, ge=1, le=100),
    query: str | None = None,
    token: TokenPayload = Depends(decode_token),
    identity: IdentityService = Depends(get_identity_service),
    documents: WorkspaceDocumentService = Depends(get_workspace_document_service),
):
    organization_id, _ = await _workspace(token, identity)
    return await documents.list_documents(organization_id, page, page_size, query)


@router.get("/{document_id}", response_model=DocumentDTO)
async def get_document(
    document_id: UUID,
    token: TokenPayload = Depends(decode_token),
    identity: IdentityService = Depends(get_identity_service),
    documents: WorkspaceDocumentService = Depends(get_workspace_document_service),
):
    organization_id, _ = await _workspace(token, identity)
    doc = await documents.get_document(organization_id, document_id)
    if not doc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Document introuvable")
    return doc


@router.get("/{document_id}/file")
async def download_document_file(
    document_id: UUID,
    token: TokenPayload = Depends(decode_token),
    identity: IdentityService = Depends(get_identity_service),
    documents: WorkspaceDocumentService = Depends(get_workspace_document_service),
):
    organization_id, _ = await _workspace(token, identity)
    stored = await documents.read_file(organization_id, document_id)
    if not stored:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Fichier introuvable")
    payload, mime_type, filename = stored
    encoded = quote(filename)
    return Response(
        content=payload,
        media_type=mime_type or "application/octet-stream",
        headers={
            "Content-Disposition": f"inline; filename*=UTF-8''{encoded}",
        },
    )


@router.patch("/{document_id}", response_model=DocumentDTO)
async def update_document(
    document_id: UUID,
    payload: DocumentUpdateDTO,
    token: TokenPayload = Depends(decode_token),
    identity: IdentityService = Depends(get_identity_service),
    documents: WorkspaceDocumentService = Depends(get_workspace_document_service),
):
    organization_id, _ = await _workspace(token, identity)
    try:
        doc = await documents.update_document(organization_id, document_id, payload)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_CONTENT, detail=str(exc)) from exc
    if not doc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Document introuvable")
    return doc


@router.delete("/{document_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_document(
    document_id: UUID,
    token: TokenPayload = Depends(decode_token),
    identity: IdentityService = Depends(get_identity_service),
    documents: WorkspaceDocumentService = Depends(get_workspace_document_service),
):
    organization_id, _ = await _workspace(token, identity)
    deleted = await documents.delete_document(organization_id, document_id)
    if not deleted:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Document introuvable")


@router.post("/upload", response_model=DocumentDTO, status_code=status.HTTP_201_CREATED)
async def upload_document(
    file: UploadFile = File(...),
    title: str | None = Form(None),
    category: str | None = Form(None),
    document_type: str | None = Form(None),
    tags: str | None = Form(None),
    token: TokenPayload = Depends(decode_token),
    identity: IdentityService = Depends(get_identity_service),
    documents: WorkspaceDocumentService = Depends(get_workspace_document_service),
):
    organization_id, owner_id = await _workspace(token, identity)
    payload = await file.read()
    metadata = DocumentCreateDTO(
        title=title,
        category=category,
        document_type=document_type,
        tags=tags.split(",") if tags else [],
    )
    try:
        return await documents.upload_document(
            organization_id=organization_id,
            owner_id=owner_id,
            filename=file.filename or "document",
            payload=payload,
            mime_type=file.content_type,
            metadata=metadata,
        )
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail=str(exc),
        ) from exc


@router.post("/search", response_model=list[DocumentDTO])
async def search_documents(
    search: DocumentSearchDTO,
    token: TokenPayload = Depends(decode_token),
    identity: IdentityService = Depends(get_identity_service),
    documents: WorkspaceDocumentService = Depends(get_workspace_document_service),
):
    organization_id, _ = await _workspace(token, identity)
    result = await documents.list_documents(
        organization_id, page=1, page_size=100, query=search.query
    )
    items = result.items
    if search.category:
        items = [d for d in items if d.category == search.category]
    if search.tags:
        items = [d for d in items if any(t in d.tags for t in search.tags)]
    return items
