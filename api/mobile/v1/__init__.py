from fastapi import APIRouter

from api.mobile.v1.auth import auth_mobile_router
from api.mobile.v1.teams import teams_mobile_router
from api.mobile.v1.supervisor import supervisor_mobile_router
from api.mobile.v1.proposals import proposals_mobile_router
from api.mobile.v1.milestones import milestones_mobile_router
from api.mobile.v1.submissions import submissions_mobile_router
from api.mobile.v1.defenses import defenses_mobile_router
from api.mobile.v1.evaluations import evaluations_mobile_router
from api.mobile.v1.notifications import notifications_mobile_router
from api.mobile.v1.coordinator import coordinator_mobile_router


mobile_v1_router = APIRouter(prefix="/api/mobile/v1")

mobile_v1_router.include_router(auth_mobile_router)
mobile_v1_router.include_router(teams_mobile_router)
mobile_v1_router.include_router(supervisor_mobile_router)
mobile_v1_router.include_router(proposals_mobile_router)
mobile_v1_router.include_router(milestones_mobile_router)
mobile_v1_router.include_router(submissions_mobile_router)
mobile_v1_router.include_router(defenses_mobile_router)
mobile_v1_router.include_router(evaluations_mobile_router)
mobile_v1_router.include_router(notifications_mobile_router)
mobile_v1_router.include_router(coordinator_mobile_router)
