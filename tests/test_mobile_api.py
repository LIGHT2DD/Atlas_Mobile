import pytest
from datetime import datetime, date, timedelta
from fastapi.testclient import TestClient
from api.v1.services.auth import AuthService
from api.v1.models.user import UserRole


def _get_auth_headers(db_session, user):
    """Helper to generate JWT bearer header for testing mobile endpoints."""
    access_token = AuthService.create_access_token(db=db_session, user_id=user.id)
    return {"Authorization": f"Bearer {access_token}"}


# ─── 1. Authentication Tests ─────────────────────────────────

def test_mobile_login_success(client, seeded_users):
    stu = seeded_users["student1"]
    res = client.post(
        "/api/mobile/v1/auth/login",
        json={"email": stu.email, "password": "Password123"}
    )
    assert res.status_code == 200
    body = res.json()
    assert body["success"] is True
    assert "access_token" in body["data"]
    assert "refresh_token" in body["data"]
    assert body["data"]["user"]["email"] == stu.email
    assert body["data"]["user"]["role"] == "student"


def test_mobile_login_invalid_password(client, seeded_users):
    stu = seeded_users["student1"]
    res = client.post(
        "/api/mobile/v1/auth/login",
        json={"email": stu.email, "password": "WrongPassword!"}
    )
    assert res.status_code == 400
    body = res.json()
    assert body["success"] is False


def test_mobile_token_refresh(client, seeded_users, db_session):
    stu = seeded_users["student1"]
    refresh_token = AuthService.create_refresh_token(db=db_session, user_id=stu.id)

    res = client.post(
        "/api/mobile/v1/auth/refresh",
        json={"refresh_token": refresh_token}
    )
    assert res.status_code == 200
    body = res.json()
    assert body["success"] is True
    assert "access_token" in body["data"]
    assert "refresh_token" in body["data"]


def test_mobile_auth_me_and_logout(client, seeded_users, db_session):
    stu = seeded_users["student1"]
    headers = _get_auth_headers(db_session, stu)

    # Test /me
    me_res = client.get("/api/mobile/v1/auth/me", headers=headers)
    assert me_res.status_code == 200
    assert me_res.json()["data"]["user"]["email"] == stu.email

    # Test /logout
    logout_res = client.post("/api/mobile/v1/auth/logout", headers=headers)
    assert logout_res.status_code == 200
    assert logout_res.json()["success"] is True


def test_mobile_register_student(client, db_session):
    res = client.post(
        "/api/mobile/v1/auth/register",
        json={
            "first_name": "Mobile",
            "last_name": "Student",
            "email": "mobile_student@atlas.edu",
            "password": "Password123",
            "confirm_password": "Password123",
        }
    )
    assert res.status_code == 201
    body = res.json()
    assert body["success"] is True
    assert body["data"]["user"]["role"] == "student"
    assert "access_token" in body["data"]


# ─── 2. Student Team Lifecycle Tests ─────────────────────────

