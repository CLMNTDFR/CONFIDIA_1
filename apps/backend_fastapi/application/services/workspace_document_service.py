from uuid import UUID

from application.dto.document_dto import (
    DocumentCreateDTO,
    DocumentDTO,
    DocumentListResponse,
    DocumentUpdateDTO,
)
from core.uploads import inspect_document
from domain.interfaces.workspace_document_repository import WorkspaceDocumentRepository


class WorkspaceDocumentService:
    def __init__(self, repository: WorkspaceDocumentRepository):
        self._repository = repository

    async def list_documents(
        self,
        organization_id: UUID,
        page: int = 1,
        page_size: int = 25,
        query: str | None = None,
    ) -> DocumentListResponse:
        items, total = await self._repository.list_for_org(
            organization_id, page, page_size, query
        )
        return DocumentListResponse(items=items, total=total, page=page, page_size=page_size)

    async def get_document(self, organization_id: UUID, document_id: UUID) -> DocumentDTO | None:
        return await self._repository.get_for_org(organization_id, document_id)

    async def upload_document(
        self,
        *,
        organization_id: UUID,
        owner_id: str,
        filename: str,
        payload: bytes,
        metadata: DocumentCreateDTO,
    ) -> DocumentDTO:
        mime_type = inspect_document(filename, payload)
        return await self._repository.create(
            organization_id=organization_id,
            owner_id=owner_id,
            filename=filename,
            payload=payload,
            mime_type=mime_type,
            metadata=metadata,
        )

    async def read_file(
        self, organization_id: UUID, document_id: UUID
    ) -> tuple[bytes, str, str] | None:
        return await self._repository.read_file(organization_id, document_id)

    async def update_document(
        self,
        organization_id: UUID,
        document_id: UUID,
        data: DocumentUpdateDTO,
    ) -> DocumentDTO | None:
        if data.title is not None and not data.title.strip():
            raise ValueError("Le titre est requis")
        return await self._repository.update_for_org(organization_id, document_id, data)

    async def delete_document(self, organization_id: UUID, document_id: UUID) -> bool:
        return await self._repository.delete_for_org(organization_id, document_id)
