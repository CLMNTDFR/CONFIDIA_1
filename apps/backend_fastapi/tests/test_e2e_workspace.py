"""One workspace journey through HTTP and PostgreSQL.

CI has Postgres and no Keycloak, so the caller is a test token, the same kind
the other HTTP tests use. The transaction is rolled back: the user, the
document row, and the event do not stay in the database.
"""

from __future__ import annotations

from datetime import UTC, datetime, time, timedelta
from uuid import uuid4
from zoneinfo import ZoneInfo

import httpx
import pytest
from jose import jwt
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine

from api.main import app
from core.config import get_settings
from infrastructure.db.session import get_db

pytestmark = pytest.mark.integration

_ZONE = ZoneInfo("Europe/Paris")
_PDF = b"%PDF-e2e"


def _headers(sub: str) -> dict[str, str]:
    token = jwt.encode(
        {
            "sub": sub,
            "email": f"{sub}@confidia.test",
            "given_name": "Eva",
            "family_name": "Test",
            "realm_access": {"roles": ["USER"]},
            "iss": "http://localhost:8080/realms/confidia",
            "azp": "confidia-backend",
        },
        key="test",
        algorithm="HS256",
    )
    return {"Authorization": f"Bearer {token}"}


async def test_e2e_document_and_event_stay_in_one_workspace(tmp_path, monkeypatch):
    monkeypatch.setenv("DOCUMENTS_STORAGE_DIR", str(tmp_path))
    get_settings.cache_clear()

    engine = create_async_engine(get_settings().database_url, pool_pre_ping=True)
    user_a = f"e2e-{uuid4()}"
    user_b = f"e2e-{uuid4()}"
    try:
        try:
            async with engine.connect() as probe:
                await probe.execute(text("SELECT 1"))
                present = await probe.scalar(text("SELECT to_regclass('public.users')"))
        except Exception:
            pytest.skip("PostgreSQL not reachable")
        if present is None:
            pytest.skip("MVP schema not applied; run alembic upgrade head")

        async with engine.connect() as connection:
            transaction = await connection.begin()
            session = AsyncSession(
                bind=connection,
                expire_on_commit=False,
                join_transaction_mode="create_savepoint",
            )

            async def _same_session():
                yield session

            app.dependency_overrides[get_db] = _same_session
            try:
                transport = httpx.ASGITransport(app=app)
                async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
                    headers_a = _headers(user_a)
                    headers_b = _headers(user_b)
                    health = await client.get("/health")
                    assert health.status_code == 200
                    assert health.json()["status"] == "healthy"

                    today = datetime.now(_ZONE).date()
                    start = datetime.combine(today, time(0, 30), tzinfo=_ZONE)
                    created = await client.post(
                        "/api/v1/calendar/events",
                        headers=headers_a,
                        json={
                            "title": "Nuit",
                            "start": start.isoformat(),
                            "end": (start + timedelta(hours=1)).isoformat(),
                            "event_type": "meeting",
                        },
                    )
                    assert created.status_code == 201, created.text
                    event_id = created.json()["id"]
                    expected = start.astimezone(UTC).strftime("%Y-%m-%dT%H:%M:%S")
                    assert created.json()["start"].startswith(expected)

                    week = await client.get("/api/v1/dashboard/week-overview", headers=headers_a)
                    assert week.status_code == 200, week.text
                    assert week.json()["days"][today.weekday()]["total_appointments"] == 1

                    uploaded = await client.post(
                        "/api/v1/documents/upload",
                        headers=headers_a,
                        files={"file": ("facture.pdf", _PDF, "application/pdf")},
                        data={"title": "Facture E2E"},
                    )
                    assert uploaded.status_code == 201, uploaded.text
                    document_id = uploaded.json()["id"]

                    listed = await client.get("/api/v1/documents/", headers=headers_a)
                    assert listed.status_code == 200
                    assert listed.json()["total"] == 1
                    downloaded = await client.get(
                        f"/api/v1/documents/{document_id}/file",
                        headers=headers_a,
                    )
                    assert downloaded.status_code == 200
                    assert downloaded.content == _PDF

                    others_docs = await client.get("/api/v1/documents/", headers=headers_b)
                    assert others_docs.status_code == 200
                    assert others_docs.json()["total"] == 0
                    stolen = await client.get(
                        f"/api/v1/documents/{document_id}",
                        headers=headers_b,
                    )
                    assert stolen.status_code == 404
                    others_events = await client.get("/api/v1/calendar/events", headers=headers_b)
                    assert others_events.status_code == 200
                    assert others_events.json()["total"] == 0
                    assert all(item["id"] != event_id for item in others_events.json()["items"])
            finally:
                app.dependency_overrides.pop(get_db, None)
                await transaction.rollback()
                await session.close()

        async with engine.connect() as check:
            left = await check.scalar(
                text("SELECT count(*) FROM users WHERE id IN (:user_a, :user_b)"),
                {"user_a": user_a, "user_b": user_b},
            )
        assert left == 0
    finally:
        await engine.dispose()
        get_settings.cache_clear()
