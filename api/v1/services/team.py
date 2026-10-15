from datetime import datetime, timezone
from typing import Optional, List, Tuple
from fastapi import HTTPException
from sqlalchemy.orm import Session

from api.v1.models.user import User, UserRole
from api.v1.models.semester import Semester
from api.v1.models.team import Team, TeamStatus
from api.v1.models.team_member import TeamMember, TeamRole
from api.v1.models.supervisor_request import SupervisorRequest, SupervisorRequestStatus
from api.v1.models.audit_log import AuditLog
from api.v1.models.notification import NotificationType
from api.v1.services.notification import NotificationService
from api.v1.services.semester import SemesterService
from api.utils.loggers import create_logger

logger = create_logger(__name__)


class TeamService:

    @classmethod
    def get_student_active_team(cls, db: Session, student_id: str) -> Optional[Team]:
        """Fetch the active team the student belongs to, if any."""
        membership = db.query(TeamMember).join(Team, TeamMember.team_id == Team.id).filter(
            TeamMember.user_id == student_id,
            TeamMember.is_deleted == False,
            Team.is_deleted == False,
        ).first()
        return membership.team if membership else None

    @classmethod
    def create_team(
        cls,
        db: Session,
        student_id: Optional[str] = None,
        name: str = "",
        project_title: Optional[str] = None,
        description: Optional[str] = None,
        department_id: Optional[str] = None,
        semester_id: Optional[str] = None,
        creator_id: Optional[str] = None,
        max_members: Optional[int] = 4,
    ) -> Team:
        """Create a new team led by the student."""
        actual_student_id = student_id or creator_id
        if not actual_student_id:
            raise HTTPException(status_code=400, detail="Student ID is required.")
        student = User.fetch_by_id(db, actual_student_id)
        if student.role != UserRole.STUDENT.value:
            raise HTTPException(status_code=403, detail="Only students can form thesis teams.")

        if not project_title:
            project_title = name

        # Ensure student is not already in an active team
        existing_team = cls.get_student_active_team(db, actual_student_id)
        if existing_team:
            raise HTTPException(
                status_code=400,
                detail=f"You are already a member of team '{existing_team.name}'."
            )

        if not semester_id:
            active_sem = SemesterService.get_active_semester(db)
            if active_sem:
                semester_id = active_sem.id
            else:
                recent_sem = db.query(Semester).filter(Semester.is_deleted == False).order_by(Semester.created_at.desc()).first()
                if recent_sem:
                    semester_id = recent_sem.id

        team = Team.create(
            db=db,
            name=name.strip(),
            project_title=project_title.strip(),
            description=description.strip() if description else None,
            leader_id=actual_student_id,
            department_id=department_id or student.department_id,
            semester_id=semester_id,
            status=TeamStatus.FORMING.value,
        )

        # Add the creator as team leader
        TeamMember.create(
            db=db,
            team_id=team.id,
            user_id=actual_student_id,
            role=TeamRole.LEADER.value,
        )

        AuditLog.log(
            db=db,
            action="TEAM_CREATED",
            user_id=actual_student_id,
            entity_type="team",
            entity_id=team.id,
            details=f"Student {student.full_name} created team '{team.name}'."
        )

        return team

    @classmethod
    def join_team_via_invite(cls, db: Session, invite_code: str, student_id: str) -> Tuple[Team, str]:
        """Add a student to a team using its invite code."""
        student = User.fetch_by_id(db, student_id)
        if student.role != UserRole.STUDENT.value:
            raise HTTPException(status_code=403, detail="Only students can join thesis teams.")

        team = Team.fetch_one_by_field(db, throw_error=False, invite_code=invite_code)
        if not team:
            raise HTTPException(status_code=404, detail="Invalid team invitation link.")

        # Check existing membership in this team
        existing_member = TeamMember.fetch_one_by_field(
            db, throw_error=False, team_id=team.id, user_id=student_id
        )
        if existing_member:
            return team, "You are already a member of this team."

        # Check if student is already in another active team
        active_team = cls.get_student_active_team(db, student_id)
        if active_team:
            raise HTTPException(
                status_code=400,
                detail=f"You are already a member of team '{active_team.name}'."
            )

        # Check team size limits
        current_members = db.query(TeamMember).filter(
            TeamMember.team_id == team.id,
            TeamMember.is_deleted == False,
        ).count()

        max_allowed = 4
        if team.semester:
            max_allowed = team.semester.max_team_size

        if current_members >= max_allowed:
            raise HTTPException(
                status_code=400,
                detail=f"This team has reached its maximum size of {max_allowed} members."
            )

        TeamMember.create(
            db=db,
            team_id=team.id,
            user_id=student_id,
            role=TeamRole.MEMBER.value,
        )

        AuditLog.log(
            db=db,
            action="TEAM_MEMBER_JOINED",
            user_id=student_id,
            entity_type="team",
            entity_id=team.id,
            details=f"Student {student.full_name} joined team '{team.name}'."
        )

        return team, f"Welcome to {team.name}!"

    @classmethod
    def leave_team(cls, db: Session, team_id: str, student_id: str):
        """Allow a student to leave a team (unless they are the sole leader of a multi-person team)."""
        membership = TeamMember.fetch_one_by_field(
            db, throw_error=False, team_id=team_id, user_id=student_id
        )
        if not membership:
            raise HTTPException(status_code=404, detail="Membership not found.")

        team = Team.fetch_by_id(db, team_id)
        total_members = db.query(TeamMember).filter(
            TeamMember.team_id == team_id,
            TeamMember.is_deleted == False,
        ).count()

        if membership.role == TeamRole.LEADER.value and total_members > 1:
            raise HTTPException(
                status_code=400,
                detail="As team leader, you must transfer leadership to another member before leaving."
            )

        TeamMember.soft_delete(db, membership.id)

        # If team has no members left, soft delete team
        if total_members <= 1:
            Team.soft_delete(db, team.id)

        AuditLog.log(
            db=db,
            action="TEAM_MEMBER_LEFT",
            user_id=student_id,
            entity_type="team",
            entity_id=team_id,
            details=f"Student left team '{team.name}'."
        )

    @classmethod
    def set_team_leader(cls, db: Session, team_id: str, new_leader_id: str, actor_id: str):
        """Transfer leadership of a team."""
        team = Team.fetch_by_id(db, team_id)
        if team.leader_id != actor_id:
            actor = User.fetch_by_id(db, actor_id)
            if not actor.is_coordinator:
                raise HTTPException(status_code=403, detail="Only the current leader or a coordinator can transfer leadership.")

        new_leader_member = TeamMember.fetch_one_by_field(
            db, throw_error=False, team_id=team_id, user_id=new_leader_id
        )
        if not new_leader_member:
            raise HTTPException(status_code=400, detail="The designated user is not a member of this team.")

        # Update member roles
        db.query(TeamMember).filter(TeamMember.team_id == team_id).update({"role": TeamRole.MEMBER.value})
        new_leader_member.role = TeamRole.LEADER.value
        team.leader_id = new_leader_id
        db.commit()

        AuditLog.log(
            db=db,
            action="TEAM_LEADER_CHANGED",
            user_id=actor_id,
            entity_type="team",
            entity_id=team_id,
            details=f"Leadership of team '{team.name}' transferred to user {new_leader_id}."
        )

    @classmethod
    def request_supervisor(
        cls,
        db: Session,
        team_id: str,
        supervisor_id: str,
        student_id: str,
        notes: Optional[str] = None,
        bg_tasks=None,
    ) -> SupervisorRequest:
        """Send a formal supervisor request from a student team."""
        team = Team.fetch_by_id(db, team_id)
        if team.supervisor_id:
            raise HTTPException(status_code=400, detail="Team already has an assigned supervisor.")

        supervisor = User.fetch_by_id(db, supervisor_id)
        if supervisor.role != UserRole.SUPERVISOR.value:
            raise HTTPException(status_code=400, detail="Requested user is not a supervisor.")

        # Check existing pending requests
        existing_req = db.query(SupervisorRequest).filter(
            SupervisorRequest.team_id == team_id,
            SupervisorRequest.status == SupervisorRequestStatus.PENDING.value,
            SupervisorRequest.is_deleted == False,
        ).first()

        if existing_req:
            raise HTTPException(status_code=400, detail="You already have a pending supervisor request. Wait for a response or cancel it.")

        req = SupervisorRequest.create(
            db=db,
            team_id=team_id,
            supervisor_id=supervisor_id,
            requested_by_id=student_id,
            notes=notes.strip() if notes else None,
            status=SupervisorRequestStatus.PENDING.value,
        )

        team.status = TeamStatus.SUPERVISOR_REQUESTED.value
        db.commit()

        # Notify supervisor
        student = User.fetch_by_id(db, student_id)
        NotificationService.notify(
            db=db,
            bg_tasks=bg_tasks,
            user_id=supervisor_id,
            title="New Supervisor Request",
            content=f"Team '{team.name}' has requested you to supervise their thesis: '{team.project_title}'.",
            notification_type=NotificationType.SYSTEM.value,
            link="/dashboard/requests",
        )

        AuditLog.log(
            db=db,
            action="SUPERVISOR_REQUESTED",
            user_id=student_id,
            entity_type="supervisor_request",
            entity_id=req.id,
            details=f"Team '{team.name}' requested supervisor {supervisor.full_name}."
        )

        return req

    @classmethod
    def respond_supervisor_request(
        cls,
        db: Session,
        request_id: str,
        supervisor_id: str,
        accept: bool,
        response_notes: Optional[str] = None,
        bg_tasks=None,
    ) -> SupervisorRequest:
        """Supervisor accepts or rejects a request."""
        req = SupervisorRequest.fetch_by_id(db, request_id)
        if req.supervisor_id != supervisor_id:
            supervisor = User.fetch_by_id(db, supervisor_id)
            if not supervisor.is_coordinator:
                raise HTTPException(status_code=403, detail="Unauthorized to respond to this request.")

        if req.status != SupervisorRequestStatus.PENDING.value:
            raise HTTPException(status_code=400, detail=f"Request is already {req.status}.")

        team = Team.fetch_by_id(db, req.team_id)
        now = datetime.now(timezone.utc)

        team_member_ids = [m.user_id for m in team.members]

        if accept:
            req.status = SupervisorRequestStatus.ACCEPTED.value
            req.responded_at = now
            req.response_notes = response_notes.strip() if response_notes else None

            team.supervisor_id = req.supervisor_id
            team.status = TeamStatus.SUPERVISOR_ASSIGNED.value
            db.commit()

            NotificationService.notify_many(
                db=db,
                bg_tasks=bg_tasks,
                user_ids=team_member_ids,
                title="Supervisor Request Accepted",
                content=f"Your supervisor request to {req.supervisor.full_name} was accepted!",
                notification_type=NotificationType.SYSTEM.value,
                link=f"/dashboard/teams/{team.id}",
            )
        else:
            req.status = SupervisorRequestStatus.REJECTED.value
            req.responded_at = now
            req.response_notes = response_notes.strip() if response_notes else None

            team.status = TeamStatus.FORMING.value
            db.commit()

            NotificationService.notify_many(
                db=db,
                bg_tasks=bg_tasks,
                user_ids=team_member_ids,
                title="Supervisor Request Declined",
                content=f"Your supervisor request to {req.supervisor.full_name} was declined.",
                notification_type=NotificationType.SYSTEM.value,
                link=f"/dashboard/teams/{team.id}",
            )

        AuditLog.log(
            db=db,
            action="SUPERVISOR_REQUEST_RESPONDED",
            user_id=supervisor_id,
            entity_type="supervisor_request",
            entity_id=req.id,
            details=f"Supervisor responded '{'ACCEPTED' if accept else 'REJECTED'}' to team '{team.name}'."
        )

        return req

    @classmethod
    def assign_supervisor_administrative(
        cls,
        db: Session,
        team_id: str,
        supervisor_id: str,
        coordinator_id: str,
        bg_tasks=None,
    ) -> Team:
        """Administrative supervisor assignment by coordinator."""
        team = Team.fetch_by_id(db, team_id)
        supervisor = User.fetch_by_id(db, supervisor_id)
        if supervisor.role != UserRole.SUPERVISOR.value:
            raise HTTPException(status_code=400, detail="User is not a supervisor.")

        team.supervisor_id = supervisor_id
        team.status = TeamStatus.SUPERVISOR_ASSIGNED.value
        db.commit()

        team_member_ids = [m.user_id for m in team.members]
        NotificationService.notify_many(
            db=db,
            bg_tasks=bg_tasks,
            user_ids=team_member_ids,
            title="Supervisor Assigned by Coordinator",
            content=f"Coordinator assigned {supervisor.full_name} as your team supervisor.",
            notification_type=NotificationType.SYSTEM.value,
            link=f"/dashboard/teams/{team.id}",
        )

        AuditLog.log(
            db=db,
            action="SUPERVISOR_ASSIGNED_BY_COORDINATOR",
            user_id=coordinator_id,
            entity_type="team",
            entity_id=team_id,
            details=f"Coordinator assigned supervisor {supervisor.full_name} to team '{team.name}'."
        )

        return team
