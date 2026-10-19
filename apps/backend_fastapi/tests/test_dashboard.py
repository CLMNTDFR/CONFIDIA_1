import asyncio
from datetime import date, datetime, time, timedelta
from zoneinfo import ZoneInfo

from fastapi.testclient import TestClient
from jose import jwt

from api.deps import get_calendar_service, get_identity_service
from api.main import app
from application.dto.calendar_dto import CalendarEventDTO, EventType, WeekCalendarScope
from application.services.calendar_service import CalendarService
from application.services.dashboard_service import DashboardService
from application.services.identity_service import IdentityService
from tests.fakes.calendar_repository import InMemoryCalendarRepository
from tests.fakes.identity_repository import InMemoryIdentityRepository

CLAIMS = {
    "sub": "test-user",
    "email": "amandine@demo.local",
    "preferred_username": "amandine",
    "given_name": "Amandine",
    "realm_access": {"roles": ["USER"]},
    "iss": "http://localhost:8080/realms/confidia",
    "azp": "confidia-backend",
}


def _auth_headers():
    token = jwt.encode(CLAIMS, key="test", algorithm="HS256")
    return {"Authorization": f"Bearer {token}"}


def _harness():
    identity = IdentityService(InMemoryIdentityRepository())
    calendar = CalendarService(InMemoryCalendarRepository())
    app.dependency_overrides[get_identity_service] = lambda: identity
    app.dependency_overrides[get_calendar_service] = lambda: calendar
    client = TestClient(app)
    return client, calendar


def test_week_overview_endpoint():
    client, _calendar = _harness()
    try:
        response = client.get("/api/v1/dashboard/week-overview", headers=_auth_headers())
        assert response.status_code == 200, response.text
        data = response.json()
        assert len(data["days"]) == 7
        assert data["days"][0]["day_label"] == "LUNDI"
        assert data["days"][0]["workload_level"] == "calm"
        assert data["days"][0]["total_appointments"] == 0
    finally:
        app.dependency_overrides.clear()


def test_week_overview_scope_filter():
    client, _calendar = _harness()
    try:
        response = client.get(
            "/api/v1/dashboard/week-overview",
            params=[("scopes", "personal")],
            headers=_auth_headers(),
        )
        assert response.status_code == 200
        data = response.json()
        assert data["active_scopes"] == ["personal"]
        assert data["days"][0]["meeting_count"] == 0
    finally:
        app.dependency_overrides.clear()


def test_serenity_briefing_endpoint():
    client, _calendar = _harness()
    try:
        response = client.get("/api/v1/dashboard/serenity-briefing", headers=_auth_headers())
        assert response.status_code == 200, response.text
        data = response.json()
        assert data["score"] == 100
        assert data["level"] == "excellent"
        assert data["greeting"].startswith("Bonjour")
        assert len(data["metrics"]) >= 3
        assert data["factors"] == []
        assert any(action["route"] == "/documents" for action in data["actions"])
        assert len(data["score_history"]) == 1
        assert data["score_history"][0]["score"] == data["score"]
        assert "EDF" not in data["summary"]
    finally:
        app.dependency_overrides.clear()


def test_day_briefing_endpoint():
    client, _calendar = _harness()
    try:
        response = client.get("/api/v1/dashboard/day-briefing", headers=_auth_headers())
        assert response.status_code == 200, response.text
        data = response.json()
        assert data["greeting"].startswith("Bonjour")
        assert isinstance(data["summary"], str) and len(data["summary"]) > 20
        assert data["urgent_payments"] == []
        assert data["new_documents"] == []
        assert data["todays_appointments"] == []
        assert data["current_score"] == 100
        assert data["projected_score"] == data["current_score"]
        assert data["value_message"] is None
        assert any(item["route"] == "/documents" for item in data["priorities"])
    finally:
        app.dependency_overrides.clear()


def test_day_briefing_requires_auth():
    response = TestClient(app).get("/api/v1/dashboard/day-briefing")
    assert response.status_code in {401, 403}


def test_week_overview_counts_created_event():
    client, _calendar = _harness()
    try:
        zone = ZoneInfo("Europe/Paris")
        today = datetime.now(zone).date()
        week_start = today - timedelta(days=today.weekday())
        start = datetime.combine(week_start, time(10, 0), tzinfo=zone)
        created = client.post(
            "/api/v1/calendar/events",
            headers=_auth_headers(),
            json={
                "title": "Réunion famille",
                "start": start.isoformat(),
                "end": (start + timedelta(hours=1)).isoformat(),
                "event_type": "meeting",
                "calendar_scope": "family",
            },
        )
        assert created.status_code == 201, created.text
        response = client.get("/api/v1/dashboard/week-overview", headers=_auth_headers())
        assert response.status_code == 200, response.text
        monday = response.json()["days"][0]
        assert monday["total_appointments"] == 1
        assert monday["meeting_count"] == 1
        assert monday["workload_level"] in {"calm", "medium", "busy"}
    finally:
        app.dependency_overrides.clear()


def test_week_overview_keeps_paris_civil_day():
    start = datetime.fromisoformat("2026-10-18T00:30:00+02:00")
    event = CalendarEventDTO(
        id="1",
        title="Nuit",
        start=start,
        end=start + timedelta(hours=1),
        event_type=EventType.MEETING,
        calendar_scope=WeekCalendarScope.FAMILY,
    )
    overview = asyncio.run(
        DashboardService().get_week_overview(
            [event],
            zone="Europe/Paris",
            reference=date(2026, 10, 18),
        )
    )
    assert overview.days[6].date == date(2026, 10, 18)
    assert overview.days[6].total_appointments == 1
    assert overview.days[5].total_appointments == 0


def test_briefing_with_event_does_not_crash():
    client, _calendar = _harness()
    try:
        start = datetime.now(ZoneInfo("Europe/Paris")).replace(microsecond=0) + timedelta(days=1)
        created = client.post(
            "/api/v1/calendar/events",
            headers=_auth_headers(),
            json={
                "title": "Réunion",
                "start": start.isoformat(),
                "end": (start + timedelta(hours=1)).isoformat(),
                "event_type": "meeting",
                "calendar_scope": "family",
            },
        )
        assert created.status_code == 201, created.text
        serenity = client.get("/api/v1/dashboard/serenity-briefing", headers=_auth_headers())
        assert serenity.status_code == 200, serenity.text
        day = client.get("/api/v1/dashboard/day-briefing", headers=_auth_headers())
        assert day.status_code == 200, day.text
        assert day.json()["todays_appointments"] == []
    finally:
        app.dependency_overrides.clear()
