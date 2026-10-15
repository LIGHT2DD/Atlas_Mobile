import sqlalchemy as sa
import enum
from sqlalchemy.orm import relationship
from datetime import datetime, timezone

from api.core.base.base_model import BaseTableModel


class SupervisorRequestStatus(enum.Enum):
    PENDING = 'pending'
    ACCEPTED = 'accepted'
    REJECTED = 'rejected'
    CANCELLED = 'cancelled'


class SupervisorRequest(BaseTableModel):
    __tablename__ = 'supervisor_requests'

    team_id = sa.Column(sa.String, sa.ForeignKey('teams.id', ondelete='CASCADE'), nullable=False, index=True)
    supervisor_id = sa.Column(sa.String, sa.ForeignKey('users.id'), nullable=False, index=True)
    requested_by_id = sa.Column(sa.String, sa.ForeignKey('users.id'), nullable=False, index=True)

    status = sa.Column(sa.String(30), default=SupervisorRequestStatus.PENDING.value, index=True)
    notes = sa.Column(sa.Text, nullable=True)  # Message from student team
    response_notes = sa.Column(sa.Text, nullable=True)  # Reason / response from supervisor
    responded_at = sa.Column(sa.DateTime(timezone=True), nullable=True)

    # Relationships
    team = relationship('Team', back_populates='supervisor_requests', foreign_keys=[team_id], lazy='selectin')
    supervisor = relationship('User', foreign_keys=[supervisor_id], lazy='selectin')
    requested_by = relationship('User', foreign_keys=[requested_by_id], lazy='selectin')

    def to_dict(self, excludes=[]):
        return super().to_dict(excludes=excludes)
