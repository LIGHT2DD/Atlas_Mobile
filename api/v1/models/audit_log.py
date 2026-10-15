import sqlalchemy as sa
from sqlalchemy.orm import relationship

from api.core.base.base_model import BaseTableModel


class AuditLog(BaseTableModel):
    __tablename__ = 'audit_logs'

    user_id = sa.Column(sa.String, sa.ForeignKey('users.id'), nullable=True, index=True)
    action = sa.Column(sa.String(100), nullable=False, index=True)  # e.g. "PROPOSAL_SUBMITTED", "DEFENSE_SCHEDULED"
    entity_type = sa.Column(sa.String(50), nullable=True, index=True)  # e.g. "proposal", "defense", "team"
    entity_id = sa.Column(sa.String, nullable=True, index=True)
    details = sa.Column(sa.Text, nullable=True)
    ip_address = sa.Column(sa.String(50), nullable=True)

    # Relationships
    user = relationship('User', foreign_keys=[user_id], lazy='selectin')

    @classmethod
    def log(cls, db, action: str, user_id: str = None, entity_type: str = None, entity_id: str = None, details: str = None, ip_address: str = None):
        """Helper to create audit log entry."""
        return cls.create(
            db=db,
            action=action,
            user_id=user_id,
            entity_type=entity_type,
            entity_id=entity_id,
            details=details,
            ip_address=ip_address,
        )

    def to_dict(self, excludes=[]):
        return super().to_dict(excludes=excludes)
