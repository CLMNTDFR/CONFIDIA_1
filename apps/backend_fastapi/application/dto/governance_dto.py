from uuid import UUID

from pydantic import BaseModel, Field


class MemberDTO(BaseModel):
    id: UUID
    user_id: str
    name: str
    email: str
    role: str
    parent_id: UUID | None = None
    permissions: list[str] = Field(default_factory=list)
    link_type: str = "reportsTo"


class InvitationDTO(BaseModel):
    id: UUID
    organization_id: UUID
    organization_name: str
    inviter_id: str
    inviter_name: str
    invitee_id: str
    invitee_name: str
    invitee_email: str
    status: str


class WorkspaceDTO(BaseModel):
    id: UUID
    name: str
    kind: str
    icon: str
    level_labels: dict[str, str] = Field(default_factory=dict)
    my_role: str
    can_manage: bool
    members: list[MemberDTO]
    sent_invitations: list[InvitationDTO]
    received_invitations: list[InvitationDTO]


class WorkspaceUpdateDTO(BaseModel):
    name: str | None = None
    icon: str | None = None
    kind: str | None = None
    level_labels: dict[str, str] | None = None


class MemberUpdateDTO(BaseModel):
    parent_id: UUID | None = None
    role: str | None = None
    permissions: list[str] | None = None
    link_type: str | None = None


class InvitationCreateDTO(BaseModel):
    invitee_id: str


class PersonDTO(BaseModel):
    id: str
    name: str
    email: str


class PersonListDTO(BaseModel):
    items: list[PersonDTO]
