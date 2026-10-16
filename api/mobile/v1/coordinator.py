from typing import Optional
from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from api.db.database import get_db
from api.v1.models.user import User, UserRole
from api.v1.models.team import Team
from api.v1.models.semester import Semester
from api.v1.models.proposal import Proposal, ProposalStatus
from api.v1.models.submission import Submission
from api.v1.models.defense import DefenseSchedule
from api.v1.models.audit_log import AuditLog
from api.v1.models.notification import NotificationType
from api.v1.services.team import TeamService
from api.v1.services.semester import SemesterService
from api.v1.services.auth import AuthService
from api.v1.services.notification import NotificationService
from api.mobile.v1.schemas import (
    AssignSupervisorPayload, SemesterCreatePayload, CoordinatorCreateUserPayload
)
from api.mobile.v1.dependencies import (
    mobile_response, require_roles_mobile
)


coordinator_mobile_router = APIRouter(prefix="/coordinator", tags=["Mobile Coordinator"])


@coordinator_mobile_router.get("/teams")
def list_all_teams(
    semester_id: Optional[str] = Query(None),
    status: Optional[str] = Query(None),
    current_user: User = Depends(require_roles_mobile(UserRole.COORDINATOR.value)),
    db: Session = Depends(get_db)
):
    """Coordinator endpoint to view all teams across departments with status filters."""
    query = db.query(Team).filter(Team.is_deleted == False)
    if semester_id:
        query = query.filter(Team.semester_id == semester_id)
    if status:
        query = query.filter(Team.status == status)

    teams = query.order_by(Team.created_at.desc()).all()

    items = []
    for t in teams:
        members = [
            {
                "user_id": m.user_id,
                "name": m.user.full_name if m.user else "Unknown",
                "role": m.role,
            }
            for m in t.members if not m.is_deleted
        ]

        items.append({
            "id": t.id,
            "name": t.name,
            "project_title": t.project_title,
            "status": t.status,
            "semester_id": t.semester_id,
            "semester_name": t.semester.name if t.semester else None,
            "supervisor_id": t.supervisor_id,
            "supervisor_name": t.supervisor.full_name if t.supervisor else "Unassigned",
            "leader_id": t.leader_id,
            "leader_name": t.leader.full_name if t.leader else "Unknown",
            "members": members,
            "final_grade": t.final_grade,
            "final_score": t.final_score,
            "grade_published": t.grade_published,
            "created_at": str(t.created_at) if t.created_at else None,
        })

    return mobile_response(data=items, message="All teams retrieved.")


@coordinator_mobile_router.post("/teams/{team_id}/assign-supervisor")
def assign_supervisor(
    team_id: str,
    payload: AssignSupervisorPayload,
    bg_tasks: BackgroundTasks,
    current_user: User = Depends(require_roles_mobile(UserRole.COORDINATOR.value)),
    db: Session = Depends(get_db)
):
    """Coordinator administratively assigns or balances faculty supervision."""
    team = TeamService.assign_supervisor_administrative(
        db=db,
        team_id=team_id,
        supervisor_id=payload.supervisor_id,
        coordinator_id=current_user.id,
        bg_tasks=bg_tasks,
    )

    return mobile_response(
        data={
            "team_id": team.id,
            "supervisor_id": team.supervisor_id,
            "status": team.status,
        },
        message=f"Supervisor assigned to team '{team.name}' successfully."
    )


@coordinator_mobile_router.get("/semesters")
def list_semesters(
    current_user: User = Depends(require_roles_mobile(UserRole.COORDINATOR.value)),
    db: Session = Depends(get_db)
):
    """List all configured academic semesters."""
    semesters = db.query(Semester).filter(
        Semester.is_deleted == False,
    ).order_by(Semester.created_at.desc()).all()

    items = [
        {
            "id": s.id,
            "name": s.name,
            "academic_year": s.academic_year,
            "start_date": str(s.start_date) if s.start_date else None,
            "end_date": str(s.end_date) if s.end_date else None,
            "max_team_size": s.max_team_size,
            "min_team_size": s.min_team_size,
            "is_active": s.is_active,
        }
        for s in semesters
    ]

    return mobile_response(data=items, message="Semesters retrieved.")


@coordinator_mobile_router.post("/semesters")
def create_semester(
    payload: SemesterCreatePayload,
    current_user: User = Depends(require_roles_mobile(UserRole.COORDINATOR.value)),
    db: Session = Depends(get_db)
):
    """Coordinator creates a new academic term."""
    sem = SemesterService.create_semester(
        db=db,
        name=payload.name,
        academic_year=payload.academic_year,
        start_date=payload.start_date,
        end_date=payload.end_date,
        max_team_size=payload.max_team_size or 4,
        min_team_size=payload.min_team_size or 2,
        is_active=payload.is_active or False,
        actor_id=current_user.id,
    )

    return mobile_response(
        data={
            "id": sem.id,
            "name": sem.name,
            "academic_year": sem.academic_year,
            "is_active": sem.is_active,
        },
        message=f"Semester '{sem.name}' created.",
        status_code=201
    )


