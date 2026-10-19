"""Governance workspace, chart and invitations without Postgres."""

from __future__ import annotations

import pytest
from fastapi.testclient import TestClient
from jose import jwt

from api.deps import get_governance_service, get_identity_service
from api.main import app
from application.services.governance_service import GovernanceService
from application.services.identity_service import IdentityService
from tests.fakes.governance_repository import InMemoryGovernanceRepository
from tests.fakes.identity_repository import InMemoryIdentityRepository


def _headers(sub: str, email: str, first: str, last: str) -> dict[str, str]:
    token = jwt.encode(
        {
            "sub": sub,
            "email": email,
            "given_name": first,
            "family_name": last,
            "realm_access": {"roles": ["USER"]},
            "iss": "http://localhost:8080/realms/confidia",
            "azp": "confidia-backend",
        },
        key="test",
        algorithm="HS256",
    )
    return {"Authorization": f"Bearer {token}"}


ALICE = _headers("kc-alice", "alice@confidia.local", "Alice", "Martin")
BOB = _headers("kc-bob", "bob@confidia.local", "Bob", "Bernard")


@pytest.fixture
def gov():
    identity_repo = InMemoryIdentityRepository()
    gov_repo = InMemoryGovernanceRepository()
    identity = IdentityService(identity_repo)
    app.dependency_overrides[get_identity_service] = lambda: identity
    app.dependency_overrides[get_governance_service] = lambda: GovernanceService(gov_repo, identity)
    with TestClient(app) as client:
        yield client, gov_repo, identity_repo
    app.dependency_overrides.clear()


def test_first_workspace_is_famille_with_the_owner(gov):
    client, _, _ = gov
    response = client.get("/api/v1/governance/workspace", headers=ALICE)
    assert response.status_code == 200
    body = response.json()
    assert body["name"] == "Famille"
    assert body["kind"] == "family"
    assert body["icon"] == "family"
    assert body["my_role"] == "owner"
    assert body["can_manage"] is True
    assert len(body["members"]) == 1
    assert body["members"][0]["name"] == "Alice Martin"
    assert "members.manage" in body["members"][0]["permissions"]
    assert body["sent_invitations"] == []
    assert body["received_invitations"] == []


def test_owner_renames_icon_and_profile_stays_aligned(gov):
    client, _, identity_repo = gov
    updated = client.patch(
        "/api/v1/governance/workspace",
        headers=ALICE,
        json={"name": "Maison Martin", "icon": "home", "kind": "family"},
    )
    assert updated.status_code == 200
    assert updated.json()["name"] == "Maison Martin"
    assert updated.json()["icon"] == "home"
    profile = client.get("/api/v1/users/me", headers=ALICE)
    assert profile.json()["organization"] == "Maison Martin"
    assert identity_repo.rows["kc-alice"].stored.organization_name == "Maison Martin"

    unknown = client.patch(
        "/api/v1/governance/workspace",
        headers=ALICE,
        json={"icon": "not-an-icon"},
    )
    assert unknown.status_code == 400
    assert unknown.json()["detail"] == "Icône inconnue"


