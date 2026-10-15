from datetime import timedelta
from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Request
from sqlalchemy.orm import Session

from api.db.database import get_db
from api.utils.settings import settings
from api.utils.loggers import create_logger
from api.v1.models.user import User, UserRole
from api.v1.services.auth import AuthService
from api.v1.services.user import UserService
from api.v1.services.team import TeamService
from api.v1.services.semester import SemesterService
from api.mobile.v1.schemas import (
    LoginRequest, RefreshTokenRequest, RegisterRequest,
    ForgotPasswordRequest, ResetPasswordRequest
)
from api.mobile.v1.dependencies import mobile_response, get_current_user_mobile


auth_mobile_router = APIRouter(prefix="/auth", tags=["Mobile Auth"])
logger = create_logger(__name__)


@auth_mobile_router.post("/login")
def login(payload: LoginRequest, db: Session = Depends(get_db)):
    """Authenticate with email and password, returning JWT access and refresh tokens."""
    try:
        user, _, _ = AuthService.authenticate(
            db,
            email=payload.email,
            password=payload.password,
            create_token=False,
        )
    except HTTPException as e:
        detail = "Invalid email or password." if e.status_code in (400, 401, 404) else e.detail
        raise HTTPException(status_code=400, detail=detail)
    except Exception as e:
        logger.error(f"Login failed: {e}", exc_info=True)
        raise HTTPException(status_code=400, detail="Invalid email or password.")

    try:
        access_expiry_minutes = (30 * 24 * 60) if payload.remember_me else settings.ACCESS_TOKEN_EXPIRE_MINUTES
        refresh_expiry_minutes = (45 * 24 * 60) if payload.remember_me else settings.REFRESH_TOKEN_EXPIRE_MINUTES

        access_token = AuthService.create_access_token(db, user.id, expiry_in_minutes=access_expiry_minutes)
        refresh_token = AuthService.create_refresh_token(db, user.id, expiry_in_minutes=refresh_expiry_minutes)

        # Attach role-specific context
        context = {}
        active_sem = SemesterService.get_active_semester(db)
        if active_sem:
            context["active_semester"] = {
                "id": active_sem.id,
                "name": active_sem.name,
                "academic_year": active_sem.academic_year,
            }

        if user.role == UserRole.STUDENT.value:
            team = TeamService.get_student_active_team(db, user.id)
            if team:
                context["active_team"] = {
                    "id": team.id,
                    "name": team.name,
                    "project_title": team.project_title,
                    "status": team.status,
                    "is_leader": team.leader_id == user.id,
                }
    except Exception as e:
        logger.error(f"Session generation failed: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail="Session initialization failed. Please try again.")

    return mobile_response(
        data={
            "access_token": access_token,
            "refresh_token": refresh_token,
            "token_type": "bearer",
            "user": {
                "id": user.id,
                "email": user.email,
                "first_name": user.first_name,
                "last_name": user.last_name,
                "full_name": user.full_name,
                "role": user.role,
                "avatar_url": getattr(user, "avatar_url", None),
                "is_active": user.is_active,
            },
            "context": context,
        },
        message="Logged in successfully."
    )


@auth_mobile_router.post("/refresh")
def refresh_tokens(payload: RefreshTokenRequest, db: Session = Depends(get_db)):
    """Exchange a valid refresh token for a new access token and rotated refresh token."""
    try:
        access, refresh = AuthService.refresh_access_token(db, payload.refresh_token)
        return mobile_response(
            data={
                "access_token": access,
                "refresh_token": refresh,
                "token_type": "bearer",
            },
            message="Token refreshed successfully."
        )
    except HTTPException as e:
        raise HTTPException(status_code=e.status_code, detail=e.detail)
    except Exception as e:
        logger.error(f"Refresh failed: {e}")
        raise HTTPException(status_code=401, detail="Invalid or expired refresh token.")


@auth_mobile_router.post("/logout")
def logout(
    current_user: User = Depends(get_current_user_mobile),
    db: Session = Depends(get_db)
):
    """Revoke user access and refresh tokens."""
    try:
        AuthService.logout(db, current_user.id)
    except Exception as e:
        logger.warning(f"Error during logout token revocation: {e}")

    return mobile_response(message="Logged out successfully.")


@auth_mobile_router.get("/me")
def get_current_user_profile(
    current_user: User = Depends(get_current_user_mobile),
    db: Session = Depends(get_db)
):
    """Fetch current user profile and active workspace state."""
    active_sem = SemesterService.get_active_semester(db)
    active_sem_dict = None
    if active_sem:
        active_sem_dict = {
            "id": active_sem.id,
            "name": active_sem.name,
            "academic_year": active_sem.academic_year,
            "start_date": str(active_sem.start_date) if active_sem.start_date else None,
            "end_date": str(active_sem.end_date) if active_sem.end_date else None,
        }

    team_dict = None
    if current_user.role == UserRole.STUDENT.value:
        team = TeamService.get_student_active_team(db, current_user.id)
        if team:
            team_dict = {
                "id": team.id,
                "name": team.name,
                "project_title": team.project_title,
                "status": team.status,
                "invite_code": team.invite_code,
                "leader_id": team.leader_id,
                "is_leader": team.leader_id == current_user.id,
                "supervisor_id": team.supervisor_id,
                "supervisor_name": team.supervisor.full_name if team.supervisor else None,
                "member_count": len(team.members),
            }

    return mobile_response(
        data={
            "user": {
                "id": current_user.id,
                "email": current_user.email,
                "first_name": current_user.first_name,
                "last_name": current_user.last_name,
                "full_name": current_user.full_name,
                "role": current_user.role,
                "phone": getattr(current_user, "phone", None),
                "avatar_url": getattr(current_user, "avatar_url", None),
                "is_active": current_user.is_active,
                "created_at": str(current_user.created_at) if current_user.created_at else None,
            },
            "active_semester": active_sem_dict,
            "active_team": team_dict,
        },
        message="Profile retrieved."
    )


@auth_mobile_router.post("/register")
def register_student(
    payload: RegisterRequest,
    bg_tasks: BackgroundTasks,
    db: Session = Depends(get_db)
):
    """Student self-registration endpoint."""
    if payload.password != payload.confirm_password:
        raise HTTPException(status_code=400, detail="Passwords do not match.")

    # Check for existing user
    existing = User.fetch_one_by_field(db, throw_error=False, email=payload.email)
    if existing:
        raise HTTPException(status_code=400, detail="An account with this email already exists.")

    new_user, access_token, refresh_token = UserService.create(
        db=db,
        payload={
            "first_name": payload.first_name,
            "last_name": payload.last_name,
            "email": payload.email,
            "password": payload.password,
            "confirm_password": payload.confirm_password,
        },
        bg_tasks=bg_tasks,
        role=UserRole.STUDENT.value,
        is_active=True,
        create_token=True,
    )

    return mobile_response(
        data={
            "access_token": access_token,
            "refresh_token": refresh_token,
            "token_type": "bearer",
            "user": {
                "id": new_user.id,
                "email": new_user.email,
                "first_name": new_user.first_name,
                "last_name": new_user.last_name,
                "full_name": new_user.full_name,
                "role": new_user.role,
                "is_active": new_user.is_active,
            }
        },
        message="Account created successfully.",
        status_code=201
    )


@auth_mobile_router.post("/forgot-password")
async def forgot_password(
    payload: ForgotPasswordRequest,
    bg_tasks: BackgroundTasks,
    request: Request,
    db: Session = Depends(get_db)
):
    """Send a password reset token/link if the email exists."""
    user = User.fetch_one_by_field(db, throw_error=False, email=payload.email)
    if user:
        base_url = str(request.base_url).rstrip("/")
        await AuthService.send_password_reset_link(db, payload.email, bg_tasks, base_url=base_url)

    # Return safe message to prevent user enumeration
    return mobile_response(
        message="If an account with that email exists, password reset instructions have been dispatched."
    )


@auth_mobile_router.post("/reset-password")
def reset_password(
    payload: ResetPasswordRequest,
    db: Session = Depends(get_db)
):
    """Reset password using a valid reset token."""
    if payload.password != payload.confirm_password:
        raise HTTPException(status_code=400, detail="Passwords do not match.")

    try:
        user_id = AuthService.verify_password_reset_token(db, payload.token)
        hashed_password = AuthService.hash_secret(payload.password)
        User.update(db, user_id, password=hashed_password)
        return mobile_response(message="Password has been reset successfully. Please sign in.")
    except HTTPException as e:
        raise HTTPException(status_code=400, detail="Invalid or expired reset token.")
