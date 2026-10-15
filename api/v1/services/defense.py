from datetime import date, datetime
from typing import List, Optional, Dict, Any
from fastapi import HTTPException
from sqlalchemy.orm import Session

from api.v1.models.user import User, UserRole
from api.v1.models.team import Team, TeamStatus
from api.v1.models.defense import DefenseSchedule, DefensePanelMember, DefenseStatus, DefensePanelRole
from api.v1.models.audit_log import AuditLog
from api.v1.models.notification import NotificationType
from api.v1.services.notification import NotificationService
from api.utils.loggers import create_logger

logger = create_logger(__name__)


def _times_overlap(start_a: str, end_a: str, start_b: str, end_b: str) -> bool:
    """Return True if time intervals [start_a, end_a] and [start_b, end_b] overlap."""
    return max(start_a, start_b) < min(end_a, end_b)


class DefenseService:

    @classmethod
    def check_conflicts(
        cls,
        db: Session,
        defense_date: date,
        start_time: str,
        end_time: str,
        room: str,
        team_id: str,
        panel_user_ids: List[str],
        exclude_defense_id: Optional[str] = None,
    ) -> List[str]:
        """
        Detect conflicts before saving a defense schedule:
        1. Room conflict: Another defense in the same room at overlapping time.
        2. Team conflict: Same team having another defense at overlapping time.
        3. Panel conflict: Any panel member scheduled for another defense at overlapping time.
        """
        conflicts = []

        # Find other non-cancelled defenses on the same date
        query = db.query(DefenseSchedule).filter(
            DefenseSchedule.date == defense_date,
            DefenseSchedule.status != DefenseStatus.CANCELLED.value,
            DefenseSchedule.is_deleted == False,
        )
        if exclude_defense_id:
            query = query.filter(DefenseSchedule.id != exclude_defense_id)

        existing_defenses = query.all()

        for d in existing_defenses:
            if not _times_overlap(start_time, end_time, d.start_time, d.end_time):
                continue

            # 1. Room conflict
            if d.room.strip().lower() == room.strip().lower():
                conflicts.append(
                    f"Room Conflict: '{d.room}' is already booked from {d.start_time} to {d.end_time} (Team: {d.team.name if d.team else 'Unknown'})."
                )

            # 2. Team conflict
            if d.team_id == team_id:
                conflicts.append(
                    f"Team Conflict: Team '{d.team.name if d.team else team_id}' is already scheduled for defense from {d.start_time} to {d.end_time}."
                )

            # 3. Panel member conflicts
            existing_panel_ids = {p.user_id: p.user for p in d.panel_members}
            for uid in panel_user_ids:
                if uid in existing_panel_ids:
                    member_user = existing_panel_ids[uid]
                    name = member_user.full_name if member_user else uid
                    conflicts.append(
                        f"Panel Conflict: Panel member '{name}' is already assigned to a defense in room '{d.room}' from {d.start_time} to {d.end_time}."
                    )

        return conflicts

    @classmethod
    def schedule_defense(
        cls,
        db: Session,
        coordinator_id: str,
        team_id: str,
        defense_date: date,
        start_time: str,
        end_time: str,
        room: str,
        panel_members_data: List[Dict[str, str]],  # [{'user_id': str, 'role': str}]
        notes: Optional[str] = None,
        bg_tasks=None,
    ) -> DefenseSchedule:
        if end_time <= start_time:
            raise HTTPException(status_code=400, detail="End time must be after start time.")

        panel_user_ids = [p['user_id'] for p in panel_members_data if 'user_id' in p]
        if not panel_user_ids:
            raise HTTPException(status_code=400, detail="At least one panel member must be assigned.")

        # Check for conflicts
        conflicts = cls.check_conflicts(
            db=db,
            defense_date=defense_date,
            start_time=start_time,
            end_time=end_time,
            room=room,
            team_id=team_id,
            panel_user_ids=panel_user_ids,
        )

        if conflicts:
            raise HTTPException(status_code=409, detail="; ".join(conflicts))

        team = Team.fetch_by_id(db, team_id)

        # Check if team already has a defense schedule
        existing_defense = db.query(DefenseSchedule).filter(
            DefenseSchedule.team_id == team_id,
            DefenseSchedule.is_deleted == False,
        ).first()

        if existing_defense:
            # Update existing
            existing_defense.date = defense_date
            existing_defense.start_time = start_time
            existing_defense.end_time = end_time
            existing_defense.room = room.strip()
            existing_defense.notes = notes.strip() if notes else None
            existing_defense.status = DefenseStatus.SCHEDULED.value

            # Clear old panel members
            db.query(DefensePanelMember).filter(DefensePanelMember.defense_id == existing_defense.id).delete()
            defense = existing_defense
        else:
            defense = DefenseSchedule.create(
                db=db,
                team_id=team_id,
                semester_id=team.semester_id,
                date=defense_date,
                start_time=start_time,
                end_time=end_time,
                room=room.strip(),
                notes=notes.strip() if notes else None,
                status=DefenseStatus.SCHEDULED.value,
            )

        # Create panel members
        for p in panel_members_data:
            DefensePanelMember.create(
                db=db,
                defense_id=defense.id,
                user_id=p['user_id'],
                role=p.get('role', DefensePanelRole.MEMBER.value),
            )

        team.status = TeamStatus.DEFENSE_SCHEDULED.value
        db.commit()

        # Notify team members and panel
        all_notify_ids = [m.user_id for m in team.members] + panel_user_ids
        NotificationService.notify_many(
            db=db,
            bg_tasks=bg_tasks,
            user_ids=list(set(all_notify_ids)),
            title="Thesis Defense Scheduled",
            content=f"Defense for team '{team.name}' scheduled on {defense_date} from {start_time} to {end_time} in {room}.",
            notification_type=NotificationType.SYSTEM.value,
            link="/dashboard/defense",
        )

        AuditLog.log(
            db=db,
            action="DEFENSE_SCHEDULED",
            user_id=coordinator_id,
            entity_type="defense",
            entity_id=defense.id,
            details=f"Scheduled defense for team '{team.name}' on {defense_date} ({start_time}-{end_time}) in {room}."
        )

        return defense
