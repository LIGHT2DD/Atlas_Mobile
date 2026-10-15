import sqlalchemy as sa
from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Request
from fastapi.responses import RedirectResponse
from sqlalchemy.orm import Session

from api.core.dependencies.context import add_template_context
from api.core.dependencies.flash_messages import MessageCategory, flash
from api.db.database import get_db
from api.utils import paginator
from api.utils.loggers import create_logger
from api.v1.models.user import User, UserRole
from api.v1.models.project import Project
from api.v1.models.project_member import ProjectMember
from api.v1.models.team import Team
from api.v1.models.team_member import TeamMember
from api.v1.models.submission import Submission, SubmissionStatus
from api.v1.models.milestone import Milestone
from api.v1.models.document import Document
from api.v1.models.feedback import Feedback
from api.v1.models.notification import NotificationType
from api.v1.services.project import ProjectService
from api.v1.services.notification import NotificationService
from api.utils.firebase_service import FirebaseService
from api.v1.routes.dashboard.helpers import (
    _get_user, _paginate, _is_coordinator, _is_supervisor, _is_student, _is_supervisor_or_coordinator
)


submissions_router = APIRouter(prefix='/submissions', tags=['Submissions'])
logger = create_logger(__name__)


# ─── List ─────────────────────────────────────────────

@submissions_router.get('')
@add_template_context('pages/dashboard/submissions/index.html')
async def submissions_list(request: Request, db: Session = Depends(get_db)):
    user = _get_user(request)
    page, size = _paginate(request, '/dashboard/submissions')

    if _is_coordinator(user):
        _, items, count = Submission.all(db, page=page, per_page=size)
        response = paginator.build_paginated_response(
            items=[s.to_dict() for s in items],
            endpoint='/dashboard/submissions', total=count, page=page, size=size,
        )
    elif _is_supervisor(user):
        project_ids = [
            p.id for p in db.query(Project.id).filter(
                Project.supervisor_id == user.id, Project.is_deleted == False,
            ).all()
        ]
        team_ids = [
            t.id for t in db.query(Team.id).filter(
                Team.supervisor_id == user.id, Team.is_deleted == False,
            ).all()
        ]
        filters = []
        if project_ids:
            filters.append(Submission.project_id.in_(project_ids))
        if team_ids:
            filters.append(Submission.team_id.in_(team_ids))

        if filters:
            query = db.query(Submission).filter(
                sa.or_(*filters),
                Submission.is_deleted == False,
            ).order_by(Submission.created_at.desc())
            count = query.count()
            offset = (page - 1) * size
            items = query.offset(offset).limit(size).all()
        else:
            items, count = [], 0

        response = paginator.build_paginated_response(
            items=[s.to_dict() for s in items],
            endpoint='/dashboard/submissions', total=count, page=page, size=size,
        )
    else:
        # Student: submissions submitted by user or by user's teams
        team_ids = [
            m.team_id for m in db.query(TeamMember.team_id).filter(
                TeamMember.user_id == user.id, TeamMember.is_deleted == False,
            ).all()
        ]
        filters = [Submission.submitted_by == user.id]
        if team_ids:
            filters.append(Submission.team_id.in_(team_ids))

        query = db.query(Submission).filter(
            sa.or_(*filters),
            Submission.is_deleted == False,
        ).order_by(Submission.created_at.desc())
        count = query.count()
        offset = (page - 1) * size
        items = query.offset(offset).limit(size).all()

        response = paginator.build_paginated_response(
            items=[s.to_dict() for s in items],
            endpoint='/dashboard/submissions', total=count, page=page, size=size,
        )

    # Map project and team titles and submitter names
    project_ids = list(set(s.get('project_id') for s in response['data'] if s.get('project_id')))
    team_ids = list(set(s.get('team_id') for s in response['data'] if s.get('team_id')))
    submitter_ids = list(set(s.get('submitted_by') for s in response['data'] if s.get('submitted_by')))

    project_map = {}
    submitter_map = {}

    if project_ids:
        for p in db.query(Project).filter(Project.id.in_(project_ids)).all():
            project_map[p.id] = p.title
    if team_ids:
        for t in db.query(Team).filter(Team.id.in_(team_ids)).all():
            project_map[t.id] = t.name
    if submitter_ids:
        for u in db.query(User).filter(User.id.in_(submitter_ids)).all():
            submitter_map[u.id] = f"{u.first_name} {u.last_name}"

    return {
        "page_title": "Reviews" if _is_supervisor(user) else "Submissions",
        "page_description": "View and manage submissions",
        "submissions": response['data'],
        "pagination_data": response['pagination_data'],
        "project_map": project_map,
        "submitter_map": submitter_map,
    }


