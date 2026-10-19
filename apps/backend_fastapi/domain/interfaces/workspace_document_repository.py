from abc import ABC, abstractmethod
from uuid import UUID

from application.dto.document_dto import (
    DocumentCreateDTO,
    DocumentDTO,
    DocumentEventLink,
    DocumentPurgeDecision,
    DocumentUpdateDTO,
)


class DocumentPurgeError(Exception):
    """Live event links do not match the decisions sent with a permanent delete."""

    def __init__(self, links: list[DocumentEventLink]):
        self.links = links
        super().__init__("Les événements liés ont changé")


def resolve_purge_decisions(
    links: list[DocumentEventLink],
    decisions: list[DocumentPurgeDecision],
) -> dict[UUID, str]:
    """Each live link needs exactly one keep or delete choice.

    Events already removed from the agenda are not part of the choice.
    The caller still clears their document link so the row can be deleted.
    """
    live = {UUID(link.event_id) for link in links if not link.deleted}
    chosen: dict[UUID, str] = {}
    for decision in decisions:
        if decision.event_id in chosen:
            raise DocumentPurgeError(links)
        chosen[decision.event_id] = decision.action
    if set(chosen) != live:
        raise DocumentPurgeError(links)
    return chosen


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
    async def list_deleted_for_org(
        self,
        organization_id: UUID,
        page: int,
        page_size: int,
        query: str | None,
    ) -> tuple[list[DocumentDTO], int]:
        ...

    @abstractmethod
    async def restore_for_org(self, organization_id: UUID, document_id: UUID) -> DocumentDTO | None:
        ...

    @abstractmethod
    async def list_event_links(
        self, organization_id: UUID, document_id: UUID
    ) -> list[DocumentEventLink] | None:
        ...

    @abstractmethod
    async def purge_for_org(
        self,
        organization_id: UUID,
        document_id: UUID,
        decisions: list[DocumentPurgeDecision],
    ) -> bool:
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
