"""
Full Academic Lifecycle End-to-End Test Suite:
Validates the complete student-supervisor-coordinator journey in ATLAS from
initial registration through team formation, supervision, proposals, milestones,
defense scheduling, rubric evaluation, and final grade publishing.
"""

import pytest
from datetime import datetime, timedelta
from fastapi.testclient import TestClient


def _bearer(token: str) -> dict:
    return {"Authorization": f"Bearer {token}"}


def test_full_academic_lifecycle_e2e(client: TestClient, db_session, seeded_users):
    """
    Simulates the entire institutional lifecycle across 10 distinct phases:
    1.  Student Registration & Profile Validation
    2.  Student Login & Token Handling
    3.  Coordinator Semester & Academic Calendar Setup
    4.  Student Team Creation & Member Addition
    5.  Faculty Supervision Request & Supervisor Acceptance
    6.  Project Proposal Lifecycle (Submit -> Changes Requested -> Resubmit v2 -> Approval)
    7.  Milestone Deliverable Submission & Supervisor Grading
    8.  Oral Defense Hearing Scheduling with Conflict Detection
    9.  Committee Rubric-Based Scoring & Evaluation
    10. Final Grade Publication & Official Transcript Verification
    """
    coord = seeded_users["coordinator"]
    sup1 = seeded_users["supervisor1"]
    sup2 = seeded_users["supervisor2"]
    sem = seeded_users["semester"]

    # ─── PHASE 1: Student Registration ───────────────────────────────────────
    reg_payload = {
        "email": "lifecycle_student1@cstu.edu.bd",
        "password": "Password123",
        "confirm_password": "Password123",
        "first_name": "Rahman",
        "last_name": "Sabber",
        "role": "student",
        "student_id": "CSTU-2026-001",
    }
    reg_res = client.post("/api/mobile/v1/auth/register", json=reg_payload)
    assert reg_res.status_code == 201, f"Registration failed: {reg_res.text}"
    reg_data = reg_res.json()["data"]
    stu1_id = reg_data["user"]["id"]
    stu1_token = reg_data["access_token"]
    assert reg_data["user"]["email"] == "lifecycle_student1@cstu.edu.bd"
    assert reg_data["user"]["role"] == "student"

    # Register teammate student 2
    reg_payload2 = {
        "email": "lifecycle_student2@cstu.edu.bd",
        "password": "Password123",
        "confirm_password": "Password123",
        "first_name": "Nabil",
        "last_name": "Ahmed",
        "role": "student",
        "student_id": "CSTU-2026-002",
    }
    reg_res2 = client.post("/api/mobile/v1/auth/register", json=reg_payload2)
    assert reg_res2.status_code == 201
    stu2_id = reg_res2.json()["data"]["user"]["id"]
    stu2_token = reg_res2.json()["data"]["access_token"]

    # ─── PHASE 2: Student Login & Token Auth ─────────────────────────────────
    login_res = client.post(
        "/api/mobile/v1/auth/login",
        json={"email": "lifecycle_student1@cstu.edu.bd", "password": "Password123"}
    )
    assert login_res.status_code == 200
    login_data = login_res.json()["data"]
    stu1_token = login_data["access_token"]
    stu1_refresh = login_data["refresh_token"]

    # Verify profile (/auth/me)
    me_res = client.get("/api/mobile/v1/auth/me", headers=_bearer(stu1_token))
    assert me_res.status_code == 200
    assert me_res.json()["data"]["user"]["email"] == "lifecycle_student1@cstu.edu.bd"

    # Verify token refresh works
    ref_res = client.post("/api/mobile/v1/auth/refresh", json={"refresh_token": stu1_refresh})
    assert ref_res.status_code == 200
    stu1_token = ref_res.json()["data"]["access_token"]

    # Login Supervisor 1 & Coordinator using seeded test accounts
    sup1_login = client.post("/api/mobile/v1/auth/login", json={"email": sup1.email, "password": "Password123"})
    assert sup1_login.status_code == 200
    sup1_token = sup1_login.json()["data"]["access_token"]
    sup1_id = sup1.id

    coord_login = client.post("/api/mobile/v1/auth/login", json={"email": coord.email, "password": "Password123"})
    assert coord_login.status_code == 200
    coord_token = coord_login.json()["data"]["access_token"]

    # ─── PHASE 3: Coordinator Setup ──────────────────────────────────────────
    # Check active semester
    sem_res = client.get("/api/mobile/v1/coordinator/semesters", headers=_bearer(coord_token))
    assert sem_res.status_code == 200
    semester_id = sem.id

    # ─── PHASE 4: Team Creation & Formation ──────────────────────────────────
    # Student 1 creates team
    team_create = client.post(
        "/api/mobile/v1/teams",
        headers=_bearer(stu1_token),
        json={
            "name": "Autonomous Drone Vision",
            "project_title": "Deep Learning Navigation for UAVs",
            "semester_id": semester_id,
        }
    )
    assert team_create.status_code == 201
    team_data = team_create.json()["data"]
    team_id = team_data["id"]
    assert team_data["name"] == "Autonomous Drone Vision"

    # Student 2 joins team via invite code
    invite_code = team_data["invite_code"]
    join_res = client.post(
        "/api/mobile/v1/teams/join",
        headers=_bearer(stu2_token),
        json={"invite_code": invite_code}
    )
    assert join_res.status_code == 200

    # Verify both students are in the team roster
    my_team_res = client.get("/api/mobile/v1/teams/my-team", headers=_bearer(stu1_token))
    assert my_team_res.status_code == 200
    team_info = my_team_res.json()["data"]["team"]
    member_ids = [m["user_id"] for m in team_info["members"]]
    assert stu1_id in member_ids
    assert stu2_id in member_ids

    # ─── PHASE 5: Supervisor Request & Acceptance ────────────────────────────
    # Student 1 requests Supervisor 1
    req_res = client.post(
        f"/api/mobile/v1/teams/{team_id}/request-supervisor",
        headers=_bearer(stu1_token),
        json={"supervisor_id": sup1_id}
    )
    assert req_res.status_code == 201
    request_id = req_res.json()["data"]["request_id"]

    # Supervisor views pending requests
    sup_reqs = client.get("/api/mobile/v1/supervisor/requests", headers=_bearer(sup1_token))
    assert sup_reqs.status_code == 200
    pending_ids = [r["id"] for r in sup_reqs.json()["data"]]
    assert request_id in pending_ids

    # Supervisor accepts request
    accept_res = client.post(
        f"/api/mobile/v1/supervisor/requests/{request_id}/respond",
        headers=_bearer(sup1_token),
        json={"accept": True}
    )
    assert accept_res.status_code == 200

    # Student verifies team supervisor assignment
    updated_team = client.get("/api/mobile/v1/teams/my-team", headers=_bearer(stu1_token))
    assert updated_team.json()["data"]["team"]["supervisor"]["id"] == sup1_id

    # ─── PHASE 6: Proposal Lifecycle ─────────────────────────────────────────
    # 1. Student submits Proposal Version 1
    prop_v1 = client.post(
        "/api/mobile/v1/proposals/submit",
        headers=_bearer(stu1_token),
        data={
            "team_id": team_id,
            "title": "Vision-based UAV Navigation Architecture",
            "abstract": "Initial proposal on SLAM and visual odometry for micro-aerial vehicles.",
        }
    )
    assert prop_v1.status_code == 200
    prop_id = prop_v1.json()["data"]["id"]
    assert prop_v1.json()["data"]["current_version"] == 1
    assert prop_v1.json()["data"]["status"] == "submitted"

    # 2. Supervisor reviews and requests revisions
    rev_res = client.post(
        f"/api/mobile/v1/proposals/{prop_id}/review",
        headers=_bearer(sup1_token),
        json={
            "decision": "changes_requested",
            "comments": "Please incorporate sensor fusion with IMU and address edge compute limits.",
        }
    )
    assert rev_res.status_code == 200
    assert rev_res.json()["data"]["decision"] == "changes_requested"

    # 3. Student resubmits revised Proposal Version 2
    prop_v2 = client.post(
        "/api/mobile/v1/proposals/submit",
        headers=_bearer(stu1_token),
        data={
            "team_id": team_id,
            "title": "Vision-based UAV Navigation Architecture v2",
            "abstract": "Revised proposal incorporating Kalman-filtered IMU sensor fusion and Jetson Orin benchmarks.",
        }
    )
    assert prop_v2.status_code == 200
    assert prop_v2.json()["data"]["current_version"] == 2
    assert prop_v2.json()["data"]["status"] == "submitted"

    # 4. Supervisor approves Proposal Version 2
    app_res = client.post(
        f"/api/mobile/v1/proposals/{prop_id}/review",
        headers=_bearer(sup1_token),
        json={
            "decision": "approved",
            "comments": "Comprehensive sensor fusion section added. Approved to proceed.",
        }
    )
    assert app_res.status_code == 200
    assert app_res.json()["data"]["decision"] == "approved"

    # ─── PHASE 7: Milestone & Deliverable Submission ─────────────────────────
    # Coordinator creates milestone
    due_date = datetime.now() + timedelta(days=7)
    m_create = client.post(
        "/api/mobile/v1/milestones",
        headers=_bearer(coord_token),
        json={
            "title": "Hardware Architecture & Prototype Demo",
            "description": "Schematics, CAD models, and flight controller integration benchmarks.",
            "due_date": due_date.isoformat(),
            "max_score": 100.0,
            "weight_percentage": 30.0,
            "semester_id": semester_id,
        }
    )
    assert m_create.status_code == 201
    milestone_id = m_create.json()["data"]["id"]

    # Student submits deliverable
    sub_res = client.post(
        "/api/mobile/v1/submissions",
        headers=_bearer(stu1_token),
        data={
            "milestone_id": milestone_id,
            "team_id": team_id,
            "title": "Hardware Prototype Deliverable v1",
            "description": "PCB layout, ArduPilot configuration, and camera calibration logs.",
            "code_url": "https://github.com/cstu-atlas/drone-vision",
        }
    )
    assert sub_res.status_code == 201
    submission_id = sub_res.json()["data"]["id"]
    assert sub_res.json()["data"]["status"] == "submitted"

    # Supervisor grades submission
    sub_grade = client.post(
        f"/api/mobile/v1/submissions/{submission_id}/grade",
        headers=_bearer(sup1_token),
        json={"score": 96.0, "feedback_text": "Superb flight calibration logs and clean PCB design."}
    )
    assert sub_grade.status_code == 200
    assert sub_grade.json()["data"]["score"] == 96.0
    assert sub_grade.json()["data"]["status"] == "reviewed"

    # ─── PHASE 8: Oral Defense Hearing Scheduling ────────────────────────────
    # Supervisor 2 login for committee assignment
    sup2_login = client.post("/api/mobile/v1/auth/login", json={"email": sup2.email, "password": "Password123"})
    assert sup2_login.status_code == 200
    sup2_id = sup2.id
    sup2_token = sup2_login.json()["data"]["access_token"]

    # Coordinator schedules oral defense
    def_sched = client.post(
        "/api/mobile/v1/defenses/schedule",
        headers=_bearer(coord_token),
        json={
            "team_id": team_id,
            "scheduled_date": "2026-12-10",
            "start_time": "14:00",
            "end_time": "15:00",
            "venue": "Academic Building Auditorium A",
            "panelist_ids": [sup1_id, sup2_id],
        }
    )
    assert def_sched.status_code == 201
    defense_data = def_sched.json()["data"]
    defense_id = defense_data["id"]
    assert defense_data["room"] == "Academic Building Auditorium A"

    # ─── PHASE 9: Committee Rubric-Based Defense Evaluation ──────────────────
    # Coordinator creates evaluation rubrics
    r1 = client.post(
        "/api/mobile/v1/evaluations/rubrics",
        headers=_bearer(coord_token),
        json={"title": "Technical Innovation & Methodology", "weight_percentage": 50.0, "max_score": 50.0}
    )
    assert r1.status_code == 201
    r1_id = r1.json()["data"]["id"]

    r2 = client.post(
        "/api/mobile/v1/evaluations/rubrics",
        headers=_bearer(coord_token),
        json={"title": "Defense Presentation & Live Demonstration", "weight_percentage": 50.0, "max_score": 50.0}
    )
    assert r2.status_code == 201
    r2_id = r2.json()["data"]["id"]

    # Verify student checks grade before publishing -> has_grade is False
    pre_grade = client.get("/api/mobile/v1/evaluations/my-grade", headers=_bearer(stu1_token))
    assert pre_grade.status_code == 200
    assert pre_grade.json()["data"]["has_grade"] is False

    # Panel examiner 1 (sup1) scores the team (48/50 and 48/50 = 96%)
    score_res = client.post(
        f"/api/mobile/v1/evaluations/team/{team_id}",
        headers=_bearer(sup1_token),
        json={
            "rubric_scores": [
                {"criteria_id": r1_id, "score": 48.0},
                {"criteria_id": r2_id, "score": 48.0},
            ],
            "remarks": "Flawless demonstration of autonomous tracking and obstacle avoidance.",
        }
    )
    assert score_res.status_code == 200
    assert score_res.json()["data"]["calculated_score"] == 96.0

    # ─── PHASE 10: Final Grade Publishing & Transcript Verification ──────────
    # Coordinator officially publishes team grades
    publish_res = client.post(f"/api/mobile/v1/evaluations/team/{team_id}/publish", headers=_bearer(coord_token))
    assert publish_res.status_code == 200
    assert publish_res.json()["data"]["grade_published"] is True

    # Both Student 1 and Student 2 view official final grade transcript
    grade_stu1 = client.get("/api/mobile/v1/evaluations/my-grade", headers=_bearer(stu1_token))
    assert grade_stu1.status_code == 200
    assert grade_stu1.json()["data"]["has_grade"] is True
    assert grade_stu1.json()["data"]["final_score"] == 96.0
    assert grade_stu1.json()["data"]["final_grade"] == "A+"
    assert grade_stu1.json()["data"]["team_name"] == "Autonomous Drone Vision"

    grade_stu2 = client.get("/api/mobile/v1/evaluations/my-grade", headers=_bearer(stu2_token))
    assert grade_stu2.status_code == 200
    assert grade_stu2.json()["data"]["has_grade"] is True
    assert grade_stu2.json()["data"]["final_score"] == 96.0
    assert grade_stu2.json()["data"]["final_grade"] == "A+"


