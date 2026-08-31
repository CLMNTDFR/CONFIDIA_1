from application.dto.user_dto import UserProfileUpdateDTO
from application.services.identity_service import IdentityService
from application.services.user_service import UserService
from core.security import TokenPayload
from tests.fakes.identity_repository import InMemoryIdentityRepository

CLAIMS = {
    "sub": "kc-profile-1",
    "email": "user@confidia.local",
    "given_name": "Jean",
    "family_name": "Dupont",
    "preferred_username": "user",
    "realm_access": {"roles": ["USER"]},
}


def _token(**overrides: str) -> TokenPayload:
    email = overrides.get("email", CLAIMS["email"])
    sub = overrides.get("sub", CLAIMS["sub"])
    return TokenPayload(sub=sub, email=email, roles=["USER"], raw=CLAIMS)


async def test_mock_profile_when_identity_missing():
    service = UserService(identity=None)
    token = TokenPayload(sub="x", email="user@confidia.local", roles=["USER"], raw={})
    profile = await service.get_profile(token)
    assert profile.first_name == "Jean"
    assert profile.organization == "Particulier"


async def test_profile_comes_from_stored_identity():
    service = UserService(IdentityService(InMemoryIdentityRepository()))
    profile = await service.get_profile(_token())
    assert profile.id == "kc-profile-1"
    assert profile.first_name == "Jean"
    assert profile.organization == "Famille"
    assert profile.roles == ["USER"]


async def test_update_profile_persists_phone_and_org_name():
    service = UserService(IdentityService(InMemoryIdentityRepository()))
    await service.get_profile(_token())
    updated = await service.update_profile(
        _token(),
        UserProfileUpdateDTO(phone="+33 6 11 22 33 44", organization="Maison"),
    )
    assert updated.phone == "+33 6 11 22 33 44"
    assert updated.organization == "Maison"

    again = await service.get_profile(_token())
    assert again.phone == "+33 6 11 22 33 44"
    assert again.organization == "Maison"


async def test_list_users_reads_identity_repo():
    service = UserService(IdentityService(InMemoryIdentityRepository()))
    await service.get_profile(_token())
    listing = await service.list_users()
    assert listing.total == 1
    assert listing.items[0].email == "user@confidia.local"
