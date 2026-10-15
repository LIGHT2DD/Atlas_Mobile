import sqlalchemy as sa
import enum
from sqlalchemy.orm import relationship
from datetime import datetime, timezone

from api.core.base.base_model import BaseTableModel


class ProposalStatus(enum.Enum):
    DRAFT = 'draft'
    SUBMITTED = 'submitted'
    CHANGES_REQUESTED = 'changes_requested'
    APPROVED = 'approved'
    REJECTED = 'rejected'


class Proposal(BaseTableModel):
    __tablename__ = 'proposals'

    team_id = sa.Column(sa.String, sa.ForeignKey('teams.id', ondelete='CASCADE'), nullable=False, unique=True, index=True)
    title = sa.Column(sa.String(500), nullable=False)
    abstract = sa.Column(sa.Text, nullable=True)
    current_version = sa.Column(sa.Integer, default=1, nullable=False)
    status = sa.Column(sa.String(50), default=ProposalStatus.DRAFT.value, index=True)

    submitted_at = sa.Column(sa.DateTime(timezone=True), nullable=True)
    reviewed_at = sa.Column(sa.DateTime(timezone=True), nullable=True)

    # Relationships
    team = relationship('Team', back_populates='proposal', foreign_keys=[team_id], lazy='selectin')
    versions = relationship('ProposalVersion', back_populates='proposal', cascade='all, delete-orphan', order_by='ProposalVersion.version_number.desc()', lazy='selectin')
    reviews = relationship('ProposalReview', back_populates='proposal', cascade='all, delete-orphan', order_by='ProposalReview.created_at.desc()', lazy='selectin')

    def to_dict(self, excludes=[]):
        return super().to_dict(excludes=excludes)


class ProposalVersion(BaseTableModel):
    __tablename__ = 'proposal_versions'

    proposal_id = sa.Column(sa.String, sa.ForeignKey('proposals.id', ondelete='CASCADE'), nullable=False, index=True)
    version_number = sa.Column(sa.Integer, nullable=False)
    title = sa.Column(sa.String(500), nullable=False)
    abstract = sa.Column(sa.Text, nullable=True)
    document_id = sa.Column(sa.String, sa.ForeignKey('documents.id'), nullable=True, index=True)
    document_path = sa.Column(sa.String(1000), nullable=True)
    submitted_by_id = sa.Column(sa.String, sa.ForeignKey('users.id'), nullable=False, index=True)
    change_summary = sa.Column(sa.Text, nullable=True)
    submitted_at = sa.Column(sa.DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    # Relationships
    proposal = relationship('Proposal', back_populates='versions', foreign_keys=[proposal_id], lazy='selectin')
    submitted_by = relationship('User', foreign_keys=[submitted_by_id], lazy='selectin')
    document = relationship('Document', foreign_keys=[document_id], lazy='selectin')
    reviews = relationship('ProposalReview', back_populates='version', cascade='all, delete-orphan', lazy='selectin')

    __table_args__ = (
        sa.UniqueConstraint('proposal_id', 'version_number', name='uq_proposal_version'),
    )

    def to_dict(self, excludes=[]):
        return super().to_dict(excludes=excludes)


class ProposalReview(BaseTableModel):
    __tablename__ = 'proposal_reviews'

    proposal_id = sa.Column(sa.String, sa.ForeignKey('proposals.id', ondelete='CASCADE'), nullable=False, index=True)
    version_id = sa.Column(sa.String, sa.ForeignKey('proposal_versions.id', ondelete='CASCADE'), nullable=True, index=True)
    reviewer_id = sa.Column(sa.String, sa.ForeignKey('users.id'), nullable=False, index=True)
    decision = sa.Column(sa.String(50), nullable=False)  # approved, changes_requested, rejected
    comments = sa.Column(sa.Text, nullable=False)

    # Relationships
    proposal = relationship('Proposal', back_populates='reviews', foreign_keys=[proposal_id], lazy='selectin')
    version = relationship('ProposalVersion', back_populates='reviews', foreign_keys=[version_id], lazy='selectin')
    reviewer = relationship('User', foreign_keys=[reviewer_id], lazy='selectin')

    def to_dict(self, excludes=[]):
        return super().to_dict(excludes=excludes)
