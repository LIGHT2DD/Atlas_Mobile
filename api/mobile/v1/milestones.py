from datetime import datetime, timezone
from typing import Optional
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from api.db.database import get_db
from api.v1.models.user import User, UserRole
from api.v1.models.milestone import Milestone
from api.v1.services.milestone import MilestoneService
from api.mobile.v1.schemas import MilestoneCreatePayload
from api.mobile.v1.dependencies import (
    mobile_response, get_current_user_mobile, require_roles_mobile
)


milestones_mobile_router = APIRouter(prefix="/milestones", tags=["Mobile Milestones"])


@milestones_mobile_router.get("")
def list_milestones(
    semester_id: Optional[str] = Query(None),
    current_user: User = Depends(get_current_user_mobile),
    db: Session = Depends(get_db)
):
    """List all scheduled thesis milestones for the semester with deadline tracking."""
    milestones = MilestoneService.get_semester_milestones(db, semester_id=semester_id)

    now = datetime.now(timezone.utc)
    items = []
    for m in milestones:
        due = m.due_date
        is_overdue = False
        if due:
            if getattr(due, "tzinfo", None) is not None:
                is_overdue = due < now
            else:
                is_overdue = due < datetime.now()

        items.append({
            "id": m.id,
            "title": m.title,
            "description": m.description,
            "due_date": str(m.due_date) if m.due_date else None,
            "max_score": m.max_score,
            "weight_percentage": m.weight_percentage,
            "semester_id": m.semester_id,
            "status": m.status,
            "is_active": m.is_active,
            "is_overdue": is_overdue,
            "submissions_count": len(m.submissions) if hasattr(m, "submissions") else 0,
        })

    return mobile_response(data=items, message="Milestones retrieved.")


@milestones_mobile_router.post("")
def create_milestone(
    payload: MilestoneCreatePayload,
    current_user: User = Depends(require_roles_mobile(UserRole.COORDINATOR.value)),
    db: Session = Depends(get_db)
):
    """Coordinator endpoint to establish a new milestone deadline across the semester."""
    milestone = MilestoneService.create_milestone(
        db=db,
        title=payload.title,
        due_date=payload.due_date,
        max_score=payload.max_score,
        weight_percentage=payload.weight_percentage,
        description=payload.description,
        semester_id=payload.semester_id,
        actor_id=current_user.id,
    )

    return mobile_response(
        data={
            "id": milestone.id,
            "title": milestone.title,
            "due_date": str(milestone.due_date),
            "max_score": milestone.max_score,
            "weight_percentage": milestone.weight_percentage,
        },
        message=f"Milestone '{milestone.title}' created successfully.",
        status_code=201
    )
