from typing import Optional
from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from api.db.database import get_db
from api.v1.models.user import User, UserRole
from api.v1.models.team import Team, TeamStatus
from api.v1.models.team_member import TeamMember
from api.v1.models.semester import Semester
from api.v1.models.department import Department
from api.v1.services.team import TeamService
from api.v1.services.semester import SemesterService
from api.mobile.v1.schemas import (
    CreateTeamRequest, JoinTeamRequest, SupervisorRequestPayload
)
from api.mobile.v1.dependencies import (
    mobile_response, get_current_user_mobile, require_roles_mobile
)


teams_mobile_router = APIRouter(prefix="/teams", tags=["Mobile Teams"])


def _serialize_team(team: Team, current_user_id: str) -> dict:
    members = []
    for m in team.members:
        if not m.is_deleted:
            members.append({
                "id": m.id,
                "user_id": m.user_id,
                "name": m.user.full_name if m.user else "Unknown",
                "email": m.user.email if m.user else "",
                "role": m.role,
                "joined_at": str(m.created_at) if m.created_at else None,
            })

    supervisor_info = None
    if team.supervisor:
        supervisor_info = {
            "id": team.supervisor.id,
            "name": team.supervisor.full_name,
            "email": team.supervisor.email,
        }

    return {
        "id": team.id,
        "name": team.name,
        "project_title": team.project_title,
        "description": team.description,
        "status": team.status,
        "invite_code": team.invite_code,
        "leader_id": team.leader_id,
        "is_leader": team.leader_id == current_user_id,
        "semester_id": team.semester_id,
        "semester_name": team.semester.name if team.semester else None,
        "supervisor": supervisor_info,
        "members": members,
        "final_grade": team.final_grade,
        "final_score": team.final_score,
        "grade_published": team.grade_published,
        "created_at": str(team.created_at) if team.created_at else None,
    }


@teams_mobile_router.get("/my-team")
def get_my_team(
    current_user: User = Depends(require_roles_mobile(UserRole.STUDENT.value)),
    db: Session = Depends(get_db)
):
    """Retrieve the student's current active team roster and status."""
    team = TeamService.get_student_active_team(db, current_user.id)
    if not team:
        active_sem = SemesterService.get_active_semester(db)
        departments = db.query(Department).filter(Department.is_deleted == False).all()
        return mobile_response(
            data={
                "has_team": False,
                "team": None,
                "active_semester": {
                    "id": active_sem.id,
                    "name": active_sem.name,
                } if active_sem else None,
                "departments": [{"id": d.id, "name": d.name} for d in departments],
            },
            message="No active team found."
        )

    return mobile_response(
        data={
            "has_team": True,
            "team": _serialize_team(team, current_user.id),
        },
        message="Active team retrieved."
    )


@teams_mobile_router.post("")
def create_team(
    payload: CreateTeamRequest,
    current_user: User = Depends(require_roles_mobile(UserRole.STUDENT.value)),
    db: Session = Depends(get_db)
):
    """Create a new thesis team led by the authenticated student."""
    team = TeamService.create_team(
        db=db,
        student_id=current_user.id,
        name=payload.name,
        project_title=payload.project_title,
        description=payload.description,
        department_id=payload.department_id,
        semester_id=payload.semester_id,
    )
    return mobile_response(
        data=_serialize_team(team, current_user.id),
        message=f"Team '{team.name}' created successfully.",
        status_code=201
    )


@teams_mobile_router.post("/join")
def join_team(
    payload: JoinTeamRequest,
    current_user: User = Depends(require_roles_mobile(UserRole.STUDENT.value)),
    db: Session = Depends(get_db)
):
    """Join an existing team using its invite code."""
    team, message = TeamService.join_team_via_invite(
        db=db,
        invite_code=payload.invite_code.strip(),
        student_id=current_user.id,
    )
    return mobile_response(
        data=_serialize_team(team, current_user.id),
        message=message
    )


@teams_mobile_router.post("/{team_id}/leave")
def leave_team(
    team_id: str,
    current_user: User = Depends(require_roles_mobile(UserRole.STUDENT.value)),
    db: Session = Depends(get_db)
):
    """Leave a team in FORMING state."""
    TeamService.leave_team(db, team_id=team_id, student_id=current_user.id)
    return mobile_response(message="You have successfully left the team.")


@teams_mobile_router.post("/{team_id}/request-supervisor")
def request_supervisor(
    team_id: str,
    payload: SupervisorRequestPayload,
    bg_tasks: BackgroundTasks,
    current_user: User = Depends(require_roles_mobile(UserRole.STUDENT.value)),
    db: Session = Depends(get_db)
):
    """Send a formal supervisor request from the team leader."""
    team = Team.fetch_by_id(db, team_id)
    if team.leader_id != current_user.id:
        raise HTTPException(
            status_code=403,
            detail="Only the team leader can submit supervision requests."
        )

    req = TeamService.request_supervisor(
        db=db,
        team_id=team_id,
        supervisor_id=payload.supervisor_id,
        student_id=current_user.id,
        notes=payload.notes,
        bg_tasks=bg_tasks,
    )

    return mobile_response(
        data={
            "request_id": req.id,
            "status": req.status,
            "supervisor_id": req.supervisor_id,
            "notes": req.notes,
        },
        message="Supervisor request sent successfully.",
        status_code=201
    )


@teams_mobile_router.get("/supervisors")
def list_supervisors(
    current_user: User = Depends(get_current_user_mobile),
    db: Session = Depends(get_db)
):
    """List faculty supervisors available for mentorship."""
    supervisors = db.query(User).filter(
        User.role == UserRole.SUPERVISOR.value,
        User.is_deleted == False,
        User.is_active == True,
    ).all()

    items = []
    for s in supervisors:
        active_teams_count = db.query(Team).filter(
            Team.supervisor_id == s.id,
            Team.is_deleted == False,
        ).count()

        items.append({
            "id": s.id,
            "name": s.full_name,
            "email": s.email,
            "department": s.department.name if getattr(s, "department", None) else None,
            "active_teams_count": active_teams_count,
        })

    return mobile_response(data=items, message="Supervisors retrieved.")
