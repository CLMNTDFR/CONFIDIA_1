from fastapi.testclient import TestClient
from jose import jwt

from api.main import app

client = TestClient(app)


def _auth_headers():
    token = jwt.encode(
        {
            "sub": "test-user",
            "email": "amandine@demo.local",
            "preferred_username": "amandine",
            "realm_access": {"roles": ["USER"]},
        },
        key="test",
        algorithm="HS256",
    )
    return {"Authorization": f"Bearer {token}"}


def test_week_overview_endpoint():
    response = client.get("/api/v1/dashboard/week-overview", headers=_auth_headers())
    assert response.status_code == 200
    data = response.json()
    assert len(data["days"]) == 7
    assert data["days"][0]["day_label"] == "LUNDI"
    assert data["days"][0]["workload_level"] in {"calm", "medium", "busy"}
    assert data["days"][0]["total_appointments"] >= 0


def test_week_overview_scope_filter():
    response = client.get(
        "/api/v1/dashboard/week-overview",
        params=[("scopes", "personal")],
        headers=_auth_headers(),
    )
    assert response.status_code == 200
    data = response.json()
    assert data["active_scopes"] == ["personal"]
    monday = data["days"][0]
    assert monday["meeting_count"] == 0


def test_serenity_briefing_endpoint():
    response = client.get("/api/v1/dashboard/serenity-briefing", headers=_auth_headers())
    assert response.status_code == 200
    data = response.json()
    assert 0 <= data["score"] <= 100
    assert data["level"] in {"excellent", "good", "moderate", "attention"}
    assert data["greeting"].startswith("Bonjour")
    assert len(data["metrics"]) >= 3
    assert len(data["factors"]) >= 1
    assert len(data["actions"]) >= 1
    assert data["actions"][0]["route"].startswith("/")
    assert len(data["score_history"]) == 14
    assert data["score_history"][-1]["score"] == data["score"]


def test_day_briefing_endpoint():
    response = client.get("/api/v1/dashboard/day-briefing", headers=_auth_headers())
    assert response.status_code == 200
    data = response.json()
    assert data["greeting"].startswith("Bonjour")
    assert isinstance(data["summary"], str) and len(data["summary"]) > 20
    assert 1 <= len(data["priorities"]) <= 3
    assert data["priorities"][0]["route"].startswith("/")
    assert len(data["urgent_payments"]) >= 1
    assert data["urgent_payments"][0]["creditor"]
    assert data["urgent_payments"][0]["amount"] > 0
    assert isinstance(data["todays_appointments"], list)
    assert len(data["new_documents"]) >= 1
    assert 0 <= data["current_score"] <= 100
    assert 0 <= data["projected_score"] <= 100
    assert data["projected_score"] >= data["current_score"]
    assert data["value_message"] is None or "pénalités" in data["value_message"]


def test_day_briefing_requires_auth():
    response = client.get("/api/v1/dashboard/day-briefing")
    assert response.status_code in {401, 403}
