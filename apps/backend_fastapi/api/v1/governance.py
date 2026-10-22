from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException

from api.deps import get_governance_service
from application.dto.governance_dto import (
    InvitationCreateDTO,
    MemberUpdateDTO,
    PersonListDTO,
    WorkspaceDTO,
    WorkspaceUpdateDTO,
)
from application.services.governance_service import GovernanceService
from core.security import TokenPayload, decode_token
from domain.governance import GovernanceError

router = APIRouter()


async def _call(result):
    try:
        return await result
    except GovernanceError as exc:
        raise HTTPException(status_code=exc.status_code, detail=exc.detail) from exc


@router.get("/workspace", response_model=WorkspaceDTO)
async def get_workspace(
    token: TokenPayload = Depends(decode_token),
    governance: GovernanceService = Depends(get_governance_service),
):
    return await _call(governance.workspace(token.raw))


@router.patch("/workspace", response_model=WorkspaceDTO)
async def update_workspace(
    data: WorkspaceUpdateDTO,
    token: TokenPayload = Depends(decode_token),
    governance: GovernanceService = Depends(get_governance_service),
):
    return await _call(governance.update_workspace(token.raw, data.model_dump(exclude_unset=True)))


@router.patch("/members/{membership_id}", response_model=WorkspaceDTO)
async def update_member(
    membership_id: UUID,
    data: MemberUpdateDTO,
    token: TokenPayload = Depends(decode_token),
    governance: GovernanceService = Depends(get_governance_service),
):
    fields = data.model_dump(exclude_unset=True)
    return await _call(governance.update_member(token.raw, membership_id, fields))


@router.delete("/members/{membership_id}", response_model=WorkspaceDTO)
async def remove_member(
    membership_id: UUID,
    token: TokenPayload = Depends(decode_token),
    governance: GovernanceService = Depends(get_governance_service),
):
    return await _call(governance.remove_member(token.raw, membership_id))


@router.get("/people", response_model=PersonListDTO)
async def search_people(
    q: str = "",
    token: TokenPayload = Depends(decode_token),
    governance: GovernanceService = Depends(get_governance_service),
):
    return await _call(governance.search(token.raw, q))


@router.post("/invitations", response_model=WorkspaceDTO)
async def create_invitation(
    data: InvitationCreateDTO,
    token: TokenPayload = Depends(decode_token),
    governance: GovernanceService = Depends(get_governance_service),
):
    return await _call(governance.invite(token.raw, data.invitee_id))


@router.post("/invitations/{invitation_id}/accept", response_model=WorkspaceDTO)
async def accept_invitation(
    invitation_id: UUID,
    token: TokenPayload = Depends(decode_token),
    governance: GovernanceService = Depends(get_governance_service),
):
    return await _call(governance.accept(token.raw, invitation_id))


@router.post("/invitations/{invitation_id}/refuse", response_model=WorkspaceDTO)
async def refuse_invitation(
    invitation_id: UUID,
    token: TokenPayload = Depends(decode_token),
    governance: GovernanceService = Depends(get_governance_service),
):
    return await _call(governance.refuse(token.raw, invitation_id))


@router.post("/invitations/{invitation_id}/cancel", response_model=WorkspaceDTO)
async def cancel_invitation(
    invitation_id: UUID,
    token: TokenPayload = Depends(decode_token),
    governance: GovernanceService = Depends(get_governance_service),
):
    return await _call(governance.cancel(token.raw, invitation_id))
