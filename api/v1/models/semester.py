import sqlalchemy as sa
from sqlalchemy.orm import relationship
from datetime import datetime, timezone

from api.core.base.base_model import BaseTableModel


class Semester(BaseTableModel):
    __tablename__ = 'semesters'

    name = sa.Column(sa.String(100), nullable=False)  # e.g., "Fall 2026", "Spring 2026"
    academic_year = sa.Column(sa.String(50), nullable=False)  # e.g., "2025-2026"
    start_date = sa.Column(sa.DateTime(timezone=True), nullable=False)
    end_date = sa.Column(sa.DateTime(timezone=True), nullable=False)
    is_active = sa.Column(sa.Boolean, default=True, index=True)
    max_team_size = sa.Column(sa.Integer, default=4, nullable=False)
    min_team_size = sa.Column(sa.Integer, default=1, nullable=False)
    description = sa.Column(sa.Text, nullable=True)

    # Relationships
    teams = relationship('Team', back_populates='semester', lazy='selectin')
    milestones = relationship('Milestone', back_populates='semester', lazy='selectin')
    criteria = relationship('EvaluationCriteria', back_populates='semester', lazy='selectin')

    def to_dict(self, excludes=[]):
        return super().to_dict(excludes=excludes)
