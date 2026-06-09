from abc import ABC, abstractmethod
from typing import BinaryIO

from application.dto.document_dto import DocumentCreateDTO, DocumentDTO, DocumentSearchDTO


class DocumentRepository(ABC):
    @abstractmethod
    async def list_documents(
        self, page: int = 1, page_size: int = 25, query: str | None = None
    ) -> tuple[list[DocumentDTO], int]:
        ...

    @abstractmethod
    async def get_document(self, document_id: int) -> DocumentDTO | None:
        ...

    @abstractmethod
    async def upload_document(
        self, file: BinaryIO, filename: str, metadata: DocumentCreateDTO
    ) -> DocumentDTO:
        ...

    @abstractmethod
    async def delete_document(self, document_id: int) -> bool:
        ...

    @abstractmethod
    async def search_documents(self, search: DocumentSearchDTO) -> list[DocumentDTO]:
        ...
