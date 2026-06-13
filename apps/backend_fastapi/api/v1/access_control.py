from fastapi import APIRouter, Depends, HTTPException, Query

from application.dto.access_control_dto import (
    MemberDTO,
    MemberUpdateDTO,
    OrganizationDTO,
    OrganizationUpdateDTO,
    PermissionDTO,
    PlanningAnalyzeDTO,
    PlanningProposalDTO,
    PlanningRefineDTO,
    RoleTemplateDTO,
    ScenarioDTO,
    SharingRequestCreateDTO,
    SharingRequestDTO,
    SharingRespondDTO,
)
from application.services.access_control_service import AccessControlService
from core.security import Role, TokenPayload, decode_token, require_roles

router = APIRouter()
_service = AccessControlService()


@router.get("/scenarios", response_model=list[ScenarioDTO])
async def list_scenarios(token: TokenPayload = Depends(decode_token)):
    return _service.list_scenarios()


@router.get("/permissions", response_model=list[PermissionDTO])
async def list_permissions(token: TokenPayload = Depends(decode_token)):
    return _service.list_permissions()


@router.get("/roles", response_model=list[RoleTemplateDTO])
async def list_roles(token: TokenPayload = Depends(decode_token)):
    return _service.list_roles()


@router.get("/organization", response_model=OrganizationDTO)
async def get_organization(
    scenario: str = Query(default="family"),
    token: TokenPayload = Depends(decode_token),
):
    return _service.get_organization(scenario)


@router.put("/organization", response_model=OrganizationDTO)
async def update_organization(
    data: OrganizationUpdateDTO,
    token: TokenPayload = Depends(decode_token),
):
    return _service.update_organization(data)


@router.get("/members", response_model=list[MemberDTO])
async def list_members(
    scenario: str = Query(default="family"),
    token: TokenPayload = Depends(decode_token),
):
    return _service.list_members(scenario)


@router.patch("/members/{member_id}", response_model=MemberDTO)
async def update_member(
    member_id: str,
    data: MemberUpdateDTO,
    scenario: str = Query(default="family"),
    token: TokenPayload = Depends(decode_token),
):
    try:
        return _service.update_member(member_id, data, scenario)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc


@router.get("/sharing-requests", response_model=list[SharingRequestDTO])
async def list_sharing_requests(token: TokenPayload = Depends(decode_token)):
    return _service.list_sharing_requests()


@router.post("/sharing-requests", response_model=SharingRequestDTO)
async def create_sharing_request(
    data: SharingRequestCreateDTO,
    token: TokenPayload = Depends(require_roles(Role.ADMIN, Role.MANAGER)),
):
    return _service.create_sharing_request(data)


@router.post("/sharing-requests/{request_id}/respond", response_model=SharingRequestDTO)
async def respond_sharing_request(
    request_id: str,
    data: SharingRespondDTO,
    token: TokenPayload = Depends(decode_token),
):
    try:
        return _service.respond_sharing(request_id, data)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc


@router.post("/ai/planning-analyze", response_model=PlanningProposalDTO)
async def analyze_planning(
    data: PlanningAnalyzeDTO,
    token: TokenPayload = Depends(decode_token),
):
    return _service.analyze_planning(data.scenario)


@router.post("/ai/planning-refine", response_model=PlanningProposalDTO)
async def refine_planning(
    data: PlanningRefineDTO,
    token: TokenPayload = Depends(decode_token),
):
    return _service.refine_planning(data)
