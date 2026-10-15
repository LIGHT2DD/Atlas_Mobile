import csv
import io
from typing import List
from sqlalchemy.orm import Session

from api.v1.models.user import User
from api.v1.models.team import Team
from api.v1.models.proposal import Proposal
from api.v1.models.milestone import Milestone
from api.v1.models.submission import Submission
from api.v1.models.defense import DefenseSchedule
from api.v1.models.evaluation import Evaluation


class ReportService:

    @classmethod
    def export_users_csv(cls, db: Session) -> str:
        users = db.query(User).filter(User.is_deleted == False).order_by(User.role, User.last_name).all()
        output = io.StringIO()
        writer = csv.writer(output)
        writer.writerow(["ID", "First Name", "Last Name", "Email", "Role", "Active", "Created At"])
        for u in users:
            writer.writerow([
                u.id, u.first_name, u.last_name, u.email, u.role,
                "Yes" if u.is_active else "No",
                u.created_at.strftime("%Y-%m-%d %H:%M") if u.created_at else ""
            ])
        return output.getvalue()

    @classmethod
    def export_teams_csv(cls, db: Session) -> str:
        teams = db.query(Team).filter(Team.is_deleted == False).order_by(Team.created_at.desc()).all()
        output = io.StringIO()
        writer = csv.writer(output)
        writer.writerow(["ID", "Team Name", "Project Title", "Leader", "Supervisor", "Semester", "Status", "Final Score", "Final Grade", "Grade Published"])
        for t in teams:
            leader_name = t.leader.full_name if t.leader else ""
            sup_name = t.supervisor.full_name if t.supervisor else "Unassigned"
            sem_name = t.semester.name if t.semester else ""
            writer.writerow([
                t.id, t.name, t.project_title, leader_name, sup_name, sem_name,
                t.status, t.final_score or "", t.final_grade or "", "Yes" if t.grade_published else "No"
            ])
        return output.getvalue()

    @classmethod
    def export_proposals_csv(cls, db: Session) -> str:
        proposals = db.query(Proposal).filter(Proposal.is_deleted == False).order_by(Proposal.created_at.desc()).all()
        output = io.StringIO()
        writer = csv.writer(output)
        writer.writerow(["ID", "Team", "Proposal Title", "Current Version", "Status", "Submitted At", "Reviewed At"])
        for p in proposals:
            team_name = p.team.name if p.team else ""
            sub_at = p.submitted_at.strftime("%Y-%m-%d %H:%M") if p.submitted_at else ""
            rev_at = p.reviewed_at.strftime("%Y-%m-%d %H:%M") if p.reviewed_at else ""
            writer.writerow([p.id, team_name, p.title, p.current_version, p.status, sub_at, rev_at])
        return output.getvalue()

    @classmethod
    def export_milestones_csv(cls, db: Session) -> str:
        milestones = db.query(Milestone).filter(Milestone.is_deleted == False).order_by(Milestone.due_date.asc()).all()
        output = io.StringIO()
        writer = csv.writer(output)
        writer.writerow(["ID", "Milestone Title", "Semester", "Due Date", "Max Score", "Weight %", "Status", "Active"])
        for m in milestones:
            sem_name = m.semester.name if m.semester else ""
            due = m.due_date.strftime("%Y-%m-%d %H:%M") if m.due_date else ""
            writer.writerow([m.id, m.title, sem_name, due, m.max_score, m.weight_percentage, m.status, "Yes" if m.is_active else "No"])
        return output.getvalue()

    @classmethod
    def export_submissions_csv(cls, db: Session) -> str:
        submissions = db.query(Submission).filter(Submission.is_deleted == False).order_by(Submission.submitted_at.desc()).all()
        output = io.StringIO()
        writer = csv.writer(output)
        writer.writerow(["ID", "Submission Title", "Team", "Milestone", "Submitter", "Version", "Is Late", "Status", "Score", "Submitted At"])
        for s in submissions:
            team_name = s.team.name if s.team else ""
            m_title = s.milestone.title if s.milestone else ""
            sub_name = s.submitter.full_name if s.submitter else ""
            sub_at = s.submitted_at.strftime("%Y-%m-%d %H:%M") if s.submitted_at else ""
            writer.writerow([
                s.id, s.title, team_name, m_title, sub_name, s.version,
                "Yes" if s.is_late else "No", s.status, s.score or "", sub_at
            ])
        return output.getvalue()

    @classmethod
    def export_defenses_csv(cls, db: Session) -> str:
        defenses = db.query(DefenseSchedule).filter(DefenseSchedule.is_deleted == False).order_by(DefenseSchedule.date.asc()).all()
        output = io.StringIO()
        writer = csv.writer(output)
        writer.writerow(["ID", "Team", "Date", "Start Time", "End Time", "Room", "Status", "Panel Members"])
        for d in defenses:
            team_name = d.team.name if d.team else ""
            panel = "; ".join(f"{p.user.full_name} ({p.role})" for p in d.panel_members if p.user)
            writer.writerow([d.id, team_name, str(d.date), d.start_time, d.end_time, d.room, d.status, panel])
        return output.getvalue()

    @classmethod
    def export_grades_csv(cls, db: Session) -> str:
        teams = db.query(Team).filter(Team.is_deleted == False).order_by(Team.final_score.desc().nullslast()).all()
        output = io.StringIO()
        writer = csv.writer(output)
        writer.writerow(["Team ID", "Team Name", "Project Title", "Leader", "Supervisor", "Semester", "Score (100)", "Letter Grade", "Published"])
        for t in teams:
            leader_name = t.leader.full_name if t.leader else ""
            sup_name = t.supervisor.full_name if t.supervisor else "Unassigned"
            sem_name = t.semester.name if t.semester else ""
            writer.writerow([
                t.id, t.name, t.project_title, leader_name, sup_name, sem_name,
                t.final_score or "N/A", t.final_grade or "N/A", "Yes" if t.grade_published else "No"
            ])
        return output.getvalue()
