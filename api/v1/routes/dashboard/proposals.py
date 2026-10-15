import os
from fastapi import APIRouter, BackgroundTasks, Depends, File, Form, HTTPException, Request, UploadFile
from fastapi.responses import RedirectResponse
from sqlalchemy.orm import Session
from typing import Optional

from api.core.dependencies.context import add_template_context
from api.core.dependencies.flash_messages import MessageCategory, flash
from api.db.database import get_db
from api.v1.models.user import User, UserRole
from api.v1.models.team import Team
from api.v1.models.proposal import Proposal, ProposalVersion, ProposalReview, ProposalStatus
from api.v1.models.document import Document
from api.v1.services.proposal import ProposalService
from api.v1.services.team import TeamService
from api.v1.services.document import DocumentService, ALLOWED_EXTENSIONS
from api.v1.routes.dashboard.helpers import (
    _get_user, _is_coordinator, _is_supervisor, _is_student, _is_supervisor_or_coordinator
)
from api.utils.loggers import create_logger

proposals_router = APIRouter(prefix='/proposals', tags=['Proposals'])
logger = create_logger(__name__)


# ─── Proposals Index ───────────────────────────────────
@proposals_router.get('')
@add_template_context('pages/dashboard/proposals/index.html')
async def proposals_index(request: Request, db: Session = Depends(get_db)):
    user = _get_user(request)

    if _is_student(user):
        team = TeamService.get_student_active_team(db, user.id)
        if not team:
            return {
                "page_title": "Thesis Proposal",
                "page_description": "Proposals require an active team",
                "is_student": True,
                "has_team": False,
                "team": None,
                "student_team": None,
                "proposal": None,
            }

        proposal = team.proposal
        if not proposal:
            return {
                "page_title": "Thesis Proposal",
                "page_description": f"Team: {team.name} — Draft your initial thesis proposal",
                "is_student": True,
                "has_team": True,
                "team": team.to_dict(),
                "student_team": team.to_dict(),
                "proposal": None,
            }

        return RedirectResponse(url=f"/dashboard/proposals/{proposal.id}", status_code=303)

    elif _is_supervisor(user):
        # Teams supervised by user
        teams = db.query(Team).filter(Team.supervisor_id == user.id, Team.is_deleted == False).all()
        team_ids = [t.id for t in teams]

        proposals = db.query(Proposal).filter(
            Proposal.team_id.in_(team_ids),
            Proposal.is_deleted == False,
        ).order_by(Proposal.updated_at.desc()).all() if team_ids else []

        return {
            "page_title": "Proposal Reviews",
            "page_description": f"Proposals from your assigned thesis teams ({len(proposals)})",
            "is_student": False,
            "is_supervisor": True,
            "proposals": [p.to_dict() for p in proposals],
        }

    else:
        # Coordinator overview
        proposals = db.query(Proposal).filter(Proposal.is_deleted == False).order_by(Proposal.created_at.desc()).all()
        return {
            "page_title": "All Thesis Proposals",
            "page_description": f"University thesis proposal lifecycle monitoring ({len(proposals)} proposals)",
            "is_student": False,
            "is_coordinator": True,
            "proposals": [p.to_dict() for p in proposals],
        }


# ─── Create / Submit New Proposal ──────────────────────
@proposals_router.get('/new')
@add_template_context('pages/dashboard/proposals/index.html')
async def proposal_new_page(request: Request, db: Session = Depends(get_db)):
    user = _get_user(request)
    if _is_student(user):
        team = TeamService.get_student_active_team(db, user.id)
        if not team:
            return {
                "page_title": "Thesis Proposal",
                "page_description": "Proposals require an active team",
                "is_student": True,
                "has_team": False,
                "team": None,
                "student_team": None,
                "proposal": None,
            }
        if team.proposal:
            return RedirectResponse(url=f"/dashboard/proposals/{team.proposal.id}", status_code=303)
        return {
            "page_title": "Create Thesis Proposal",
            "page_description": f"Team: {team.name} — Draft your initial thesis proposal",
            "is_student": True,
            "has_team": True,
            "team": team.to_dict(),
            "student_team": team.to_dict(),
            "proposal": None,
        }
    return RedirectResponse(url="/dashboard/proposals", status_code=303)


