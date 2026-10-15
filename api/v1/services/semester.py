from datetime import datetime
from typing import Optional
from fastapi import HTTPException
from sqlalchemy.orm import Session

from api.v1.models.semester import Semester
from api.v1.models.audit_log import AuditLog
from api.utils.loggers import create_logger

logger = create_logger(__name__)


class SemesterService:

    @classmethod
    def get_active_semester(cls, db: Session) -> Optional[Semester]:
        """Fetch the current active semester."""
        return db.query(Semester).filter(
            Semester.is_active == True,
            Semester.is_deleted == False,
        ).order_by(Semester.created_at.desc()).first()

    @classmethod
    def create_semester(
        cls,
        db: Session,
        name: str,
        academic_year: str,
        start_date: datetime,
        end_date: datetime,
        max_team_size: int = 4,
        min_team_size: int = 1,
        description: Optional[str] = None,
        is_active: bool = True,
        actor_id: Optional[str] = None,
    ) -> Semester:
        if end_date <= start_date:
            raise HTTPException(status_code=400, detail="End date must be after start date.")

        if max_team_size < min_team_size:
            raise HTTPException(status_code=400, detail="Max team size cannot be smaller than min team size.")

        # If marking this semester as active, deactivate other semesters
        if is_active:
            db.query(Semester).filter(Semester.is_active == True).update({"is_active": False})

        semester = Semester.create(
            db=db,
            name=name.strip(),
            academic_year=academic_year.strip(),
            start_date=start_date,
            end_date=end_date,
            max_team_size=max_team_size,
            min_team_size=min_team_size,
            description=description.strip() if description else None,
            is_active=is_active,
        )

        AuditLog.log(
            db=db,
            action="SEMESTER_CREATED",
            user_id=actor_id,
            entity_type="semester",
            entity_id=semester.id,
            details=f"Created semester {semester.name} ({semester.academic_year})"
        )

        return semester

    @classmethod
    def update_semester(
        cls,
        db: Session,
        semester_id: str,
        actor_id: Optional[str] = None,
        **kwargs,
    ) -> Semester:
        semester = Semester.fetch_by_id(db, semester_id)

        if 'is_active' in kwargs and kwargs['is_active']:
            db.query(Semester).filter(
                Semester.id != semester_id,
                Semester.is_active == True,
            ).update({"is_active": False})

        updated = Semester.update(db, semester_id, **kwargs)

        AuditLog.log(
            db=db,
            action="SEMESTER_UPDATED",
            user_id=actor_id,
            entity_type="semester",
            entity_id=semester_id,
            details=f"Updated semester {semester.name}"
        )

        return updated
