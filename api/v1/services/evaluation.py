from datetime import datetime, timezone
from typing import List, Dict, Optional, Tuple
from fastapi import HTTPException
from sqlalchemy.orm import Session

from api.v1.models.user import User
from api.v1.models.team import Team, TeamStatus
from api.v1.models.evaluation import EvaluationCriteria, Evaluation, EvaluationScore
from api.v1.models.audit_log import AuditLog
from api.v1.models.notification import NotificationType
from api.v1.services.notification import NotificationService
from api.v1.services.semester import SemesterService
from api.utils.loggers import create_logger

logger = create_logger(__name__)


def _score_to_letter_grade(score: float) -> str:
    """Standard academic letter grade assignment."""
    if score >= 90.0:
        return "A+"
    elif score >= 85.0:
        return "A"
    elif score >= 80.0:
        return "A-"
    elif score >= 75.0:
        return "B+"
    elif score >= 70.0:
        return "B"
    elif score >= 65.0:
        return "B-"
    elif score >= 60.0:
        return "C+"
    elif score >= 50.0:
        return "C"
    else:
        return "F"


class EvaluationService:

    @classmethod
    def get_semester_rubrics(cls, db: Session, semester_id: Optional[str] = None) -> List[EvaluationCriteria]:
        """Fetch all evaluation criteria for a semester."""
        if not semester_id:
            active_sem = SemesterService.get_active_semester(db)
            if active_sem:
                semester_id = active_sem.id

        query = db.query(EvaluationCriteria).filter(
            EvaluationCriteria.is_active == True,
            EvaluationCriteria.is_deleted == False,
        )
        if semester_id:
            query = query.filter(EvaluationCriteria.semester_id == semester_id)
        return query.order_by(EvaluationCriteria.order_index.asc()).all()

    @classmethod
    def create_criteria(
        cls,
        db: Session,
        title: str,
        weight_percentage: float,
        max_score: float = 100.0,
        description: Optional[str] = None,
        semester_id: Optional[str] = None,
        order_index: int = 0,
        actor_id: Optional[str] = None,
    ) -> EvaluationCriteria:
        if weight_percentage <= 0 or weight_percentage > 100:
            raise HTTPException(status_code=400, detail="Weight percentage must be between 0 and 100.")

        if not semester_id:
            active_sem = SemesterService.get_active_semester(db)
            if active_sem:
                semester_id = active_sem.id

        criteria = EvaluationCriteria.create(
            db=db,
            title=title.strip(),
            weight_percentage=weight_percentage,
            max_score=max_score,
            description=description.strip() if description else None,
            semester_id=semester_id,
            order_index=order_index,
            is_active=True,
        )

        AuditLog.log(
            db=db,
            action="EVALUATION_CRITERIA_CREATED",
            user_id=actor_id,
            entity_type="rubric",
            entity_id=criteria.id,
            details=f"Created criteria '{criteria.title}' ({weight_percentage}% weight)."
        )

        return criteria

    @classmethod
    def submit_evaluation(
        cls,
        db: Session,
        team_id: str,
        evaluator_id: str,
        criteria_scores: Dict[str, float],  # {criteria_id: score}
        overall_comments: Optional[str] = None,
        defense_id: Optional[str] = None,
        bg_tasks=None,
    ) -> Evaluation:
        """
        Record authoritative weighted rubric evaluation by a supervisor or panel member.
        """
        team = Team.fetch_by_id(db, team_id)
        evaluator = User.fetch_by_id(db, evaluator_id)

        # Fetch criteria to validate scores
        criteria_list = cls.get_semester_rubrics(db, team.semester_id)
        if not criteria_list:
            raise HTTPException(status_code=400, detail="No evaluation rubric has been configured for this semester.")

        criteria_map = {c.id: c for c in criteria_list}

        total_weighted_score = 0.0
        total_weight = 0.0

        for cid, score in criteria_scores.items():
            if cid not in criteria_map:
                continue
            crit = criteria_map[cid]
            if score < 0 or score > crit.max_score:
                raise HTTPException(
                    status_code=400,
                    detail=f"Score for '{crit.title}' must be between 0 and {crit.max_score}."
                )
            weighted_contrib = (score / crit.max_score) * crit.weight_percentage
            total_weighted_score += weighted_contrib
            total_weight += crit.weight_percentage

        # Normalize score if total criteria weights don't sum to exactly 100
        final_evaluator_score = total_weighted_score
        if total_weight > 0 and total_weight != 100.0:
            final_evaluator_score = (total_weighted_score / total_weight) * 100.0

        final_evaluator_score = round(final_evaluator_score, 2)

        # Check existing evaluation by this evaluator for this team
        existing_eval = db.query(Evaluation).filter(
            Evaluation.team_id == team_id,
            Evaluation.evaluator_id == evaluator_id,
            Evaluation.is_deleted == False,
        ).first()

        if existing_eval:
            evaluation = existing_eval
            evaluation.overall_comments = overall_comments.strip() if overall_comments else None
            evaluation.calculated_score = final_evaluator_score
            evaluation.is_submitted = True
            evaluation.defense_id = defense_id
            db.query(EvaluationScore).filter(EvaluationScore.evaluation_id == evaluation.id).delete()
        else:
            evaluation = Evaluation.create(
                db=db,
                team_id=team_id,
                evaluator_id=evaluator_id,
                defense_id=defense_id,
                overall_comments=overall_comments.strip() if overall_comments else None,
                calculated_score=final_evaluator_score,
                is_submitted=True,
            )

        # Create score records
        for cid, score in criteria_scores.items():
            if cid in criteria_map:
                EvaluationScore.create(
                    db=db,
                    evaluation_id=evaluation.id,
                    criteria_id=cid,
                    score=score,
                )

        # Update Team aggregate final score and grade
        all_evals = db.query(Evaluation).filter(
            Evaluation.team_id == team_id,
            Evaluation.is_submitted == True,
            Evaluation.is_deleted == False,
        ).all()

        if all_evals:
            avg_score = round(sum(e.calculated_score for e in all_evals) / len(all_evals), 2)
            team.final_score = avg_score
            team.final_grade = _score_to_letter_grade(avg_score)
            db.commit()

        AuditLog.log(
            db=db,
            action="EVALUATION_SUBMITTED",
            user_id=evaluator_id,
            entity_type="evaluation",
            entity_id=evaluation.id,
            details=f"Evaluator {evaluator.full_name} scored team '{team.name}' with {final_evaluator_score}%."
        )

        return evaluation

    @classmethod
    def publish_grades(cls, db: Session, team_id: str, coordinator_id: str, bg_tasks=None) -> Team:
        """Publish final authoritative grade for a team."""
        team = Team.fetch_by_id(db, team_id)
        if team.final_score is None:
            raise HTTPException(status_code=400, detail="Cannot publish grade: Team has no evaluation scores yet.")

        team.grade_published = True
        team.status = TeamStatus.COMPLETED.value
        db.commit()

        # Notify team members
        team_member_ids = [m.user_id for m in team.members]
        NotificationService.notify_many(
            db=db,
            bg_tasks=bg_tasks,
            user_ids=team_member_ids,
            title="Final Grade Published",
            content=f"Your final thesis grade has been published: {team.final_grade} ({team.final_score}%). Congratulations!",
            notification_type=NotificationType.SYSTEM.value,
            link="/dashboard/grades",
        )

        AuditLog.log(
            db=db,
            action="GRADE_PUBLISHED",
            user_id=coordinator_id,
            entity_type="team",
            entity_id=team.id,
            details=f"Coordinator published final grade {team.final_grade} ({team.final_score}%) for team '{team.name}'."
        )

        return team

    publish_grade = publish_grades