@coordinator_mobile_router.post("/semesters/{semester_id}/activate")
def activate_semester(
    semester_id: str,
    current_user: User = Depends(require_roles_mobile(UserRole.COORDINATOR.value)),
    db: Session = Depends(get_db)
):
    """Set a semester as the active term, deactivating all others."""
    sem = SemesterService.update_semester(
        db=db,
        semester_id=semester_id,
        actor_id=current_user.id,
        is_active=True,
    )

    return mobile_response(
        data={"id": sem.id, "name": sem.name, "is_active": sem.is_active},
        message=f"Semester '{sem.name}' activated as current term."
    )


@coordinator_mobile_router.get("/audit-logs")
def get_audit_logs(
    limit: int = Query(50, ge=1, le=200),
    current_user: User = Depends(require_roles_mobile(UserRole.COORDINATOR.value)),
    db: Session = Depends(get_db)
):
    """Retrieve chronological university audit trail for accreditation compliance."""
    logs = db.query(AuditLog).order_by(AuditLog.created_at.desc()).limit(limit).all()

    items = [
        {
            "id": l.id,
            "action": l.action,
            "user_id": l.user_id,
            "user_name": l.user.full_name if l.user else "System",
            "entity_type": l.entity_type,
            "entity_id": l.entity_id,
            "details": l.details,
            "created_at": str(l.created_at) if l.created_at else None,
        }
        for l in logs
    ]

    return mobile_response(data=items, message="Audit logs retrieved.")


@coordinator_mobile_router.get("/reports/summary")
def get_reports_summary(
    current_user: User = Depends(require_roles_mobile(UserRole.COORDINATOR.value)),
    db: Session = Depends(get_db)
):
    """Retrieve departmental academic statistics and progression KPIs."""
    total_students = db.query(User).filter(User.role == UserRole.STUDENT.value, User.is_deleted == False).count()
    total_supervisors = db.query(User).filter(User.role == UserRole.SUPERVISOR.value, User.is_deleted == False).count()
    total_teams = db.query(Team).filter(Team.is_deleted == False).count()
    proposals_approved = db.query(Proposal).filter(Proposal.status == ProposalStatus.APPROVED.value, Proposal.is_deleted == False).count()
    defenses_scheduled = db.query(DefenseSchedule).filter(DefenseSchedule.is_deleted == False).count()
    grades_published = db.query(Team).filter(Team.grade_published == True, Team.is_deleted == False).count()
    total_submissions = db.query(Submission).filter(Submission.is_deleted == False).count()

    return mobile_response(
        data={
            "total_students": total_students,
            "total_supervisors": total_supervisors,
            "total_teams": total_teams,
            "proposals_approved": proposals_approved,
            "defenses_scheduled": defenses_scheduled,
            "grades_published": grades_published,
            "total_submissions": total_submissions,
        },
        message="Departmental summary report retrieved."
    )


@coordinator_mobile_router.get("/users")
def list_faculty_and_coordinators(
    role: Optional[str] = Query(None),
    current_user: User = Depends(require_roles_mobile(UserRole.COORDINATOR.value)),
    db: Session = Depends(get_db)
):
    """List faculty supervisors and department coordinators."""
    query = db.query(User).filter(
        User.role.in_([UserRole.SUPERVISOR.value, UserRole.COORDINATOR.value, UserRole.ADMIN.value]),
        User.is_deleted == False
    )
    if role:
        norm_role = role.strip().lower()
        if norm_role == "coordinator":
            query = query.filter(User.role.in_([UserRole.COORDINATOR.value, UserRole.ADMIN.value]))
        elif norm_role == "supervisor":
            query = query.filter(User.role == UserRole.SUPERVISOR.value)

    users = query.order_by(User.role.asc(), User.first_name.asc()).all()
    items = [
        {
            "id": u.id,
            "first_name": u.first_name,
            "last_name": u.last_name,
            "full_name": u.full_name,
            "email": u.email,
            "role": "coordinator" if u.role in ("coordinator", "admin") else u.role,
            "department_id": u.department_id,
            "department_name": u.department.name if getattr(u, "department", None) else None,
            "is_active": u.is_active,
            "created_at": str(u.created_at) if u.created_at else None,
        }
        for u in users
    ]
    return mobile_response(data=items, message="Faculty and coordinator roster retrieved.")


import time

_sudo_failed_attempts: dict[str, list[float]] = {}
_SUDO_MAX_ATTEMPTS = 5
_SUDO_LOCKOUT_SECONDS = 60.0

