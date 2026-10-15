import os
import pytest
from datetime import datetime, date, timedelta
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from passlib.context import CryptContext

from main import app
from api.db.database import Base, get_db
from api.v1.models import (
    User, UserRole,
    Semester,
    Team, TeamStatus,
    TeamMember, TeamRole,
    SupervisorRequest, SupervisorRequestStatus,
    Proposal, ProposalStatus, ProposalVersion,
    Milestone, MilestoneStatus,
    Submission, SubmissionStatus,
    EvaluationCriteria, Evaluation, EvaluationScore,
    DefenseSchedule, DefenseStatus,
)
from api.v1.services.auth import AuthService

import api.db.database as db_mod
from sqlalchemy.orm import scoped_session

TEST_DB_URL = "sqlite:///./test_atlas.db"
test_engine = create_engine(TEST_DB_URL, connect_args={"check_same_thread": False})
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=test_engine)

# Patch global database singletons to point to test_engine
db_mod.engine = test_engine
db_mod.SessionLocal = TestingSessionLocal
db_mod.db_session = scoped_session(TestingSessionLocal)

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
TEST_PASSWORD_HASH = pwd_context.hash("Password123")


@pytest.fixture(autouse=True)
def reset_db_per_test():
    """Drop and recreate all tables per test to ensure true isolation."""
    Base.metadata.drop_all(bind=test_engine)
    Base.metadata.create_all(bind=test_engine)
    yield
    db_mod.db_session.remove()


@pytest.fixture
def db_session():
    session = TestingSessionLocal()
    yield session
    session.close()


@pytest.fixture
def client(db_session):
    def override_get_db():
        session = TestingSessionLocal()
        try:
            yield session
        finally:
            session.close()

    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app, follow_redirects=False) as test_client:
        yield test_client
    app.dependency_overrides.clear()


@pytest.fixture
def seeded_users(db_session):
    coord = User.create(
        db=db_session,
        first_name="Coordinator",
        last_name="Admin",
        email="coord_test@atlas.edu",
        password=TEST_PASSWORD_HASH,
        role=UserRole.COORDINATOR.value,
        is_active=True,
    )

    sup1 = User.create(
        db=db_session,
        first_name="Supervisor",
        last_name="One",
        email="sup1_test@atlas.edu",
        password=TEST_PASSWORD_HASH,
        role=UserRole.SUPERVISOR.value,
        is_active=True,
    )

    sup2 = User.create(
        db=db_session,
        first_name="Supervisor",
        last_name="Two",
        email="sup2_test@atlas.edu",
        password=TEST_PASSWORD_HASH,
        role=UserRole.SUPERVISOR.value,
        is_active=True,
    )

    stu1 = User.create(
        db=db_session,
        first_name="Student",
        last_name="Leader",
        email="stu1_test@atlas.edu",
        password=TEST_PASSWORD_HASH,
        role=UserRole.STUDENT.value,
        is_active=True,
    )

    stu2 = User.create(
        db=db_session,
        first_name="Student",
        last_name="Member",
        email="stu2_test@atlas.edu",
        password=TEST_PASSWORD_HASH,
        role=UserRole.STUDENT.value,
        is_active=True,
    )

    stu3 = User.create(
        db=db_session,
        first_name="Student",
        last_name="Independent",
        email="stu3_test@atlas.edu",
        password=TEST_PASSWORD_HASH,
        role=UserRole.STUDENT.value,
        is_active=True,
    )

    sem = Semester.create(
        db=db_session,
        name="Test Term 2026",
        academic_year="2026-2027",
        start_date=date(2026, 9, 1),
        end_date=date(2027, 1, 31),
        is_active=True,
    )

    return {
        "coordinator": coord,
        "supervisor1": sup1,
        "supervisor2": sup2,
        "student1": stu1,
        "student2": stu2,
        "student3": stu3,
        "semester": sem,
    }


def login_user(client: TestClient, email: str, password: str = "Password123"):
    response = client.post(
        "/api/v1/auth/login",
        json={"email": email, "password": password},
    )
    return response