@proposals_router.post('/new')
async def proposal_create(request: Request, bg_tasks: BackgroundTasks, db: Session = Depends(get_db)):
    user = _get_user(request)
    try:
        team = TeamService.get_student_active_team(db, user.id)
        if not team:
            raise HTTPException(status_code=400, detail="You must belong to an active team to submit a proposal.")

        form = await request.form()
        title = form.get('title', '').strip()
        abstract = form.get('abstract', '').strip()
        submit_now = form.get('submit_now') in ('true', 'on', '1', True)
        file = form.get('document')

        if not title:
            raise HTTPException(status_code=400, detail="Proposal title is required.")

        proposal = ProposalService.get_or_create_draft(
            db=db,
            team_id=team.id,
            student_id=user.id,
            title=title,
            abstract=abstract,
        )

        document_id = None
        document_path = None
        if file and hasattr(file, 'filename') and file.filename:
            doc = await DocumentService.upload_document(
                db=db,
                file=file,
                title=f"Proposal v1 - {team.name}",
                project_id=team.id,
                uploaded_by=user.id,
                description="Initial proposal document",
            )
            document_id = doc.id
            document_path = doc.file_path

        if submit_now and team.supervisor_id:
            ProposalService.submit_proposal(
                db=db,
                proposal_id=proposal.id,
                student_id=user.id,
                title=title,
                abstract=abstract,
                document_id=document_id,
                document_path=document_path,
                change_summary="Initial proposal submission",
                bg_tasks=bg_tasks,
            )
            flash(request, "Proposal successfully submitted to your supervisor for review!", MessageCategory.SUCCESS)
        elif submit_now and not team.supervisor_id:
            flash(request, "Proposal saved as Draft. Your team must have an assigned supervisor before formal submission.", MessageCategory.INFO)
        else:
            flash(request, "Proposal draft saved successfully.", MessageCategory.SUCCESS)

        return RedirectResponse(url=f"/dashboard/proposals/{proposal.id}", status_code=303)
    except HTTPException as e:
        flash(request, e.detail, MessageCategory.ERROR)
        return RedirectResponse(url="/dashboard/proposals", status_code=303)


# ─── Create Draft Proposal (Legacy Alias) ──────────────
@proposals_router.post('/new-draft')
async def proposal_create_draft(request: Request, db: Session = Depends(get_db)):
    user = _get_user(request)
    try:
        form = await request.form()
        team_id = form.get('team_id', '').strip()
        title = form.get('title', '').strip()
        abstract = form.get('abstract', '').strip()

        if not team_id:
            team = TeamService.get_student_active_team(db, user.id)
            if team:
                team_id = team.id

        if not team_id or not title:
            raise HTTPException(status_code=400, detail="Team ID and title are required.")

        proposal = ProposalService.get_or_create_draft(
            db=db,
            team_id=team_id,
            student_id=user.id,
            title=title,
            abstract=abstract,
        )

        flash(request, "Proposal draft saved. Complete details and upload document to submit.", MessageCategory.SUCCESS)
        return RedirectResponse(url=f"/dashboard/proposals/{proposal.id}", status_code=303)
    except HTTPException as e:
        flash(request, e.detail, MessageCategory.ERROR)
        return RedirectResponse(url="/dashboard/proposals", status_code=303)


# ─── Proposal Detail & Versions ────────────────────────
@proposals_router.get('/{proposal_id}')
@add_template_context('pages/dashboard/proposals/detail.html')
async def proposal_detail(request: Request, proposal_id: str, db: Session = Depends(get_db)):
    user = _get_user(request)
    proposal = Proposal.fetch_by_id(db, proposal_id)
    team = Team.fetch_by_id(db, proposal.team_id)

    is_member = any(m.user_id == user.id for m in team.members)
    is_supervisor = (team.supervisor_id == user.id)
    is_coord = _is_coordinator(user)

    if not (is_member or is_supervisor or is_coord):
        raise HTTPException(status_code=403, detail="Unauthorized access to this proposal.")

    versions = db.query(ProposalVersion).filter(
        ProposalVersion.proposal_id == proposal.id,
        ProposalVersion.is_deleted == False,
    ).order_by(ProposalVersion.version_number.desc()).all()

    reviews = db.query(ProposalReview).filter(
        ProposalReview.proposal_id == proposal.id,
        ProposalReview.is_deleted == False,
    ).order_by(ProposalReview.created_at.desc()).all()

    can_submit = is_member and proposal.status in (ProposalStatus.DRAFT.value, ProposalStatus.CHANGES_REQUESTED.value)
    can_create_version = is_member and proposal.status == ProposalStatus.CHANGES_REQUESTED.value
    can_review = (is_supervisor or is_coord) and proposal.status == ProposalStatus.SUBMITTED.value
    latest_version = versions[0].to_dict() if versions else None

    return {
        "page_title": proposal.title,
        "page_description": f"Team: {team.name} • Version {proposal.current_version} • Status: {proposal.status.upper()}",
        "proposal": proposal.to_dict(),
        "team": team.to_dict(),
        "versions": [v.to_dict() for v in versions],
        "latest_version": latest_version,
        "reviews": [r.to_dict() for r in reviews],
        "can_submit": can_submit,
        "can_create_version": can_create_version,
        "can_review": can_review,
        "is_member": is_member,
        "is_supervisor": is_supervisor,
        "is_coordinator": is_coord,
        "document_accept": ",".join(f".{ext}" for ext in sorted(ALLOWED_EXTENSIONS)),
    }


