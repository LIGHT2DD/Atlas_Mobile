from datetime import datetime
from typing import Optional, List
from fastapi import HTTPException
from sqlalchemy.orm import Session

from api.v1.models.milestone import Milestone, MilestoneStatus
from api.v1.models.semester import Semester
from api.v1.models.audit_log import AuditLog
from api.v1.services.semester import SemesterService
from api.utils.loggers import create_logger

logger = create_logger(__name__)


class MilestoneService:

    @classmethod
    def get_semester_milestones(cls, db: Session, semester_id: Optional[str] = None) -> List[Milestone]:
        """Fetch all active milestones for a semester."""
        if not semester_id:
            active_sem = SemesterService.get_active_semester(db)
            if active_sem:
                semester_id = active_sem.id

        query = db.query(Milestone).filter(Milestone.is_deleted == False)
        if semester_id:
            query = query.filter(Milestone.semester_id == semester_id)
        return query.order_by(Milestone.due_date.asc()).all()

    @classmethod
    def create_milestone(
        cls,
        db: Session,
        title: str,
        due_date: datetime,
        max_score: float = 100.0,
        weight_percentage: float = 0.0,
        description: Optional[str] = None,
        semester_id: Optional[str] = None,
        actor_id: Optional[str] = None,
    ) -> Milestone:
        if not semester_id:
            active_sem = SemesterService.get_active_semester(db)
            if active_sem:
                semester_id = active_sem.id

        milestone = Milestone.create(
            db=db,
            title=title.strip(),
            description=description.strip() if description else None,
            due_date=due_date,
            max_score=max_score,
            weight_percentage=weight_percentage,
            semester_id=semester_id,
            status=MilestoneStatus.PENDING.value,
            is_active=True,
        )

        AuditLog.log(
            db=db,
            action="MILESTONE_CREATED",
            user_id=actor_id,
            entity_type="milestone",
            entity_id=milestone.id,
            details=f"Created milestone '{milestone.title}' due {due_date.isoformat()}."
        )

        return milestone

    @classmethod
    def update_milestone(
        cls,
        db: Session,
        milestone_id: str,
        actor_id: Optional[str] = None,
        **kwargs,
    ) -> Milestone:
        milestone = Milestone.fetch_by_id(db, milestone_id)
        updated = Milestone.update(db, milestone_id, **kwargs)

        AuditLog.log(
            db=db,
            action="MILESTONE_UPDATED",
            user_id=actor_id,
            entity_type="milestone",
            entity_id=milestone_id,
            details=f"Updated milestone '{milestone.title}'."
        )

        return updated
