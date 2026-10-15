from typing import Optional
from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from api.db.database import get_db
from api.v1.models.user import User, UserRole
from api.v1.models.team import Team
from api.v1.models.evaluation import EvaluationCriteria, Evaluation, EvaluationScore
from api.v1.services.evaluation import EvaluationService
from api.v1.services.team import TeamService
from api.mobile.v1.schemas import (
    RubricCriteriaCreatePayload, EvaluationSubmitPayload
)
from api.mobile.v1.dependencies import (
    mobile_response, get_current_user_mobile, require_roles_mobile
)


evaluations_mobile_router = APIRouter(prefix="/evaluations", tags=["Mobile Evaluations & Rubrics"])


@evaluations_mobile_router.get("/rubrics")
def list_rubrics(
    semester_id: Optional[str] = Query(None),
    current_user: User = Depends(get_current_user_mobile),
    db: Session = Depends(get_db)
):
    """Retrieve departmental rubric criteria for grading."""
    criteria = EvaluationService.get_semester_rubrics(db, semester_id=semester_id)
    items = [
        {
            "id": c.id,
            "title": c.title,
            "description": c.description,
            "max_score": c.max_score,
            "weight_percentage": c.weight_percentage,
            "order_index": c.order_index,
        }
        for c in criteria
    ]
    return mobile_response(data=items, message="Rubric criteria retrieved.")


@evaluations_mobile_router.post("/rubrics")
def create_rubric_criterion(
    payload: RubricCriteriaCreatePayload,
    current_user: User = Depends(require_roles_mobile(UserRole.COORDINATOR.value)),
    db: Session = Depends(get_db)
):
    """Coordinator endpoint to define a rubric evaluation criterion."""
    criterion = EvaluationService.create_criteria(
        db=db,
        title=payload.title,
        weight_percentage=payload.weight_percentage,
        max_score=payload.max_score,
        description=payload.description,
        actor_id=current_user.id,
    )
    return mobile_response(
        data={
            "id": criterion.id,
            "title": criterion.title,
            "max_score": criterion.max_score,
            "weight_percentage": criterion.weight_percentage,
        },
        message=f"Rubric criterion '{criterion.title}' created.",
        status_code=201
    )


@evaluations_mobile_router.get("/team/{team_id}")
def get_team_evaluations(
    team_id: str,
    current_user: User = Depends(require_roles_mobile(UserRole.SUPERVISOR.value, UserRole.COORDINATOR.value)),
    db: Session = Depends(get_db)
):
    """Retrieve submitted evaluations and scores for a specific team."""
    team = Team.fetch_by_id(db, team_id)
    evals = db.query(Evaluation).filter(
        Evaluation.team_id == team_id,
        Evaluation.is_deleted == False,
    ).all()

    items = []
    for e in evals:
        scores = [
            {
                "criteria_id": s.criteria_id,
                "criteria_title": s.criteria.title if s.criteria else None,
                "score": s.score,
                "max_score": s.criteria.max_score if s.criteria else None,
            }
            for s in e.scores
        ]

        items.append({
            "id": e.id,
            "evaluator_id": e.evaluator_id,
            "evaluator_name": e.evaluator.full_name if e.evaluator else "Unknown",
            "calculated_score": e.calculated_score,
            "overall_comments": e.overall_comments,
            "scores": scores,
            "created_at": str(e.created_at) if e.created_at else None,
        })

    return mobile_response(
        data={
            "team_id": team.id,
            "team_name": team.name,
            "final_score": team.final_score,
            "final_grade": team.final_grade,
            "grade_published": team.grade_published,
            "evaluations": items,
        },
        message="Team evaluations retrieved."
    )


@evaluations_mobile_router.post("/team/{team_id}")
def submit_evaluation(
    team_id: str,
    payload: EvaluationSubmitPayload,
    bg_tasks: BackgroundTasks,
    current_user: User = Depends(require_roles_mobile(UserRole.SUPERVISOR.value, UserRole.COORDINATOR.value)),
    db: Session = Depends(get_db)
):
    """Supervisor/Panel Member endpoint to evaluate and score a team across rubric criteria."""
    scores_dict = {item.criteria_id: item.score for item in payload.rubric_scores}

    eval_record = EvaluationService.submit_evaluation(
        db=db,
        team_id=team_id,
        evaluator_id=current_user.id,
        criteria_scores=scores_dict,
        overall_comments=payload.remarks,
        bg_tasks=bg_tasks,
    )

    team = Team.fetch_by_id(db, team_id)

    return mobile_response(
        data={
            "evaluation_id": eval_record.id,
            "calculated_score": eval_record.calculated_score,
            "team_aggregate_score": team.final_score,
            "team_aggregate_grade": team.final_grade,
        },
        message="Evaluation scores recorded successfully."
    )


@evaluations_mobile_router.post("/team/{team_id}/publish")
def publish_team_grade(
    team_id: str,
    bg_tasks: BackgroundTasks,
    current_user: User = Depends(require_roles_mobile(UserRole.COORDINATOR.value)),
    db: Session = Depends(get_db)
):
    """Coordinator endpoint to lock and authoritatively publish final academic grades."""
    team = EvaluationService.publish_grades(
        db=db,
        team_id=team_id,
        coordinator_id=current_user.id,
        bg_tasks=bg_tasks,
    )

    return mobile_response(
        data={
            "team_id": team.id,
            "final_score": team.final_score,
            "final_grade": team.final_grade,
            "grade_published": team.grade_published,
        },
        message=f"Final grade for team '{team.name}' published successfully."
    )


@evaluations_mobile_router.get("/my-grade")
def get_my_published_grade(
    current_user: User = Depends(require_roles_mobile(UserRole.STUDENT.value)),
    db: Session = Depends(get_db)
):
    """Student endpoint to access officially certified and published final grades."""
    team = TeamService.get_student_active_team(db, current_user.id)
    if not team:
        return mobile_response(
            data={"has_grade": False, "reason": "No active team."},
            message="No active team found."
        )

    if not team.grade_published:
        return mobile_response(
            data={
                "has_grade": False,
                "team_name": team.name,
                "reason": "Final evaluation scores are under departmental review and have not yet been published.",
            },
            message="Grade not yet published."
        )

    return mobile_response(
        data={
            "has_grade": True,
            "team_id": team.id,
            "team_name": team.name,
            "project_title": team.project_title,
            "final_grade": team.final_grade,
            "final_score": team.final_score,
            "published": True,
        },
        message="Official grade transcript retrieved."
    )
