from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Request
from fastapi.responses import RedirectResponse
from sqlalchemy.orm import Session

from api.core.dependencies.context import add_template_context
from api.core.dependencies.flash_messages import MessageCategory, flash
from api.db.database import get_db
from api.v1.models.user import User
from api.v1.models.team import Team
from api.v1.models.semester import Semester
from api.v1.models.evaluation import EvaluationCriteria, Evaluation, EvaluationScore
from api.v1.services.evaluation import EvaluationService
from api.v1.services.semester import SemesterService
from api.v1.routes.dashboard.helpers import (
    _get_user, _is_coordinator, _is_supervisor, _is_student, _require_coordinator
)
from api.utils.loggers import create_logger

evaluations_router = APIRouter(tags=['Evaluations & Rubrics'])
logger = create_logger(__name__)


# ─── Coordinator Rubric Configuration ──────────────────
@evaluations_router.get('/rubrics')
@add_template_context('pages/dashboard/rubrics/index.html')
async def rubrics_index(request: Request, db: Session = Depends(get_db)):
    user = _get_user(request)
    active_sem = SemesterService.get_active_semester(db)
    rubrics = EvaluationService.get_semester_rubrics(db, active_sem.id if active_sem else None)

    total_weight = sum(r.weight_percentage for r in rubrics)

    return {
        "page_title": "Evaluation Rubrics",
        "page_description": "Configure weighted criteria for thesis defense and assessments",
        "rubrics": [r.to_dict() for r in rubrics],
        "total_weight": total_weight,
        "is_coordinator": _is_coordinator(user),
        "active_semester": active_sem.to_dict() if active_sem else None,
    }


@evaluations_router.post('/rubrics/new')
async def rubric_create(request: Request, db: Session = Depends(get_db)):
    user = _require_coordinator(request)
    try:
        form = await request.form()
        title = form.get('title', '').strip()
        weight_str = form.get('weight_percentage', '').strip()
        max_score_str = form.get('max_score', '100').strip()
        description = form.get('description', '').strip()
        order_index = int(form.get('order_index', 0))

        if not title or not weight_str:
            raise HTTPException(status_code=400, detail="Title and weight percentage are required.")

        weight = float(weight_str)
        max_score = float(max_score_str)

        EvaluationService.create_criteria(
            db=db,
            title=title,
            weight_percentage=weight,
            max_score=max_score,
            description=description,
            order_index=order_index,
            actor_id=user.id,
        )
        flash(request, f"Rubric criterion '{title}' created successfully.", MessageCategory.SUCCESS)
    except HTTPException as e:
        logger.warning(f"Rubric create failed: {e.detail}")
        flash(request, e.detail, MessageCategory.ERROR)
    except Exception as e:
        logger.error(f"Unexpected error creating rubric: {e}", exc_info=True)
        flash(request, f"Error creating criterion: {str(e)}", MessageCategory.ERROR)

    return RedirectResponse(url='/dashboard/rubrics', status_code=303)


@evaluations_router.post('/rubrics/{rubric_id}/delete')
async def rubric_delete(rubric_id: str, request: Request, db: Session = Depends(get_db)):
    user = _require_coordinator(request)
    try:
        EvaluationCriteria.soft_delete(db, rubric_id)
        flash(request, "Rubric criterion removed successfully.", MessageCategory.SUCCESS)
    except HTTPException as e:
        logger.warning(f"Rubric delete failed: {e.detail}")
        flash(request, e.detail, MessageCategory.ERROR)
    except Exception as e:
        logger.error(f"Unexpected error deleting rubric {rubric_id}: {e}", exc_info=True)
        flash(request, f"Error deleting rubric criterion: {str(e)}", MessageCategory.ERROR)

    return RedirectResponse(url='/dashboard/rubrics', status_code=303)