def test_mobile_team_flow_and_supervisor_request(client, seeded_users, db_session):
    stu1 = seeded_users["student1"]
    stu2 = seeded_users["student2"]
    sup1 = seeded_users["supervisor1"]
    sem = seeded_users["semester"]

    headers_stu1 = _get_auth_headers(db_session, stu1)
    headers_stu2 = _get_auth_headers(db_session, stu2)
    headers_sup1 = _get_auth_headers(db_session, sup1)

    # 1. stu1 creates team
    team_res = client.post(
        "/api/mobile/v1/teams",
        headers=headers_stu1,
        json={
            "name": "Mobile Phoenix",
            "project_title": "Edge Robotics",
            "semester_id": sem.id,
            "description": "Robotics thesis",
        }
    )
    assert team_res.status_code == 201
    team_data = team_res.json()["data"]
    team_id = team_data["id"]
    invite_code = team_data["invite_code"]

    # 2. stu1 views my-team
    my_team_res = client.get("/api/mobile/v1/teams/my-team", headers=headers_stu1)
    assert my_team_res.status_code == 200
    assert my_team_res.json()["data"]["has_team"] is True
    assert my_team_res.json()["data"]["team"]["id"] == team_id

    # 3. stu2 joins team via invite code
    join_res = client.post(
        "/api/mobile/v1/teams/join",
        headers=headers_stu2,
        json={"invite_code": invite_code}
    )
    assert join_res.status_code == 200
    assert len(join_res.json()["data"]["members"]) == 2

    # 4. stu1 requests supervisor sup1
    req_res = client.post(
        f"/api/mobile/v1/teams/{team_id}/request-supervisor",
        headers=headers_stu1,
        json={
            "supervisor_id": sup1.id,
            "notes": "Please supervise our mobile robotics thesis.",
        }
    )
    assert req_res.status_code == 201
    req_id = req_res.json()["data"]["request_id"]

    # 5. sup1 checks requests inbox
    sup_reqs_res = client.get("/api/mobile/v1/supervisor/requests", headers=headers_sup1)
    assert sup_reqs_res.status_code == 200
    assert any(r["id"] == req_id for r in sup_reqs_res.json()["data"])

    # 6. sup1 accepts request
    respond_res = client.post(
        f"/api/mobile/v1/supervisor/requests/{req_id}/respond",
        headers=headers_sup1,
        json={"accept": True, "notes": "Approved. Welcome to the lab."}
    )
    assert respond_res.status_code == 200
    assert respond_res.json()["data"]["status"] == "accepted"

    # 7. sup1 checks assigned teams
    sup_teams_res = client.get("/api/mobile/v1/supervisor/teams", headers=headers_sup1)
    assert sup_teams_res.status_code == 200
    assert any(t["id"] == team_id for t in sup_teams_res.json()["data"])


# ─── 3. Proposal Lifecycle Tests ─────────────────────────────

def test_mobile_proposal_submission_and_review(client, seeded_users, db_session):
    stu1 = seeded_users["student1"]
    sup1 = seeded_users["supervisor1"]
    sem = seeded_users["semester"]

    headers_stu1 = _get_auth_headers(db_session, stu1)
    headers_sup1 = _get_auth_headers(db_session, sup1)

    # Setup: Create team with assigned supervisor
    team_res = client.post(
        "/api/mobile/v1/teams",
        headers=headers_stu1,
        json={"name": "Proposal Team", "project_title": "AI Diagnostics", "semester_id": sem.id}
    )
    team_id = team_res.json()["data"]["id"]

    # Request & assign supervisor
    req_res = client.post(
        f"/api/mobile/v1/teams/{team_id}/request-supervisor",
        headers=headers_stu1,
        json={"supervisor_id": sup1.id}
    )
    req_id = req_res.json()["data"]["request_id"]
    client.post(
        f"/api/mobile/v1/supervisor/requests/{req_id}/respond",
        headers=headers_sup1,
        json={"accept": True}
    )

    # 1. stu1 submits proposal
    prop_res = client.post(
        "/api/mobile/v1/proposals/submit",
        headers=headers_stu1,
        data={
            "team_id": team_id,
            "title": "Autonomous AI Diagnostics System",
            "abstract": "A novel deep learning architecture for multi-modal radiology analysis.",
        }
    )
    assert prop_res.status_code == 200
    prop_data = prop_res.json()["data"]
    prop_id = prop_data["id"]
    assert prop_data["status"] == "submitted"
    assert prop_data["current_version"] == 1

    # 2. sup1 requests changes
    review1 = client.post(
        f"/api/mobile/v1/proposals/{prop_id}/review",
        headers=headers_sup1,
        json={
            "decision": "changes_requested",
            "comments": "Please elaborate on data privacy and ethical clearance.",
        }
    )
    assert review1.status_code == 200
    assert review1.json()["data"]["decision"] == "changes_requested"

    # 3. stu1 resubmits revised proposal (increments version)
    prop_res2 = client.post(
        "/api/mobile/v1/proposals/submit",
        headers=headers_stu1,
        data={
            "team_id": team_id,
            "title": "Autonomous AI Diagnostics System v2",
            "abstract": "Revised abstract addressing data privacy, anonymization protocols, and IRB approval.",
        }
    )
    assert prop_res2.status_code == 200
    assert prop_res2.json()["data"]["current_version"] == 2
    assert prop_res2.json()["data"]["status"] == "submitted"

    # 4. sup1 approves proposal
    review2 = client.post(
        f"/api/mobile/v1/proposals/{prop_id}/review",
        headers=headers_sup1,
        json={
            "decision": "approved",
            "comments": "Comprehensive improvements. Approved to proceed.",
        }
    )
    assert review2.status_code == 200
    assert review2.json()["data"]["decision"] == "approved"


