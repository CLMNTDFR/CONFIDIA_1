from __future__ import annotations

from dataclasses import dataclass
from datetime import UTC, datetime
from uuid import UUID, uuid4

from application.dto.document_dto import (
    DocumentCreateDTO,
    DocumentDTO,
    DocumentEventLink,
    DocumentPurgeDecision,
    DocumentUpdateDTO,
)
from domain.interfaces.workspace_document_repository import (
    WorkspaceDocumentRepository,
    resolve_purge_decisions,
)


@dataclass
class MemoryEventLink:
    event_id: UUID
    organization_id: UUID
    document_id: UUID | None
    title: str
    start: datetime
    deleted_at: datetime | None = None


class InMemoryDocumentRepository(WorkspaceDocumentRepository):
    def __init__(self) -> None:
        self.rows: list[DocumentDTO] = []
        self.payloads: dict[str, bytes] = {}
        self.org_of: dict[str, UUID] = {}
        self.deleted: dict[str, datetime] = {}
        self.events: list[MemoryEventLink] = []

    def _in_org(self, document_id: str, organization_id: UUID) -> bool:
        return self.org_of.get(document_id) == organization_id

    def _matches(self, row: DocumentDTO, query: str | None) -> bool:
        if not query:
            return True
        q = query.lower()
        return q in row.title.lower() or q in (row.correspondent or "").lower()

    def _select(
        self, organization_id: UUID, query: str | None, *, trashed: bool
    ) -> list[DocumentDTO]:
        items = []
        for row in self.rows:
            if not self._in_org(row.id, organization_id):
                continue
            if (row.id in self.deleted) != trashed:
                continue
            if not self._matches(row, query):
                continue
            if trashed:
                items.append(row.model_copy(update={"deleted_at": self.deleted[row.id]}))
            else:
                items.append(row)
        return items

    async def list_for_org(
        self,
        organization_id: UUID,
        page: int,
        page_size: int,
        query: str | None,
    ) -> tuple[list[DocumentDTO], int]:
        items = self._select(organization_id, query, trashed=False)
        total = len(items)
        start = (page - 1) * page_size
        return items[start : start + page_size], total

    async def list_deleted_for_org(
        self,
        organization_id: UUID,
        page: int,
        page_size: int,
        query: str | None,
    ) -> tuple[list[DocumentDTO], int]:
        items = self._select(organization_id, query, trashed=True)
        total = len(items)
        start = (page - 1) * page_size
        return items[start : start + page_size], total

    async def get_for_org(self, organization_id: UUID, document_id: UUID) -> DocumentDTO | None:
        key = str(document_id)
        if not self._in_org(key, organization_id) or key in self.deleted:
            return None
        for row in self.rows:
            if row.id == key:
                return row
        return None

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
        doc_id = str(uuid4())
        dto = DocumentDTO(
            id=doc_id,
            title=metadata.title or filename,
            created=datetime.now(UTC),
            modified=datetime.now(UTC),
            category=metadata.category,
            document_type=metadata.document_type,
            mime_type=mime_type,
            file_size=len(payload),
            tags=metadata.tags,
        )
        self.rows.append(dto)
        self.payloads[doc_id] = payload
        self.org_of[doc_id] = organization_id
        return dto

    async def read_file(
        self, organization_id: UUID, document_id: UUID
    ) -> tuple[bytes, str, str] | None:
        dto = await self.get_for_org(organization_id, document_id)
        if dto is None:
            return None
        payload = self.payloads.get(str(document_id))
        if payload is None:
            return None
        mime = dto.mime_type or "application/octet-stream"
        suffix = ".pdf" if "pdf" in mime else ""
        name = dto.title.replace("/", "_")
        if suffix and not name.lower().endswith(suffix):
            name = f"{name}{suffix}"
        return payload, mime, name

    async def update_for_org(
        self,
        organization_id: UUID,
        document_id: UUID,
        data: DocumentUpdateDTO,
    ) -> DocumentDTO | None:
        if await self.get_for_org(organization_id, document_id) is None:
            return None
        for index, row in enumerate(self.rows):
            if row.id != str(document_id):
                continue
            updated = row.model_copy(
                update={
                    "title": data.title.strip() if data.title is not None else row.title,
                    "correspondent": (
                        data.correspondent.strip() or None
                        if data.correspondent is not None
                        else row.correspondent
                    ),
                    "document_type": (
                        data.document_type.strip() or None
                        if data.document_type is not None
                        else row.document_type
                    ),
                    "category": (
                        data.category.strip() or None if data.category is not None else row.category
                    ),
                    "is_important": (
                        data.is_important if data.is_important is not None else row.is_important
                    ),
                    "modified": datetime.now(UTC),
                }
            )
            self.rows[index] = updated
            return updated
        return None

    async def delete_for_org(self, organization_id: UUID, document_id: UUID) -> bool:
        key = str(document_id)
        if not self._in_org(key, organization_id) or key in self.deleted:
            return False
        if not any(row.id == key for row in self.rows):
            return False
        self.deleted[key] = datetime.now(UTC)
        return True

    async def restore_for_org(self, organization_id: UUID, document_id: UUID) -> DocumentDTO | None:
        key = str(document_id)
        if not self._in_org(key, organization_id) or key not in self.deleted:
            return None
        self.deleted.pop(key, None)
        for row in self.rows:
            if row.id == key:
                return row
        return None

    def _links(self, organization_id: UUID, document_id: UUID) -> list[DocumentEventLink]:
        return [
            DocumentEventLink(
                event_id=str(event.event_id),
                title=event.title,
                start=event.start,
                deleted=event.deleted_at is not None,
            )
            for event in self.events
            if event.organization_id == organization_id and event.document_id == document_id
        ]

    async def list_event_links(
        self, organization_id: UUID, document_id: UUID
    ) -> list[DocumentEventLink] | None:
        key = str(document_id)
        if not self._in_org(key, organization_id) or key not in self.deleted:
            return None
        return self._links(organization_id, document_id)

    async def purge_for_org(
        self,
        organization_id: UUID,
        document_id: UUID,
        decisions: list[DocumentPurgeDecision],
    ) -> bool:
        key = str(document_id)
        if not self._in_org(key, organization_id) or key not in self.deleted:
            return False
        links = self._links(organization_id, document_id)
        chosen = resolve_purge_decisions(links, decisions)
        now = datetime.now(UTC)
        for event in self.events:
            if event.organization_id != organization_id or event.document_id != document_id:
                continue
            if chosen.get(event.event_id) == "delete":
                event.deleted_at = now
            event.document_id = None
        self.rows = [row for row in self.rows if row.id != key]
        self.payloads.pop(key, None)
        self.org_of.pop(key, None)
        self.deleted.pop(key, None)
        return True
