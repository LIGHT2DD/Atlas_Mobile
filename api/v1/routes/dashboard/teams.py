from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Request
from fastapi.responses import RedirectResponse
from sqlalchemy.orm import Session

from api.core.dependencies.context import add_template_context
from api.core.dependencies.flash_messages import MessageCategory, flash
from api.db.database import get_db
from api.v1.models.user import User, UserRole
from api.v1.models.team import Team, TeamStatus
from api.v1.models.team_member import TeamMember, TeamRole
from api.v1.models.supervisor_request import SupervisorRequest, SupervisorRequestStatus
from api.v1.models.semester import Semester
from api.v1.models.department import Department
from api.v1.services.team import TeamService
from api.v1.services.semester import SemesterService
from api.v1.routes.dashboard.helpers import (
    _get_user, _is_coordinator, _is_supervisor, _is_student, _require_coordinator
)
from api.utils import paginator
from api.utils.loggers import create_logger

teams_router = APIRouter(prefix='/teams', tags=['Teams'])
requests_router = APIRouter(prefix='/requests', tags=['Supervisor Requests'])
logger = create_logger(__name__)


# ─── Teams List / My Team ──────────────────────────────
@teams_router.get('')
@add_template_context('pages/dashboard/teams/index.html')
async def teams_index(request: Request, db: Session = Depends(get_db)):
    user = _get_user(request)

    if _is_student(user):
        team = TeamService.get_student_active_team(db, user.id)
        if team:
            return RedirectResponse(url=f"/dashboard/teams/{team.id}", status_code=303)
        # Show create/join team view
        active_sem = SemesterService.get_active_semester(db)
        if not active_sem:
            active_sem = db.query(Semester).filter(Semester.is_deleted == False).order_by(Semester.created_at.desc()).first()
        departments = db.query(Department).filter(Department.is_deleted == False).all()
        return {
            "page_title": "My Team",
            "page_description": "Create or join a thesis team",
            "is_student": True,
            "has_team": False,
            "active_semester": active_sem.to_dict() if active_sem else None,
            "departments": [d.to_dict() for d in departments],
        }

    elif _is_supervisor(user):
        teams = db.query(Team).filter(
            Team.supervisor_id == user.id,
            Team.is_deleted == False,
        ).order_by(Team.created_at.desc()).all()
        return {
            "page_title": "Supervised Teams",
            "page_description": f"Teams currently assigned under your supervision ({len(teams)})",
            "is_student": False,
            "is_supervisor": True,
            "teams": [t.to_dict() for t in teams],
        }

    else:
        # Coordinator view
        teams = db.query(Team).filter(Team.is_deleted == False).order_by(Team.created_at.desc()).all()
        semesters = db.query(Semester).filter(Semester.is_deleted == False).all()
        supervisors = db.query(User).filter(User.role == UserRole.SUPERVISOR.value, User.is_deleted == False).all()
        return {
            "page_title": "All Thesis Teams",
            "page_description": f"University-wide thesis team oversight ({len(teams)} teams)",
            "is_student": False,
            "is_coordinator": True,
            "teams": [t.to_dict() for t in teams],
            "semesters": [s.to_dict() for s in semesters],
            "supervisors": [s.to_dict() for s in supervisors],
        }


# ─── Create Team ───────────────────────────────────────
@teams_router.get('/new')
async def team_create_page(request: Request, db: Session = Depends(get_db)):
    user = _get_user(request)
    if _is_student(user):
        team = TeamService.get_student_active_team(db, user.id)
        if team:
            return RedirectResponse(url=f"/dashboard/teams/{team.id}", status_code=303)
        return RedirectResponse(url="/dashboard/teams?action=create", status_code=303)
    return RedirectResponse(url="/dashboard/teams", status_code=303)


@teams_router.post('/new')
async def team_create(request: Request, db: Session = Depends(get_db)):
    user = _get_user(request)
    try:
        if not _is_student(user):
            raise HTTPException(status_code=403, detail="Only students can form thesis teams.")

        form = await request.form()
        name = form.get('name', '').strip()
        project_title = form.get('project_title', '').strip()
        description = form.get('description', '').strip()
        department_id = form.get('department_id') or None

        if not name:
            raise HTTPException(status_code=400, detail="Team name is required.")

        if not project_title:
            project_title = f"{name} Thesis Project"

        team = TeamService.create_team(
            db=db,
            student_id=user.id,
            name=name,
            project_title=project_title,
            description=description,
            department_id=department_id,
        )
        flash(request, f"Team '{team.name}' created successfully!", MessageCategory.SUCCESS)
        return RedirectResponse(url=f"/dashboard/teams/{team.id}", status_code=303)
    except HTTPException as e:
        logger.warning(f"Team create failed: {e.detail}")
        flash(request, e.detail, MessageCategory.ERROR)
        return RedirectResponse(url="/dashboard/teams?action=create", status_code=303)
    except Exception as e:
        logger.error(f"Unexpected error creating team: {e}", exc_info=True)
        flash(request, f"Error creating team: {str(e)}", MessageCategory.ERROR)
        return RedirectResponse(url="/dashboard/teams?action=create", status_code=303)


