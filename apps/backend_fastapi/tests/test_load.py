"""Concurrent reads on the in-process API.

Login happens once, before the burst. The burst only reads health, the week
overview, the document list, and the calendar. The time limit catches a hang.
It is not a capacity target.
"""

from __future__ import annotations

import asyncio
import time

import pytest
from httpx import ASGITransport, AsyncClient

from api.deps import get_calendar_service, get_identity_service, get_workspace_document_service
from api.main import app
from application.services.calendar_service import CalendarService
from application.services.identity_service import IdentityService
from application.services.workspace_document_service import WorkspaceDocumentService
from tests.fakes.calendar_repository import InMemoryCalendarRepository
from tests.fakes.document_repository import InMemoryDocumentRepository
from tests.fakes.identity_repository import InMemoryIdentityRepository
from tests.fakes.keycloak import FakeKeycloakAsyncClient

pytestmark = pytest.mark.load

_ROUNDS = 8
_LIMIT_SECONDS = 10
_REGISTER = {
    "email": "load-path@confidia.local",
    "email_confirm": "load-path@confidia.local",
    "username": "loadpath",
    "first_name": "Load",
    "last_name": "Path",
    "password": "SolidPassw0rd!",
    "password_confirm": "SolidPassw0rd!",
}


@pytest.fixture
def load_app(monkeypatch: pytest.MonkeyPatch):
    FakeKeycloakAsyncClient.reset()
    app.dependency_overrides[get_identity_service] = lambda: IdentityService(
        InMemoryIdentityRepository()
    )
    app.dependency_overrides[get_workspace_document_service] = lambda: WorkspaceDocumentService(
        InMemoryDocumentRepository()
    )
    app.dependency_overrides[get_calendar_service] = lambda: CalendarService(
        InMemoryCalendarRepository()
    )
    monkeypatch.setattr(
        "infrastructure.keycloak.admin_client.httpx.AsyncClient",
        FakeKeycloakAsyncClient,
    )
    monkeypatch.setattr(
        "application.services.auth_service.httpx.AsyncClient",
        FakeKeycloakAsyncClient,
    )
    yield
    app.dependency_overrides.clear()
    FakeKeycloakAsyncClient.reset()


async def _read(client: AsyncClient, path: str, headers: dict[str, str] | None):
    response = await client.get(path, headers=headers)
    return path, response.status_code, response.json()


async def test_read_endpoints_stay_successful_under_concurrency(load_app):
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        registered = await client.post("/api/v1/auth/register", json=_REGISTER)
        assert registered.status_code == 201, registered.text
        logged = await client.post(
            "/api/v1/auth/login",
            json={"username": _REGISTER["username"], "password": _REGISTER["password"]},
        )
        assert logged.status_code == 200, logged.text
        headers = {"Authorization": f"Bearer {logged.json()['access_token']}"}
        warmup = await client.get("/api/v1/dashboard/week-overview", headers=headers)
        assert warmup.status_code == 200, warmup.text
        assert len(warmup.json()["days"]) == 7

        calls = [
            ("/health", None),
            ("/api/v1/dashboard/week-overview", headers),
            ("/api/v1/documents/", headers),
            ("/api/v1/calendar/events", headers),
        ] * _ROUNDS
        started = time.perf_counter()
        results = await asyncio.gather(*[_read(client, path, hdr) for path, hdr in calls])
        elapsed = time.perf_counter() - started

    assert elapsed < _LIMIT_SECONDS
    assert len(results) == len(calls)
    for path, status, body in results:
        assert status == 200, (path, body)
        if path == "/health":
            assert body["status"] == "healthy"
        elif path.endswith("week-overview"):
            assert len(body["days"]) == 7
        else:
            assert isinstance(body["total"], int)
