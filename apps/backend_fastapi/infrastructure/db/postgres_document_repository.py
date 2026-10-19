from __future__ import annotations

from datetime import UTC, datetime
from pathlib import Path
from uuid import UUID, uuid4

from sqlalchemy import func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from application.dto.document_dto import (
    DocumentCreateDTO,
    DocumentDTO,
    DocumentEventLink,
    DocumentPurgeDecision,
    DocumentUpdateDTO,
)
from core.uploads import suffix_for_mime
from domain.interfaces.workspace_document_repository import (
    WorkspaceDocumentRepository,
    resolve_purge_decisions,
)
from infrastructure.db.models import CalendarEvent, Document


def _event_links(events: list[CalendarEvent]) -> list[DocumentEventLink]:
    return [
        DocumentEventLink(
            event_id=str(event.id),
            title=event.title,
            start=event.starts_at,
            deleted=event.deleted_at is not None,
        )
        for event in events
    ]


def _to_dto(row: Document) -> DocumentDTO:
    return DocumentDTO(
        id=str(row.id),
        title=row.title,
        content=row.content,
        created=row.created_at,
        modified=row.updated_at,
        correspondent=row.correspondent,
        document_type=row.document_type,
        category=row.category,
        mime_type=row.mime_type,
        file_size=row.file_size,
        is_important=row.is_important,
        deleted_at=row.deleted_at,
        tags=[],
    )