@coordinator_mobile_router.post("/users")
def create_faculty_or_coordinator(
    payload: CoordinatorCreateUserPayload,
    bg_tasks: BackgroundTasks,
    current_user: User = Depends(require_roles_mobile(UserRole.COORDINATOR.value)),
    db: Session = Depends(get_db)
):
    """
    Coordinator administrative user creation with elevated security controls:
    1. Sudo Elevated Password verification required if creating a Coordinator.
    2. Rate limiting & audit logging on failed sudo elevated attempts.
    3. Institutional domain check (@atlas.edu) for Coordinator accounts.
    4. Immutable AuditLog recording.
    5. Broadcast alert notifications to all active peer coordinators.
    """
    target_role = payload.role.strip().lower()
    if target_role not in (UserRole.SUPERVISOR.value, UserRole.COORDINATOR.value):
        raise HTTPException(status_code=400, detail="Invalid role. Must be 'supervisor' or 'coordinator'.")

    # Guardrails for Coordinator creation
    if target_role == UserRole.COORDINATOR.value:
        now_ts = time.time()
        user_attempts = [t for t in _sudo_failed_attempts.get(current_user.id, []) if now_ts - t < _SUDO_LOCKOUT_SECONDS]
        _sudo_failed_attempts[current_user.id] = user_attempts

        if len(user_attempts) >= _SUDO_MAX_ATTEMPTS:
            AuditLog.log(
                db=db,
                action="SECURITY_SUDO_LOCKOUT",
                user_id=current_user.id,
                entity_type="user",
                details=f"Elevated authorization temporarily locked out for coordinator {current_user.full_name} due to excessive failures."
            )
            raise HTTPException(
                status_code=429,
                detail="Too many failed elevated password attempts. Authorization locked for 60 seconds."
            )

        if not payload.current_password or not payload.current_password.strip():
            raise HTTPException(
                status_code=400,
                detail="Current coordinator password is required to authorize creating another coordinator account."
            )
        if not AuthService.verify_hash(payload.current_password.strip(), current_user.password):
            _sudo_failed_attempts[current_user.id].append(now_ts)
            AuditLog.log(
                db=db,
                action="SECURITY_SUDO_FAILURE",
                user_id=current_user.id,
                entity_type="user",
                details=f"Failed elevated authorization attempt by coordinator {current_user.full_name} when attempting to create coordinator account for '{payload.email}'."
            )
            remaining = _SUDO_MAX_ATTEMPTS - len(_sudo_failed_attempts[current_user.id])
            raise HTTPException(
                status_code=403,
                detail=f"Elevated authorization failed: Invalid coordinator password. ({remaining} attempts remaining before temporary lockout)."
            )

        # Clear failed attempts on successful elevated authorization
        _sudo_failed_attempts.pop(current_user.id, None)

        if not payload.email.lower().endswith("@atlas.edu"):
            raise HTTPException(
                status_code=400,
                detail="Coordinator accounts must use an institutional email ending with @atlas.edu."
            )

    # Check for existing user with this email
    existing = User.fetch_one_by_field(db, throw_error=False, email=payload.email.lower().strip())
    if existing:
        raise HTTPException(status_code=400, detail="An account with this email already exists.")

    new_user = User.create(
        db=db,
        first_name=payload.first_name.strip(),
        last_name=payload.last_name.strip(),
        email=payload.email.lower().strip(),
        password=AuthService.hash_secret(payload.password),
        role=target_role,
        department_id=payload.department_id,
        is_active=True,
    )

    action_name = "COORDINATOR_CREATED" if target_role == UserRole.COORDINATOR.value else "SUPERVISOR_CREATED"
    AuditLog.log(
        db=db,
        action=action_name,
        user_id=current_user.id,
        entity_type="user",
        entity_id=new_user.id,
        details=f"Coordinator {current_user.full_name} created {target_role.capitalize()} account for {new_user.full_name} ({new_user.email}).",
    )

    # Broadcast notification to peer coordinators if coordinator created
    if target_role == UserRole.COORDINATOR.value:
        other_coords = db.query(User).filter(
            User.role.in_([UserRole.COORDINATOR.value, UserRole.ADMIN.value]),
            User.id != new_user.id,
            User.is_deleted == False
        ).all()
        for coord in other_coords:
            NotificationService.notify(
                db=db,
                bg_tasks=bg_tasks,
                user_id=coord.id,
                title="New Academic Coordinator Registered",
                content=f"Coordinator account for {new_user.full_name} ({new_user.email}) was created by {current_user.full_name}.",
                notification_type=NotificationType.SYSTEM.value,
                link="/coordinator/users",
            )
    else:
        NotificationService.notify(
            db=db,
            bg_tasks=bg_tasks,
            user_id=new_user.id,
            title="Welcome to ATLAS Faculty Portal",
            content=f"Welcome {new_user.full_name}! Your supervisor account has been activated by Coordinator {current_user.full_name}.",
            notification_type=NotificationType.SYSTEM.value,
            link="/dashboard",
        )

    return mobile_response(
        data={
            "id": new_user.id,
            "first_name": new_user.first_name,
            "last_name": new_user.last_name,
            "full_name": new_user.full_name,
            "email": new_user.email,
            "role": new_user.role,
            "department_id": new_user.department_id,
            "is_active": new_user.is_active,
        },
        message=f"{target_role.capitalize()} account created successfully.",
        status_code=201
    )