# ─── 4. Milestones & Submissions Tests ────────────────────────

def test_mobile_milestone_and_submission_grading(client, seeded_users, db_session):
    stu1 = seeded_users["student1"]
    sup1 = seeded_users["supervisor1"]
    coord = seeded_users["coordinator"]
    sem = seeded_users["semester"]

    headers_stu1 = _get_auth_headers(db_session, stu1)
    headers_sup1 = _get_auth_headers(db_session, sup1)
    headers_coord = _get_auth_headers(db_session, coord)

    # Setup team with sup1
    team_res = client.post(
        "/api/mobile/v1/teams",
        headers=headers_stu1,
        json={"name": "Milestone Team", "project_title": "IoT Grid", "semester_id": sem.id}
    )
    team_id = team_res.json()["data"]["id"]
    req_res = client.post(f"/api/mobile/v1/teams/{team_id}/request-supervisor", headers=headers_stu1, json={"supervisor_id": sup1.id})
    client.post(f"/api/mobile/v1/supervisor/requests/{req_res.json()['data']['request_id']}/respond", headers=headers_sup1, json={"accept": True})

    # 1. Coordinator creates a milestone
    due = datetime.now() + timedelta(days=5)
    m_res = client.post(
        "/api/mobile/v1/milestones",
        headers=headers_coord,
        json={
            "title": "System Architecture Document",
            "due_date": due.isoformat(),
            "max_score": 100.0,
            "weight_percentage": 25.0,
            "semester_id": sem.id,
        }
    )
    assert m_res.status_code == 201
    milestone_id = m_res.json()["data"]["id"]

    # 2. List milestones
    list_m_res = client.get("/api/mobile/v1/milestones", headers=headers_stu1)
    assert list_m_res.status_code == 200
    assert any(m["id"] == milestone_id for m in list_m_res.json()["data"])

    # 3. Student submits deliverable
    sub_res = client.post(
        "/api/mobile/v1/submissions",
        headers=headers_stu1,
        data={
            "milestone_id": milestone_id,
            "team_id": team_id,
            "title": "Architecture Report v1",
            "description": "Full UML and microservices breakdown",
            "code_url": "https://github.com/atlas-demo/iot-grid",
        }
    )
    assert sub_res.status_code == 201
    sub_data = sub_res.json()["data"]
    submission_id = sub_data["id"]
    assert sub_data["is_late"] is False
    assert sub_data["status"] == "submitted"

    # 4. Supervisor grades submission
    grade_res = client.post(
        f"/api/mobile/v1/submissions/{submission_id}/grade",
        headers=headers_sup1,
        json={"score": 93.5, "feedback_text": "Exceptional microservices architecture."}
    )
    assert grade_res.status_code == 200
    assert grade_res.json()["data"]["score"] == 93.5
    assert grade_res.json()["data"]["status"] == "reviewed"


# ─── 5. Defense Scheduling & Conflict Engine Tests ───────────