# ─── Join Team via Invite Code ─────────────────────────
@teams_router.get('/join')
async def team_join_page(request: Request, db: Session = Depends(get_db)):
    user = _get_user(request)
    if _is_student(user):
        team = TeamService.get_student_active_team(db, user.id)
        if team:
            return RedirectResponse(url=f"/dashboard/teams/{team.id}", status_code=303)
        return RedirectResponse(url="/dashboard/teams?action=join", status_code=303)
    return RedirectResponse(url="/dashboard/teams", status_code=303)


@teams_router.post('/join')
async def team_join(request: Request, db: Session = Depends(get_db)):
    user = _get_user(request)
    try:
        form = await request.form()
        invite_code = form.get('invite_code', '').strip()
        if not invite_code:
            raise HTTPException(status_code=400, detail="Please enter an invitation code.")

        team, msg = TeamService.join_team_via_invite(db=db, invite_code=invite_code, student_id=user.id)
        flash(request, msg, MessageCategory.SUCCESS)
        return RedirectResponse(url=f"/dashboard/teams/{team.id}", status_code=303)
    except HTTPException as e:
        logger.warning(f"Team join failed: {e.detail}")
        flash(request, e.detail, MessageCategory.ERROR)
        return RedirectResponse(url="/dashboard/teams?action=join", status_code=303)
    except Exception as e:
        logger.error(f"Unexpected error joining team: {e}", exc_info=True)
        flash(request, f"Error joining team: {str(e)}", MessageCategory.ERROR)
        return RedirectResponse(url="/dashboard/teams?action=join", status_code=303)


# ─── Team Detail ───────────────────────────────────────
@teams_router.get('/{team_id}')
@add_template_context('pages/dashboard/teams/detail.html')
async def team_detail(request: Request, team_id: str, db: Session = Depends(get_db)):
    user = _get_user(request)
    team = Team.fetch_by_id(db, team_id)

    # Permission check: must be team member, assigned supervisor, or coordinator
    is_member = any(m.user_id == user.id for m in team.members)
    is_supervisor_assigned = (team.supervisor_id == user.id)
    is_coord = _is_coordinator(user)

    if not (is_member or is_supervisor_assigned or is_coord):
        raise HTTPException(status_code=403, detail="You do not have access to this team.")

    is_leader = (team.leader_id == user.id)
    base_url = str(request.base_url).rstrip('/')
    invite_url = f"{base_url}/invite/{team.invite_code}"

    # Supervisors for request dropdown
    supervisors = db.query(User).filter(
        User.role == UserRole.SUPERVISOR.value,
        User.is_deleted == False,
    ).all()

    # Pending supervisor request
    pending_request = db.query(SupervisorRequest).filter(
        SupervisorRequest.team_id == team.id,
        SupervisorRequest.status == SupervisorRequestStatus.PENDING.value,
        SupervisorRequest.is_deleted == False,
    ).first()

    return {
        "page_title": team.name,
        "page_description": team.project_title,
        "team": team.to_dict(),
        "members": [m.to_dict() for m in team.members],
        "is_member": is_member,
        "is_leader": is_leader,
        "is_supervisor": is_supervisor_assigned,
        "is_coordinator": is_coord,
        "invite_url": invite_url,
        "supervisors": [s.to_dict() for s in supervisors],
        "pending_request": pending_request.to_dict() if pending_request else None,
        "proposal": team.proposal.to_dict() if team.proposal else None,
        "defense": team.defense.to_dict() if team.defense else None,
    }


# ─── Request Supervisor ────────────────────────────────
@teams_router.post('/{team_id}/request-supervisor')
async def team_request_supervisor(team_id: str, request: Request, bg_tasks: BackgroundTasks, db: Session = Depends(get_db)):
    user = _get_user(request)
    try:
        form = await request.form()
        supervisor_id = form.get('supervisor_id', '').strip()
        notes = form.get('notes', '').strip()

        if not supervisor_id:
            raise HTTPException(status_code=400, detail="Please select a supervisor.")

        TeamService.request_supervisor(
            db=db,
            team_id=team_id,
            supervisor_id=supervisor_id,
            student_id=user.id,
            notes=notes,
            bg_tasks=bg_tasks,
        )
        flash(request, "Supervisor request sent successfully! Awaiting faculty response.", MessageCategory.SUCCESS)
    except HTTPException as e:
        flash(request, e.detail, MessageCategory.ERROR)

    return RedirectResponse(url=f"/dashboard/teams/{team_id}", status_code=303)


