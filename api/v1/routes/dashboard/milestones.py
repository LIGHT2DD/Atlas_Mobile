from datetime import datetime, timezone

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Request
from fastapi.responses import RedirectResponse
from sqlalchemy.orm import Session

from api.core.dependencies.flash_messages import MessageCategory, flash
from api.db.database import get_db
from api.utils.loggers import create_logger
from api.v1.models.user import UserRole
from api.v1.models.project import Project
from api.v1.models.project_member import ProjectMember, ProjectMemberRole
from api.v1.models.milestone import Milestone, MilestoneStatus
from api.v1.models.notification import NotificationType
from api.v1.services.notification import NotificationService
from api.v1.routes.dashboard.helpers import _get_user


from api.core.dependencies.context import add_template_context
from api.v1.services.milestone import MilestoneService
from api.v1.services.semester import SemesterService
from api.v1.services.team import TeamService
from api.v1.models.submission import Submission
from api.v1.routes.dashboard.helpers import (
    _get_user, _is_coordinator, _is_supervisor, _is_student, _require_coordinator
)

project_milestones_router = APIRouter(prefix='/projects/{project_id}/milestones', tags=['Milestones'])
milestones_router = APIRouter(prefix='/milestones', tags=['Milestones'])
deadlines_router = APIRouter(prefix='/deadlines', tags=['Deadlines'])
logger = create_logger(__name__)



def _can_manage_project(db, user, project_id):
    """Check if user can manage milestones for this project."""
    if _is_coordinator(user):
        return True
    # Check if owner
    member = ProjectMember.fetch_one_by_field(
        db, throw_error=False, project_id=project_id, user_id=user.id
    )
    if member and member.role == ProjectMemberRole.OWNER.value:
        return True
    # Supervisor of this project
    project = Project.fetch_by_id(db, project_id)
    return project.supervisor_id == user.id


def _get_project_member_ids(db, project_id):
    """Get all member IDs + supervisor ID for a project."""
    member_ids = [m.user_id for m in db.query(ProjectMember).filter(
        ProjectMember.project_id == project_id, ProjectMember.is_deleted == False
    ).all()]
    project = Project.fetch_by_id(db, project_id)
    if project.supervisor_id and project.supervisor_id not in member_ids:
        member_ids.append(project.supervisor_id)
    return member_ids


# ─── Create ───────────────────────────────────────────

@project_milestones_router.post('/new')
async def milestone_create(request: Request, project_id: str, bg_tasks: BackgroundTasks, db: Session = Depends(get_db)):
    user = _get_user(request)
    try:
        if not _can_manage_project(db, user, project_id):
            raise HTTPException(403, "You don't have permission to add milestones")

        payload = await request.form()
        title = payload.get('title', '').strip()
        description = payload.get('description', '').strip()
        due_date = payload.get('due_date', '').strip()

        if not title or not due_date:
            raise HTTPException(400, "Title and due date are required")

        try:
            parsed_due_date = datetime.fromisoformat(due_date)
        except ValueError:
            raise HTTPException(400, "Invalid date format")

        if parsed_due_date.date() < datetime.now().date():
            raise HTTPException(400, "Milestone due date cannot be in the past")

        Milestone.create(
            db=db,
            title=title,
            description=description,
            due_date=parsed_due_date,
            project_id=project_id,
            status=MilestoneStatus.PENDING.value,
        )

        # Notify project members
        project = Project.fetch_by_id(db, project_id)
        member_ids = _get_project_member_ids(db, project_id)
        NotificationService.notify_many(
            db=db, bg_tasks=bg_tasks, user_ids=member_ids,
            title="New Milestone Added",
            content=f"{user.full_name} added a new milestone \"{title}\" to project \"{project.title}\" (due {due_date}).",
            notification_type=NotificationType.MILESTONE.value,
            link=f"/dashboard/projects/{project_id}",
            exclude_user_id=user.id,
        )

        flash(request, 'Milestone created successfully', MessageCategory.SUCCESS)
    except HTTPException as e:
        flash(request, e.detail, MessageCategory.ERROR)
    return RedirectResponse(url=f"/dashboard/projects/{project_id}", status_code=303)


# ─── Update ───────────────────────────────────────────

