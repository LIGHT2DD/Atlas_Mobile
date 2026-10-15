from datetime import date, datetime
from typing import Optional
from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException
from sqlalchemy.orm import Session

from api.db.database import get_db
from api.v1.models.user import User, UserRole
from api.v1.models.defense import DefenseSchedule, DefenseStatus, DefensePanelRole
from api.v1.services.defense import DefenseService
from api.mobile.v1.schemas import DefenseSchedulePayload
from api.mobile.v1.dependencies import (
    mobile_response, get_current_user_mobile, require_roles_mobile
)


defenses_mobile_router = APIRouter(prefix="/defenses", tags=["Mobile Defenses"])


def _serialize_defense(d: DefenseSchedule) -> dict:
    panel = []
    for p in d.panel_members:
        if not p.is_deleted:
            panel.append({
                "id": p.id,
                "user_id": p.user_id,
                "name": p.user.full_name if p.user else "Unknown",
                "role": p.role,
            })

    return {
        "id": d.id,
        "team_id": d.team_id,
        "team_name": d.team.name if d.team else "Unknown",
        "project_title": d.team.project_title if d.team else "",
        "date": str(d.date) if d.date else None,
        "start_time": d.start_time,
        "end_time": d.end_time,
        "room": d.room,
        "status": d.status,
        "notes": d.notes,
        "panel_members": panel,
        "created_at": str(d.created_at) if d.created_at else None,
    }


@defenses_mobile_router.get("")
def list_defenses(
    current_user: User = Depends(get_current_user_mobile),
    db: Session = Depends(get_db)
):
    """Retrieve scheduled oral defense sessions."""
    defenses = db.query(DefenseSchedule).filter(
        DefenseSchedule.is_deleted == False,
    ).order_by(DefenseSchedule.date.asc(), DefenseSchedule.start_time.asc()).all()

    items = [_serialize_defense(d) for d in defenses]
    return mobile_response(data=items, message="Defense schedules retrieved.")


@defenses_mobile_router.post("/schedule")
def schedule_defense(
    payload: DefenseSchedulePayload,
    bg_tasks: BackgroundTasks,
    current_user: User = Depends(require_roles_mobile(UserRole.COORDINATOR.value)),
    db: Session = Depends(get_db)
):
    """Coordinator endpoint to schedule a defense with automated conflict detection."""
    try:
        defense_date_obj = date.fromisoformat(payload.scheduled_date)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid date format. Expected YYYY-MM-DD.")

    panel_data = [
        {"user_id": pid, "role": DefensePanelRole.MEMBER.value}
        for pid in payload.panelist_ids
    ]
    if panel_data:
        panel_data[0]["role"] = DefensePanelRole.CHAIR.value

    defense = DefenseService.schedule_defense(
        db=db,
        coordinator_id=current_user.id,
        team_id=payload.team_id,
        defense_date=defense_date_obj,
        start_time=payload.start_time,
        end_time=payload.end_time,
        room=payload.venue,
        panel_members_data=panel_data,
        bg_tasks=bg_tasks,
    )

    return mobile_response(
        data=_serialize_defense(defense),
        message="Defense scheduled successfully without conflicts.",
        status_code=201
    )
