import pytest
from datetime import datetime, timedelta, timezone
from api.v1.services.team import TeamService
from api.v1.services.milestone import MilestoneService
from api.v1.services.submission import SubmissionService
from api.v1.models.submission import SubmissionStatus


def test_milestone_and_submission_lifecycle(db_session, seeded_users):
    stu1 = seeded_users["student1"]
    sup1 = seeded_users["supervisor1"]
    sem = seeded_users["semester"]

    team = TeamService.create_team(
        db=db_session,
        student_id=stu1.id,
        name="Submission Test Team",
        project_title="Submission Project",
        semester_id=sem.id,
    )
    team.supervisor_id = sup1.id
    db_session.commit()

    # Coordinator creates milestone due in 2 days
    now = datetime.now()
    m_on_time = MilestoneService.create_milestone(
        db=db_session,
        title="SRS Milestone",
        due_date=now + timedelta(days=2),
        max_score=100.0,
        weight_percentage=20.0,
        semester_id=sem.id,
    )

    # 1. On-time submission
    sub = SubmissionService.create_submission(
        db=db_session,
        milestone_id=m_on_time.id,
        team_id=team.id,
        submitted_by=stu1.id,
        title="SRS Submission",
        code_url="https://github.com/atlas-demo/code",
    )
    assert sub.is_late is False
    assert sub.status == SubmissionStatus.SUBMITTED.value

    # 2. Supervisor grades submission
    graded_sub = SubmissionService.grade_submission(
        db=db_session,
        submission_id=sub.id,
        reviewer_id=sup1.id,
        score=94.5,
        feedback_text="Very comprehensive specifications.",
    )
    assert graded_sub.score == 94.5
    assert graded_sub.status == SubmissionStatus.REVIEWED.value


def test_late_submission_server_side_detection(db_session, seeded_users):
    stu1 = seeded_users["student1"]
    sem = seeded_users["semester"]

    team = TeamService.create_team(
        db=db_session,
        student_id=stu1.id,
        name="Late Test Team",
        project_title="Late Project",
        semester_id=sem.id,
    )

    # Milestone expired yesterday
    now = datetime.now()
    m_expired = MilestoneService.create_milestone(
        db=db_session,
        title="Expired Milestone",
        due_date=now - timedelta(days=2),
        max_score=100.0,
        weight_percentage=10.0,
        semester_id=sem.id,
    )

    # Submit against expired milestone
    sub = SubmissionService.create_submission(
        db=db_session,
        milestone_id=m_expired.id,
        team_id=team.id,
        submitted_by=stu1.id,
        title="Late Submission",
    )
    # Server-side validation MUST detect late submission
    assert sub.is_late is True
    assert sub.status == SubmissionStatus.LATE.value
