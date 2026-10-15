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
from api.v1.services.team import TeamService
from api.v1.services.semester import SemesterService
from api.mobile.v1.schemas import (
    AssignSupervisorPayload, SemesterCreatePayload
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
