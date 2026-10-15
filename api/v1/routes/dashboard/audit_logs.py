from fastapi import APIRouter, Depends, Request
from sqlalchemy.orm import Session
from typing import Optional

from api.core.dependencies.context import add_template_context
from api.db.database import get_db
from api.v1.models.audit_log import AuditLog
from api.v1.routes.dashboard.helpers import _require_coordinator
from api.utils import paginator

audit_logs_router = APIRouter(prefix='/audit-logs', tags=['Audit Logs'])


@audit_logs_router.get('')
@add_template_context('pages/dashboard/audit_logs/index.html')
async def audit_logs_index(request: Request, db: Session = Depends(get_db)):
    user = _require_coordinator(request)

    page = int(request.query_params.get('page', 1))
    size = int(request.query_params.get('size', 20))
    action_filter = request.query_params.get('action')

    query = db.query(AuditLog).filter(AuditLog.is_deleted == False)
    if action_filter:
        query = query.filter(AuditLog.action.ilike(f"%{action_filter}%"))

    total = query.count()
    offset = (page - 1) * size
    logs = query.order_by(AuditLog.created_at.desc()).offset(offset).limit(size).all()

    pagination_data = {
        'page': page,
        'size': size,
        'total': total,
        'pages': max(1, (total + size - 1) // size),
        'has_next': (page * size) < total,
        'has_prev': page > 1,
    }

    return {
        "page_title": "Audit Logs",
        "page_description": "Search and monitor university lifecycle compliance events",
        "logs": [l.to_dict() for l in logs],
        "pagination_data": pagination_data,
        "action_filter": action_filter or "",
    }