# ─── Create ───────────────────────────────────────────

@submissions_router.get('/new')
@add_template_context('pages/dashboard/submissions/create.html')
async def submission_create_page(request: Request, db: Session = Depends(get_db)):
    user = _get_user(request)

    # Get projects user is a member of
    if _is_coordinator(user):
        projects = db.query(Project).filter(Project.is_deleted == False).all()
    else:
        member_records = db.query(ProjectMember).filter(
            ProjectMember.user_id == user.id, ProjectMember.is_deleted == False,
        ).all()
        project_ids = [m.project_id for m in member_records]
        projects = db.query(Project).filter(
            Project.id.in_(project_ids), Project.is_deleted == False,
        ).all() if project_ids else []

    # Pre-select project if passed in query
    selected_project = request.query_params.get('project_id', '')

    # Build per-project documents & milestones map for JS
    project_documents = {}
    project_milestones = {}
    for p in projects:
        docs = db.query(Document).filter(
            Document.project_id == p.id, Document.is_deleted == False,
        ).order_by(Document.created_at.desc()).all()
        project_documents[p.id] = [d.to_dict() for d in docs]

        mstones = db.query(Milestone).filter(
            Milestone.project_id == p.id, Milestone.is_deleted == False,
        ).order_by(Milestone.due_date).all()
        project_milestones[p.id] = [m.to_dict() for m in mstones]

    return {
        "page_title": "New Submission",
        "page_description": "Submit your work",
        "projects": projects,
        "selected_project": selected_project,
        "project_documents": project_documents,
        "project_milestones": project_milestones,
    }


@submissions_router.post('/new')
async def submission_create(request: Request, bg_tasks: BackgroundTasks, db: Session = Depends(get_db)):
    user = _get_user(request)
    try:
        payload = await request.form()
        title = payload.get('title', '').strip()
        description = payload.get('description', '').strip()
        project_id = payload.get('project_id')
        milestone_id = payload.get('milestone_id') or None

        if not title or not project_id:
            raise HTTPException(400, "Title and project are required")

        # Handle document: either upload new or select existing
        document_id = None
        doc_source = payload.get('doc_source', 'none')  # 'none', 'upload', 'existing'

        if doc_source == 'upload':
            file = payload.get('file')
            if file and hasattr(file, 'filename') and file.filename:
                doc_title = payload.get('doc_title', '').strip() or file.filename
                document = await FirebaseService.upload_document(
                    db=db,
                    file=file,
                    title=doc_title,
                    project_id=project_id,
                    uploaded_by=user.id,
                    description=f"Uploaded with submission: {title}",
                    milestone_id=milestone_id,
                )
                document_id = document.id
            else:
                raise HTTPException(400, "Please select a file to upload")
        elif doc_source == 'existing':
            existing_doc_id = payload.get('existing_document_id', '').strip()
            if existing_doc_id:
                # Verify the document belongs to this project
                doc = Document.fetch_one_by_field(
                    db, throw_error=False,
                    id=existing_doc_id, project_id=project_id,
                )
                if not doc:
                    raise HTTPException(400, "Selected document not found in this project")
                document_id = existing_doc_id
            else:
                raise HTTPException(400, "Please select an existing document")

        submission = Submission.create(
            db=db,
            title=title,
            description=description,
            project_id=project_id,
            milestone_id=milestone_id,
            submitted_by=user.id,
            document_id=document_id,
            status=SubmissionStatus.SUBMITTED.value,
        )

        # Notify supervisor about new submission
        project = Project.fetch_by_id(db, project_id)
        if project.supervisor_id:
            NotificationService.notify(
                db=db, bg_tasks=bg_tasks, user_id=project.supervisor_id,
                title="New Submission",
                content=f"{user.full_name} submitted \"{title}\" for project \"{project.title}\".",
                notification_type=NotificationType.SUBMISSION.value,
                link=f"/dashboard/submissions/{submission.id}",
            )

        flash(request, 'Submission created successfully', MessageCategory.SUCCESS)
        return RedirectResponse(url=f"/dashboard/submissions/{submission.id}", status_code=303)
    except HTTPException as e:
        flash(request, e.detail, MessageCategory.ERROR)
        return RedirectResponse(url="/dashboard/submissions/new", status_code=303)


