import sqlalchemy as sa
from sqlalchemy.orm import relationship

from api.core.base.base_model import BaseTableModel


class EvaluationCriteria(BaseTableModel):
    __tablename__ = 'evaluation_criteria'

    semester_id = sa.Column(sa.String, sa.ForeignKey('semesters.id'), nullable=True, index=True)
    title = sa.Column(sa.String(200), nullable=False)
    description = sa.Column(sa.Text, nullable=True)
    weight_percentage = sa.Column(sa.Float, nullable=False)  # e.g. 15.0 for 15%
    max_score = sa.Column(sa.Float, default=100.0, nullable=False)
    order_index = sa.Column(sa.Integer, default=0, nullable=False)
    is_active = sa.Column(sa.Boolean, default=True, index=True)

    # Relationships
    semester = relationship('Semester', back_populates='criteria', foreign_keys=[semester_id], lazy='selectin')
    scores = relationship('EvaluationScore', back_populates='criteria', lazy='selectin')

    def to_dict(self, excludes=[]):
        return super().to_dict(excludes=excludes)


class Evaluation(BaseTableModel):
    __tablename__ = 'evaluations'

    team_id = sa.Column(sa.String, sa.ForeignKey('teams.id', ondelete='CASCADE'), nullable=False, index=True)
    evaluator_id = sa.Column(sa.String, sa.ForeignKey('users.id'), nullable=False, index=True)
    defense_id = sa.Column(sa.String, sa.ForeignKey('defense_schedules.id', ondelete='SET NULL'), nullable=True, index=True)

    overall_comments = sa.Column(sa.Text, nullable=True)
    calculated_score = sa.Column(sa.Float, nullable=True)  # Weighted total out of 100
    is_submitted = sa.Column(sa.Boolean, default=False, index=True)

    __table_args__ = (
        sa.Index('ix_evaluations_team_defense', 'team_id', 'defense_id'),
    )

    # Relationships
    team = relationship('Team', back_populates='evaluations', foreign_keys=[team_id], lazy='selectin')
    evaluator = relationship('User', foreign_keys=[evaluator_id], lazy='selectin')
    defense = relationship('DefenseSchedule', back_populates='evaluations', foreign_keys=[defense_id], lazy='selectin')
    scores = relationship('EvaluationScore', back_populates='evaluation', cascade='all, delete-orphan', lazy='selectin')

    def to_dict(self, excludes=[]):
        return super().to_dict(excludes=excludes)


class EvaluationScore(BaseTableModel):
    __tablename__ = 'evaluation_scores'

    evaluation_id = sa.Column(sa.String, sa.ForeignKey('evaluations.id', ondelete='CASCADE'), nullable=False, index=True)
    criteria_id = sa.Column(sa.String, sa.ForeignKey('evaluation_criteria.id'), nullable=False, index=True)
    score = sa.Column(sa.Float, nullable=False)  # Raw score out of criteria.max_score
    comments = sa.Column(sa.Text, nullable=True)

    __table_args__ = (
        sa.UniqueConstraint('evaluation_id', 'criteria_id', name='uq_eval_criteria_score'),
    )

    # Relationships
    evaluation = relationship('Evaluation', back_populates='scores', foreign_keys=[evaluation_id], lazy='selectin')
    criteria = relationship('EvaluationCriteria', back_populates='scores', foreign_keys=[criteria_id], lazy='selectin')

    def to_dict(self, excludes=[]):
        return super().to_dict(excludes=excludes)
