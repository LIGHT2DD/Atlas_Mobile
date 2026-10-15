from fastapi import HTTPException, Request
from api.v1.models.user import UserRole
from api.utils.loggers import create_logger

logger = create_logger(__name__)


def _get_user(request: Request):
    """Return the authenticated user or raise 401."""
    user = getattr(request.state, 'current_user', None)
    if not user:
        logger.warning(f"Unauthenticated request attempt to {request.url.path}")
        raise HTTPException(status_code=401, detail="Authentication required.")
    return user


def _is_coordinator(user) -> bool:
    if not user:
        return False
    return bool(user.role in (UserRole.COORDINATOR.value, UserRole.ADMIN.value) or getattr(user, 'is_coordinator', False))


def _is_supervisor(user) -> bool:
    if not user:
        return False
    return bool(user.role == UserRole.SUPERVISOR.value or getattr(user, 'is_supervisor', False))


def _is_student(user) -> bool:
    if not user:
        return False
    return bool(user.role == UserRole.STUDENT.value or getattr(user, 'is_student', False))


def _is_supervisor_or_coordinator(user) -> bool:
    return _is_supervisor(user) or _is_coordinator(user)


def _require_role(request: Request, allowed_roles: list[str]):
    user = _get_user(request)
    roles = set(allowed_roles)
    if UserRole.COORDINATOR.value in roles or UserRole.ADMIN.value in roles or 'admin' in roles:
        roles.add(UserRole.COORDINATOR.value)
        roles.add(UserRole.ADMIN.value)

    if user.role not in roles:
        logger.warning(f"Forbidden access: User {user.id} ({user.role}) denied on {request.url.path}. Required: {roles}")
        raise HTTPException(status_code=403, detail="You do not have permission to access this resource.")
    return user


def _require_coordinator(request: Request):
    user = _get_user(request)
    if not _is_coordinator(user):
        logger.warning(f"Forbidden access: User {user.id} ({user.role}) denied on {request.url.path}. Coordinator role required.")
        raise HTTPException(status_code=403, detail="Coordinator authorization required.")
    return user


def _require_supervisor(request: Request):
    user = _get_user(request)
    if not _is_supervisor(user):
        logger.warning(f"Forbidden access: User {user.id} ({user.role}) denied on {request.url.path}. Supervisor role required.")
        raise HTTPException(status_code=403, detail="Supervisor authorization required.")
    return user


def _require_student(request: Request):
    user = _get_user(request)
    if not _is_student(user):
        logger.warning(f"Forbidden access: User {user.id} ({user.role}) denied on {request.url.path}. Student role required.")
        raise HTTPException(status_code=403, detail="Student authorization required.")
    return user


def _require_supervisor_or_coordinator(request: Request):
    user = _get_user(request)
    if not (_is_supervisor(user) or _is_coordinator(user)):
        logger.warning(f"Forbidden access: User {user.id} ({user.role}) denied on {request.url.path}. Supervisor or Coordinator role required.")
        raise HTTPException(status_code=403, detail="Supervisor or Coordinator authorization required.")
    return user


def _paginate(request: Request, endpoint: str):
    """Extract page/size from query params."""
    try:
        page = max(1, int(request.query_params.get('page', 1)))
    except (ValueError, TypeError):
        page = 1
    try:
        size = min(100, max(1, int(request.query_params.get('size', 10))))
    except (ValueError, TypeError):
        size = 10
    return page, size