# ─── Detail ───────────────────────────────────────────

@submissions_router.get('/{submission_id}')
@add_template_context('pages/dashboard/submissions/detail.html')
async def submission_detail(request: Request, submission_id: str, db: Session = Depends(get_db)):
    user = _get_user(request)
    submission = Submission.fetch_by_id(db, submission_id)

    team = None
    if submission.team_id:
        team = Team.fetch_one_by_field(db, throw_error=False, id=submission.team_id)

    project = None
    if submission.project_id:
        project = Project.fetch_one_by_field(db, throw_error=False, id=submission.project_id)

    submitter = User.fetch_one_by_field(db, throw_error=False, id=submission.submitted_by)

    # Associated document
    document = None
    if submission.document_id:
        document = Document.fetch_one_by_field(db, throw_error=False, id=submission.document_id)

    # Milestone
    milestone = None
    if submission.milestone_id:
        milestone = Milestone.fetch_one_by_field(db, throw_error=False, id=submission.milestone_id)

    # Feedback for this submission
    feedbacks = db.query(Feedback, User).join(
        User, Feedback.given_by == User.id
    ).filter(
        Feedback.submission_id == submission_id,
        Feedback.is_deleted == False,
    ).order_by(Feedback.created_at.desc()).all()

    feedback_list = [{
        "feedback": f.to_dict(),
        "reviewer": u.to_dict(),
    } for f, u in feedbacks]

    status_choices = [s.value for s in SubmissionStatus]
    can_review = _is_supervisor_or_coordinator(user)

    project_data = {
        "id": team.id if team else (project.id if project else ""),
        "title": team.name if team else (project.title if project else "Thesis Project"),
        "name": team.name if team else (project.title if project else "Thesis Project"),
    }
    if project:
        project_data = project.to_dict()

    return {
        "page_title": submission.title,
        "page_description": "Submission details",
        "submission": submission.to_dict(),
        "team": team.to_dict() if team else None,
        "project": project_data,
        "submitter": submitter.to_dict() if submitter else {"first_name": "Student", "last_name": ""},
        "document": document.to_dict() if document else None,
        "milestone": milestone.to_dict() if milestone else None,
        "feedbacks": feedback_list,
        "status_choices": status_choices,
        "can_review": can_review,
    }


# ─── Edit ─────────────────────────────────────────────

