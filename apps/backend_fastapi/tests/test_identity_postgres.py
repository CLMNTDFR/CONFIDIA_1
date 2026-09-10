"""Postgres identity upsert. Skipped when the database or schema is missing."""

from __future__ import annotations

from uuid import uuid4

import pytest
from sqlalchemy import func, select, text
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from application.services.identity_service import IdentityService
from core.config import get_settings
from infrastructure.db.models import Calendar, Organization
from infrastructure.db.postgres_identity_repository import PostgresIdentityRepository

pytestmark = pytest.mark.integration


@pytest.fixture
async def db_session():
    engine = create_async_engine(get_settings().database_url, pool_pre_ping=True)
    try:
        async with engine.connect() as conn:
            await conn.execute(text("SELECT 1"))
            present = await conn.scalar(text("SELECT to_regclass('public.users')"))
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


async def test_postgres_login_creates_user_org_calendar_once(db_session: AsyncSession):
    user_id = f"pytest-{uuid4()}"
    email = f"{user_id}@confidia.test"
    service = IdentityService(PostgresIdentityRepository(db_session))
    claims = {
        "sub": user_id,
        "email": email,
        "given_name": "Testa",
        "family_name": "Pytest",
    }

    first = await service.ensure_from_token_claims(claims)
    second = await service.ensure_from_token_claims({**claims, "given_name": "Testa-2"})

    assert first.id == user_id
    assert first.email == email
    assert first.organization_name == "Famille"
    assert first.membership_role == "owner"
    assert second.organization_id == first.organization_id
    assert second.first_name == "Testa"

    calendars = await db_session.scalars(
        select(Calendar).where(Calendar.organization_id == first.organization_id)
    )
    family = list(calendars)
    assert len(family) == 1
    assert family[0].slug == "family"

    org_count = await db_session.scalar(
        select(func.count()).select_from(Organization).where(
            Organization.id == first.organization_id
        )
    )
    assert org_count == 1


async def test_postgres_update_profile_renames_workspace(db_session: AsyncSession):
    user_id = f"pytest-{uuid4()}"
    service = IdentityService(PostgresIdentityRepository(db_session))
    await service.ensure_from_token_claims(
        {"sub": user_id, "email": f"{user_id}@confidia.test", "given_name": "Camille"}
    )
    updated = await service.update_profile(
        user_id,
        phone="+33 6 00 00 00 00",
        organization_name="Maison Test",
    )
    assert updated.phone == "+33 6 00 00 00 00"
    assert updated.organization_name == "Maison Test"
    reloaded = await service.get_user(user_id)
    assert reloaded is not None
    assert reloaded.organization_name == "Maison Test"


async def test_postgres_two_users_get_separate_famille_orgs(db_session: AsyncSession):
    service = IdentityService(PostgresIdentityRepository(db_session))
    a_id, b_id = f"pytest-{uuid4()}", f"pytest-{uuid4()}"
    user_a = await service.ensure_from_token_claims(
        {"sub": a_id, "email": f"{a_id}@confidia.test", "given_name": "A"}
    )
    user_b = await service.ensure_from_token_claims(
        {"sub": b_id, "email": f"{b_id}@confidia.test", "given_name": "B"}
    )
    assert user_a.organization_id != user_b.organization_id


async def test_postgres_document_upload_list_detail(db_session: AsyncSession, tmp_path):
    from application.dto.document_dto import DocumentCreateDTO
    from application.services.workspace_document_service import WorkspaceDocumentService
    from infrastructure.db.postgres_document_repository import PostgresDocumentRepository

    identity = IdentityService(PostgresIdentityRepository(db_session))
    user_id = f"pytest-{uuid4()}"
    stored = await identity.ensure_from_token_claims(
        {"sub": user_id, "email": f"{user_id}@confidia.test", "given_name": "Docs"}
    )
    assert stored.organization_id is not None
    service = WorkspaceDocumentService(PostgresDocumentRepository(db_session, tmp_path))
    created = await service.upload_document(
        organization_id=stored.organization_id,
        owner_id=stored.id,
        filename="facture.pdf",
        payload=b"%PDF-test",
        metadata=DocumentCreateDTO(title="Facture test", category="Énergie"),
    )
    listed = await service.list_documents(stored.organization_id)
    assert listed.total == 1
    from uuid import UUID

    fetched = await service.get_document(stored.organization_id, UUID(created.id))
    assert fetched is not None
    assert fetched.title == "Facture test"
    stored_file = tmp_path / str(stored.organization_id) / f"{created.id}.pdf"
    assert stored_file.read_bytes() == b"%PDF-test"