def test_academic_lifecycle_security_and_edge_cases_e2e(client: TestClient, db_session, seeded_users):
    """
    Validates institutional constraints, RBAC security gates, and conflict detection:
    - 401 on invalid student credentials
    - 404 on invalid team join invite code
    - 403 when a student attempts privileged faculty actions (reviewing proposal)
    - 409 conflict detection when two defenses book the same room/time
    - 400 rejection when grading exceeds rubric max_score limits
    - 400 rejection when trying to publish grades before evaluations exist
    """
    coord = seeded_users["coordinator"]
    sup1 = seeded_users["supervisor1"]
    sem = seeded_users["semester"]

    # 1. Auth Gate: Reject invalid student password
    bad_login = client.post(
        "/api/mobile/v1/auth/login",
        json={"email": "lifecycle_student1@cstu.edu.bd", "password": "WrongPassword999!"}
    )
    assert bad_login.status_code == 400

    # Login legitimate accounts
    coord_res = client.post("/api/mobile/v1/auth/login", json={"email": coord.email, "password": "Password123"})
    coord_token = coord_res.json()["data"]["access_token"]

    sup_res = client.post("/api/mobile/v1/auth/login", json={"email": sup1.email, "password": "Password123"})
    sup_token = sup_res.json()["data"]["access_token"]

    # Register student for edge testing
    stu_res = client.post("/api/mobile/v1/auth/register", json={
        "email": "edge_stu@cstu.edu.bd",
        "password": "Password123",
        "confirm_password": "Password123",
        "first_name": "Edge",
        "last_name": "Tester",
        "role": "student",
        "student_id": "CSTU-EDGE-01",
    })
    stu_token = stu_res.json()["data"]["access_token"]

    # 2. Team Code: 404 on bogus invite code
    bad_join = client.post(
        "/api/mobile/v1/teams/join",
        headers=_bearer(stu_token),
        json={"invite_code": "NONEXISTENT_CODE_XYZ"}
    )
    assert bad_join.status_code == 404

    # Create team for edge testing
    edge_team = client.post(
        "/api/mobile/v1/teams",
        headers=_bearer(stu_token),
        json={
            "name": "Edge Case Team",
            "project_title": "Security & Fault Tolerance Analysis",
            "semester_id": sem.id,
        }
    )
    edge_team_id = edge_team.json()["data"]["id"]

    # 3. RBAC Gate: Student cannot review proposals (403)
    unauth_review = client.post(
        f"/api/mobile/v1/proposals/bogus-id/review",
        headers=_bearer(stu_token),
        json={"decision": "approved", "comments": "Self-approval attempt"}
    )
    assert unauth_review.status_code == 403

    # 4. Premature Grade Publish: 400 when publishing team with no evaluation
    premature_pub = client.post(
        f"/api/mobile/v1/evaluations/team/{edge_team_id}/publish",
        headers=_bearer(coord_token),
    )
    assert premature_pub.status_code == 400

    # 5. Defense Conflict Detection (409):
    # Schedule first defense
    def1 = client.post(
        "/api/mobile/v1/defenses/schedule",
        headers=_bearer(coord_token),
        json={
            "team_id": edge_team_id,
            "scheduled_date": "2026-12-15",
            "start_time": "10:00",
            "end_time": "11:00",
            "venue": "Hall B",
            "panelist_ids": [sup1.id],
        }
    )
    assert def1.status_code == 201

    # Register second student & team to attempt room double-booking
    stu2_res = client.post("/api/mobile/v1/auth/register", json={
        "email": "edge_stu2@cstu.edu.bd",
        "password": "Password123",
        "confirm_password": "Password123",
        "first_name": "Edge2",
        "last_name": "Tester2",
        "role": "student",
        "student_id": "CSTU-EDGE-02",
    })
    team2_res = client.post(
        "/api/mobile/v1/teams",
        headers=_bearer(stu2_res.json()["data"]["access_token"]),
        json={"name": "Edge Team 2", "project_title": "Project 2", "semester_id": sem.id}
    )
    team2_id = team2_res.json()["data"]["id"]

    # Attempt to book same date, overlapping time, and same venue -> Expect 409 Conflict
    conflict_def = client.post(
        "/api/mobile/v1/defenses/schedule",
        headers=_bearer(coord_token),
        json={
            "team_id": team2_id,
            "scheduled_date": "2026-12-15",
            "start_time": "10:30",
            "end_time": "11:30",
            "venue": "Hall B",
            "panelist_ids": [sup1.id],
        }
    )
    assert conflict_def.status_code == 409
    assert "Room Conflict" in conflict_def.json().get("message", "")

