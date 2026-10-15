import sqlalchemy as sa
import enum
from sqlalchemy.orm import relationship

from api.core.base.base_model import BaseTableModel


class DefenseStatus(enum.Enum):
    SCHEDULED = 'scheduled'
    COMPLETED = 'completed'
    CANCELLED = 'cancelled'


class DefensePanelRole(enum.Enum):
    CHAIR = 'chair'
    MEMBER = 'member'
    EXTERNAL = 'external'


class DefenseSchedule(BaseTableModel):
    __tablename__ = 'defense_schedules'

    team_id = sa.Column(sa.String, sa.ForeignKey('teams.id', ondelete='CASCADE'), nullable=False, unique=True, index=True)
    semester_id = sa.Column(sa.String, sa.ForeignKey('semesters.id'), nullable=True, index=True)

    date = sa.Column(sa.Date, nullable=False, index=True)
    start_time = sa.Column(sa.String(10), nullable=False)  # HH:MM e.g. "10:00"
    end_time = sa.Column(sa.String(10), nullable=False)    # HH:MM e.g. "11:00"
    room = sa.Column(sa.String(100), nullable=False, index=True)
    status = sa.Column(sa.String(30), default=DefenseStatus.SCHEDULED.value, index=True)
    notes = sa.Column(sa.Text, nullable=True)

    # Relationships
    team = relationship('Team', back_populates='defense', foreign_keys=[team_id], lazy='selectin')
    semester = relationship('Semester', foreign_keys=[semester_id], lazy='selectin')
    panel_members = relationship('DefensePanelMember', back_populates='defense', cascade='all, delete-orphan', lazy='selectin')
    evaluations = relationship('Evaluation', back_populates='defense', lazy='selectin')

    @property
    def defense_date(self):
        return self.date

    @property
    def location_room(self):
        return self.room

    def to_dict(self, excludes=[]):
        from api.core.base.base_model import DateStr
        data = super().to_dict(excludes=excludes)
        if self.date:
            d_str = DateStr(self.date.isoformat())
            data['date'] = d_str
            data['defense_date'] = d_str
        data['location_room'] = self.room
        return data


class DefensePanelMember(BaseTableModel):
    __tablename__ = 'defense_panel_members'

    defense_id = sa.Column(sa.String, sa.ForeignKey('defense_schedules.id', ondelete='CASCADE'), nullable=False, index=True)
    user_id = sa.Column(sa.String, sa.ForeignKey('users.id'), nullable=False, index=True)
    role = sa.Column(sa.String(30), default=DefensePanelRole.MEMBER.value, nullable=False)

    __table_args__ = (
        sa.UniqueConstraint('defense_id', 'user_id', name='uq_defense_panel_member'),
    )

    # Relationships
    defense = relationship('DefenseSchedule', back_populates='panel_members', foreign_keys=[defense_id], lazy='selectin')
    user = relationship('User', foreign_keys=[user_id], lazy='selectin')

    @property
    def faculty(self):
        return self.user

    def to_dict(self, excludes=[]):
        data = super().to_dict(excludes=excludes)
        if self.user:
            user_data = self.user.to_dict()
            data['user'] = user_data
            data['faculty'] = user_data
        return data
