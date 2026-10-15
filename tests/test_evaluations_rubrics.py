import pytest
from fastapi import HTTPException
from api.v1.services.team import TeamService
from api.v1.services.evaluation import EvaluationService


def test_rubrics_evaluation_and_grade_calculation(db_session, seeded_users):
    stu1 = seeded_users["student1"]
    sup1 = seeded_users["supervisor1"]
    coord = seeded_users["coordinator"]
    sem = seeded_users["semester"]

    team = TeamService.create_team(
        db=db_session, student_id=stu1.id, name="Grade Calculation Team", semester_id=sem.id
    )

    # 1. Create 2 criteria:
    # Theory: 40% weight, max 100
    # Practice: 60% weight, max 100
    crit1 = EvaluationService.create_criteria(
        db=db_session,
        title="Theory & Methodology",
        weight_percentage=40.0,
        max_score=100.0,
        semester_id=sem.id,
        actor_id=coord.id,
    )
    crit2 = EvaluationService.create_criteria(
        db=db_session,
        title="Implementation Quality",
        weight_percentage=60.0,
        max_score=100.0,
        semester_id=sem.id,
        actor_id=coord.id,
    )

    # 2. Score: 90 on crit1 (40 * 0.9 = 36), 80 on crit2 (60 * 0.8 = 48) -> Weighted = 84.0%
    scores_dict = {
        crit1.id: 90.0,
        crit2.id: 80.0,
    }

    eval_record = EvaluationService.submit_evaluation(
        db=db_session,
        team_id=team.id,
        evaluator_id=sup1.id,
        criteria_scores=scores_dict,
        overall_comments="Solid execution with good theoretical grounding.",
    )

    assert eval_record.calculated_score == 84.0
    db_session.refresh(team)
    assert team.final_score == 84.0
    assert team.final_grade == "A-"  # 84% maps to A-

    # 3. Publish grade
    published_team = EvaluationService.publish_grade(
        db=db_session,
        team_id=team.id,
        coordinator_id=coord.id,
    )
    assert published_team.grade_published is True


def test_score_validation_exceeding_max(db_session, seeded_users):
    stu1 = seeded_users["student1"]
    sup1 = seeded_users["supervisor1"]
    coord = seeded_users["coordinator"]
    sem = seeded_users["semester"]

    team = TeamService.create_team(
        db=db_session, student_id=stu1.id, name="Score Validation Team", semester_id=sem.id
    )
    crit = EvaluationService.create_criteria(
        db=db_session,
        title="System Design",
        weight_percentage=100.0,
        max_score=100.0,
        semester_id=sem.id,
        actor_id=coord.id,
    )

    # Attempt score of 150 when max is 100
    with pytest.raises(HTTPException) as exc:
        EvaluationService.submit_evaluation(
            db=db_session,
            team_id=team.id,
            evaluator_id=sup1.id,
            criteria_scores={crit.id: 150.0},
        )
    assert exc.value.status_code == 400
    assert "must be between 0 and" in exc.value.detail
