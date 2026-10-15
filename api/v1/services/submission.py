from datetime import datetime, timezone
from typing import Optional, List
from fastapi import HTTPException
from sqlalchemy.orm import Session

from api.v1.models.user import User, UserRole
from api.v1.models.team import Team
from api.v1.models.milestone import Milestone
from api.v1.models.submission import Submission, SubmissionStatus
from api.v1.models.document import Document
from api.v1.models.feedback import Feedback
from api.v1.models.audit_log import AuditLog
from api.v1.models.notification import NotificationType
from api.v1.services.notification import NotificationService
from api.utils.loggers import create_logger

logger = create_logger(__name__)


class SubmissionService:

    @classmethod
    def create_submission(
        cls,
        db: Session,
        milestone_id: str,
        team_id: str,
        submitted_by: Optional[str] = None,
        title: str = "Submission",
        description: Optional[str] = None,
        document_id: Optional[str] = None,
        file_path: Optional[str] = None,
        code_url: Optional[str] = None,
        bg_tasks=None,
        submitted_by_id: Optional[str] = None,
    ) -> Submission:
        actual_submitter = submitted_by or submitted_by_id
        if not actual_submitter:
            raise HTTPException(status_code=400, detail="Submitter user ID required.")
        team = Team.fetch_by_id(db, team_id)
        is_member = any(m.user_id == actual_submitter for m in team.members)
        if not is_member:
            raise HTTPException(status_code=403, detail="You must belong to this team to submit deliverables.")

        milestone = Milestone.fetch_by_id(db, milestone_id)

        now = datetime.now(timezone.utc)
        due = milestone.due_date
        if due.tzinfo is None:
            due = due.replace(tzinfo=timezone.utc)

        # Authoritative backend late determination
        is_late = now > due
        status = SubmissionStatus.LATE.value if is_late else SubmissionStatus.SUBMITTED.value

        # Determine version for this milestone
        existing_count = db.query(Submission).filter(
            Submission.team_id == team_id,
            Submission.milestone_id == milestone_id,
            Submission.is_deleted == False,
        ).count()
        version = existing_count + 1

        submission = Submission.create(
            db=db,
            title=title.strip(),
            description=description.strip() if description else None,
            milestone_id=milestone_id,
            team_id=team_id,
            submitted_by=actual_submitter,
            document_id=document_id,
            file_path=file_path,
            code_url=code_url.strip() if code_url else None,
            version=version,
            is_late=is_late,
            status=status,
            submitted_at=now,
        )

        submitter = User.fetch_by_id(db, actual_submitter)

        # Notify supervisor
        if team.supervisor_id:
            late_text = " (LATE)" if is_late else ""
            NotificationService.notify(
                db=db,
                bg_tasks=bg_tasks,
                user_id=team.supervisor_id,
                title=f"New Deliverable Submitted{late_text}",
                content=f"Team '{team.name}' submitted deliverable for milestone '{milestone.title}' (v{version}).",
                notification_type=NotificationType.SUBMISSION.value,
                link=f"/dashboard/submissions/{submission.id}",
            )

        AuditLog.log(
            db=db,
            action="DELIVERABLE_SUBMITTED",
            user_id=actual_submitter,
            entity_type="submission",
            entity_id=submission.id,
            details=f"Team '{team.name}' submitted milestone '{milestone.title}' v{version}{' (LATE)' if is_late else ''}."
        )

        return submission

    @classmethod
    def grade_submission(
        cls,
        db: Session,
        submission_id: str,
        reviewer_id: str,
        score: float,
        feedback_text: Optional[str] = None,
        bg_tasks=None,
        feedback: Optional[str] = None,
    ) -> Submission:
        actual_feedback = feedback_text or feedback
        submission = Submission.fetch_by_id(db, submission_id)
        team = Team.fetch_by_id(db, submission.team_id) if submission.team_id else None
        reviewer = User.fetch_by_id(db, reviewer_id)

        if team and team.supervisor_id != reviewer_id and not reviewer.is_coordinator:
            raise HTTPException(status_code=403, detail="Only assigned supervisor or coordinator can grade this submission.")

        milestone = Milestone.fetch_by_id(db, submission.milestone_id) if submission.milestone_id else None
        max_possible = milestone.max_score if milestone else 100.0

        if score < 0 or score > max_possible:
            raise HTTPException(
                status_code=400,
                detail=f"Score must be between 0 and {max_possible}."
            )

        submission.score = score
        submission.feedback = actual_feedback.strip() if actual_feedback else None
        submission.status = SubmissionStatus.REVIEWED.value
        db.commit()

        # Record feedback entry
        Feedback.create(
            db=db,
            content=feedback_text.strip() if feedback_text else f"Graded: {score}/{max_possible}",
            grade=f"{score}/{max_possible}",
            submission_id=submission.id,
            project_id=submission.project_id or (team.id if team else ""),
            given_by=reviewer_id,
        )

        # Notify team members
        if team:
            member_ids = [m.user_id for m in team.members]
            NotificationService.notify_many(
                db=db,
                bg_tasks=bg_tasks,
                user_ids=member_ids,
                title="Deliverable Graded",
                content=f"Your submission '{submission.title}' was reviewed by {reviewer.full_name}. Score: {score}/{max_possible}.",
                notification_type=NotificationType.FEEDBACK.value,
                link=f"/dashboard/submissions/{submission.id}",
            )

        AuditLog.log(
            db=db,
            action="SUBMISSION_GRADED",
            user_id=reviewer_id,
            entity_type="submission",
            entity_id=submission.id,
            details=f"Reviewer {reviewer.full_name} graded submission '{submission.title}' with {score}/{max_possible}."
        )

        return submission
