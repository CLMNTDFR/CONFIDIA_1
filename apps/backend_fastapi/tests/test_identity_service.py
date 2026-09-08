import pytest

from application.services.identity_service import (
    IdentityService,
    email_from_claims,
    names_from_claims,
)
from tests.fakes.identity_repository import InMemoryIdentityRepository

CLAIMS = {
    "sub": "kc-user-1",
    "email": "user@confidia.local",
    "given_name": "Jean",
    "family_name": "Dupont",
    "preferred_username": "user",
}


@pytest.mark.asyncio
async def test_ensure_from_token_creates_user_and_famille_org():
    repo = InMemoryIdentityRepository()
    service = IdentityService(repo)

    first = await service.ensure_from_token_claims(CLAIMS)
    second = await service.ensure_from_token_claims(CLAIMS)

    assert first.id == "kc-user-1"
    assert first.email == "user@confidia.local"
    assert first.first_name == "Jean"
    assert first.organization_name == "Famille"
    assert first.membership_role == "owner"
    assert second.organization_id == first.organization_id
    assert len(repo.rows) == 1


@pytest.mark.asyncio
async def test_ensure_keeps_confidia_names_after_first_login():
    repo = InMemoryIdentityRepository()
    service = IdentityService(repo)
    await service.ensure_from_token_claims(CLAIMS)
    await service.update_profile("kc-user-1", first_name="Camille")

    again = await service.ensure_from_token_claims({**CLAIMS, "given_name": "Jeanne"})
    assert again.first_name == "Camille"
    assert again.organization_name == "Famille"


def test_names_and_email_fallbacks():
    assert names_from_claims({"name": "Ada Lovelace"}) == ("Ada", "Lovelace")
    assert email_from_claims({"preferred_username": "ada"}) == "ada@confidia.local"


@pytest.mark.asyncio
async def test_ensure_rejects_token_without_sub():
    service = IdentityService(InMemoryIdentityRepository())
    with pytest.raises(ValueError, match="missing sub"):
        await service.ensure_from_token_claims({"email": "nobody@confidia.local"})
