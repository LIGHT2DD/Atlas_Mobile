import pytest
from fastapi import HTTPException
from api.v1.services.team import TeamService
from api.v1.models.team import TeamStatus
from api.v1.models.team_member import TeamRole
from api.v1.models.supervisor_request import SupervisorRequestStatus


def test_team_creation_and_leader(db_session, seeded_users):
    stu1 = seeded_users["student1"]
    sem = seeded_users["semester"]

    team = TeamService.create_team(
        db=db_session,
        student_id=stu1.id,
        name="Apollo Mission",
        project_title="Lunar Autonomous Systems",
        semester_id=sem.id,
    )
    assert team.name == "Apollo Mission"
    assert team.leader_id == stu1.id
    assert team.status == TeamStatus.FORMING.value
    assert len(team.members) == 1
    assert team.members[0].user_id == stu1.id
    assert team.members[0].role == TeamRole.LEADER.value


def test_single_active_team_rule(db_session, seeded_users):
    stu1 = seeded_users["student1"]
    sem = seeded_users["semester"]

    # First team
    TeamService.create_team(
        db=db_session,
        student_id=stu1.id,
        name="Team Alpha",
        project_title="Project Alpha",
        semester_id=sem.id,
    )

    # Attempting to create a second team while already in Team Alpha must fail
    with pytest.raises(HTTPException) as exc:
        TeamService.create_team(
            db=db_session,
            student_id=stu1.id,
            name="Second Team",
            project_title="Another Project",
            semester_id=sem.id,
        )
    assert exc.value.status_code == 400
    assert "already a member of team" in exc.value.detail


def test_team_member_addition_and_limit(db_session, seeded_users):
    stu1 = seeded_users["student1"]
    stu2 = seeded_users["student2"]
    stu3 = seeded_users["student3"]
    sem = seeded_users["semester"]

    team = TeamService.create_team(
        db=db_session,
        student_id=stu1.id,
        name="Collaboration Team",
        project_title="Collab Project",
        semester_id=sem.id,
    )

    # stu2 joins via invite code
    joined_team, msg = TeamService.join_team_via_invite(
        db=db_session,
        invite_code=team.invite_code,
        student_id=stu2.id,
    )
    assert joined_team.id == team.id

    # stu3 joins via invite code
    joined_team, msg = TeamService.join_team_via_invite(
        db=db_session,
        invite_code=team.invite_code,
        student_id=stu3.id,
    )
    assert joined_team.id == team.id

    # Duplicate join attempt by stu2
    _, duplicate_msg = TeamService.join_team_via_invite(
        db=db_session,
        invite_code=team.invite_code,
        student_id=stu2.id,
    )
    assert "already a member" in duplicate_msg


def test_supervisor_request_and_approval(db_session, seeded_users):
    stu1 = seeded_users["student1"]
    sup1 = seeded_users["supervisor1"]
    sem = seeded_users["semester"]

    team = TeamService.create_team(
        db=db_session,
        student_id=stu1.id,
        name="Supervision Team",
        project_title="Supervised Project",
        semester_id=sem.id,
    )

    req = TeamService.request_supervisor(
        db=db_session,
        team_id=team.id,
        supervisor_id=sup1.id,
        student_id=stu1.id,
        notes="Please supervise our team.",
    )
    assert req.status == SupervisorRequestStatus.PENDING.value
    assert req.supervisor_id == sup1.id

    # Supervisor 1 accepts
    accepted_req = TeamService.respond_supervisor_request(
        db=db_session,
        request_id=req.id,
        supervisor_id=sup1.id,
        accept=True,
    )
    assert accepted_req.status == SupervisorRequestStatus.ACCEPTED.value

    # Verify team supervisor is assigned
    db_session.refresh(team)
    assert team.supervisor_id == sup1.id
    assert team.status == TeamStatus.SUPERVISOR_ASSIGNED.value