def test_search_invite_accept_and_rights(gov):
    client, _, _ = gov
    client.get("/api/v1/governance/workspace", headers=ALICE)
    client.get("/api/v1/governance/workspace", headers=BOB)

    empty = client.get("/api/v1/governance/people", headers=ALICE, params={"q": "a"})
    assert empty.json()["items"] == []
    found = client.get("/api/v1/governance/people", headers=ALICE, params={"q": "bob"})
    assert found.status_code == 200
    assert [row["id"] for row in found.json()["items"]] == ["kc-bob"]

    self_invite = client.post(
        "/api/v1/governance/invitations",
        headers=ALICE,
        json={"invitee_id": "kc-alice"},
    )
    assert self_invite.status_code == 400

    invited = client.post(
        "/api/v1/governance/invitations",
        headers=ALICE,
        json={"invitee_id": "kc-bob"},
    )
    assert invited.status_code == 200
    sent = invited.json()["sent_invitations"]
    assert sent[0]["status"] == "pending"
    assert sent[0]["invitee_email"] == "bob@confidia.local"
    invitation_id = sent[0]["id"]

    again = client.post(
        "/api/v1/governance/invitations",
        headers=ALICE,
        json={"invitee_id": "kc-bob"},
    )
    assert again.status_code == 409

    bob = client.get("/api/v1/governance/workspace", headers=BOB)
    received = bob.json()["received_invitations"]
    assert received[0]["id"] == invitation_id
    assert received[0]["organization_name"] == "Famille"
    assert received[0]["status"] == "pending"

    accepted = client.post(
        f"/api/v1/governance/invitations/{invitation_id}/accept",
        headers=BOB,
    )
    assert accepted.status_code == 200
    assert accepted.json()["received_invitations"][0]["status"] == "accepted"
    assert accepted.json()["name"] == "Famille"
    assert len(accepted.json()["members"]) == 1

    alice = client.get("/api/v1/governance/workspace", headers=ALICE)
    members = {row["user_id"]: row for row in alice.json()["members"]}
    assert set(members) == {"kc-alice", "kc-bob"}
    assert members["kc-bob"]["role"] == "member"
    assert members["kc-bob"]["parent_id"] == members["kc-alice"]["id"]
    assert members["kc-bob"]["permissions"] == ["calendar.read", "documents.read"]

    cycle = client.patch(
        f"/api/v1/governance/members/{members['kc-alice']['id']}",
        headers=ALICE,
        json={"parent_id": members["kc-bob"]["id"]},
    )
    assert cycle.status_code == 400

    saved = client.patch(
        f"/api/v1/governance/members/{members['kc-bob']['id']}",
        headers=ALICE,
        json={"permissions": ["calendar.read", "documents.read", "documents.medical", "nope"]},
    )
    assert saved.status_code == 200
    bob_row = next(row for row in saved.json()["members"] if row["user_id"] == "kc-bob")
    assert bob_row["permissions"] == ["calendar.read", "documents.read", "documents.medical"]

    rooted = client.patch(
        f"/api/v1/governance/members/{members['kc-bob']['id']}",
        headers=ALICE,
        json={"parent_id": None, "link_type": "dottedLine"},
    )
    assert rooted.status_code == 200
    bob_row = next(row for row in rooted.json()["members"] if row["user_id"] == "kc-bob")
    assert bob_row["parent_id"] is None
    assert bob_row["link_type"] == "dottedLine"

    locked = client.patch(
        f"/api/v1/governance/members/{members['kc-alice']['id']}",
        headers=ALICE,
        json={"role": "member"},
    )
    assert locked.status_code == 400


def test_refuse_then_invite_again_and_cancel(gov):
    client, _, _ = gov
    client.get("/api/v1/governance/workspace", headers=ALICE)
    client.get("/api/v1/governance/workspace", headers=BOB)
    invited = client.post(
        "/api/v1/governance/invitations",
        headers=ALICE,
        json={"invitee_id": "kc-bob"},
    )
    invitation_id = invited.json()["sent_invitations"][0]["id"]
    refused = client.post(
        f"/api/v1/governance/invitations/{invitation_id}/refuse",
        headers=BOB,
    )
    assert refused.status_code == 200
    assert refused.json()["received_invitations"][0]["status"] == "refused"

    reopened = client.post(
        "/api/v1/governance/invitations",
        headers=ALICE,
        json={"invitee_id": "kc-bob"},
    )
    assert reopened.status_code == 200
    assert reopened.json()["sent_invitations"][0]["status"] == "pending"
    assert reopened.json()["sent_invitations"][0]["id"] == invitation_id

    cancelled = client.post(
        f"/api/v1/governance/invitations/{invitation_id}/cancel",
        headers=ALICE,
    )
    assert cancelled.status_code == 200
    assert cancelled.json()["sent_invitations"][0]["status"] == "cancelled"
    bob = client.get("/api/v1/governance/workspace", headers=BOB)
    assert bob.json()["received_invitations"] == []


