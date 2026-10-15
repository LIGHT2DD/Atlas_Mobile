from datetime import datetime, timezone
from sqlalchemy.orm import Session
from sqlalchemy import func

from api.v1.models.user import User, UserRole
from api.v1.models.team import Team, TeamStatus
from api.v1.models.team_member import TeamMember
from api.v1.models.supervisor_request import SupervisorRequest, SupervisorRequestStatus
from api.v1.models.proposal import Proposal, ProposalStatus
from api.v1.models.milestone import Milestone
from api.v1.models.submission import Submission, SubmissionStatus
from api.v1.models.defense import DefenseSchedule, DefenseStatus
from api.v1.models.notification import Notification
from api.v1.models.audit_log import AuditLog
from api.v1.models.semester import Semester
from api.v1.services.semester import SemesterService
from api.v1.services.team import TeamService
from api.utils.loggers import create_logger

logger = create_logger(__name__)


class DashboardService:
    """Aggregates meaningful stats for ATLAS role-based dashboard overviews."""

    # ── Student ───────────────────────────────────────
    @classmethod
    def student_stats(cls, db: Session, user_id: str) -> dict:
        active_sem = SemesterService.get_active_semester(db)
        team = TeamService.get_student_active_team(db, user_id)

        proposal = None
        milestones = []
        submissions = []
        defense = None
        upcoming_deadlines = []

        now = datetime.now(timezone.utc)

        if team:
            proposal = db.query(Proposal).filter(
                Proposal.team_id == team.id,
                Proposal.is_deleted == False,
            ).first()

            # Milestones for team's semester
            milestones = db.query(Milestone).filter(
                Milestone.semester_id == team.semester_id,
                Milestone.is_active == True,
                Milestone.is_deleted == False,
            ).order_by(Milestone.due_date.asc()).all()

            # Submissions by team
            submissions = db.query(Submission).filter(
                Submission.team_id == team.id,
                Submission.is_deleted == False,
            ).order_by(Submission.submitted_at.desc()).all()

            defense = db.query(DefenseSchedule).filter(
                DefenseSchedule.team_id == team.id,
                DefenseSchedule.status != DefenseStatus.CANCELLED.value,
                DefenseSchedule.is_deleted == False,
            ).first()

            # Upcoming deadlines
            for m in milestones:
                due = m.due_date.replace(tzinfo=timezone.utc) if m.due_date.tzinfo is None else m.due_date
                if due >= now:
                    submitted = any(s.milestone_id == m.id for s in submissions)
                    upcoming_deadlines.append({
                        "title": m.title,
                        "due_date": due,
                        "is_submitted": submitted,
                    })

        total_milestones = len(milestones)
        completed_submissions = sum(1 for s in submissions if s.status == SubmissionStatus.REVIEWED.value)
        progress_percentage = int((completed_submissions / total_milestones) * 100) if total_milestones > 0 else 0

        recent_notifications = db.query(Notification).filter(
            Notification.user_id == user_id,
            Notification.is_deleted == False,
        ).order_by(Notification.created_at.desc()).limit(5).all()

        return {
            "semester": active_sem,
            "team": team,
            "proposal": proposal,
            "milestones": milestones,
            "submissions": submissions,
            "defense": defense,
            "progress_percentage": progress_percentage,
            "upcoming_deadlines": upcoming_deadlines[:5],
            "recent_notifications": recent_notifications,
        }

    # ── Supervisor ────────────────────────────────────
    @classmethod
    def supervisor_stats(cls, db: Session, user_id: str) -> dict:
        active_sem = SemesterService.get_active_semester(db)

        # Assigned teams
        teams = db.query(Team).filter(
            Team.supervisor_id == user_id,
            Team.is_deleted == False,
        ).all()
        team_ids = [t.id for t in teams]

        # Pending supervisor requests
        pending_requests = db.query(SupervisorRequest).filter(
            SupervisorRequest.supervisor_id == user_id,
            SupervisorRequest.status == SupervisorRequestStatus.PENDING.value,
            SupervisorRequest.is_deleted == False,
        ).all()

        # Pending proposals to review
        pending_proposals = db.query(Proposal).filter(
            Proposal.team_id.in_(team_ids),
            Proposal.status == ProposalStatus.SUBMITTED.value,
            Proposal.is_deleted == False,
        ).all() if team_ids else []

        # Pending milestone submissions to review
        pending_submissions = db.query(Submission).filter(
            Submission.team_id.in_(team_ids),
            Submission.status.in_([SubmissionStatus.SUBMITTED.value, SubmissionStatus.LATE.value]),
            Submission.is_deleted == False,
        ).all() if team_ids else []

        # Upcoming defenses where supervisor is panel or supervisor
        upcoming_defenses = db.query(DefenseSchedule).filter(
            DefenseSchedule.team_id.in_(team_ids),
            DefenseSchedule.status == DefenseStatus.SCHEDULED.value,
            DefenseSchedule.is_deleted == False,
        ).order_by(DefenseSchedule.date.asc()).all() if team_ids else []

        recent_activity = db.query(AuditLog).filter(
            AuditLog.entity_id.in_(team_ids),
            AuditLog.is_deleted == False,
        ).order_by(AuditLog.created_at.desc()).limit(8).all() if team_ids else []

        return {
            "semester": active_sem,
            "teams": teams,
            "total_teams": len(teams),
            "pending_requests_count": len(pending_requests),
            "pending_requests": pending_requests,
            "pending_proposals_count": len(pending_proposals),
            "pending_proposals": pending_proposals,
            "pending_submissions_count": len(pending_submissions),
            "pending_submissions": pending_submissions,
            "upcoming_defenses": upcoming_defenses,
            "recent_activity": recent_activity,
        }

    # ── Coordinator ───────────────────────────────────
    @classmethod
    def admin_stats(cls, db: Session) -> dict:
        active_sem = SemesterService.get_active_semester(db)

        total_students = db.query(User).filter(User.role == UserRole.STUDENT.value, User.is_deleted == False).count()
        total_supervisors = db.query(User).filter(User.role == UserRole.SUPERVISOR.value, User.is_deleted == False).count()
        total_teams = db.query(Team).filter(Team.is_deleted == False).count()

        # Teams by status
        teams_forming = db.query(Team).filter(Team.status == TeamStatus.FORMING.value, Team.is_deleted == False).count()
        teams_sup_requested = db.query(Team).filter(Team.status == TeamStatus.SUPERVISOR_REQUESTED.value, Team.is_deleted == False).count()
        teams_active = db.query(Team).filter(Team.status.in_([TeamStatus.SUPERVISOR_ASSIGNED.value, TeamStatus.PROPOSAL_APPROVED.value, TeamStatus.IN_PROGRESS.value]), Team.is_deleted == False).count()
        teams_defense = db.query(Team).filter(Team.status == TeamStatus.DEFENSE_SCHEDULED.value, Team.is_deleted == False).count()
        teams_completed = db.query(Team).filter(Team.status == TeamStatus.COMPLETED.value, Team.is_deleted == False).count()

        # Proposals
        total_proposals = db.query(Proposal).filter(Proposal.is_deleted == False).count()
        pending_proposals = db.query(Proposal).filter(Proposal.status == ProposalStatus.SUBMITTED.value, Proposal.is_deleted == False).count()
        approved_proposals = db.query(Proposal).filter(Proposal.status == ProposalStatus.APPROVED.value, Proposal.is_deleted == False).count()
        proposal_approval_rate = int((approved_proposals / total_proposals) * 100) if total_proposals > 0 else 0

        # Submissions
        total_submissions = db.query(Submission).filter(Submission.is_deleted == False).count()
        late_submissions = db.query(Submission).filter(Submission.is_late == True, Submission.is_deleted == False).count()

        # Upcoming defenses
        now_date = datetime.now(timezone.utc).date()
        upcoming_defenses = db.query(DefenseSchedule).filter(
            DefenseSchedule.date >= now_date,
            DefenseSchedule.status == DefenseStatus.SCHEDULED.value,
            DefenseSchedule.is_deleted == False,
        ).order_by(DefenseSchedule.date.asc()).limit(5).all()

        # Recent audit logs
        recent_audit_logs = db.query(AuditLog).filter(
            AuditLog.is_deleted == False,
        ).order_by(AuditLog.created_at.desc()).limit(10).all()

        return {
            "semester": active_sem,
            "total_students": total_students,
            "total_supervisors": total_supervisors,
            "total_teams": total_teams,
            "teams_forming": teams_forming,
            "teams_sup_requested": teams_sup_requested,
            "teams_active": teams_active,
            "teams_defense": teams_defense,
            "teams_completed": teams_completed,
            "total_proposals": total_proposals,
            "pending_proposals": pending_proposals,
            "proposal_approval_rate": proposal_approval_rate,
            "total_submissions": total_submissions,
            "late_submissions": late_submissions,
            "upcoming_defenses": upcoming_defenses,
            "recent_audit_logs": recent_audit_logs,
        }
