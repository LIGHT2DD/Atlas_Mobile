import os
from typing import Optional
from fastapi import APIRouter, BackgroundTasks, Depends, File, Form, HTTPException, UploadFile
from sqlalchemy.orm import Session

from api.db.database import get_db
from api.v1.models.user import User, UserRole
from api.v1.models.submission import Submission
from api.v1.services.submission import SubmissionService
from api.v1.services.document import DocumentService
from api.mobile.v1.schemas import SubmissionGradePayload
from api.mobile.v1.dependencies import (
    mobile_response, get_current_user_mobile, require_roles_mobile
)


submissions_mobile_router = APIRouter(prefix="/submissions", tags=["Mobile Submissions"])


def _serialize_submission(s: Submission) -> dict:
    return {
        "id": s.id,
        "title": s.title,
        "description": s.description,
        "milestone_id": s.milestone_id,
        "milestone_title": s.milestone.title if s.milestone else None,
        "team_id": s.team_id,
        "team_name": s.team.name if s.team else None,
        "submitted_by_id": s.submitted_by,
        "submitted_by_name": s.submitter.full_name if s.submitter else "Unknown",
        "code_url": s.code_url,
        "file_path": s.file_path,
        "version": s.version,
        "is_late": s.is_late,
        "status": s.status,
        "score": s.score,
        "feedback": s.feedback,
        "submitted_at": str(s.submitted_at) if s.submitted_at else None,
    }


@submissions_mobile_router.get("/team/{team_id}")
def list_team_submissions(
    team_id: str,
    current_user: User = Depends(get_current_user_mobile),
    db: Session = Depends(get_db)
):
    """List all deliverable submissions made by a specific team."""
    submissions = db.query(Submission).filter(
        Submission.team_id == team_id,
        Submission.is_deleted == False,
    ).order_by(Submission.submitted_at.desc()).all()

    items = [_serialize_submission(s) for s in submissions]
    return mobile_response(data=items, message="Team submissions retrieved.")


@submissions_mobile_router.get("/{submission_id}")
def get_submission_details(
    submission_id: str,
    current_user: User = Depends(get_current_user_mobile),
    db: Session = Depends(get_db)
):
    """Retrieve full details of a specific milestone submission."""
    sub = Submission.fetch_by_id(db, submission_id)
    return mobile_response(data=_serialize_submission(sub), message="Submission details retrieved.")


@submissions_mobile_router.post("")
async def create_submission(
    milestone_id: str = Form(...),
    team_id: str = Form(...),
    title: str = Form(...),
    description: Optional[str] = Form(None),
    code_url: Optional[str] = Form(None),
    file: Optional[UploadFile] = File(None),
    bg_tasks: BackgroundTasks = None,
    current_user: User = Depends(require_roles_mobile(UserRole.STUDENT.value)),
    db: Session = Depends(get_db)
):
    """Submit a milestone deliverable with optional document attachment and code repository URL."""
    document_id = None
    file_path = None
    if file and file.filename:
        doc = await DocumentService.upload_document(
            db=db,
            file=file,
            title=f"Submission - {title}",
            project_id=team_id,
            uploaded_by=current_user.id,
            description=description,
            milestone_id=milestone_id,
        )
        document_id = doc.id
        file_path = doc.file_path

    submission = SubmissionService.create_submission(
        db=db,
        milestone_id=milestone_id,
        team_id=team_id,
        submitted_by=current_user.id,
        title=title,
        description=description,
        document_id=document_id,
        file_path=file_path,
        code_url=code_url,
        bg_tasks=bg_tasks,
    )

    return mobile_response(
        data=_serialize_submission(submission),
        message="Deliverable submitted successfully.",
        status_code=201
    )


@submissions_mobile_router.post("/{submission_id}/grade")
def grade_submission(
    submission_id: str,
    payload: SubmissionGradePayload,
    bg_tasks: BackgroundTasks,
    current_user: User = Depends(require_roles_mobile(UserRole.SUPERVISOR.value, UserRole.COORDINATOR.value)),
    db: Session = Depends(get_db)
):
    """Supervisor/Coordinator endpoint to score and provide critique on a deliverable."""
    submission = SubmissionService.grade_submission(
        db=db,
        submission_id=submission_id,
        reviewer_id=current_user.id,
        score=payload.score,
        feedback_text=payload.feedback_text,
        bg_tasks=bg_tasks,
    )

    return mobile_response(
        data=_serialize_submission(submission),
        message="Submission graded successfully."
    )
