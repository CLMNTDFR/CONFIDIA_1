from fastapi.testclient import TestClient

from api.main import app

client = TestClient(app)


def _auth_headers():
    login = client.post("/api/v1/auth/login", json={"username": "user", "password": "user"})
    assert login.status_code == 200
    token = login.json()["access_token"]
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