class PostgresDocumentRepository(WorkspaceDocumentRepository):
    def __init__(self, session: AsyncSession, storage_dir: Path):
        self._session = session
        self._storage_dir = storage_dir
        self._storage_dir.mkdir(parents=True, exist_ok=True)

    def _file_in_storage(self, storage_path: str | None) -> Path | None:
        if not storage_path:
            return None
        root = self._storage_dir.resolve()
        dest = (self._storage_dir / storage_path).resolve()
        try:
            dest.relative_to(root)
        except ValueError:
            return None
        return dest

    async def _page(
        self,
        organization_id: UUID,
        page: int,
        page_size: int,
        query: str | None,
        *,
        trashed: bool,
    ) -> tuple[list[DocumentDTO], int]:
        filters = [
            Document.organization_id == organization_id,
            Document.deleted_at.is_not(None) if trashed else Document.deleted_at.is_(None),
        ]
        if query:
            like = f"%{query.strip()}%"
            filters.append(
                or_(
                    Document.title.ilike(like),
                    Document.correspondent.ilike(like),
                    Document.category.ilike(like),
                )
            )
        total = await self._session.scalar(
            select(func.count()).select_from(Document).where(*filters)
        )
        order = Document.deleted_at.desc() if trashed else Document.created_at.desc()
        stmt = (
            select(Document)
            .where(*filters)
            .order_by(order)
            .offset((page - 1) * page_size)
            .limit(page_size)
        )
        rows = (await self._session.scalars(stmt)).all()
        return [_to_dto(row) for row in rows], int(total or 0)

    async def list_for_org(
        self,
        organization_id: UUID,
        page: int,
        page_size: int,
        query: str | None,
    ) -> tuple[list[DocumentDTO], int]:
        return await self._page(organization_id, page, page_size, query, trashed=False)

    async def list_deleted_for_org(
        self,
        organization_id: UUID,
        page: int,
        page_size: int,
        query: str | None,
    ) -> tuple[list[DocumentDTO], int]:
        return await self._page(organization_id, page, page_size, query, trashed=True)

    async def get_for_org(self, organization_id: UUID, document_id: UUID) -> DocumentDTO | None:
        stmt = select(Document).where(
            Document.id == document_id,
            Document.organization_id == organization_id,
            Document.deleted_at.is_(None),
        )
        row = (await self._session.execute(stmt)).scalar_one_or_none()
        return _to_dto(row) if row else None

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
        document_id = uuid4()
        suffix = suffix_for_mime(mime_type or "", filename)
        relative = Path(str(organization_id)) / f"{document_id}{suffix}"
        dest = self._storage_dir / relative
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_bytes(payload)
        row = Document(
            id=document_id,
            organization_id=organization_id,
            owner_id=owner_id,
            title=metadata.title or filename,
            content=None,
            correspondent=metadata.correspondent,
            document_type=metadata.document_type,
            category=metadata.category,
            mime_type=mime_type,
            file_size=len(payload),
            storage_path=str(relative),
            created_by=owner_id,
        )
        self._session.add(row)
        await self._session.flush()
        loaded = await self.get_for_org(organization_id, document_id)
        assert loaded is not None
        return loaded

    async def read_file(
        self, organization_id: UUID, document_id: UUID
    ) -> tuple[bytes, str, str] | None:
        stmt = select(Document).where(
            Document.id == document_id,
            Document.organization_id == organization_id,
            Document.deleted_at.is_(None),
        )
        row = (await self._session.execute(stmt)).scalar_one_or_none()
        if row is None:
            return None
        dest = self._file_in_storage(row.storage_path)
        if dest is None or not dest.is_file():
            return None
        suffix = dest.suffix
        name = (row.title or "document").replace("/", "_").replace("\\", "_")
        if suffix and not name.lower().endswith(suffix.lower()):
            name = f"{name}{suffix}"
        mime = row.mime_type or "application/octet-stream"
        return dest.read_bytes(), mime, name

    async def update_for_org(
        self,
        organization_id: UUID,
        document_id: UUID,
        data: DocumentUpdateDTO,
    ) -> DocumentDTO | None:
        stmt = select(Document).where(
            Document.id == document_id,
            Document.organization_id == organization_id,
            Document.deleted_at.is_(None),
        )
        row = (await self._session.execute(stmt)).scalar_one_or_none()
        if row is None:
            return None
        updates = data.model_dump(exclude_unset=True)
        if "title" in updates and updates["title"] is not None:
            row.title = str(updates["title"]).strip()
        if "correspondent" in updates:
            value = updates["correspondent"]
            row.correspondent = str(value).strip() or None if value is not None else None
        if "document_type" in updates:
            value = updates["document_type"]
            row.document_type = str(value).strip() or None if value is not None else None
        if "category" in updates:
            value = updates["category"]
            row.category = str(value).strip() or None if value is not None else None
        if "is_important" in updates and updates["is_important"] is not None:
            row.is_important = bool(updates["is_important"])
        row.updated_at = datetime.now(UTC)
        await self._session.flush()
        return _to_dto(row)

    async def delete_for_org(self, organization_id: UUID, document_id: UUID) -> bool:
        stmt = select(Document).where(
            Document.id == document_id,
            Document.organization_id == organization_id,
            Document.deleted_at.is_(None),
        )
        row = (await self._session.execute(stmt)).scalar_one_or_none()
        if row is None:
            return False
        row.deleted_at = datetime.now(UTC)
        row.updated_at = row.deleted_at
        await self._session.flush()
        return True

    async def _trashed(self, organization_id: UUID, document_id: UUID) -> Document | None:
        stmt = select(Document).where(
            Document.id == document_id,
            Document.organization_id == organization_id,
            Document.deleted_at.is_not(None),
        )
        return (await self._session.execute(stmt)).scalar_one_or_none()

    async def restore_for_org(self, organization_id: UUID, document_id: UUID) -> DocumentDTO | None:
        row = await self._trashed(organization_id, document_id)
        if row is None:
            return None
        row.deleted_at = None
        row.updated_at = datetime.now(UTC)
        await self._session.flush()
        return _to_dto(row)

    async def _links_for(self, organization_id: UUID, document_id: UUID) -> list[CalendarEvent]:
        stmt = select(CalendarEvent).where(
            CalendarEvent.document_id == document_id,
            CalendarEvent.organization_id == organization_id,
        )
        return list((await self._session.scalars(stmt)).all())

    async def list_event_links(
        self, organization_id: UUID, document_id: UUID
    ) -> list[DocumentEventLink] | None:
        if await self._trashed(organization_id, document_id) is None:
            return None
        events = await self._links_for(organization_id, document_id)
        return _event_links(events)

    async def purge_for_org(
        self,
        organization_id: UUID,
        document_id: UUID,
        decisions: list[DocumentPurgeDecision],
    ) -> bool:
        row = await self._trashed(organization_id, document_id)
        if row is None:
            return False
        events = await self._links_for(organization_id, document_id)
        chosen = resolve_purge_decisions(_event_links(events), decisions)
        now = datetime.now(UTC)
        for event in events:
            action = chosen.get(event.id)
            if action == "delete":
                event.deleted_at = now
            event.document_id = None
            event.updated_at = now
        dest = self._file_in_storage(row.storage_path)
        await self._session.flush()
        await self._session.delete(row)
        await self._session.flush()
        if dest is not None and dest.is_file():
            dest.unlink()
        return True
