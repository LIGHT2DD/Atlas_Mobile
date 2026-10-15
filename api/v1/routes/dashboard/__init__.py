from fastapi import APIRouter

from api.v1.routes.dashboard.overview import overview_router
from api.v1.routes.dashboard.projects import projects_router
from api.v1.routes.dashboard.submissions import submissions_router
from api.v1.routes.dashboard.milestones import (
    milestones_router, deadlines_router, project_milestones_router
)
from api.v1.routes.dashboard.messages import messages_router
from api.v1.routes.dashboard.students import students_router
from api.v1.routes.dashboard.users import users_router
from api.v1.routes.dashboard.departments import departments_router
from api.v1.routes.dashboard.settings import settings_router
from api.v1.routes.dashboard.documents import documents_router, document_view_router
from api.v1.routes.dashboard.feedback import feedback_router
from api.v1.routes.dashboard.notifications import notifications_router

# ATLAS Specific Core Routers
from api.v1.routes.dashboard.semesters import semesters_router
from api.v1.routes.dashboard.teams import teams_router, requests_router
from api.v1.routes.dashboard.proposals import proposals_router
from api.v1.routes.dashboard.defenses import defenses_router
from api.v1.routes.dashboard.evaluations import evaluations_router
from api.v1.routes.dashboard.reports import reports_router
from api.v1.routes.dashboard.audit_logs import audit_logs_router


dashboard_router = APIRouter(prefix='/dashboard', tags=['Dashboard'])

# Register all sub-routers
dashboard_router.include_router(overview_router)
dashboard_router.include_router(projects_router)
dashboard_router.include_router(semesters_router)
dashboard_router.include_router(teams_router)
dashboard_router.include_router(requests_router)
dashboard_router.include_router(proposals_router)
dashboard_router.include_router(milestones_router)
dashboard_router.include_router(deadlines_router)
dashboard_router.include_router(project_milestones_router)
dashboard_router.include_router(submissions_router)
dashboard_router.include_router(defenses_router)
dashboard_router.include_router(evaluations_router)
dashboard_router.include_router(reports_router)
dashboard_router.include_router(audit_logs_router)
dashboard_router.include_router(messages_router)
dashboard_router.include_router(students_router)
dashboard_router.include_router(users_router)
dashboard_router.include_router(departments_router)
dashboard_router.include_router(settings_router)
dashboard_router.include_router(documents_router)
dashboard_router.include_router(document_view_router)
dashboard_router.include_router(feedback_router)
dashboard_router.include_router(notifications_router)

