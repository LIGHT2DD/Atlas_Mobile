from datetime import date, datetime
from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Request
from fastapi.responses import RedirectResponse
from sqlalchemy.orm import Session

from api.core.dependencies.context import add_template_context
from api.core.dependencies.flash_messages import MessageCategory, flash
from api.db.database import get_db
from api.utils.loggers import create_logger
from api.v1.models.user import User, UserRole
from api.v1.models.team import Team
from api.v1.models.defense import DefenseSchedule, DefensePanelMember, DefenseStatus, DefensePanelRole
from api.v1.services.defense import DefenseService
from api.v1.routes.dashboard.helpers import (
    _get_user, _is_coordinator, _is_supervisor, _is_student, _require_coordinator
)

defenses_router = APIRouter(prefix='/defense', tags=['Defense'])
logger = create_logger(__name__)


@defenses_router.get('')
@add_template_context('pages/dashboard/defense/index.html')
async def defense_index(request: Request, db: Session = Depends(get_db)):
    user = _get_user(request)

    teams = db.query(Team).filter(Team.is_deleted == False).order_by(Team.name).all()
    supervisors = db.query(User).filter(User.role == UserRole.SUPERVISOR.value, User.is_deleted == False).all()

    if _is_student(user):
        # Student views their team defense
        student_team = None
        for t in teams:
            if any(m.user_id == user.id for m in t.members):
                student_team = t
                break

        defense = None
        if student_team:
            defense = db.query(DefenseSchedule).filter(
                DefenseSchedule.team_id == student_team.id,
                DefenseSchedule.is_deleted == False,
            ).first()

        return {
            "page_title": "Thesis Defense",
            "page_description": "Scheduled defense session, room location, and evaluation panel",
            "is_student": True,
            "team": student_team.to_dict() if student_team else None,
            "defense": defense.to_dict() if defense else None,
            "panel_members": [p.to_dict() for p in defense.panel_members] if defense else [],
        }

    elif _is_supervisor(user):
        # Supervisor views defenses where they are supervisor or panel member
        panel_defense_ids = [
            p.defense_id for p in db.query(DefensePanelMember.defense_id).filter(
                DefensePanelMember.user_id == user.id,
                DefensePanelMember.is_deleted == False,
            ).all()
        ]
        supervised_team_ids = [t.id for t in teams if t.supervisor_id == user.id]

        defenses = db.query(DefenseSchedule).filter(
            (DefenseSchedule.id.in_(panel_defense_ids)) | (DefenseSchedule.team_id.in_(supervised_team_ids)),
            DefenseSchedule.is_deleted == False,
        ).order_by(DefenseSchedule.date.asc()).all()

        return {
            "page_title": "Thesis Defenses",
            "page_description": "Scheduled defenses for your assigned teams and panel duties",
            "is_student": False,
            "is_coordinator": False,
            "defenses": [d.to_dict() for d in defenses],
        }

    elif _is_coordinator(user):
        # Coordinator management view
        defenses = db.query(DefenseSchedule).filter(
            DefenseSchedule.is_deleted == False,
        ).order_by(DefenseSchedule.date.asc()).all()

        return {
            "page_title": "Defense Scheduling & Panels",
            "page_description": "Schedule conflict-free thesis defenses, assign rooms, and appoint panels",
            "is_student": False,
            "is_coordinator": True,
            "defenses": [d.to_dict() for d in defenses],
            "teams": [t.to_dict() for t in teams],
            "supervisors": [s.to_dict() for s in supervisors],
        }
    else:
        logger.warning(f"Forbidden access to defenses by user {user.id} ({user.role})")
        raise HTTPException(status_code=403, detail="Forbidden")


@defenses_router.post('/schedule')
@defenses_router.post('/new')
async def defense_schedule_create(
    request: Request,
    bg_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
):
    user = _require_coordinator(request)
    try:
        form = await request.form()
        team_id = form.get('team_id', '').strip()
        date_str = (form.get('date') or form.get('defense_date') or '').strip()
        start_time = form.get('start_time', '').strip()
        end_time = form.get('end_time', '').strip()
        room = (form.get('room') or form.get('location_room') or '').strip()
        panel_user_ids = form.getlist('panel_members') or form.getlist('panel_member_ids')
        notes = form.get('notes', '').strip()

        if not team_id or not date_str or not start_time or not end_time or not room:
            raise HTTPException(status_code=400, detail="Team, date, start time, end time, and room are required.")

        defense_date = date.fromisoformat(date_str)
        panel_data = [{'user_id': uid, 'role': 'member'} for uid in panel_user_ids if uid]

        DefenseService.schedule_defense(
            db=db,
            coordinator_id=user.id,
            team_id=team_id,
            defense_date=defense_date,
            start_time=start_time,
            end_time=end_time,
            room=room,
            panel_members_data=panel_data,
            notes=notes,
            bg_tasks=bg_tasks,
        )

        flash(request, "Thesis defense scheduled successfully with conflict verification!", MessageCategory.SUCCESS)
    except HTTPException as e:
        logger.warning(f"Defense scheduling validation failed: {e.detail}")
        flash(request, e.detail, MessageCategory.ERROR)
    except Exception as e:
        logger.error(f"Unexpected error scheduling defense: {e}", exc_info=True)
        flash(request, f"Scheduling error: {str(e)}", MessageCategory.ERROR)

    return RedirectResponse(url='/dashboard/defense', status_code=303)


@defenses_router.post('/{defense_id}/delete')
async def defense_delete(defense_id: str, request: Request, db: Session = Depends(get_db)):
    user = _require_coordinator(request)
    try:
        DefenseSchedule.soft_delete(db, defense_id)
        flash(request, "Defense session removed successfully.", MessageCategory.SUCCESS)
    except HTTPException as e:
        logger.warning(f"Defense delete failed: {e.detail}")
        flash(request, e.detail, MessageCategory.ERROR)
    except Exception as e:
        logger.error(f"Unexpected error deleting defense {defense_id}: {e}", exc_info=True)
        flash(request, f"Error deleting defense session: {str(e)}", MessageCategory.ERROR)

    return RedirectResponse(url='/dashboard/defense', status_code=303)
