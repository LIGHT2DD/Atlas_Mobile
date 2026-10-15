import pytest
from datetime import date
from fastapi import HTTPException
from api.v1.services.team import TeamService
from api.v1.services.defense import DefenseService


def test_defense_scheduling_and_room_conflict(db_session, seeded_users):
    stu1 = seeded_users["student1"]
    stu2 = seeded_users["student2"]
    sup1 = seeded_users["supervisor1"]
    sup2 = seeded_users["supervisor2"]
    coord = seeded_users["coordinator"]
    sem = seeded_users["semester"]

    team1 = TeamService.create_team(
        db=db_session, student_id=stu1.id, name="Defense Team 1", semester_id=sem.id
    )
    team2 = TeamService.create_team(
        db=db_session, student_id=stu2.id, name="Defense Team 2", semester_id=sem.id
    )

    defense_date = date(2026, 12, 15)

    # Schedule Team 1 in Room 101 from 10:00 to 11:30
    d1 = DefenseService.schedule_defense(
        db=db_session,
        coordinator_id=coord.id,
        team_id=team1.id,
        defense_date=defense_date,
        start_time="10:00",
        end_time="11:30",
        room="Room 101",
        panel_members_data=[{"user_id": sup1.id, "role": "chair"}],
    )
    assert d1.id is not None

    # Attempt to schedule Team 2 in the SAME Room 101 overlapping 10:30 to 12:00 -> MUST FAIL
    with pytest.raises(HTTPException) as exc:
        DefenseService.schedule_defense(
            db=db_session,
            coordinator_id=coord.id,
            team_id=team2.id,
            defense_date=defense_date,
            start_time="10:30",
            end_time="12:00",
            room="Room 101",
            panel_members_data=[{"user_id": sup2.id, "role": "chair"}],
        )
    assert exc.value.status_code == 409
    assert "room conflict" in exc.value.detail.lower()


def test_defense_panel_member_conflict(db_session, seeded_users):
    stu1 = seeded_users["student1"]
    stu2 = seeded_users["student2"]
    sup1 = seeded_users["supervisor1"]
    coord = seeded_users["coordinator"]
    sem = seeded_users["semester"]

    team1 = TeamService.create_team(
        db=db_session, student_id=stu1.id, name="Defense Team 1", semester_id=sem.id
    )
    team2 = TeamService.create_team(
        db=db_session, student_id=stu2.id, name="Defense Team 2", semester_id=sem.id
    )

    defense_date = date(2026, 12, 15)

    # Schedule Team 1 with sup1 in Room 101 from 10:00 to 11:30
    DefenseService.schedule_defense(
        db=db_session,
        coordinator_id=coord.id,
        team_id=team1.id,
        defense_date=defense_date,
        start_time="10:00",
        end_time="11:30",
        room="Room 101",
        panel_members_data=[{"user_id": sup1.id, "role": "chair"}],
    )

    # Attempt to schedule Team 2 in Room 202 (different room) but with busy sup1 (10:30 - 11:30)
    with pytest.raises(HTTPException) as exc:
        DefenseService.schedule_defense(
            db=db_session,
            coordinator_id=coord.id,
            team_id=team2.id,
            defense_date=defense_date,
            start_time="10:30",
            end_time="11:30",
            room="Room 202",
            panel_members_data=[{"user_id": sup1.id, "role": "member"}],
        )
    assert exc.value.status_code == 409
    assert "panel conflict" in exc.value.detail.lower()