# ─── Submit Proposal (Version Increment) ───────────────
@proposals_router.post('/{proposal_id}/submit')
@proposals_router.post('/{proposal_id}/resubmit')
async def proposal_submit(
    proposal_id: str,
    request: Request,
    bg_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
):
    user = _get_user(request)
    try:
        form = await request.form()
        title = form.get('title', '').strip()
        abstract = form.get('abstract', '').strip()
        change_summary = form.get('change_summary', '').strip()
        file = form.get('document')

        proposal = Proposal.fetch_by_id(db, proposal_id)
        team = Team.fetch_by_id(db, proposal.team_id)

        document_id = None
        document_path = None

        # Process document upload if provided
        if file and hasattr(file, 'filename') and file.filename:
            doc = await DocumentService.upload_document(
                db=db,
                file=file,
                title=f"Proposal v{proposal.current_version if proposal.status == ProposalStatus.DRAFT.value else proposal.current_version + 1} - {team.name}",
                project_id=team.id,
                uploaded_by=user.id,
                description=change_summary or "Proposal document",
            )
            document_id = doc.id
            document_path = doc.file_path

        ProposalService.submit_proposal(
            db=db,
            proposal_id=proposal_id,
            student_id=user.id,
            title=title or proposal.title,
            abstract=abstract or proposal.abstract,
            document_id=document_id,
            document_path=document_path,
            change_summary=change_summary,
            bg_tasks=bg_tasks,
        )

        flash(request, "Proposal successfully submitted to your supervisor for review!", MessageCategory.SUCCESS)
    except HTTPException as e:
        logger.warning(f"Proposal submit failed: {e.detail}")
        flash(request, e.detail, MessageCategory.ERROR)
    except Exception as e:
        logger.error(f"Unexpected error submitting proposal {proposal_id}: {e}", exc_info=True)
        flash(request, f"Submission error: {str(e)}", MessageCategory.ERROR)

    return RedirectResponse(url=f"/dashboard/proposals/{proposal_id}", status_code=303)


# ─── Supervisor Review Proposal ────────────────────────
@proposals_router.post('/{proposal_id}/review')
async def proposal_review(
    proposal_id: str,
    request: Request,
    bg_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
):
    user = _get_user(request)
    try:
        if not _is_supervisor_or_coordinator(user):
            logger.warning(f"Forbidden proposal review attempt by user {user.id} ({user.role})")
            raise HTTPException(status_code=403, detail="Only supervisors and coordinators can review proposals.")

        form = await request.form()
        decision = form.get('decision', '').strip().lower()
        comments = form.get('comments', '').strip()

        if not comments:
            raise HTTPException(status_code=400, detail="Review comments are mandatory.")

        ProposalService.review_proposal(
            db=db,
            proposal_id=proposal_id,
            reviewer_id=user.id,
            decision=decision,
            comments=comments,
            bg_tasks=bg_tasks,
        )

        action_labels = {
            'approved': 'approved',
            'changes_requested': 'marked for revisions',
            'rejected': 'rejected',
        }
        flash(request, f"Proposal review submitted: {action_labels.get(decision, decision)}.", MessageCategory.SUCCESS)
    except HTTPException as e:
        logger.warning(f"Proposal review validation failed: {e.detail}")
        flash(request, e.detail, MessageCategory.ERROR)
    except Exception as e:
        logger.error(f"Unexpected error reviewing proposal {proposal_id}: {e}", exc_info=True)
        flash(request, f"Review error: {str(e)}", MessageCategory.ERROR)

    return RedirectResponse(url=f"/dashboard/proposals/{proposal_id}", status_code=303)
