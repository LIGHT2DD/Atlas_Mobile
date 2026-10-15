from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException
from sqlalchemy.orm import Session

from api.db.database import get_db
from api.v1.models.user import User, UserRole
from api.v1.models.team import Team
from api.v1.models.supervisor_request import SupervisorRequest, SupervisorRequestStatus
from api.v1.services.team import TeamService
from api.mobile.v1.schemas import SupervisorRespondPayload
from api.mobile.v1.dependencies import (
    mobile_response, require_roles_mobile
)


supervisor_mobile_router = APIRouter(prefix="/supervisor", tags=["Mobile Supervisor"])


@supervisor_mobile_router.get("/requests")
def list_supervision_requests(
    current_user: User = Depends(require_roles_mobile(UserRole.SUPERVISOR.value)),
    db: Session = Depends(get_db)
):
    """Retrieve all pending supervision requests for the authenticated supervisor."""
    requests = db.query(SupervisorRequest).filter(
        SupervisorRequest.supervisor_id == current_user.id,
        SupervisorRequest.status == SupervisorRequestStatus.PENDING.value,
        SupervisorRequest.is_deleted == False,
    ).order_by(SupervisorRequest.created_at.desc()).all()

    items = []
    for r in requests:
        team = r.team
        items.append({
            "id": r.id,
            "team_id": r.team_id,
            "team_name": team.name if team else "Unknown",
            "project_title": team.project_title if team else "",
            "notes": r.notes,
            "requested_by_id": r.requested_by_id,
            "requested_by_name": r.requested_by.full_name if r.requested_by else "Unknown",
            "member_count": len(team.members) if team else 0,
            "status": r.status,
            "created_at": str(r.created_at) if r.created_at else None,
        })

    return mobile_response(data=items, message="Pending supervision requests retrieved.")


@supervisor_mobile_router.post("/requests/{request_id}/respond")
def respond_supervision_request(
    request_id: str,
    payload: SupervisorRespondPayload,
    bg_tasks: BackgroundTasks,
    current_user: User = Depends(require_roles_mobile(UserRole.SUPERVISOR.value)),
    db: Session = Depends(get_db)
):
    """Accept or decline a student team supervision request."""
    req = TeamService.respond_supervisor_request(
        db=db,
        request_id=request_id,
        supervisor_id=current_user.id,
        accept=payload.accept,
        response_notes=payload.notes,
        bg_tasks=bg_tasks,
    )

    action_text = "accepted" if payload.accept else "declined"
    return mobile_response(
        data={
            "request_id": req.id,
            "status": req.status,
            "response_notes": req.response_notes,
        },
        message=f"Supervision request {action_text} successfully."
    )


@supervisor_mobile_router.get("/teams")
def list_supervised_teams(
    current_user: User = Depends(require_roles_mobile(UserRole.SUPERVISOR.value)),
    db: Session = Depends(get_db)
):
    """List all teams currently assigned to the authenticated supervisor."""
    teams = db.query(Team).filter(
        Team.supervisor_id == current_user.id,
        Team.is_deleted == False,
    ).order_by(Team.created_at.desc()).all()

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
            "leader_id": t.leader_id,
            "leader_name": t.leader.full_name if t.leader else "Unknown",
            "members": members,
            "final_grade": t.final_grade,
            "final_score": t.final_score,
            "grade_published": t.grade_published,
            "created_at": str(t.created_at) if t.created_at else None,
        })

    return mobile_response(data=items, message="Supervised teams retrieved.")
