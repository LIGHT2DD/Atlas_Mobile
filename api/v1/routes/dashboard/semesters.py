from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, Request
from fastapi.responses import RedirectResponse
from sqlalchemy.orm import Session

from api.core.dependencies.context import add_template_context
from api.core.dependencies.flash_messages import MessageCategory, flash
from api.db.database import get_db
from api.v1.models.semester import Semester
from api.v1.services.semester import SemesterService
from api.v1.routes.dashboard.helpers import _require_coordinator
from api.utils import paginator
from api.utils.loggers import create_logger

semesters_router = APIRouter(prefix='/semesters', tags=['Semesters'])
logger = create_logger(__name__)


@semesters_router.get('')
@add_template_context('pages/dashboard/semesters/index.html')
async def semesters_list(request: Request, db: Session = Depends(get_db)):
    user = _require_coordinator(request)
    semesters = db.query(Semester).filter(Semester.is_deleted == False).order_by(Semester.start_date.desc()).all()
    active_semester = SemesterService.get_active_semester(db)

    return {
        "page_title": "Semester Management",
        "page_description": "Configure university academic terms and session limits",
        "semesters": [s.to_dict() for s in semesters],
        "active_semester": active_semester.to_dict() if active_semester else None,
    }


@semesters_router.post('/new')
async def semester_create(request: Request, db: Session = Depends(get_db)):
    user = _require_coordinator(request)
    try:
        form = await request.form()
        name = form.get('name', '').strip()
        academic_year = form.get('academic_year', '').strip()
        start_str = form.get('start_date', '').strip()
        end_str = form.get('end_date', '').strip()
        max_size = int(form.get('max_team_size', 4))
        min_size = int(form.get('min_team_size', 1))
        description = form.get('description', '').strip()
        is_active = str(form.get('is_active', '')).lower() in ('on', 'true', '1')

        if not name or not academic_year or not start_str or not end_str:
            raise HTTPException(status_code=400, detail="Name, academic year, and dates are required.")

        start_date = datetime.fromisoformat(start_str)
        end_date = datetime.fromisoformat(end_str)

        SemesterService.create_semester(
            db=db,
            name=name,
            academic_year=academic_year,
            start_date=start_date,
            end_date=end_date,
            max_team_size=max_size,
            min_team_size=min_size,
            description=description,
            is_active=is_active,
            actor_id=user.id,
        )
        flash(request, f"Semester '{name}' created successfully.", MessageCategory.SUCCESS)
    except HTTPException as e:
        logger.warning(f"Semester create failed: {e.detail}")
        flash(request, e.detail, MessageCategory.ERROR)
    except Exception as e:
        logger.error(f"Unexpected error creating semester '{name}': {e}", exc_info=True)
        flash(request, f"Failed to create semester: {str(e)}", MessageCategory.ERROR)

    return RedirectResponse(url='/dashboard/semesters', status_code=303)


@semesters_router.post('/{semester_id}/activate')
async def semester_activate(semester_id: str, request: Request, db: Session = Depends(get_db)):
    user = _require_coordinator(request)
    try:
        SemesterService.update_semester(db=db, semester_id=semester_id, actor_id=user.id, is_active=True)
        flash(request, "Semester set as active session.", MessageCategory.SUCCESS)
    except HTTPException as e:
        logger.warning(f"Semester activate failed: {e.detail}")
        flash(request, e.detail, MessageCategory.ERROR)
    except Exception as e:
        logger.error(f"Unexpected error activating semester {semester_id}: {e}", exc_info=True)
        flash(request, f"Error activating semester: {str(e)}", MessageCategory.ERROR)

    return RedirectResponse(url='/dashboard/semesters', status_code=303)


@semesters_router.post('/{semester_id}/delete')
async def semester_delete(semester_id: str, request: Request, db: Session = Depends(get_db)):
    user = _require_coordinator(request)
    try:
        Semester.soft_delete(db, semester_id)
        flash(request, "Semester archived successfully.", MessageCategory.SUCCESS)
    except HTTPException as e:
        logger.warning(f"Semester delete failed: {e.detail}")
        flash(request, e.detail, MessageCategory.ERROR)
    except Exception as e:
        logger.error(f"Unexpected error deleting semester {semester_id}: {e}", exc_info=True)
        flash(request, f"Error deleting semester: {str(e)}", MessageCategory.ERROR)

    return RedirectResponse(url='/dashboard/semesters', status_code=303)