def test_member_cannot_invite_and_owner_cannot_be_removed(gov):
    client, repo, _ = gov
    client.get("/api/v1/governance/workspace", headers=ALICE)
    repo.members[0].role = "member"
    denied = client.post(
        "/api/v1/governance/invitations",
        headers=ALICE,
        json={"invitee_id": "kc-bob"},
    )
    assert denied.status_code == 403

    repo.members[0].role = "owner"
    client.get("/api/v1/governance/workspace", headers=BOB)
    invited = client.post(
        "/api/v1/governance/invitations",
        headers=ALICE,
        json={"invitee_id": "kc-bob"},
    )
    invitation_id = invited.json()["sent_invitations"][0]["id"]
    client.post(f"/api/v1/governance/invitations/{invitation_id}/accept", headers=BOB)
    alice = client.get("/api/v1/governance/workspace", headers=ALICE)
    owner_id = next(row["id"] for row in alice.json()["members"] if row["role"] == "owner")
    bob_id = next(row["id"] for row in alice.json()["members"] if row["role"] == "member")
    kept = client.delete(f"/api/v1/governance/members/{owner_id}", headers=ALICE)
    assert kept.status_code == 400
    removed = client.delete(f"/api/v1/governance/members/{bob_id}", headers=ALICE)
    assert removed.status_code == 200
    assert [row["user_id"] for row in removed.json()["members"]] == ["kc-alice"]


@pytest.mark.integration
async def test_postgres_chart_and_invitation_round_trip():
    from uuid import uuid4

    from sqlalchemy import text
    from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

    from application.services.governance_service import GovernanceService
    from application.services.identity_service import IdentityService
    from core.config import get_settings
    from infrastructure.db.postgres_governance_repository import PostgresGovernanceRepository
    from infrastructure.db.postgres_identity_repository import PostgresIdentityRepository

    engine = create_async_engine(get_settings().database_url, pool_pre_ping=True)
    try:
        async with engine.connect() as conn:
            await conn.execute(text("SELECT 1"))
            present = await conn.scalar(text("SELECT to_regclass('public.invitations')"))
            if present is None:
                pytest.skip("invitation table missing; run alembic upgrade head")
    except Exception:
        await engine.dispose()
        pytest.skip("PostgreSQL not reachable")

    factory = async_sessionmaker(engine, expire_on_commit=False, class_=AsyncSession)
    stamp = uuid4().hex[:10]
    alice = {
        "sub": f"gov-a-{stamp}",
        "email": f"alice-{stamp}@confidia.local",
        "given_name": "Alice",
        "family_name": f"Zz{stamp}",
    }
    bob = {
        "sub": f"gov-b-{stamp}",
        "email": f"bob-{stamp}@confidia.local",
        "given_name": "Bob",
        "family_name": f"Zz{stamp}",
    }
    async with factory() as session:
        try:
            service = GovernanceService(
                PostgresGovernanceRepository(session),
                IdentityService(PostgresIdentityRepository(session)),
            )
            opened = await service.workspace(alice)
            assert opened.name == "Famille"
            assert opened.icon == "family"
            assert opened.members[0].role == "owner"
            await service.workspace(bob)
            found = await service.search(alice, f"Zz{stamp}")
            assert {row.id for row in found.items} == {bob["sub"]}
            invited = await service.invite(alice, bob["sub"])
            invitation_id = invited.sent_invitations[0].id
            accepted = await service.accept(bob, invitation_id)
            assert accepted.received_invitations[0].status == "accepted"
            again = await service.workspace(alice)
            guest = next(row for row in again.members if row.user_id == bob["sub"])
            owner = next(row for row in again.members if row.role == "owner")
            assert guest.parent_id == owner.id
            renamed = await service.update_workspace(
                alice, {"name": f"Maison {stamp}", "icon": "home", "kind": "club"}
            )
            assert renamed.name == f"Maison {stamp}"
            assert renamed.icon == "home"
            assert renamed.kind == "club"
        finally:
            await session.rollback()
    await engine.dispose()
