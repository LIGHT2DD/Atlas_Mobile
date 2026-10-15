"""
ATLAS Database Seeder
Populates a complete, realistic university thesis lifecycle dataset for development & demonstration.

Credentials:
- Coordinator: coordinator@atlas.edu / Password123
- Supervisors: supervisor1@atlas.edu, supervisor2@atlas.edu, supervisor3@atlas.edu / Password123
- Students:    student1@atlas.edu through student12@atlas.edu / Password123

Usage:
    python -m scripts.seeders.seed_atlas
"""

import sys
import os
from datetime import datetime, date, timedelta, timezone

# Ensure project root is on path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..')))

from passlib.context import CryptContext
from api.db.database import get_db_with_ctx_manager, create_database
from api.v1.models import (
    User, UserRole,
    Department,
    Semester,
    Team, TeamStatus,
    TeamMember, TeamRole,
    SupervisorRequest, SupervisorRequestStatus,
    Proposal, ProposalStatus, ProposalVersion, ProposalReview,
    Milestone, MilestoneStatus,
    Submission, SubmissionStatus,
    EvaluationCriteria, Evaluation, EvaluationScore,
    DefenseSchedule, DefensePanelMember, DefenseStatus, DefensePanelRole,
    Notification, NotificationType,
    AuditLog,
)

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
PASSWORD_HASH = pwd_context.hash("Password123")


