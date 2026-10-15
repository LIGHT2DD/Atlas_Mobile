import os
from typing import Optional
from fastapi import APIRouter, BackgroundTasks, Depends, File, Form, HTTPException, UploadFile
from sqlalchemy.orm import Session

from api.db.database import get_db
from api.v1.models.user import User, UserRole
from api.v1.models.team import Team
from api.v1.models.proposal import Proposal, ProposalVersion, ProposalReview
from api.v1.services.proposal import ProposalService
from api.v1.services.document import DocumentService
from api.mobile.v1.schemas import ProposalSubmitPayload, ProposalReviewPayload
from api.mobile.v1.dependencies import (
    mobile_response, get_current_user_mobile, require_roles_mobile
)


proposals_mobile_router = APIRouter(prefix="/proposals", tags=["Mobile Proposals"])


def _serialize_proposal(proposal: Proposal) -> dict:
    versions = []
    for v in sorted(proposal.versions, key=lambda x: x.version_number, reverse=True):
        versions.append({
            "id": v.id,
            "version_number": v.version_number,
            "title": v.title,
            "abstract": v.abstract,
            "document_path": v.document_path,
            "change_summary": v.change_summary,
            "submitted_by_id": v.submitted_by_id,
            "submitted_by_name": v.submitted_by.full_name if v.submitted_by else "Unknown",
            "submitted_at": str(v.submitted_at) if v.submitted_at else None,
        })

    reviews = []
    for r in sorted(proposal.reviews, key=lambda x: x.created_at or 0, reverse=True):
        reviews.append({
            "id": r.id,
            "reviewer_id": r.reviewer_id,
            "reviewer_name": r.reviewer.full_name if r.reviewer else "Unknown",
            "decision": r.decision,
            "comments": r.comments,
            "created_at": str(r.created_at) if r.created_at else None,
        })

    return {
        "id": proposal.id,
        "team_id": proposal.team_id,
        "team_name": proposal.team.name if proposal.team else "Unknown",
        "title": proposal.title,
        "abstract": proposal.abstract,
        "status": proposal.status,
        "current_version": proposal.current_version,
        "submitted_at": str(proposal.submitted_at) if proposal.submitted_at else None,
        "reviewed_at": str(proposal.reviewed_at) if proposal.reviewed_at else None,
        "versions": versions,
        "reviews": reviews,
    }


@proposals_mobile_router.get("/team/{team_id}")
def get_team_proposal(
    team_id: str,
    current_user: User = Depends(get_current_user_mobile),
    db: Session = Depends(get_db)
):
    """Retrieve full proposal record, versions, and review feedback for a given team."""
    proposal = db.query(Proposal).filter(
        Proposal.team_id == team_id,
        Proposal.is_deleted == False,
    ).first()

    if not proposal:
        return mobile_response(
            data={"has_proposal": False, "proposal": None},
            message="No proposal created for this team yet."
        )

    return mobile_response(
        data={"has_proposal": True, "proposal": _serialize_proposal(proposal)},
        message="Proposal retrieved."
    )


@proposals_mobile_router.post("/submit")
async def submit_proposal(
    team_id: str = Form(...),
    title: str = Form(...),
    abstract: str = Form(...),
    file: Optional[UploadFile] = File(None),
    bg_tasks: BackgroundTasks = None,
    current_user: User = Depends(require_roles_mobile(UserRole.STUDENT.value)),
    db: Session = Depends(get_db)
):
    """Submit a new thesis proposal or a revision after requested changes."""
    # 1. Fetch or draft proposal
    proposal = ProposalService.get_or_create_draft(
        db=db,
        team_id=team_id,
        student_id=current_user.id,
        title=title,
        abstract=abstract,
    )

    document_path = None
    document_id = None
    if file and file.filename:
        # Validate file extension
        ext = os.path.splitext(file.filename)[1].lower()
        if ext not in [".pdf", ".docx", ".doc"]:
            raise HTTPException(status_code=400, detail="Only PDF and Word documents are permitted for proposals.")

        doc = await DocumentService.upload_document(
            db=db,
            file=file,
            title=f"Proposal - {title}",
            project_id=team_id,
            uploaded_by=current_user.id,
            description="Formal thesis proposal document",
            allowed_extensions=[".pdf", ".docx", ".doc"],
        )
        document_id = doc.id
        document_path = doc.file_path

    # 2. Formal state transition submission
    prop, version = ProposalService.submit_proposal(
        db=db,
        proposal_id=proposal.id,
        student_id=current_user.id,
        title=title,
        abstract=abstract,
        document_id=document_id,
        document_path=document_path,
        bg_tasks=bg_tasks,
    )

    return mobile_response(
        data=_serialize_proposal(prop),
        message=f"Proposal v{version.version_number} submitted successfully."
    )


@proposals_mobile_router.post("/{proposal_id}/review")
def review_proposal(
    proposal_id: str,
    payload: ProposalReviewPayload,
    bg_tasks: BackgroundTasks,
    current_user: User = Depends(require_roles_mobile(UserRole.SUPERVISOR.value, UserRole.COORDINATOR.value)),
    db: Session = Depends(get_db)
):
    """Review and transition a submitted proposal (Approve, Request Changes, or Reject)."""
    review = ProposalService.review_proposal(
        db=db,
        proposal_id=proposal_id,
        reviewer_id=current_user.id,
        decision=payload.decision,
        comments=payload.comments or "",
        bg_tasks=bg_tasks,
    )

    return mobile_response(
        data={
            "proposal_id": proposal_id,
            "decision": review.decision,
            "comments": review.comments,
        },
        message=f"Proposal decision '{review.decision}' recorded successfully."
    )
