from typing import Optional, List, Any
from datetime import datetime, date
from pydantic import BaseModel, EmailStr, Field


# ─── Standard Response Envelope ─────────────────────────────

class MobileResponse(BaseModel):
    success: bool = True
    status_code: int = 200
    message: str = "Operation completed successfully."
    data: Optional[Any] = None
    errors: Optional[List[str]] = None


# ─── Auth Schemas ───────────────────────────────────────────

class LoginRequest(BaseModel):
    email: EmailStr
    password: str
    remember_me: Optional[bool] = False


class RefreshTokenRequest(BaseModel):
    refresh_token: str


class RegisterRequest(BaseModel):
    first_name: str = Field(..., min_length=1, max_length=100)
    last_name: str = Field(..., min_length=1, max_length=100)
    email: EmailStr
    password: str = Field(..., min_length=8)
    confirm_password: str = Field(..., min_length=8)


class ForgotPasswordRequest(BaseModel):
    email: EmailStr


class ResetPasswordRequest(BaseModel):
    token: str
    password: str = Field(..., min_length=8)
    confirm_password: str = Field(..., min_length=8)


# ─── Team Schemas ───────────────────────────────────────────

class CreateTeamRequest(BaseModel):
    name: str = Field(..., min_length=2, max_length=100)
    project_title: str = Field(..., min_length=3, max_length=200)
    semester_id: Optional[str] = None
    department_id: Optional[str] = None
    description: Optional[str] = None


class JoinTeamRequest(BaseModel):
    invite_code: str = Field(..., min_length=4, max_length=32)


class SupervisorRequestPayload(BaseModel):
    supervisor_id: str
    notes: Optional[str] = None


class SupervisorRespondPayload(BaseModel):
    accept: bool
    notes: Optional[str] = None


class AssignSupervisorPayload(BaseModel):
    supervisor_id: str


# ─── Proposal Schemas ───────────────────────────────────────

class ProposalSubmitPayload(BaseModel):
    team_id: str
    title: str = Field(..., min_length=3, max_length=255)
    abstract: str = Field(..., min_length=10)


class ProposalReviewPayload(BaseModel):
    decision: str = Field(..., pattern="^(approved|changes_requested|rejected)$")
    comments: Optional[str] = None


# ─── Milestone & Submission Schemas ─────────────────────────

class MilestoneCreatePayload(BaseModel):
    title: str = Field(..., min_length=2, max_length=150)
    description: Optional[str] = None
    due_date: datetime
    max_score: float = 100.0
    weight_percentage: float = 20.0
    semester_id: Optional[str] = None


class SubmissionGradePayload(BaseModel):
    score: float = Field(..., ge=0.0)
    feedback_text: Optional[str] = None


# ─── Defense Schemas ────────────────────────────────────────

class DefenseSchedulePayload(BaseModel):
    team_id: str
    scheduled_date: str  # YYYY-MM-DD
    start_time: str      # HH:MM
    end_time: str        # HH:MM
    venue: str
    panelist_ids: List[str] = []


# ─── Evaluation & Grade Schemas ─────────────────────────────

class RubricCriteriaCreatePayload(BaseModel):
    title: str = Field(..., min_length=2, max_length=150)
    description: Optional[str] = None
    max_score: float = Field(..., gt=0.0)
    weight_percentage: float = Field(..., gt=0.0, le=100.0)


class EvaluationScoreItem(BaseModel):
    criteria_id: str
    score: float = Field(..., ge=0.0)
    remarks: Optional[str] = None


class EvaluationSubmitPayload(BaseModel):
    rubric_scores: List[EvaluationScoreItem]
    remarks: Optional[str] = None


class PublishGradePayload(BaseModel):
    final_grade: str = Field(..., min_length=1, max_length=10)
    final_score: float = Field(..., ge=0.0, le=100.0)


# ─── Notification & Device Schemas ──────────────────────────

class DeviceTokenPayload(BaseModel):
    fcm_token: str
    device_type: Optional[str] = "android"


# ─── Semester Schemas ───────────────────────────────────────

class SemesterCreatePayload(BaseModel):
    name: str = Field(..., min_length=2, max_length=100)
    academic_year: str = Field(..., min_length=4, max_length=50)
    start_date: date
    end_date: date
    max_team_size: Optional[int] = 4
    min_team_size: Optional[int] = 2
    is_active: Optional[bool] = False


# ─── Coordinator Faculty & User Management ───────────────────

class CoordinatorCreateUserPayload(BaseModel):
    first_name: str = Field(..., min_length=1, max_length=100)
    last_name: str = Field(..., min_length=1, max_length=100)
    email: EmailStr
    password: str = Field(..., min_length=8)
    role: str = Field(..., pattern=r"^(supervisor|coordinator)$")
    department_id: Optional[str] = None
    current_password: Optional[str] = None  # Elevated sudo verification required if role == 'coordinator'

