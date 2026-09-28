"""Postgres calendar CRUD. Skipped when the database or MVP schema is missing."""

from __future__ import annotations

from datetime import UTC, datetime, timedelta
from uuid import UUID, uuid4

import pytest
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from application.dto.calendar_dto import CalendarEventCreateDTO, EventType
from application.services.calendar_service import CalendarService
from application.services.identity_service import IdentityService
from core.config import get_settings
from infrastructure.db.postgres_calendar_repository import PostgresCalendarRepository
from infrastructure.db.postgres_identity_repository import PostgresIdentityRepository

pytestmark = pytest.mark.integration


@pytest.fixture
async def db_session():
    engine = create_async_engine(get_settings().database_url, pool_pre_ping=True)
    try:
        async with engine.connect() as conn:
            await conn.execute(text("SELECT 1"))
            present = await conn.scalar(text("SELECT to_regclass('public.calendar_events')"))
            if present is None:
                pytest.skip("MVP schema not applied; run alembic upgrade head")
    except Exception:
        await engine.dispose()
        pytest.skip("PostgreSQL not reachable")

    factory = async_sessionmaker(engine, expire_on_commit=False, class_=AsyncSession)
    async with factory() as session:
        try:
            yield session
        finally:
            await session.rollback()
    await engine.dispose()


async def test_postgres_calendar_create_list_reload(db_session: AsyncSession):
    identity = IdentityService(PostgresIdentityRepository(db_session))
    user_id = f"pytest-{uuid4()}"
    stored = await identity.ensure_from_token_claims(
        {
            "sub": user_id,
            "email": f"{user_id}@confidia.test",
            "given_name": "Cal",
            "family_name": "Test",
        }
    )
    assert stored.organization_id is not None
    calendar = CalendarService(PostgresCalendarRepository(db_session))
    empty = await calendar.list_events(stored.organization_id)
    assert empty.total == 0

    start = datetime.now(UTC).replace(microsecond=0) + timedelta(days=2)
    created = await calendar.create_event(
        stored.organization_id,
        stored.id,
        CalendarEventCreateDTO(
            title="  RDV orthodontiste  ",
            start=start,
            end=start + timedelta(hours=1),
            event_type=EventType.APPOINTMENT,
            location="Cabinet",
        ),
    )
    assert created.title == "RDV orthodontiste"
    assert created.source == "confidia"
    assert created.calendar_scope.value == "family"

    listed = await calendar.list_events(stored.organization_id)
    assert listed.total == 1
    assert listed.items[0].id == created.id

    fetched = await calendar.get_event(stored.organization_id, UUID(created.id))
    assert fetched is not None
    assert fetched.title == "RDV orthodontiste"
