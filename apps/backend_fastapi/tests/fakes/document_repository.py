from __future__ import annotations

from uuid import UUID, uuid4

from application.dto.document_dto import DocumentCreateDTO, DocumentDTO, DocumentUpdateDTO
from domain.interfaces.workspace_document_repository import WorkspaceDocumentRepository


class InMemoryDocumentRepository(WorkspaceDocumentRepository):
    def __init__(self) -> None:
        self.rows: list[DocumentDTO] = []
        self.payloads: dict[str, bytes] = {}
        self.org_of: dict[str, UUID] = {}

    def _in_org(self, document_id: str, organization_id: UUID) -> bool:
        return self.org_of.get(document_id) == organization_id

    async def list_for_org(
        self,
        organization_id: UUID,
        page: int,
        page_size: int,
        query: str | None,
    ) -> tuple[list[DocumentDTO], int]:
        items = [row for row in self.rows if self._in_org(row.id, organization_id)]
        if query:
            q = query.lower()
            items = [
                d
                for d in items
                if q in d.title.lower() or q in (d.correspondent or "").lower()
            ]
        total = len(items)
        start = (page - 1) * page_size
        return items[start : start + page_size], total

    async def get_for_org(self, organization_id: UUID, document_id: UUID) -> DocumentDTO | None:
        key = str(document_id)
        if not self._in_org(key, organization_id):
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
        from datetime import UTC, datetime

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
        from datetime import UTC, datetime

        if not self._in_org(str(document_id), organization_id):
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
        if not self._in_org(key, organization_id):
            return False
        before = len(self.rows)
        self.rows = [row for row in self.rows if row.id != key]
        self.payloads.pop(key, None)
        self.org_of.pop(key, None)
        return len(self.rows) < before
