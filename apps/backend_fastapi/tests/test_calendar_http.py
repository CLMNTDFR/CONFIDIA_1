"""HTTP calendar: workspace-persisted CRUD, no invented events."""

from __future__ import annotations

from datetime import UTC, datetime, timedelta

import pytest
from fastapi.testclient import TestClient
from jose import jwt

from api.deps import get_calendar_service, get_identity_service
from api.main import app
from application.services.calendar_service import CalendarService
from application.services.identity_service import IdentityService
from tests.fakes.calendar_repository import InMemoryCalendarRepository
from tests.fakes.identity_repository import InMemoryIdentityRepository

CLAIMS = {
    "sub": "kc-cal-1",
    "email": "cal@confidia.local",
    "given_name": "Camille",
    "family_name": "Martin",
    "realm_access": {"roles": ["USER"]},
    "iss": "http://localhost:8080/realms/confidia",
    "azp": "confidia-backend",
}
TOKEN = jwt.encode(CLAIMS, key="test", algorithm="HS256")
HEADERS = {"Authorization": f"Bearer {TOKEN}"}


@pytest.fixture
def calendar_harness():
    identity_repo = InMemoryIdentityRepository()
    calendar_repo = InMemoryCalendarRepository()
    app.dependency_overrides[get_identity_service] = lambda: IdentityService(identity_repo)
    app.dependency_overrides[get_calendar_service] = lambda: CalendarService(calendar_repo)
    with TestClient(app) as client:
        yield client, calendar_repo
    app.dependency_overrides.clear()


def _payload(**overrides):
    start = datetime.now(UTC).replace(microsecond=0) + timedelta(days=1)
    body = {
        "title": "RDV pédiatre",
        "description": "Carnet de santé",
        "start": start.isoformat(),
        "end": (start + timedelta(hours=1)).isoformat(),
        "event_type": "appointment",
        "location": "Cabinet",
        "all_day": False,
        "calendar_scope": "family",
    }
    body.update(overrides)
    return body


def test_calendar_starts_empty_then_persists(calendar_harness):
    client, repo = calendar_harness
    empty = client.get("/api/v1/calendar/events", headers=HEADERS)
    assert empty.status_code == 200, empty.text
    assert empty.json()["total"] == 0

    created = client.post("/api/v1/calendar/events", headers=HEADERS, json=_payload())
    assert created.status_code == 201, created.text
    body = created.json()
    assert body["title"] == "RDV pédiatre"
    assert body["source"] == "confidia"
    assert body["calendar_scope"] == "family"
    event_id = body["id"]

    listed = client.get("/api/v1/calendar/events", headers=HEADERS)
    assert listed.json()["total"] == 1
    assert listed.json()["items"][0]["id"] == event_id

    patched = client.patch(
        f"/api/v1/calendar/events/{event_id}",
        headers=HEADERS,
        json={"title": "RDV dentiste"},
    )
    assert patched.status_code == 200
    assert patched.json()["title"] == "RDV dentiste"

    fetched = client.get(f"/api/v1/calendar/events/{event_id}", headers=HEADERS)
    assert fetched.json()["title"] == "RDV dentiste"

    deleted = client.delete(f"/api/v1/calendar/events/{event_id}", headers=HEADERS)
    assert deleted.status_code == 204
    assert client.get("/api/v1/calendar/events", headers=HEADERS).json()["total"] == 0
    assert client.get(f"/api/v1/calendar/events/{event_id}", headers=HEADERS).status_code == 404


def test_calendar_rejects_blank_title(calendar_harness):
    client, _repo = calendar_harness
    response = client.post(
        "/api/v1/calendar/events",
        headers=HEADERS,
        json=_payload(title="  "),
    )
    assert response.status_code == 400


def test_calendar_rejects_inverted_range(calendar_harness):
    client, _repo = calendar_harness
    start = datetime.now(UTC).replace(microsecond=0)
    response = client.post(
        "/api/v1/calendar/events",
        headers=HEADERS,
        json=_payload(
            start=(start + timedelta(hours=2)).isoformat(),
            end=start.isoformat(),
        ),
    )
    assert response.status_code == 400


def test_calendar_is_isolated_between_workspaces(calendar_harness):
    client, _repo = calendar_harness
    created = client.post("/api/v1/calendar/events", headers=HEADERS, json=_payload())
    assert created.status_code == 201, created.text
    event_id = created.json()["id"]

    other_claims = {
        "sub": "kc-cal-2",
        "email": "other@confidia.local",
        "given_name": "Other",
        "family_name": "User",
        "realm_access": {"roles": ["USER"]},
        "iss": "http://localhost:8080/realms/confidia",
        "azp": "confidia-backend",
    }
    other_headers = {
        "Authorization": f"Bearer {jwt.encode(other_claims, key='test', algorithm='HS256')}"
    }
    listed = client.get("/api/v1/calendar/events", headers=other_headers)
    assert listed.status_code == 200
    assert listed.json()["total"] == 0
    stolen = client.get(f"/api/v1/calendar/events/{event_id}", headers=other_headers)
    assert stolen.status_code == 404


def test_calendar_requires_auth():
    response = TestClient(app).get("/api/v1/calendar/events")
    assert response.status_code in {401, 403}
