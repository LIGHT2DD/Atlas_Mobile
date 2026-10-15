from fastapi import APIRouter, Depends, Request
from fastapi.responses import Response
from sqlalchemy.orm import Session

from api.core.dependencies.context import add_template_context
from api.db.database import get_db
from api.v1.services.report import ReportService
from api.v1.routes.dashboard.helpers import _require_coordinator

reports_router = APIRouter(prefix='/reports', tags=['Reports'])


@reports_router.get('')
@add_template_context('pages/dashboard/reports/index.html')
async def reports_index(request: Request, db: Session = Depends(get_db)):
    user = _require_coordinator(request)
    return {
        "page_title": "Academic Reports",
        "page_description": "Export university thesis data and grade books in CSV format",
    }


@reports_router.get('/export/{report_type}')
async def report_export_csv(report_type: str, request: Request, db: Session = Depends(get_db)):
    user = _require_coordinator(request)

    exporters = {
        'users': (ReportService.export_users_csv, 'atlas_users.csv'),
        'teams': (ReportService.export_teams_csv, 'atlas_teams.csv'),
        'proposals': (ReportService.export_proposals_csv, 'atlas_proposals.csv'),
        'milestones': (ReportService.export_milestones_csv, 'atlas_milestones.csv'),
        'submissions': (ReportService.export_submissions_csv, 'atlas_submissions.csv'),
        'defenses': (ReportService.export_defenses_csv, 'atlas_defenses.csv'),
        'grades': (ReportService.export_grades_csv, 'atlas_grades.csv'),
    }

    if report_type not in exporters:
        return Response("Invalid report type", status_code=400)

    func, filename = exporters[report_type]
    csv_data = func(db)

    return Response(
        content=csv_data,
        media_type="text/csv",
        headers={"Content-Disposition": f"attachment; filename={filename}"}
    )
