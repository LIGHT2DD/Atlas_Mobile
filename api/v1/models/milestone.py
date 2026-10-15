import sqlalchemy as sa
import enum
from sqlalchemy.orm import relationship

from api.core.base.base_model import BaseTableModel


class MilestoneStatus(enum.Enum):
    PENDING = 'pending'
    IN_PROGRESS = 'in_progress'
    COMPLETED = 'completed'
    OVERDUE = 'overdue'


class Milestone(BaseTableModel):
    __tablename__ = 'milestones'
    
    title = sa.Column(sa.String(255), nullable=False)
    description = sa.Column(sa.Text, nullable=True)
    due_date = sa.Column(sa.DateTime(timezone=True), nullable=False)
    status = sa.Column(sa.String(30), default=MilestoneStatus.PENDING.value, index=True)
    max_score = sa.Column(sa.Float, default=100.0, nullable=False)
    weight_percentage = sa.Column(sa.Float, default=0.0, nullable=True)
    is_active = sa.Column(sa.Boolean, default=True, index=True)
    
    semester_id = sa.Column(sa.String, sa.ForeignKey('semesters.id'), nullable=True, index=True)
    project_id = sa.Column(sa.String, sa.ForeignKey('projects.id'), nullable=True, index=True)
    
    # Relationships
    semester = relationship('Semester', back_populates='milestones', foreign_keys=[semester_id], lazy='selectin')
    submissions = relationship('Submission', back_populates='milestone', lazy='selectin')
    
    def to_dict(self, excludes=[]):
        return super().to_dict(excludes=excludes)
