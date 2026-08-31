from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

from application.services.identity_service import IdentityService
from infrastructure.db.postgres_identity_repository import PostgresIdentityRepository
from infrastructure.db.session import get_db


def get_identity_service(session: AsyncSession = Depends(get_db)) -> IdentityService:
    return IdentityService(PostgresIdentityRepository(session))
