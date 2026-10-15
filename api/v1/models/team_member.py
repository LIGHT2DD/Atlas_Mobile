import sqlalchemy as sa
import enum
from sqlalchemy.orm import relationship

from api.core.base.base_model import BaseTableModel


class TeamRole(enum.Enum):
    LEADER = 'leader'
    MEMBER = 'member'


class TeamMember(BaseTableModel):
    __tablename__ = 'team_members'

    team_id = sa.Column(sa.String, sa.ForeignKey('teams.id', ondelete='CASCADE'), nullable=False, index=True)
    user_id = sa.Column(sa.String, sa.ForeignKey('users.id'), nullable=False, index=True)
    role = sa.Column(sa.String(20), default=TeamRole.MEMBER.value, nullable=False)

    __table_args__ = (
        sa.UniqueConstraint('team_id', 'user_id', name='uq_team_member'),
    )

    # Relationships
    team = relationship('Team', back_populates='members', foreign_keys=[team_id], lazy='selectin')
    user = relationship('User', foreign_keys=[user_id], lazy='selectin')

    @property
    def is_leader(self):
        return self.role == TeamRole.LEADER.value

    def to_dict(self, excludes=[]):
        return super().to_dict(excludes=excludes)
