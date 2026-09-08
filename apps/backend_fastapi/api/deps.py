from pathlib import Path

from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

from application.services.calendar_service import CalendarService
from application.services.identity_service import IdentityService
from application.services.workspace_document_service import WorkspaceDocumentService
from core.config import get_settings
from infrastructure.db.postgres_calendar_repository import PostgresCalendarRepository
from infrastructure.db.postgres_document_repository import PostgresDocumentRepository
from infrastructure.db.postgres_identity_repository import PostgresIdentityRepository
from infrastructure.db.session import get_db


def get_identity_service(session: AsyncSession = Depends(get_db)) -> IdentityService:
    return IdentityService(PostgresIdentityRepository(session))


def get_workspace_document_service(
    session: AsyncSession = Depends(get_db),
) -> WorkspaceDocumentService:
    storage = Path(get_settings().documents_storage_dir)
    return WorkspaceDocumentService(PostgresDocumentRepository(session, storage))


def get_calendar_service(session: AsyncSession = Depends(get_db)) -> CalendarService:
    return CalendarService(PostgresCalendarRepository(session))
