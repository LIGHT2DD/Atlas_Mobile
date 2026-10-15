import sqlalchemy as sa
import enum
import secrets
from sqlalchemy.orm import relationship

from api.core.base.base_model import BaseTableModel


def _generate_team_invite_code():
    return secrets.token_urlsafe(10)


class TeamStatus(enum.Enum):
    FORMING = 'forming'
    SUPERVISOR_REQUESTED = 'supervisor_requested'
    SUPERVISOR_ASSIGNED = 'supervisor_assigned'
    PROPOSAL_APPROVED = 'proposal_approved'
    IN_PROGRESS = 'in_progress'
    DEFENSE_SCHEDULED = 'defense_scheduled'
    COMPLETED = 'completed'


class Team(BaseTableModel):
    __tablename__ = 'teams'

    name = sa.Column(sa.String(150), nullable=False)
    project_title = sa.Column(sa.String(500), nullable=True)
    description = sa.Column(sa.Text, nullable=True)
    status = sa.Column(sa.String(50), default=TeamStatus.FORMING.value, index=True)
    invite_code = sa.Column(sa.String(24), unique=True, index=True, default=_generate_team_invite_code)

    semester_id = sa.Column(sa.String, sa.ForeignKey('semesters.id'), nullable=True, index=True)
    leader_id = sa.Column(sa.String, sa.ForeignKey('users.id'), nullable=False, index=True)
    supervisor_id = sa.Column(sa.String, sa.ForeignKey('users.id'), nullable=True, index=True)
    department_id = sa.Column(sa.String, sa.ForeignKey('departments.id'), nullable=True, index=True)

    final_score = sa.Column(sa.Float, nullable=True)
    final_grade = sa.Column(sa.String(10), nullable=True)
    grade_published = sa.Column(sa.Boolean, default=False, index=True)

    # Relationships
    semester = relationship('Semester', back_populates='teams', foreign_keys=[semester_id], lazy='selectin')
    leader = relationship('User', foreign_keys=[leader_id], lazy='selectin')
    supervisor = relationship('User', foreign_keys=[supervisor_id], lazy='selectin')
    department = relationship('Department', foreign_keys=[department_id], lazy='selectin')
    members = relationship('TeamMember', back_populates='team', cascade='all, delete-orphan', lazy='selectin')
    supervisor_requests = relationship('SupervisorRequest', back_populates='team', cascade='all, delete-orphan', lazy='selectin')
    proposal = relationship('Proposal', back_populates='team', uselist=False, cascade='all, delete-orphan', lazy='selectin')
    submissions = relationship('Submission', back_populates='team', lazy='selectin')
    defense = relationship('DefenseSchedule', back_populates='team', uselist=False, lazy='selectin')
    evaluations = relationship('Evaluation', back_populates='team', lazy='selectin')

    def to_dict(self, excludes=[]):
        return super().to_dict(excludes=excludes)