def test_mobile_defense_conflict_detection(client, seeded_users, db_session):
    stu1 = seeded_users["student1"]
    stu2 = seeded_users["student2"]
    sup1 = seeded_users["supervisor1"]
    sup2 = seeded_users["supervisor2"]
    coord = seeded_users["coordinator"]
    sem = seeded_users["semester"]

    headers_stu1 = _get_auth_headers(db_session, stu1)
    headers_stu2 = _get_auth_headers(db_session, stu2)
    headers_coord = _get_auth_headers(db_session, coord)

    # Create two teams
    t1_res = client.post("/api/mobile/v1/teams", headers=headers_stu1, json={"name": "Defense Team 1", "project_title": "Project 1", "semester_id": sem.id})
    t1_id = t1_res.json()["data"]["id"]

    t2_res = client.post("/api/mobile/v1/teams", headers=headers_stu2, json={"name": "Defense Team 2", "project_title": "Project 2", "semester_id": sem.id})
    t2_id = t2_res.json()["data"]["id"]

    # 1. Schedule defense for Team 1 in Conference Room A (10:00 - 11:00)
    sched1 = client.post(
        "/api/mobile/v1/defenses/schedule",
        headers=headers_coord,
        json={
            "team_id": t1_id,
            "scheduled_date": "2026-11-15",
            "start_time": "10:00",
            "end_time": "11:00",
            "venue": "Conference Room A",
            "panelist_ids": [sup1.id, sup2.id],
        }
    )
    assert sched1.status_code == 201

    # 2. Attempt to schedule Team 2 in the same room at overlapping time -> MUST return 409 Conflict
    sched_room_conflict = client.post(
        "/api/mobile/v1/defenses/schedule",
        headers=headers_coord,
        json={
            "team_id": t2_id,
            "scheduled_date": "2026-11-15",
            "start_time": "10:30",
            "end_time": "11:30",
            "venue": "Conference Room A",
            "panelist_ids": [sup2.id],
        }
    )
    assert sched_room_conflict.status_code == 409
    assert "Room Conflict" in sched_room_conflict.json()["message"]

    # 3. Attempt to schedule Team 2 in a DIFFERENT room but with sup1 who is busy -> MUST return 409 Conflict
    sched_panel_conflict = client.post(
        "/api/mobile/v1/defenses/schedule",
        headers=headers_coord,
        json={
            "team_id": t2_id,
            "scheduled_date": "2026-11-15",
            "start_time": "10:15",
            "end_time": "11:15",
            "venue": "Room B (Virtual)",
            "panelist_ids": [sup1.id],
        }
    )
    assert sched_panel_conflict.status_code == 409
    assert "Panel Conflict" in sched_panel_conflict.json()["message"]


# ─── 6. Rubrics, Evaluation & Grade Publishing Tests ─────────

def test_mobile_rubric_evaluation_and_grade_publishing(client, seeded_users, db_session):
    stu1 = seeded_users["student1"]
    sup1 = seeded_users["supervisor1"]
    coord = seeded_users["coordinator"]
    sem = seeded_users["semester"]

    headers_stu1 = _get_auth_headers(db_session, stu1)
    headers_sup1 = _get_auth_headers(db_session, sup1)
    headers_coord = _get_auth_headers(db_session, coord)

    # 1. Coordinator creates rubric criteria
    c1_res = client.post(
        "/api/mobile/v1/evaluations/rubrics",
        headers=headers_coord,
        json={
            "title": "System Implementation & Rigor",
            "weight_percentage": 50.0,
            "max_score": 50.0,
        }
    )
    assert c1_res.status_code == 201
    c1_id = c1_res.json()["data"]["id"]

    c2_res = client.post(
        "/api/mobile/v1/evaluations/rubrics",
        headers=headers_coord,
        json={
            "title": "Oral Presentation & Q&A",
            "weight_percentage": 50.0,
            "max_score": 50.0,
        }
    )
    assert c2_res.status_code == 201
    c2_id = c2_res.json()["data"]["id"]

    # Create team
    team_res = client.post("/api/mobile/v1/teams", headers=headers_stu1, json={"name": "Grading Team", "project_title": "Security Suite", "semester_id": sem.id})
    team_id = team_res.json()["data"]["id"]

    # 2. Student checks grade BEFORE publication -> not published
    pre_grade_res = client.get("/api/mobile/v1/evaluations/my-grade", headers=headers_stu1)
    assert pre_grade_res.status_code == 200
    assert pre_grade_res.json()["data"]["has_grade"] is False

    # 3. Supervisor submits rubric evaluation (45/50 and 47/50 => 92%)
    eval_res = client.post(
        f"/api/mobile/v1/evaluations/team/{team_id}",
        headers=headers_sup1,
        json={
            "rubric_scores": [
                {"criteria_id": c1_id, "score": 45.0},
                {"criteria_id": c2_id, "score": 47.0},
            ],
            "remarks": "Solid demonstration and thorough Q&A responses.",
        }
    )
    assert eval_res.status_code == 200
    assert eval_res.json()["data"]["calculated_score"] == 92.0

    # 4. Coordinator publishes grades
    pub_res = client.post(f"/api/mobile/v1/evaluations/team/{team_id}/publish", headers=headers_coord)
    assert pub_res.status_code == 200
    assert pub_res.json()["data"]["grade_published"] is True

    # 5. Student checks grade AFTER publication -> official transcript unlocked
    post_grade_res = client.get("/api/mobile/v1/evaluations/my-grade", headers=headers_stu1)
    assert post_grade_res.status_code == 200
    assert post_grade_res.json()["data"]["has_grade"] is True
    assert post_grade_res.json()["data"]["final_score"] == 92.0
    assert post_grade_res.json()["data"]["final_grade"] == "A+"