# ─── Evaluations Scoring Page ──────────────────────────
@evaluations_router.get('/evaluations')
@add_template_context('pages/dashboard/evaluations/index.html')
async def evaluations_index(request: Request, db: Session = Depends(get_db)):
    user = _get_user(request)

    if _is_student(user):
        return RedirectResponse(url='/dashboard/grades', status_code=303)

    active_sem = SemesterService.get_active_semester(db)
    rubrics = EvaluationService.get_semester_rubrics(db, active_sem.id if active_sem else None)

    if _is_supervisor(user):
        teams = db.query(Team).filter(Team.supervisor_id == user.id, Team.is_deleted == False).all()
    else:
        teams = db.query(Team).filter(Team.is_deleted == False).all()

    evaluations = db.query(Evaluation).filter(Evaluation.is_deleted == False).all()

    return {
        "page_title": "Thesis Evaluations",
        "page_description": "Score thesis teams using official weighted rubric criteria",
        "teams": [t.to_dict() for t in teams],
        "rubrics": [r.to_dict() for r in rubrics],
        "evaluations": [e.to_dict() for e in evaluations],
        "is_coordinator": _is_coordinator(user),
    }


@evaluations_router.post('/evaluations/{team_id}/score')
async def evaluation_submit_score(
    team_id: str,
    request: Request,
    bg_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
):
    user = _get_user(request)
    if not (_is_supervisor(user) or _is_coordinator(user)):
        raise HTTPException(status_code=403, detail="Only supervisors or coordinators can submit evaluations.")

    try:
        form = await request.form()
        overall_comments = form.get('overall_comments', '').strip()

        criteria_scores = {}
        for key, val in form.items():
            if key.startswith('score_'):
                criteria_id = key.replace('score_', '')
                criteria_scores[criteria_id] = float(val)

        if not criteria_scores:
            raise HTTPException(status_code=400, detail="Please enter scores for the rubric criteria.")

        EvaluationService.submit_evaluation(
            db=db,
            team_id=team_id,
            evaluator_id=user.id,
            criteria_scores=criteria_scores,
            overall_comments=overall_comments,
            bg_tasks=bg_tasks,
        )

        flash(request, "Evaluation submitted and final weighted score updated successfully!", MessageCategory.SUCCESS)
    except HTTPException as e:
        logger.warning(f"Evaluation submit failed: {e.detail}")
        flash(request, e.detail, MessageCategory.ERROR)
    except Exception as e:
        logger.error(f"Unexpected error submitting evaluation for team {team_id}: {e}", exc_info=True)
        flash(request, f"Scoring error: {str(e)}", MessageCategory.ERROR)

    return RedirectResponse(url='/dashboard/evaluations', status_code=303)


# ─── Grades Portal ─────────────────────────────────────
@evaluations_router.get('/grades')
@add_template_context('pages/dashboard/grades/index.html')
async def grades_index(request: Request, db: Session = Depends(get_db)):
    user = _get_user(request)

    if _is_student(user):
        # Student views their team published result
        student_team = db.query(Team).join(Team.members).filter(
            User.id == user.id,
            Team.is_deleted == False,
        ).first()

        evaluations = []
        if student_team and student_team.grade_published:
            evaluations = db.query(Evaluation).filter(Evaluation.team_id == student_team.id).all()

        return {
            "page_title": "My Final Grade",
            "page_description": "Official published thesis evaluation results and breakdown",
            "is_student": True,
            "team": student_team.to_dict() if student_team else None,
            "evaluations": [e.to_dict() for e in evaluations],
        }

    else:
        # Coordinator / Supervisor overview of all team grades
        teams = db.query(Team).filter(Team.is_deleted == False).order_by(Team.final_score.desc().nullslast()).all()
        return {
            "page_title": "Grade Publication",
            "page_description": "Review authoritative aggregate scores and publish final thesis grades",
            "is_student": False,
            "is_coordinator": _is_coordinator(user),
            "teams": [t.to_dict() for t in teams],
        }


@evaluations_router.post('/grades/{team_id}/publish')
async def grade_publish(
    team_id: str,
    request: Request,
    bg_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
):
    user = _require_coordinator(request)
    try:
        team = EvaluationService.publish_grades(
            db=db,
            team_id=team_id,
            coordinator_id=user.id,
            bg_tasks=bg_tasks,
        )
        flash(request, f"Final grade {team.final_grade} published for team '{team.name}'.", MessageCategory.SUCCESS)
    except HTTPException as e:
        logger.warning(f"Grade publish failed: {e.detail}")
        flash(request, e.detail, MessageCategory.ERROR)
    except Exception as e:
        logger.error(f"Unexpected error publishing grade for team {team_id}: {e}", exc_info=True)
        flash(request, f"Publish error: {str(e)}", MessageCategory.ERROR)

    return RedirectResponse(url='/dashboard/grades', status_code=303)
