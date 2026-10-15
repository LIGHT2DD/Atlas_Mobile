import pytest
from fastapi.testclient import TestClient
from api.v1.services.auth import AuthService


def test_login_successful(client, seeded_users, db_session):
    coord = seeded_users["coordinator"]
    user, access_token, refresh_token = AuthService.authenticate(
        db=db_session,
        email=coord.email,
        password="Password123",
        create_token=True,
    )
    assert user.id == coord.id
    assert access_token is not None
    assert refresh_token is not None


def test_login_invalid_credentials(db_session, seeded_users):
    coord = seeded_users["coordinator"]
    with pytest.raises(Exception):
        AuthService.authenticate(
            db=db_session,
            email=coord.email,
            password="WrongPassword999",
            create_token=True,
        )


def test_rbac_student_blocked_from_coordinator_endpoints(client, seeded_users, db_session):
    stu = seeded_users["student1"]
    _, access_token, _ = AuthService.authenticate(
        db=db_session,
        email=stu.email,
        password="Password123",
        create_token=True,
    )
    headers = {"Authorization": f"Bearer {access_token}"}
    client.cookies.set("access_token", access_token)

    # Attempt to create a rubric (Coordinator only)
    response = client.post(
        "/dashboard/rubrics/new",
        data={"title": "Unauthorized Rubric", "weight_percentage": "20"},
        headers=headers,
    )
    assert response.status_code == 403


def test_rbac_supervisor_blocked_from_semesters_management(client, seeded_users, db_session):
    sup = seeded_users["supervisor1"]
    _, access_token, _ = AuthService.authenticate(
        db=db_session,
        email=sup.email,
        password="Password123",
        create_token=True,
    )
    headers = {"Authorization": f"Bearer {access_token}"}
    client.cookies.set("access_token", access_token)

    response = client.post(
        "/dashboard/semesters/new",
        data={
            "name": "Hacked Semester",
            "academic_year": "2026-2027",
            "start_date": "2026-09-01",
            "end_date": "2027-01-31",
        },
        headers=headers,
    )
    assert response.status_code == 403


def test_student_registration_and_login(client, db_session):
    # 1. Sign up a new student
    signup_data = {
        "action": "register",
        "first_name": "Test",
        "last_name": "Student",
        "email": "newstudent@atlas.edu",
        "password": "Password123",
        "confirm_password": "Password123",
    }
    signup_res = client.post("/auth?role=student&mode=register", data=signup_data)
    assert signup_res.status_code == 303
    assert signup_res.headers["location"] == "/dashboard"

    # 2. Verify account is active and can authenticate successfully
    user, token, _ = AuthService.authenticate(
        db=db_session,
        email="newstudent@atlas.edu",
        password="Password123",
        create_token=True,
    )
    assert user is not None
    assert user.is_active is True
    assert user.role == "student"
    assert token is not None