# ─── Coordinator Assign Supervisor ─────────────────────
@teams_router.post('/{team_id}/assign-supervisor')
async def team_assign_supervisor(team_id: str, request: Request, bg_tasks: BackgroundTasks, db: Session = Depends(get_db)):
    user = _require_coordinator(request)
    try:
        form = await request.form()
        supervisor_id = form.get('supervisor_id', '').strip()
        if not supervisor_id:
            raise HTTPException(status_code=400, detail="Please select a supervisor.")

        TeamService.assign_supervisor_administrative(
            db=db,
            team_id=team_id,
            supervisor_id=supervisor_id,
            coordinator_id=user.id,
            bg_tasks=bg_tasks,
        )
        flash(request, "Supervisor assigned successfully.", MessageCategory.SUCCESS)
    except HTTPException as e:
        flash(request, e.detail, MessageCategory.ERROR)

    return RedirectResponse(url=f"/dashboard/teams/{team_id}", status_code=303)


# ─── Leave Team ────────────────────────────────────────
@teams_router.post('/{team_id}/leave')
async def team_leave(team_id: str, request: Request, db: Session = Depends(get_db)):
    user = _get_user(request)
    try:
        TeamService.leave_team(db=db, team_id=team_id, student_id=user.id)
        flash(request, "You have left the team.", MessageCategory.INFO)
    except HTTPException as e:
        flash(request, e.detail, MessageCategory.ERROR)
        return RedirectResponse(url=f"/dashboard/teams/{team_id}", status_code=303)

    return RedirectResponse(url="/dashboard/teams", status_code=303)


# ─── Add Team Member (by University Email) ─────────────
@teams_router.post('/{team_id}/add-member')
async def team_add_member(team_id: str, request: Request, db: Session = Depends(get_db)):
    user = _get_user(request)
    try:
        team = Team.fetch_by_id(db, team_id)
        is_leader = (team.leader_id == user.id)
        if not (is_leader or _is_coordinator(user)):
            raise HTTPException(status_code=403, detail="Only team leader or coordinator can add members.")

        form = await request.form()
        student_email = (form.get('student_email') or '').strip().lower()
        if not student_email:
            raise HTTPException(status_code=400, detail="Student email is required.")

        student = db.query(User).filter(User.email == student_email, User.is_deleted == False).first()
        if not student:
            raise HTTPException(status_code=404, detail=f"No registered student found with email '{student_email}'.")

        if student.role != UserRole.STUDENT.value:
            raise HTTPException(status_code=400, detail="Only students can be added as team members.")

        # Check existing membership
        existing = db.query(TeamMember).filter(
            TeamMember.team_id == team.id,
            TeamMember.user_id == student.id,
            TeamMember.is_deleted == False,
        ).first()
        if existing:
            raise HTTPException(status_code=400, detail="This student is already a member of this team.")

        # Check if student is in another active team
        active_team = TeamService.get_student_active_team(db, student.id)
        if active_team:
            raise HTTPException(status_code=400, detail=f"Student is already a member of team '{active_team.name}'.")

        # Check team max size limit
        current_count = db.query(TeamMember).filter(
            TeamMember.team_id == team.id,
            TeamMember.is_deleted == False,
        ).count()
        max_allowed = team.semester.max_team_size if team.semester else 4
        if current_count >= max_allowed:
            raise HTTPException(status_code=400, detail=f"Team has reached the maximum size of {max_allowed} members.")

        TeamMember.create(
            db=db,
            team_id=team.id,
            user_id=student.id,
            role=TeamRole.MEMBER.value,
        )
        flash(request, f"{student.full_name} added to team successfully!", MessageCategory.SUCCESS)
    except HTTPException as e:
        logger.warning(f"Add member failed: {e.detail}")
        flash(request, e.detail, MessageCategory.ERROR)
    except Exception as e:
        logger.error(f"Unexpected error adding member to team {team_id}: {e}", exc_info=True)
        flash(request, f"Error adding member: {str(e)}", MessageCategory.ERROR)

    return RedirectResponse(url=f"/dashboard/teams/{team_id}", status_code=303)