# ─── 7. Notifications & FCM Device Token Tests ───────────────

def test_mobile_notifications_and_device_token(client, seeded_users, db_session):
    stu1 = seeded_users["student1"]
    headers_stu1 = _get_auth_headers(db_session, stu1)

    # 1. Register FCM device token
    fcm_res = client.post(
        "/api/mobile/v1/notifications/device-token",
        headers=headers_stu1,
        json={"fcm_token": "fcm_mock_token_abc_123", "device_type": "android"}
    )
    assert fcm_res.status_code == 200
    assert fcm_res.json()["success"] is True

    # 2. Fetch notifications
    notif_res = client.get("/api/mobile/v1/notifications", headers=headers_stu1)
    assert notif_res.status_code == 200
    assert "unread_count" in notif_res.json()["data"]

    # 3. Mark all read
    read_res = client.post("/api/mobile/v1/notifications/read-all", headers=headers_stu1)
    assert read_res.status_code == 200


# ─── 8. Coordinator Administration & Reports Tests ───────────

def test_mobile_coordinator_admin_features(client, seeded_users, db_session):
    coord = seeded_users["coordinator"]
    headers_coord = _get_auth_headers(db_session, coord)

    # 1. Semesters listing
    sem_res = client.get("/api/mobile/v1/coordinator/semesters", headers=headers_coord)
    assert sem_res.status_code == 200

    # 2. Audit logs
    audit_res = client.get("/api/mobile/v1/coordinator/audit-logs", headers=headers_coord)
    assert audit_res.status_code == 200
    assert isinstance(audit_res.json()["data"], list)

    # 3. Departmental reports summary
    report_res = client.get("/api/mobile/v1/coordinator/reports/summary", headers=headers_coord)
    assert report_res.status_code == 200
    data = report_res.json()["data"]
    assert "total_students" in data
    assert "total_teams" in data
    assert "proposals_approved" in data


# ─── 9. Strict Negative RBAC & Security Boundary Tests ────────

def test_negative_rbac_student_blocked_from_coordinator_endpoints(client, seeded_users, db_session):
    stu = seeded_users["student1"]
    headers_stu = _get_auth_headers(db_session, stu)

    # Student trying to create rubric -> MUST return 403 Forbidden JSON
    res = client.post(
        "/api/mobile/v1/evaluations/rubrics",
        headers=headers_stu,
        json={"title": "Hacked", "weight_percentage": 50.0, "max_score": 50.0}
    )
    assert res.status_code == 403
    assert res.json()["success"] is False

    # Student trying to schedule defense -> MUST return 403 Forbidden JSON
    res2 = client.post(
        "/api/mobile/v1/defenses/schedule",
        headers=headers_stu,
        json={"team_id": "dummy", "scheduled_date": "2026-11-20", "start_time": "10:00", "end_time": "11:00", "venue": "Room 101"}
    )
    assert res2.status_code == 403
    assert res2.json()["success"] is False


def test_unauthenticated_request_rejected(client):
    res = client.get("/api/mobile/v1/auth/me")
    assert res.status_code == 401
    assert res.json()["success"] is False