@project_milestones_router.post('/{milestone_id}/edit')
async def milestone_edit(request: Request, project_id: str, milestone_id: str, bg_tasks: BackgroundTasks, db: Session = Depends(get_db)):
    user = _get_user(request)
    try:
        if not _can_manage_project(db, user, project_id):
            raise HTTPException(403, "You don't have permission to edit milestones")

        payload = await request.form()
        update_data = {}

        title = payload.get('title', '').strip()
        if title:
            update_data['title'] = title

        description = payload.get('description', '')
        update_data['description'] = description.strip()

        due_date = payload.get('due_date', '').strip()
        if due_date:
            try:
                parsed_due_date = datetime.fromisoformat(due_date)
            except ValueError:
                raise HTTPException(400, "Invalid date format")
            if parsed_due_date.date() < datetime.now().date():
                raise HTTPException(400, "Milestone due date cannot be in the past")
            update_data['due_date'] = parsed_due_date

        status = payload.get('status', '').strip()
        if status and status in [s.value for s in MilestoneStatus]:
            update_data['status'] = status

        Milestone.update(db, milestone_id, **update_data)

        # Notify project members
        milestone = Milestone.fetch_by_id(db, milestone_id)
        project = Project.fetch_by_id(db, project_id)
        member_ids = _get_project_member_ids(db, project_id)
        NotificationService.notify_many(
            db=db, bg_tasks=bg_tasks, user_ids=member_ids,
            title="Milestone Updated",
            content=f"{user.full_name} updated the milestone \"{milestone.title}\" in project \"{project.title}\".",
            notification_type=NotificationType.MILESTONE.value,
            link=f"/dashboard/projects/{project_id}",
            exclude_user_id=user.id,
        )

        flash(request, 'Milestone updated successfully', MessageCategory.SUCCESS)
    except HTTPException as e:
        flash(request, e.detail, MessageCategory.ERROR)
    return RedirectResponse(url=f"/dashboard/projects/{project_id}", status_code=303)


# ─── Update Status ────────────────────────────────────

@project_milestones_router.post('/{milestone_id}/status')
async def milestone_update_status(request: Request, project_id: str, milestone_id: str, bg_tasks: BackgroundTasks, db: Session = Depends(get_db)):
    user = _get_user(request)
    try:
        payload = await request.form()
        status = payload.get('status', '').strip()
        if status not in [s.value for s in MilestoneStatus]:
            raise HTTPException(400, "Invalid status")

        Milestone.update(db, milestone_id, status=status)

        # Notify project members
        milestone = Milestone.fetch_by_id(db, milestone_id)
        project = Project.fetch_by_id(db, project_id)
        member_ids = _get_project_member_ids(db, project_id)
        status_label = status.replace("_", " ").title()
        NotificationService.notify_many(
            db=db, bg_tasks=bg_tasks, user_ids=member_ids,
            title=f"Milestone {status_label}",
            content=f"The milestone \"{milestone.title}\" in project \"{project.title}\" has been marked as {status_label}.",
            notification_type=NotificationType.MILESTONE.value,
            link=f"/dashboard/projects/{project_id}",
            exclude_user_id=user.id,
        )

        flash(request, f'Milestone marked as {status_label}', MessageCategory.SUCCESS)
    except HTTPException as e:
        flash(request, e.detail, MessageCategory.ERROR)
    return RedirectResponse(url=f"/dashboard/projects/{project_id}", status_code=303)


# ─── Delete ───────────────────────────────────────────

@project_milestones_router.post('/{milestone_id}/delete')
async def milestone_delete(request: Request, project_id: str, milestone_id: str, db: Session = Depends(get_db)):
    user = _get_user(request)
    try:
        if not _can_manage_project(db, user, project_id):
            raise HTTPException(403, "You don't have permission to delete milestones")

        Milestone.soft_delete(db, milestone_id)
        flash(request, 'Milestone deleted', MessageCategory.SUCCESS)
    except HTTPException as e:
        flash(request, e.detail, MessageCategory.ERROR)
    return RedirectResponse(url=f"/dashboard/projects/{project_id}", status_code=303)


# ─── ATLAS Top-Level Milestones ───────────────────────