# ─── Remove Team Member ─────────────────────────────────
@teams_router.post('/{team_id}/members/{user_id}/remove')
async def team_remove_member(team_id: str, user_id: str, request: Request, db: Session = Depends(get_db)):
    user = _get_user(request)
    try:
        team = Team.fetch_by_id(db, team_id)
        is_leader = (team.leader_id == user.id)
        is_self = (user.id == user_id)
        if not (is_leader or is_self or _is_coordinator(user)):
            logger.warning(f"Unauthorized member remove attempt on team {team_id} by user {user.id}")
            raise HTTPException(status_code=403, detail="Unauthorized to remove this member.")

        membership = db.query(TeamMember).filter(
            TeamMember.team_id == team_id,
            TeamMember.user_id == user_id,
            TeamMember.is_deleted == False,
        ).first()
        if not membership:
            raise HTTPException(status_code=404, detail="Team membership not found.")

        total_members = db.query(TeamMember).filter(
            TeamMember.team_id == team_id,
            TeamMember.is_deleted == False,
        ).count()

        if membership.role == TeamRole.LEADER.value and total_members > 1:
            raise HTTPException(status_code=400, detail="Team leader must transfer leadership before leaving.")

        TeamMember.soft_delete(db, membership.id)
        if total_members <= 1:
            Team.soft_delete(db, team.id)
            flash(request, "Team disbanded as the last member was removed.", MessageCategory.INFO)
            return RedirectResponse(url="/dashboard/teams", status_code=303)

        flash(request, "Member removed from team.", MessageCategory.SUCCESS)
    except HTTPException as e:
        logger.warning(f"Remove member failed: {e.detail}")
        flash(request, e.detail, MessageCategory.ERROR)
    except Exception as e:
        logger.error(f"Unexpected error removing member from team {team_id}: {e}", exc_info=True)
        flash(request, f"Error removing member: {str(e)}", MessageCategory.ERROR)

    return RedirectResponse(url=f"/dashboard/teams/{team_id}", status_code=303)


# ─── Supervisor Requests Portal ────────────────────────
@requests_router.get('')
@add_template_context('pages/dashboard/requests/index.html')
async def supervisor_requests_list(request: Request, db: Session = Depends(get_db)):
    user = _get_user(request)
    if not (_is_supervisor(user) or _is_coordinator(user)):
        raise HTTPException(status_code=403, detail="Supervisor or Coordinator access required.")

    query = db.query(SupervisorRequest).filter(SupervisorRequest.is_deleted == False)
    if _is_supervisor(user):
        query = query.filter(SupervisorRequest.supervisor_id == user.id)

    requests = query.order_by(SupervisorRequest.created_at.desc()).all()

    return {
        "page_title": "Supervisor Requests",
        "page_description": "Review and respond to thesis supervision requests",
        "requests": [r.to_dict() for r in requests],
    }


@requests_router.post('/{request_id}/accept')
async def supervisor_request_accept(
    request_id: str,
    request: Request,
    bg_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
):
    user = _get_user(request)
    try:
        TeamService.respond_supervisor_request(
            db=db,
            request_id=request_id,
            supervisor_id=user.id,
            accept=True,
            bg_tasks=bg_tasks,
        )
        flash(request, "Supervision request accepted successfully!", MessageCategory.SUCCESS)
    except HTTPException as e:
        flash(request, e.detail, MessageCategory.ERROR)

    return RedirectResponse(url='/dashboard/requests', status_code=303)


@requests_router.post('/{request_id}/reject')
async def supervisor_request_reject(
    request_id: str,
    request: Request,
    bg_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
):
    user = _get_user(request)
    try:
        form = await request.form()
        response_notes = form.get('notes', '') or form.get('response_notes', '')
        TeamService.respond_supervisor_request(
            db=db,
            request_id=request_id,
            supervisor_id=user.id,
            accept=False,
            response_notes=response_notes.strip() if response_notes else None,
            bg_tasks=bg_tasks,
        )
        flash(request, "Supervision request declined.", MessageCategory.INFO)
    except HTTPException as e:
        flash(request, e.detail, MessageCategory.ERROR)

    return RedirectResponse(url='/dashboard/requests', status_code=303)


@requests_router.post('/{request_id}/respond')
async def supervisor_request_respond(
    request_id: str,
    request: Request,
    bg_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
):
    user = _get_user(request)
    try:
        form = await request.form()
        decision = form.get('decision', '').strip().lower()
        response_notes = form.get('response_notes', '') or form.get('notes', '')

        accept = (decision == 'accept')

        TeamService.respond_supervisor_request(
            db=db,
            request_id=request_id,
            supervisor_id=user.id,
            accept=accept,
            response_notes=response_notes.strip() if response_notes else None,
            bg_tasks=bg_tasks,
        )

        status_text = "accepted" if accept else "declined"
        flash(request, f"Request successfully {status_text}.", MessageCategory.SUCCESS)
    except HTTPException as e:
        flash(request, e.detail, MessageCategory.ERROR)

    return RedirectResponse(url='/dashboard/requests', status_code=303)
