from datetime import datetime, timezone
from typing import Optional, Tuple
from fastapi import HTTPException
from sqlalchemy.orm import Session

from api.v1.models.user import User, UserRole
from api.v1.models.team import Team, TeamStatus
from api.v1.models.proposal import Proposal, ProposalVersion, ProposalReview, ProposalStatus
from api.v1.models.audit_log import AuditLog
from api.v1.models.notification import NotificationType
from api.v1.services.notification import NotificationService
from api.utils.loggers import create_logger

logger = create_logger(__name__)


class ProposalService:

    @classmethod
    def get_or_create_draft(
        cls,
        db: Session,
        team_id: str,
        student_id: str,
        title: str,
        abstract: Optional[str] = None,
    ) -> Proposal:
        """Fetch existing proposal for the team or create an initial draft."""
        team = Team.fetch_by_id(db, team_id)
        is_member = any(m.user_id == student_id for m in team.members)
        if not is_member:
            raise HTTPException(status_code=403, detail="You must be a member of this team.")

        proposal = db.query(Proposal).filter(
            Proposal.team_id == team_id,
            Proposal.is_deleted == False,
        ).first()

        if proposal:
            if proposal.status not in (ProposalStatus.DRAFT.value, ProposalStatus.CHANGES_REQUESTED.value):
                raise HTTPException(status_code=400, detail=f"Proposal is already {proposal.status}. You cannot edit drafts right now.")
            proposal.title = title.strip()
            if abstract:
                proposal.abstract = abstract.strip()
            db.commit()
            return proposal

        proposal = Proposal.create(
            db=db,
            team_id=team_id,
            title=title.strip(),
            abstract=abstract.strip() if abstract else None,
            current_version=1,
            status=ProposalStatus.DRAFT.value,
        )

        AuditLog.log(
            db=db,
            action="PROPOSAL_DRAFT_CREATED",
            user_id=student_id,
            entity_type="proposal",
            entity_id=proposal.id,
            details=f"Created proposal draft: '{proposal.title}'"
        )

        return proposal

    @classmethod
    def submit_proposal(
        cls,
        db: Session,
        proposal_id: str,
        student_id: str,
        title: Optional[str] = None,
        abstract: Optional[str] = None,
        document_id: Optional[str] = None,
        document_path: Optional[str] = None,
        change_summary: Optional[str] = None,
        bg_tasks=None,
    ) -> Tuple[Proposal, ProposalVersion]:
        """
        Submit or resubmit a proposal.
        Enforces state transition:
        - DRAFT -> SUBMITTED (Version 1)
        - CHANGES_REQUESTED -> SUBMITTED (Version N+1)
        """
        proposal = Proposal.fetch_by_id(db, proposal_id)
        team = Team.fetch_by_id(db, proposal.team_id)

        is_member = any(m.user_id == student_id for m in team.members)
        if not is_member:
            raise HTTPException(status_code=403, detail="Only team members can submit proposals.")

        if not team.supervisor_id:
            raise HTTPException(status_code=400, detail="Team must have an assigned supervisor before submitting a proposal.")

        now = datetime.now(timezone.utc)

        if proposal.status == ProposalStatus.DRAFT.value:
            # First submission: Version 1
            proposal.status = ProposalStatus.SUBMITTED.value
            proposal.current_version = 1
            proposal.submitted_at = now
            if title:
                proposal.title = title.strip()
            if abstract:
                proposal.abstract = abstract.strip()

            version = ProposalVersion.create(
                db=db,
                proposal_id=proposal.id,
                version_number=1,
                title=proposal.title,
                abstract=proposal.abstract,
                document_id=document_id,
                document_path=document_path,
                submitted_by_id=student_id,
                change_summary=change_summary or "Initial submission",
                submitted_at=now,
            )

        elif proposal.status == ProposalStatus.CHANGES_REQUESTED.value:
            # Resubmission: Increment version
            next_ver = proposal.current_version + 1
            proposal.status = ProposalStatus.SUBMITTED.value
            proposal.current_version = next_ver
            proposal.submitted_at = now
            if title:
                proposal.title = title.strip()
            if abstract:
                proposal.abstract = abstract.strip()

            version = ProposalVersion.create(
                db=db,
                proposal_id=proposal.id,
                version_number=next_ver,
                title=proposal.title,
                abstract=proposal.abstract,
                document_id=document_id,
                document_path=document_path,
                submitted_by_id=student_id,
                change_summary=change_summary or f"Version {next_ver} resubmission address feedback",
                submitted_at=now,
            )

        else:
            raise HTTPException(
                status_code=400,
                detail=f"Invalid state transition: Cannot submit proposal with status '{proposal.status}'."
            )

        db.commit()

        # Notify supervisor
        submitter = User.fetch_by_id(db, student_id)
        NotificationService.notify(
            db=db,
            bg_tasks=bg_tasks,
            user_id=team.supervisor_id,
            title=f"Proposal Submitted (v{version.version_number})",
            content=f"Team '{team.name}' has submitted proposal v{version.version_number}: '{proposal.title}'.",
            notification_type=NotificationType.SUBMISSION.value,
            link=f"/dashboard/proposals/{proposal.id}",
        )

        AuditLog.log(
            db=db,
            action="PROPOSAL_SUBMITTED",
            user_id=student_id,
            entity_type="proposal",
            entity_id=proposal.id,
            details=f"Submitted proposal version {version.version_number}."
        )

        return proposal, version

    @classmethod
    def review_proposal(
        cls,
        db: Session,
        proposal_id: str,
        reviewer_id: str,
        decision: str,  # 'approved', 'changes_requested', 'rejected'
        comments: str,
        bg_tasks=None,
    ) -> ProposalReview:
        """
        Supervisor reviews proposal:
        - SUBMITTED -> APPROVED
        - SUBMITTED -> CHANGES_REQUESTED
        - SUBMITTED -> REJECTED
        """
        proposal = Proposal.fetch_by_id(db, proposal_id)
        team = Team.fetch_by_id(db, proposal.team_id)
        reviewer = User.fetch_by_id(db, reviewer_id)

        if team.supervisor_id != reviewer_id and not reviewer.is_coordinator:
            raise HTTPException(status_code=403, detail="Only the assigned supervisor or a coordinator can review this proposal.")

        if proposal.status != ProposalStatus.SUBMITTED.value:
            raise HTTPException(
                status_code=400,
                detail=f"Invalid state transition: Proposal is '{proposal.status}'. Reviews require 'submitted' status."
            )

        normalized_decision = decision.strip().lower()
        if normalized_decision not in ('approved', 'changes_requested', 'rejected'):
            raise HTTPException(status_code=400, detail="Decision must be 'approved', 'changes_requested', or 'rejected'.")

        now = datetime.now(timezone.utc)
        proposal.reviewed_at = now

        # Get latest version
        latest_version = db.query(ProposalVersion).filter(
            ProposalVersion.proposal_id == proposal.id,
            ProposalVersion.version_number == proposal.current_version,
        ).first()

        review = ProposalReview.create(
            db=db,
            proposal_id=proposal.id,
            version_id=latest_version.id if latest_version else None,
            reviewer_id=reviewer_id,
            decision=normalized_decision,
            comments=comments.strip(),
        )

        if normalized_decision == 'approved':
            proposal.status = ProposalStatus.APPROVED.value
            team.status = TeamStatus.PROPOSAL_APPROVED.value
            notification_title = "Proposal Approved!"
            notification_msg = f"Your thesis proposal '{proposal.title}' was approved by {reviewer.full_name}!"
        elif normalized_decision == 'changes_requested':
            proposal.status = ProposalStatus.CHANGES_REQUESTED.value
            notification_title = "Changes Requested on Proposal"
            notification_msg = f"{reviewer.full_name} requested revisions for '{proposal.title}'. Review feedback and resubmit."
        else:
            proposal.status = ProposalStatus.REJECTED.value
            notification_title = "Proposal Rejected"
            notification_msg = f"Your thesis proposal was marked rejected by {reviewer.full_name}."

        db.commit()

        # Notify team members
        team_member_ids = [m.user_id for m in team.members]
        NotificationService.notify_many(
            db=db,
            bg_tasks=bg_tasks,
            user_ids=team_member_ids,
            title=notification_title,
            content=notification_msg,
            notification_type=NotificationType.FEEDBACK.value,
            link=f"/dashboard/proposals/{proposal.id}",
        )

        AuditLog.log(
            db=db,
            action=f"PROPOSAL_{normalized_decision.upper()}",
            user_id=reviewer_id,
            entity_type="proposal",
            entity_id=proposal.id,
            details=f"Reviewer {reviewer.full_name} marked proposal '{proposal.title}' as {normalized_decision}."
        )

        return review