@submissions_router.get('/{submission_id}/edit')
@add_template_context('pages/dashboard/submissions/edit.html')
async def submission_edit_page(request: Request, submission_id: str, db: Session = Depends(get_db)):
    user = _get_user(request)
    submission = Submission.fetch_by_id(db, submission_id)

    # Only submitter or coordinator/admin can edit
    if submission.submitted_by != user.id and not _is_coordinator(user):
        logger.warning(f"Unauthorized edit attempt on submission {submission_id} by user {user.id}")
        raise HTTPException(403, "You can only edit your own submissions")

    team = None
    if submission.team_id:
        team = Team.fetch_one_by_field(db, throw_error=False, id=submission.team_id)

    project = None
    if submission.project_id:
        project = Project.fetch_one_by_field(db, throw_error=False, id=submission.project_id)

    milestones = []
    if submission.milestone_id:
        m = Milestone.fetch_one_by_field(db, throw_error=False, id=submission.milestone_id)
        if m:
            milestones.append(m)
    if submission.project_id:
        proj_ms = db.query(Milestone).filter(
            Milestone.project_id == submission.project_id,
            Milestone.is_deleted == False,
        ).all()
        milestones = list({m.id: m for m in (milestones + proj_ms)}.values())

    # Current document
    current_document = None
    if submission.document_id:
        current_document = Document.fetch_one_by_field(db, throw_error=False, id=submission.document_id)

    # Available documents
    documents = []
    if submission.project_id:
        documents = db.query(Document).filter(
            Document.project_id == submission.project_id,
            Document.is_deleted == False,
        ).order_by(Document.created_at.desc()).all()

    project_data = {
        "id": team.id if team else (project.id if project else ""),
        "title": team.name if team else (project.title if project else "Thesis Project"),
    }
    if project:
        project_data = project.to_dict()

    return {
        "page_title": f"Edit: {submission.title}",
        "page_description": "Edit submission",
        "submission": submission.to_dict(),
        "team": team.to_dict() if team else None,
        "project": project_data,
        "milestones": milestones,
        "current_document": current_document.to_dict() if current_document else None,
        "documents": [d.to_dict() for d in documents],
    }


@submissions_router.post('/{submission_id}/edit')
async def submission_edit(request: Request, submission_id: str, bg_tasks: BackgroundTasks, db: Session = Depends(get_db)):
    user = _get_user(request)
    try:
        submission = Submission.fetch_by_id(db, submission_id)

        if submission.submitted_by != user.id and not _is_coordinator(user):
            logger.warning(f"Forbidden edit attempt on submission {submission_id} by user {user.id}")
            raise HTTPException(403, "You can only edit your own submissions")

        payload = await request.form()
        update_data = {}

        title = payload.get('title', '').strip()
        if title:
            update_data['title'] = title

        description = payload.get('description', '')
        update_data['description'] = description.strip()

        milestone_id = payload.get('milestone_id')
        update_data['milestone_id'] = milestone_id or None

        # Handle document change
        doc_source = payload.get('doc_source', 'keep')  # 'keep', 'upload', 'existing', 'remove'

        if doc_source == 'upload':
            file = payload.get('file')
            if file and hasattr(file, 'filename') and file.filename:
                doc_title = payload.get('doc_title', '').strip() or file.filename
                document = await FirebaseService.upload_document(
                    db=db,
                    file=file,
                    title=doc_title,
                    project_id=submission.project_id,
                    uploaded_by=user.id,
                    description=f"Uploaded with submission: {title or submission.title}",
                    milestone_id=update_data.get('milestone_id', submission.milestone_id),
                )
                update_data['document_id'] = document.id
        elif doc_source == 'existing':
            existing_doc_id = payload.get('existing_document_id', '').strip()
            if existing_doc_id:
                doc = Document.fetch_one_by_field(
                    db, throw_error=False,
                    id=existing_doc_id,
                )
                if doc:
                    update_data['document_id'] = existing_doc_id
        elif doc_source == 'remove':
            update_data['document_id'] = None

        Submission.update(db, submission_id, **update_data)

        # Notify supervisor about submission update
        supervisor_id = None
        context_name = "Thesis Project"
        if submission.team_id:
            team = Team.fetch_one_by_field(db, throw_error=False, id=submission.team_id)
            if team and team.supervisor_id:
                supervisor_id = team.supervisor_id
                context_name = team.name
        elif submission.project_id:
            project = Project.fetch_one_by_field(db, throw_error=False, id=submission.project_id)
            if project and project.supervisor_id:
                supervisor_id = project.supervisor_id
                context_name = project.title

        if supervisor_id and supervisor_id != user.id:
            NotificationService.notify(
                db=db, bg_tasks=bg_tasks, user_id=supervisor_id,
                title="Submission Updated",
                content=f"{user.full_name} updated the submission \"{title or submission.title}\" for \"{context_name}\".",
                notification_type=NotificationType.SUBMISSION.value,
                link=f"/dashboard/submissions/{submission_id}",
            )

        flash(request, 'Submission updated successfully', MessageCategory.SUCCESS)
        return RedirectResponse(url=f"/dashboard/submissions/{submission_id}", status_code=303)
    except HTTPException as e:
        logger.warning(f"Submission edit failed: {e.detail}")
        flash(request, e.detail, MessageCategory.ERROR)
        return RedirectResponse(url=f"/dashboard/submissions/{submission_id}/edit", status_code=303)
    except Exception as e:
        logger.error(f"Unexpected error editing submission {submission_id}: {e}", exc_info=True)
        flash(request, f"Update failed: {str(e)}", MessageCategory.ERROR)
        return RedirectResponse(url=f"/dashboard/submissions/{submission_id}/edit", status_code=303)


