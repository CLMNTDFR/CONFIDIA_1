from typing import BinaryIO

from application.dto.document_dto import (
    DocumentCreateDTO,
    DocumentDTO,
    DocumentListResponse,
    DocumentSearchDTO,
)
from domain.interfaces.document_repository import DocumentRepository


class DocumentService:
    def __init__(self, repository: DocumentRepository):
        self._repository = repository

    async def list_documents(
        self, page: int = 1, page_size: int = 25, query: str | None = None
    ) -> DocumentListResponse:
        items, total = await self._repository.list_documents(page, page_size, query)
        return DocumentListResponse(items=items, total=total, page=page, page_size=page_size)

    async def get_document(self, document_id: int) -> DocumentDTO | None:
        return await self._repository.get_document(document_id)

    async def upload_document(
        self, file: BinaryIO, filename: str, metadata: DocumentCreateDTO
    ) -> DocumentDTO:
        return await self._repository.upload_document(file, filename, metadata)

    async def delete_document(self, document_id: int) -> bool:
        return await self._repository.delete_document(document_id)

    async def search_documents(self, search: DocumentSearchDTO) -> list[DocumentDTO]:
        return await self._repository.search_documents(search)
