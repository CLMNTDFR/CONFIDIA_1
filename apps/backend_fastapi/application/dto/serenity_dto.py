from datetime import date, datetime
from enum import Enum

from pydantic import BaseModel, Field


class SerenityDomain(str, Enum):
    MESSAGING = "messaging"
    CALENDAR = "calendar"
    PAYMENTS = "payments"
    DOCUMENTS = "documents"
    NOTIFICATIONS = "notifications"


class SerenityLevel(str, Enum):
    EXCELLENT = "excellent"
    GOOD = "good"
    MODERATE = "moderate"
    ATTENTION = "attention"


class SerenityMetricDTO(BaseModel):
    key: str
    label: str
    value: int
    unit: str | None = None
    domain: SerenityDomain


class SerenityFactorDTO(BaseModel):
    domain: SerenityDomain
    label: str
    detail: str
    impact: int = Field(ge=0, le=30)
    severity: str


class SerenityActionDTO(BaseModel):
    id: str
    label: str
    description: str
    route: str
    icon: str
    ai_powered: bool = False
    priority: int = 0


class SerenityScorePointDTO(BaseModel):
    date: date
    score: int = Field(ge=0, le=100)


class SerenityBriefingResponse(BaseModel):
    score: int = Field(ge=0, le=100)
    level: SerenityLevel
    greeting: str
    headline: str
    summary: str
    metrics: list[SerenityMetricDTO]
    factors: list[SerenityFactorDTO]
    actions: list[SerenityActionDTO]
    score_history: list[SerenityScorePointDTO]
    generated_at: datetime


class DayPriorityDTO(BaseModel):
    id: str
    label: str
    description: str
    route: str
    domain: SerenityDomain
    priority: int = 0


class DayUrgentPaymentDTO(BaseModel):
    id: str
    creditor: str
    amount: float = Field(ge=0)
    currency: str = "EUR"
    due_date: date
    days_until_due: int


class DayAppointmentDTO(BaseModel):
    id: str
    title: str
    start: datetime
    end: datetime
    location: str | None = None
    event_type: str


class DayDocumentDTO(BaseModel):
    id: int
    title: str
    document_type: str | None = None
    is_important: bool = False


class DayBriefingResponse(BaseModel):
    """Start-the-day briefing: priorities, agenda and serenity projection."""

    greeting: str
    summary: str
    priorities: list[DayPriorityDTO] = Field(max_length=3)
    urgent_payments: list[DayUrgentPaymentDTO]
    todays_appointments: list[DayAppointmentDTO]
    new_documents: list[DayDocumentDTO]
    current_score: int = Field(ge=0, le=100)
    projected_score: int = Field(ge=0, le=100)
    value_message: str | None = None
    generated_at: datetime