@milestones_router.get('')
@add_template_context('pages/dashboard/milestones/index.html')
async def atlas_milestones_index(request: Request, db: Session = Depends(get_db)):
    user = _get_user(request)
    active_sem = SemesterService.get_active_semester(db)
    milestones = MilestoneService.get_semester_milestones(db, active_sem.id if active_sem else None)

    # If student, fetch team submission map
    student_team = None
    team_submissions = {}
    if _is_student(user):
        student_team = TeamService.get_student_active_team(db, user.id)
        if student_team:
            subs = db.query(Submission).filter(
                Submission.team_id == student_team.id,
                Submission.is_deleted == False
            ).all()
            for s in subs:
                team_submissions[s.milestone_id] = s

    return {
        "page_title": "Academic Milestones",
        "page_description": "Track semester deliverables, deadlines, and submission progress",
        "milestones": [m.to_dict() for m in milestones],
        "active_semester": active_sem.to_dict() if active_sem else None,
        "is_coordinator": _is_coordinator(user),
        "student_team": student_team.to_dict() if student_team else None,
        "team_submissions": {k: v.to_dict() for k, v in team_submissions.items()},
        "now": datetime.now(timezone.utc),
    }


@milestones_router.post('/new')
async def atlas_milestone_create(request: Request, db: Session = Depends(get_db)):
    user = _require_coordinator(request)
    try:
        form = await request.form()
        title = form.get('title', '').strip()
        due_date_str = form.get('due_date', '').strip()
        max_score = float(form.get('max_score', 100))
        weight = float(form.get('weight_percentage', 0))
        description = form.get('description', '').strip()

        if not title or not due_date_str:
            raise HTTPException(status_code=400, detail="Title and due date are required.")

        due_date = datetime.fromisoformat(due_date_str)
        MilestoneService.create_milestone(
            db=db,
            title=title,
            due_date=due_date,
            max_score=max_score,
            weight_percentage=weight,
            description=description,
            actor_id=user.id,
        )
        flash(request, f"Milestone '{title}' created successfully.", MessageCategory.SUCCESS)
    except Exception as e:
        flash(request, str(getattr(e, 'detail', e)), MessageCategory.ERROR)
    return RedirectResponse(url="/dashboard/milestones", status_code=303)


@milestones_router.post('/{milestone_id}/edit')
async def atlas_milestone_edit(milestone_id: str, request: Request, db: Session = Depends(get_db)):
    user = _require_coordinator(request)
    try:
        form = await request.form()
        title = form.get('title', '').strip()
        due_date_str = form.get('due_date', '').strip()
        max_score = float(form.get('max_score', 100))
        weight = float(form.get('weight_percentage', 0))
        description = form.get('description', '').strip()

        update_kwargs = {"title": title, "description": description, "max_score": max_score, "weight_percentage": weight}
        if due_date_str:
            update_kwargs["due_date"] = datetime.fromisoformat(due_date_str)

        MilestoneService.update_milestone(db=db, milestone_id=milestone_id, actor_id=user.id, **update_kwargs)
        flash(request, "Milestone updated successfully.", MessageCategory.SUCCESS)
    except Exception as e:
        flash(request, str(getattr(e, 'detail', e)), MessageCategory.ERROR)
    return RedirectResponse(url="/dashboard/milestones", status_code=303)


@milestones_router.post('/{milestone_id}/delete')
async def atlas_milestone_delete(milestone_id: str, request: Request, db: Session = Depends(get_db)):
    user = _require_coordinator(request)
    try:
        Milestone.soft_delete(db, milestone_id)
        flash(request, "Milestone removed.", MessageCategory.SUCCESS)
    except Exception as e:
        flash(request, str(getattr(e, 'detail', e)), MessageCategory.ERROR)
    return RedirectResponse(url="/dashboard/milestones", status_code=303)


# ─── ATLAS Top-Level Deadlines ────────────────────────

@deadlines_router.get('')
@add_template_context('pages/dashboard/deadlines/index.html')
async def atlas_deadlines_index(request: Request, db: Session = Depends(get_db)):
    user = _get_user(request)
    active_sem = SemesterService.get_active_semester(db)
    milestones = MilestoneService.get_semester_milestones(db, active_sem.id if active_sem else None)

    now = datetime.now()
    upcoming = []
    overdue = []
    for m in milestones:
        m_dict = m.to_dict()
        m_dict['is_overdue'] = m.due_date < now
        if m.due_date < now:
            overdue.append(m_dict)
        else:
            upcoming.append(m_dict)

    return {
        "page_title": "Academic Deadlines",
        "page_description": "Upcoming deadlines, milestone deliverables, and timeline tracking",
        "upcoming_deadlines": upcoming,
        "overdue_deadlines": overdue,
        "all_milestones": [m.to_dict() for m in milestones],
        "active_semester": active_sem.to_dict() if active_sem else None,
        "is_coordinator": _is_coordinator(user),
    }

