from enum import Enum

from pydantic import BaseModel, Field


class HierarchyLinkType(str, Enum):
    REPORTS_TO = "reportsTo"
    DOTTED_LINE = "dottedLine"
    DELEGATE = "delegate"


class PermissionDTO(BaseModel):
    id: str
    label: str
    category: str
    description: str


class RoleTemplateDTO(BaseModel):
    id: str
    label: str
    description: str
    level: int
    default_permissions: list[str] = Field(default_factory=list)


class OrgNodeDTO(BaseModel):
    id: str
    label: str
    subtitle: str | None = None
    role_id: str
    parent_id: str | None = None
    avatar_initials: str | None = None
    member_id: str | None = None
    sort_order: int = 0
    hierarchy_link_type: HierarchyLinkType = HierarchyLinkType.REPORTS_TO


class OrganizationDTO(BaseModel):
    id: str
    name: str
    scenario: str
    description: str
    nodes: list[OrgNodeDTO]


class MemberDTO(BaseModel):
    id: str
    name: str
    email: str
    role_id: str
    node_id: str
    permissions: list[str] = Field(default_factory=list)
    inherits_from_hierarchy: bool = True


class ScenarioDTO(BaseModel):
    id: str
    label: str
    description: str
    icon: str


class SharingRequestDTO(BaseModel):
    id: str
    requester_name: str
    requester_role: str
    target_name: str
    document_type: str
    permission: str
    message: str
    status: str = "pending"
    created_at: str


class SharingRequestCreateDTO(BaseModel):
    target_member_id: str
    document_type: str
    permission: str
    message: str


class SharingRespondDTO(BaseModel):
    accept: bool
    message: str | None = None


class OrganizationUpdateDTO(BaseModel):
    scenario: str
    nodes: list[OrgNodeDTO]


class OrgNodeReparentDTO(BaseModel):
    parent_id: str | None = None
    hierarchy_link_type: HierarchyLinkType | None = None


class MemberUpdateDTO(BaseModel):
    role_id: str | None = None
    permissions: list[str] | None = None
    inherits_from_hierarchy: bool | None = None


class PlanningAnalyzeDTO(BaseModel):
    scenario: str = "family"


class PlanningConflictDTO(BaseModel):
    id: str
    title: str
    severity: str
    events: list[str]


class PlanningProposalDTO(BaseModel):
    conflicts: list[PlanningConflictDTO]
    proposal: str
    alternatives: list[str] = Field(default_factory=list)


class PlanningRefineDTO(BaseModel):
    scenario: str = "family"
    prompt: str
