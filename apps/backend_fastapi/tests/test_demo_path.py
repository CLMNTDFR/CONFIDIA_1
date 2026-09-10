"""Holberton demo path: health, register, dashboard, upload, detail, file, logout."""

from __future__ import annotations

from io import BytesIO

import pytest
from fastapi.testclient import TestClient

from api.deps import get_calendar_service, get_identity_service, get_workspace_document_service
from api.main import app
from application.services.calendar_service import CalendarService
from application.services.identity_service import IdentityService
from application.services.workspace_document_service import WorkspaceDocumentService
from tests.fakes.calendar_repository import InMemoryCalendarRepository
from tests.fakes.document_repository import InMemoryDocumentRepository
from tests.fakes.identity_repository import InMemoryIdentityRepository
from tests.fakes.keycloak import FakeKeycloakAsyncClient

REGISTER = {
    "email": "demo-path@confidia.local",
    "email_confirm": "demo-path@confidia.local",
    "username": "demopath",
    "first_name": "Demo",
    "last_name": "Path",
    "password": "SolidPassw0rd!",
    "password_confirm": "SolidPassw0rd!",
}


@pytest.fixture
def demo_path_client(monkeypatch: pytest.MonkeyPatch):
    FakeKeycloakAsyncClient.reset()
    identity = IdentityService(InMemoryIdentityRepository())
    documents = WorkspaceDocumentService(InMemoryDocumentRepository())
    calendar = CalendarService(InMemoryCalendarRepository())
    app.dependency_overrides[get_identity_service] = lambda: identity
    app.dependency_overrides[get_workspace_document_service] = lambda: documents
    app.dependency_overrides[get_calendar_service] = lambda: calendar
    monkeypatch.setattr(
        "infrastructure.keycloak.admin_client.httpx.AsyncClient",
        FakeKeycloakAsyncClient,
    )
    monkeypatch.setattr(
        "application.services.auth_service.httpx.AsyncClient",
        FakeKeycloakAsyncClient,
    )
    with TestClient(app) as client:
        yield client
    app.dependency_overrides.clear()
    FakeKeycloakAsyncClient.reset()


def test_holberton_demo_path(demo_path_client: TestClient):
    client = demo_path_client
    assert client.get("/health").status_code == 200

    created = client.post("/api/v1/auth/register", json=REGISTER)
    assert created.status_code == 201, created.text
    token = created.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    dashboard = client.get("/api/v1/dashboard/week-overview", headers=headers)
    assert dashboard.status_code == 200, dashboard.text
    assert len(dashboard.json()["days"]) == 7

    payload = b"%PDF-demo-path"
    uploaded = client.post(
        "/api/v1/documents/upload",
        headers=headers,
        files={"file": ("facture.pdf", BytesIO(payload), "application/pdf")},
        data={"title": "Facture EDF"},
    )
    assert uploaded.status_code == 201, uploaded.text
    doc_id = uploaded.json()["id"]
    assert uploaded.json()["title"] == "Facture EDF"

    listed = client.get("/api/v1/documents/", headers=headers)
    assert listed.status_code == 200
    assert listed.json()["total"] == 1

    detail = client.get(f"/api/v1/documents/{doc_id}", headers=headers)
    assert detail.status_code == 200
    assert detail.json()["title"] == "Facture EDF"

    downloaded = client.get(f"/api/v1/documents/{doc_id}/file", headers=headers)
    assert downloaded.status_code == 200
    assert downloaded.content == payload

    logout = client.post(
        "/api/v1/auth/logout",
        json={"refresh_token": created.json()["refresh_token"]},
    )
    assert logout.status_code == 200
    still_there = client.get(f"/api/v1/documents/{doc_id}", headers=headers)
    assert still_there.status_code == 200