# ─── Update Status (Review) ──────────────────────────

@submissions_router.post('/{submission_id}/status')
async def submission_update_status(request: Request, submission_id: str, bg_tasks: BackgroundTasks, db: Session = Depends(get_db)):
    user = _get_user(request)
    try:
        if not _is_supervisor_or_coordinator(user):
            logger.warning(f"Forbidden review attempt on submission {submission_id} by user {user.id} ({user.role})")
            raise HTTPException(403, "Only supervisors and coordinators can review submissions")

        payload = await request.form()
        status = payload.get('status', '').strip()
        if status not in [s.value for s in SubmissionStatus]:
            raise HTTPException(400, "Invalid status")

        Submission.update(db, submission_id, status=status)

        # Notify the submitter about status change
        submission = Submission.fetch_by_id(db, submission_id)
        status_label = status.replace("_", " ").title()
        NotificationService.notify(
            db=db, bg_tasks=bg_tasks, user_id=submission.submitted_by,
            title=f"Submission {status_label}",
            content=f"Your submission \"{submission.title}\" has been marked as {status_label} by {user.full_name}.",
            notification_type=NotificationType.SUBMISSION.value,
            link=f"/dashboard/submissions/{submission_id}",
        )

        flash(request, f'Submission marked as {status_label}', MessageCategory.SUCCESS)
    except HTTPException as e:
        logger.warning(f"Submission status update failed: {e.detail}")
        flash(request, e.detail, MessageCategory.ERROR)
    except Exception as e:
        logger.error(f"Unexpected error updating submission status: {e}", exc_info=True)
        flash(request, f"Status update failed: {str(e)}", MessageCategory.ERROR)
    return RedirectResponse(url=f"/dashboard/submissions/{submission_id}", status_code=303)


# ─── Delete ───────────────────────────────────────────

@submissions_router.post('/{submission_id}/delete')
async def submission_delete(request: Request, submission_id: str, db: Session = Depends(get_db)):
    user = _get_user(request)
    try:
        submission = Submission.fetch_by_id(db, submission_id)
        if submission.submitted_by != user.id and not _is_coordinator(user):
            logger.warning(f"Forbidden delete attempt on submission {submission_id} by user {user.id}")
            raise HTTPException(403, "You can only delete your own submissions")

        Submission.soft_delete(db, submission_id)
        flash(request, 'Submission deleted successfully', MessageCategory.SUCCESS)
        return RedirectResponse(url="/dashboard/submissions", status_code=303)
    except HTTPException as e:
        logger.warning(f"Submission delete failed: {e.detail}")
        flash(request, e.detail, MessageCategory.ERROR)
        return RedirectResponse(url=f"/dashboard/submissions/{submission_id}", status_code=303)
    except Exception as e:
        logger.error(f"Unexpected error deleting submission {submission_id}: {e}", exc_info=True)
        flash(request, f"Delete failed: {str(e)}", MessageCategory.ERROR)
        return RedirectResponse(url=f"/dashboard/submissions/{submission_id}", status_code=303)
