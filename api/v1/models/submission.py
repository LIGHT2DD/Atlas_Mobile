import sqlalchemy as sa
import enum
from sqlalchemy.orm import relationship
from datetime import datetime, timezone

from api.core.base.base_model import BaseTableModel


class SubmissionStatus(enum.Enum):
    MISSING = 'missing'
    SUBMITTED = 'submitted'
    LATE = 'late'
    UNDER_REVIEW = 'under_review'
    REVIEWED = 'reviewed'
    APPROVED = 'approved'
    REVISION_REQUIRED = 'revision_required'
    REJECTED = 'rejected'


class Submission(BaseTableModel):
    __tablename__ = 'submissions'
    
    title = sa.Column(sa.String(255), nullable=False)
    description = sa.Column(sa.Text, nullable=True)
    status = sa.Column(sa.String(30), default=SubmissionStatus.SUBMITTED.value, index=True)
    
    milestone_id = sa.Column(sa.String, sa.ForeignKey('milestones.id'), nullable=True, index=True)
    team_id = sa.Column(sa.String, sa.ForeignKey('teams.id', ondelete='CASCADE'), nullable=True, index=True)
    project_id = sa.Column(sa.String, sa.ForeignKey('projects.id'), nullable=True, index=True)
    submitted_by = sa.Column(sa.String, sa.ForeignKey('users.id'), nullable=False, index=True)
    document_id = sa.Column(sa.String, sa.ForeignKey('documents.id'), nullable=True, index=True)

    file_path = sa.Column(sa.String(1000), nullable=True)
    code_url = sa.Column(sa.String(500), nullable=True)
    version = sa.Column(sa.Integer, default=1, nullable=False)
    is_late = sa.Column(sa.Boolean, default=False, index=True)
    submitted_at = sa.Column(sa.DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    score = sa.Column(sa.Float, nullable=True)
    feedback = sa.Column(sa.Text, nullable=True)
    
    # Relationships
    milestone = relationship('Milestone', back_populates='submissions', foreign_keys=[milestone_id], lazy='selectin')
    team = relationship('Team', back_populates='submissions', foreign_keys=[team_id], lazy='selectin')
    submitter = relationship('User', foreign_keys=[submitted_by], lazy='selectin')
    document = relationship('Document', foreign_keys=[document_id], lazy='selectin')
    feedbacks = relationship('Feedback', backref='submission', cascade='all, delete-orphan', lazy='selectin')

    def to_dict(self, excludes=[]):
        return super().to_dict(excludes=excludes)