def seed_atlas():
    print("=" * 60)
    print("[*] SEEDING ATLAS: Academic Thesis Lifecycle & Assessment Suite")
    print("=" * 60)


    create_database()

    with get_db_with_ctx_manager() as db:
        now = datetime.now()

        # ── 1. Departments ─────────────────────────────────────
        print("--> Seeding Departments...")
        depts_data = [
            {"name": "Computer Science & Engineering", "code": "CSE", "description": "Department of Computer Science and Engineering"},
            {"name": "Software Engineering", "code": "SWE", "description": "Department of Software Engineering"},
            {"name": "Information Technology", "code": "IT", "description": "Department of Information Technology"},
        ]
        departments = {}
        for d_info in depts_data:
            existing = db.query(Department).filter(Department.name == d_info["name"]).first()
            if not existing:
                existing = Department.create(db=db, **d_info)
            departments[d_info["code"]] = existing

        # ── 2. Semesters ───────────────────────────────────────
        print("--> Seeding Semesters...")
        active_semester = db.query(Semester).filter(Semester.name == "Fall 2026").first()
        if not active_semester:
            active_semester = Semester.create(
                db=db,
                name="Fall 2026",
                academic_year="2026-2027",
                start_date=date(2026, 9, 1),
                end_date=date(2027, 1, 31),
                is_active=True,
            )
        else:
            active_semester.is_active = True
            db.commit()

        past_semester = db.query(Semester).filter(Semester.name == "Spring 2026").first()
        if not past_semester:
            past_semester = Semester.create(
                db=db,
                name="Spring 2026",
                academic_year="2025-2026",
                start_date=date(2026, 2, 1),
                end_date=date(2026, 6, 30),
                is_active=False,
            )

        # ── 3. Users ───────────────────────────────────────────
        print("--> Seeding Users...")
        # Coordinator
        coordinator = db.query(User).filter(User.email == "coordinator@atlas.edu").first()
        if not coordinator:
            coordinator = User.create(
                db=db,
                first_name="Prof. Nazim",
                last_name="Uddin",
                email="coordinator@atlas.edu",
                password=PASSWORD_HASH,
                role=UserRole.COORDINATOR.value,
                is_active=True,
            )
        else:
            coordinator.first_name = "Prof. Nazim"
            coordinator.last_name = "Uddin"
            db.commit()

        # Supervisors
        supervisors_data = [
            ("Fatema Jannat", "Dihan", "supervisor1@atlas.edu"),
            ("Tanvir", "Ahmed", "supervisor2@atlas.edu"),
            ("Md Abu Rumman", "Refat", "supervisor3@atlas.edu"),
        ]
        supervisors = []
        for fn, ln, em in supervisors_data:
            sup = db.query(User).filter(User.email == em).first()
            if not sup:
                sup = User.create(
                    db=db,
                    first_name=fn,
                    last_name=ln,
                    email=em,
                    password=PASSWORD_HASH,
                    role=UserRole.SUPERVISOR.value,
                    is_active=True,
                )
            else:
                sup.first_name = fn
                sup.last_name = ln
                db.commit()
            supervisors.append(sup)

        # Students (12)
        students_data = [
            ("Tahmid", "Hasan", "student1@atlas.edu"),
            ("Samiul", "Islam", "student2@atlas.edu"),
            ("Nahid", "Hossain", "student3@atlas.edu"),
            ("Rafiul", "Karim", "student4@atlas.edu"),
            ("Tanzeem", "Rahman", "student5@atlas.edu"),
            ("Mahmudul", "Hasan", "student6@atlas.edu"),
            ("Farhan", "Ishrak", "student7@atlas.edu"),
            ("Nafis", "Fuad", "student8@atlas.edu"),
            ("Wasif", "Chowdhury", "student9@atlas.edu"),
            ("Arifur", "Rahman", "student10@atlas.edu"),
            ("Shahriar", "Kabir", "student11@atlas.edu"),
            ("Zubair", "Ahmed", "student12@atlas.edu"),
        ]
        students = []
        for fn, ln, em in students_data:
            stu = db.query(User).filter(User.email == em).first()
            if not stu:
                stu = User.create(
                    db=db,
                    first_name=fn,
                    last_name=ln,
                    email=em,
                    password=PASSWORD_HASH,
                    role=UserRole.STUDENT.value,
                    is_active=True,
                )
            else:
                stu.first_name = fn
                stu.last_name = ln
                db.commit()
            students.append(stu)

        # ── 4. Teams & Members ─────────────────────────────────
        print("--> Seeding Teams & Members...")
        teams_data = [
            {
                "name": "Neural Nexus",
                "department": departments["SWE"],
                "supervisor": supervisors[0],
                "status": TeamStatus.COMPLETED.value,
                "leader": students[0],
                "members": [students[0], students[1], students[2]],
                "final_score": 92.5,
                "final_grade": "A+",
                "published": True,
            },
            {
                "name": "Distributed Ledger Lab",
                "department": departments["CSE"],
                "supervisor": supervisors[1],
                "status": TeamStatus.IN_PROGRESS.value,
                "leader": students[3],
                "members": [students[3], students[4], students[5]],
                "final_score": 86.0,
                "final_grade": "A",
                "published": False,
            },
            {
                "name": "Autonomous Drone Fleet",
                "department": departments["IT"],
                "supervisor": supervisors[2],
                "status": TeamStatus.SUPERVISOR_REQUESTED.value,
                "leader": students[6],
                "members": [students[6], students[7], students[8]],
                "final_score": None,
                "final_grade": None,
                "published": False,
            },
            {
                "name": "Quantum Secure Key Exchange",
                "department": departments["CSE"],
                "supervisor": None,
                "status": TeamStatus.FORMING.value,
                "leader": students[9],
                "members": [students[9], students[10], students[11]],
                "final_score": None,
                "final_grade": None,
                "published": False,
            },
        ]

        teams = []
        for td in teams_data:
            t = db.query(Team).filter(Team.name == td["name"]).first()
            if not t:
                t = Team.create(
                    db=db,
                    name=td["name"],
                    project_title=td["name"],
                    leader_id=td["leader"].id,
                    semester_id=active_semester.id,
                    department_id=td["department"].id if td["department"] else None,
                    supervisor_id=td["supervisor"].id if td["supervisor"] else None,
                    status=td["status"],
                    final_score=td["final_score"],
                    final_grade=td["final_grade"],
                    grade_published=td["published"],
                )
                # Add members
                for m_user in td["members"]:
                    role = TeamRole.LEADER.value if m_user.id == td["leader"].id else TeamRole.MEMBER.value
                    TeamMember.create(
                        db=db,
                        team_id=t.id,
                        user_id=m_user.id,
                        role=role,
                    )
            teams.append(t)

        # ── 5. Supervisor Requests ─────────────────────────────
        print("--> Seeding Supervisor Requests...")
        # Team 3 requested supervisor 3
        if not db.query(SupervisorRequest).filter(SupervisorRequest.team_id == teams[2].id).first():
            SupervisorRequest.create(
                db=db,
                team_id=teams[2].id,
                supervisor_id=supervisors[2].id,
                requested_by_id=students[6].id,
                status=SupervisorRequestStatus.PENDING.value,
                notes="Dear Professor Refat, we would be honored to have your guidance on our autonomous multi-agent drone coordination thesis.",
            )

        # ── 6. Proposals, Versions, Reviews ────────────────────
        print("--> Seeding Proposals & Version History...")
        # Team 1: Approved Proposal with 2 Versions
        p1 = db.query(Proposal).filter(Proposal.team_id == teams[0].id).first()
        if not p1:
            p1 = Proposal.create(
                db=db,
                team_id=teams[0].id,
                title="Distributed Neural Consensus Algorithm For Real-Time Edge Clustering",
                abstract="This thesis explores a novel fault-tolerant distributed consensus algorithm optimized for low-latency neural processing clusters on heterogeneous edge devices.",
                current_version=2,
                status=ProposalStatus.APPROVED.value,
                submitted_at=now - timedelta(days=45),
                reviewed_at=now - timedelta(days=40),
            )
            # Version 1 (Changes Requested)
            ProposalVersion.create(
                db=db,
                proposal_id=p1.id,
                version_number=1,
                title="Distributed Neural Consensus Algorithm",
                abstract="Initial abstract proposing neural clustering consensus.",
                submitted_by_id=students[0].id,
                created_at=now - timedelta(days=50),
            )
            ProposalReview.create(
                db=db,
                proposal_id=p1.id,
                reviewer_id=supervisors[0].id,
                decision=ProposalStatus.CHANGES_REQUESTED.value,
                comments="Strong conceptual foundation, but please elaborate on the Byzantine fault tolerance mechanisms and formal mathematical proof requirements.",
                created_at=now - timedelta(days=46),
            )
            # Version 2 (Approved)
            ProposalVersion.create(
                db=db,
                proposal_id=p1.id,
                version_number=2,
                title="Distributed Neural Consensus Algorithm For Real-Time Edge Clustering",
                abstract=p1.abstract,
                change_summary="Expanded Byzantine fault tolerance section and added formal convergence proofs in Chapter 3.",
                submitted_by_id=students[0].id,
                created_at=now - timedelta(days=45),
            )
            ProposalReview.create(
                db=db,
                proposal_id=p1.id,
                reviewer_id=supervisors[0].id,
                decision=ProposalStatus.APPROVED.value,
                comments="Revisions thoroughly address all concerns. The fault model is rigorous. Approved to proceed to SRS.",
                created_at=now - timedelta(days=40),
            )

        # Team 2: Approved Proposal v1
        p2 = db.query(Proposal).filter(Proposal.team_id == teams[1].id).first()
        if not p2:
            p2 = Proposal.create(
                db=db,
                team_id=teams[1].id,
                title="High-Throughput Sharded Blockchain for Cross-Border Academic Credential Verification",
                abstract="A cryptographically secure decentralized ledger for instant verification of university degrees across transnational academic institutions.",
                current_version=1,
                status=ProposalStatus.APPROVED.value,
                submitted_at=now - timedelta(days=35),
                reviewed_at=now - timedelta(days=32),
            )
            ProposalVersion.create(
                db=db,
                proposal_id=p2.id,
                version_number=1,
                title=p2.title,
                abstract=p2.abstract,
                submitted_by_id=students[3].id,
                created_at=now - timedelta(days=35),
            )
            ProposalReview.create(
                db=db,
                proposal_id=p2.id,
                reviewer_id=supervisors[1].id,
                decision=ProposalStatus.APPROVED.value,
                comments="Excellent scope and clear social impact. Approved.",
                created_at=now - timedelta(days=32),
            )

        # Team 3: Submitted Proposal v1
        p3 = db.query(Proposal).filter(Proposal.team_id == teams[2].id).first()
        if not p3:
            p3 = Proposal.create(
                db=db,
                team_id=teams[2].id,
                title="Autonomous Pathfinding in GPS-Denied Environments using Visual Odometry",
                abstract="Investigating swarm UAV visual-inertial odometry algorithms for emergency rescue operations in indoor GPS-denied catastrophe zones.",
                current_version=1,
                status=ProposalStatus.SUBMITTED.value,
                submitted_at=now - timedelta(days=5),
            )
            ProposalVersion.create(
                db=db,
                proposal_id=p3.id,
                version_number=1,
                title=p3.title,
                abstract=p3.abstract,
                submitted_by_id=students[6].id,
                created_at=now - timedelta(days=5),
            )


        # ── 7. Milestones & Deadlines ───────────────────────────
        print("--> Seeding Milestones & Deadlines...")
        milestones_list = [
            ("Proposal Submission", "Initial thesis title, abstract, methodology and scope proposal.", now - timedelta(days=30), 50.0, 10.0),
            ("Software Requirements Specification (SRS)", "Comprehensive IEEE-compliant SRS document detailing functional and non-functional requirements.", now - timedelta(days=15), 100.0, 15.0),
            ("Midterm Architecture & Prototype", "System architecture diagram, data schema, and working functional core prototype.", now + timedelta(days=15), 100.0, 25.0),
            ("Final Codebase & Test Suite", "Complete implemented software repository with automated tests and CI/CD pipeline.", now + timedelta(days=40), 100.0, 25.0),
            ("Final Thesis Report & Defense", "Full academic dissertation report and oral defense presentation slides.", now + timedelta(days=60), 100.0, 25.0),
        ]

        milestones = []
        for m_title, m_desc, m_due, m_max, m_wt in milestones_list:
            m = db.query(Milestone).filter(Milestone.title == m_title, Milestone.semester_id == active_semester.id).first()
            if not m:
                m = Milestone.create(
                    db=db,
                    title=m_title,
                    description=m_desc,
                    due_date=m_due,
                    max_score=m_max,
                    weight_percentage=m_wt,
                    semester_id=active_semester.id,
                    status=MilestoneStatus.PENDING.value,
                    is_active=True,
                )
            milestones.append(m)

        # ── 8. Milestone Submissions ───────────────────────────
        print("--> Seeding Milestone Submissions...")
        # Team 1 submitted SRS & Midterm
        if not db.query(Submission).filter(Submission.team_id == teams[0].id, Submission.milestone_id == milestones[1].id).first():
            Submission.create(
                db=db,
                title="SRS Deliverable - Neural Nexus",
                team_id=teams[0].id,
                milestone_id=milestones[1].id,
                submitted_by=students[0].id,
                code_url="https://github.com/atlas-demo/neural-consensus-engine",
                status=SubmissionStatus.REVIEWED.value,
                submitted_at=now - timedelta(days=18),
                is_late=False,
                score=95.0,
                feedback="Exemplary SRS document. Use cases and mathematical specifications are well structured.",
            )

        if not db.query(Submission).filter(Submission.team_id == teams[0].id, Submission.milestone_id == milestones[2].id).first():
            Submission.create(
                db=db,
                title="Midterm Prototype Deliverable",
                team_id=teams[0].id,
                milestone_id=milestones[2].id,
                submitted_by=students[0].id,
                code_url="https://github.com/atlas-demo/neural-consensus-engine/tree/prototype",
                status=SubmissionStatus.REVIEWED.value,
                submitted_at=now - timedelta(days=2),
                is_late=False,
                score=90.0,
                feedback="Prototype demo shows verified consensus convergence across simulated cluster nodes.",
            )

        # Team 2 submitted SRS
        if not db.query(Submission).filter(Submission.team_id == teams[1].id, Submission.milestone_id == milestones[1].id).first():
            Submission.create(
                db=db,
                title="SRS Deliverable - Distributed Ledger Lab",
                team_id=teams[1].id,
                milestone_id=milestones[1].id,
                submitted_by=students[3].id,
                code_url="https://github.com/atlas-demo/sharded-credentials",
                status=SubmissionStatus.REVIEWED.value,
                submitted_at=now - timedelta(days=14),
                is_late=False,
                score=88.0,
                feedback="Well written. Ensure privacy guarantees under GDPR compliance are detailed in section 4.",
            )


        # ── 9. Evaluation Rubrics ──────────────────────────────
        print("--> Seeding Rubrics Criteria...")
        rubrics_data = [
            ("Problem Definition & Literature Review", 10.0, 100.0, "Clarity of problem formulation and depth of academic literature synthesis.", 1),
            ("Methodology & Mathematical Modeling", 15.0, 100.0, "Theoretical soundness and rigorous justification of chosen methodologies.", 2),
            ("Implementation & Engineering Quality", 25.0, 100.0, "Code quality, architecture, design patterns, testing, and deployment execution.", 3),
            ("Technical Documentation & Report", 15.0, 100.0, "Adherence to academic dissertation formatting, grammar, and completeness.", 4),
            ("Oral Presentation & Live Demonstration", 15.0, 100.0, "Clarity of slides, effective communication, and live functional demo.", 5),
            ("Defense Viva & Defense Q&A", 20.0, 100.0, "Ability to answer technical panel questions and defend algorithmic decisions.", 6),
        ]

        rubric_criteria = []
        for r_title, r_wt, r_max, r_desc, r_order in rubrics_data:
            crit = db.query(EvaluationCriteria).filter(EvaluationCriteria.title == r_title, EvaluationCriteria.semester_id == active_semester.id).first()
            if not crit:
                crit = EvaluationCriteria.create(
                    db=db,
                    title=r_title,
                    weight_percentage=r_wt,
                    max_score=r_max,
                    description=r_desc,
                    semester_id=active_semester.id,
                    order_index=r_order,
                )
            rubric_criteria.append(crit)

        # ── 10. Defense Schedules ──────────────────────────────
        print("--> Seeding Defense Schedules...")
        # Team 1 Defense
        d1 = db.query(DefenseSchedule).filter(DefenseSchedule.team_id == teams[0].id).first()
        if not d1:
            d1 = DefenseSchedule.create(
                db=db,
                team_id=teams[0].id,
                semester_id=active_semester.id,
                date=date(2026, 12, 10),
                start_time="10:00",
                end_time="11:30",
                room="Main Auditorium Lab 401",
                status=DefenseStatus.COMPLETED.value,
            )
            DefensePanelMember.create(db=db, defense_id=d1.id, user_id=supervisors[1].id, role=DefensePanelRole.CHAIR.value)
            DefensePanelMember.create(db=db, defense_id=d1.id, user_id=supervisors[2].id, role=DefensePanelRole.MEMBER.value)

        # Team 2 Defense
        d2 = db.query(DefenseSchedule).filter(DefenseSchedule.team_id == teams[1].id).first()
        if not d2:
            d2 = DefenseSchedule.create(
                db=db,
                team_id=teams[1].id,
                semester_id=active_semester.id,
                date=date(2026, 12, 12),
                start_time="14:00",
                end_time="15:30",
                room="Conference Room 204",
                status=DefenseStatus.SCHEDULED.value,
            )
            DefensePanelMember.create(db=db, defense_id=d2.id, user_id=supervisors[0].id, role=DefensePanelRole.CHAIR.value)
            DefensePanelMember.create(db=db, defense_id=d2.id, user_id=supervisors[2].id, role=DefensePanelRole.MEMBER.value)

        # ── 11. Evaluations & Scores ───────────────────────────
        print("--> Seeding Evaluations & Rubric Scores...")
        if not db.query(Evaluation).filter(Evaluation.team_id == teams[0].id).first():
            eval1 = Evaluation.create(
                db=db,
                team_id=teams[0].id,
                evaluator_id=supervisors[1].id,
                overall_comments="Outstanding thesis presentation and flawless live demonstration of Byzantine edge consensus.",
                calculated_score=92.5,
                is_submitted=True,
            )
            scores = [95.0, 92.0, 94.0, 90.0, 92.0, 91.0]
            for crit, sc in zip(rubric_criteria, scores):
                EvaluationScore.create(
                    db=db,
                    evaluation_id=eval1.id,
                    criteria_id=crit.id,
                    score=sc,
                )


        # ── 12. Notifications & Audit Logs ─────────────────────
        print("--> Seeding Notifications & Audit Logs...")
        Notification.create(
            db=db,
            user_id=students[0].id,
            title="Final Grade Published",
            content="Your official thesis assessment for 'Neural Nexus' has been published by the Academic Coordinator: Grade A+ (92.5%).",
            type=NotificationType.SYSTEM.value,
            link="/dashboard/grades",
        )
        Notification.create(
            db=db,
            user_id=supervisors[2].id,
            title="New Supervision Request",
            content="Team 'Autonomous Drone Fleet' has requested you as their thesis supervisor.",
            type=NotificationType.PROJECT_UPDATE.value,
            link="/dashboard/requests",
        )

        AuditLog.log(
            db=db,
            action="GRADE_PUBLISHED",
            user_id=coordinator.id,
            entity_type="team",
            entity_id=teams[0].id,
            details=f"Published official final grade A+ (92.5%) for Team '{teams[0].name}'.",
        )
        AuditLog.log(
            db=db,
            action="DEFENSE_SCHEDULED",
            user_id=coordinator.id,
            entity_type="defense",
            entity_id=d2.id,
            details=f"Scheduled oral defense for Team '{teams[1].name}' on 2026-12-12 in Conference Room 204.",
        )

        db.commit()

    print("=" * 60)
    print("[+] ATLAS SEEDING COMPLETED SUCCESSFULLY!")
    print("=" * 60)
    print("\nAcademic Demo Accounts:")
    print(" - Coordinator:  coordinator@atlas.edu   / Password123")
    print(" - Supervisors:  supervisor1@atlas.edu   / Password123")
    print("                 supervisor2@atlas.edu   / Password123")
    print("                 supervisor3@atlas.edu   / Password123")
    print(" - Students:     student1@atlas.edu      / Password123  (Team Leader, Graded A+)")
    print("                 student4@atlas.edu      / Password123  (Team Leader, In Progress)")
    print("                 student7@atlas.edu      / Password123  (Supervisor Requested)")
    print("                 student10@atlas.edu     / Password123  (Forming Team)")
    print("=" * 60)



if __name__ == "__main__":
    seed_atlas()
