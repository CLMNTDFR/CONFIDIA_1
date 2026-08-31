from abc import ABC, abstractmethod
from uuid import UUID

from application.dto.document_dto import DocumentCreateDTO, DocumentDTO, DocumentUpdateDTO


class WorkspaceDocumentRepository(ABC):
    @abstractmethod
    async def list_for_org(
        self,
        organization_id: UUID,
        page: int,
        page_size: int,
        query: str | None,
    ) -> tuple[list[DocumentDTO], int]:
        ...

    @abstractmethod
    async def get_for_org(self, organization_id: UUID, document_id: UUID) -> DocumentDTO | None:
        ...

    @abstractmethod
    async def read_file(
        self, organization_id: UUID, document_id: UUID
    ) -> tuple[bytes, str, str] | None:
        ...

    @abstractmethod
    async def update_for_org(
        self,
        organization_id: UUID,
        document_id: UUID,
        data: DocumentUpdateDTO,
    ) -> DocumentDTO | None:
        ...

    @abstractmethod
    async def delete_for_org(self, organization_id: UUID, document_id: UUID) -> bool:
        ...

    @abstractmethod
    async def create(
        self,
        *,
        organization_id: UUID,
        owner_id: str,
        filename: str,
        payload: bytes,
        mime_type: str | None,
        metadata: DocumentCreateDTO,
    ) -> DocumentDTO:
        ...
