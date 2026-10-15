from typing import Optional, List, Callable
from fastapi import Request, HTTPException, Depends
from fastapi.responses import JSONResponse
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session

from api.db.database import get_db
from api.v1.models.user import User, UserRole
from api.v1.services.auth import AuthService


bearer_scheme = HTTPBearer(auto_error=False)


def mobile_response(data: Optional[dict | list] = None, message: str = "Operation completed successfully.", status_code: int = 200) -> JSONResponse:
    return JSONResponse(
        status_code=status_code,
        content={
            "success": True,
            "status_code": status_code,
            "message": message,
            "data": data,
            "errors": None
        }
    )


def mobile_error(message: str, status_code: int = 400, errors: Optional[List[str]] = None) -> JSONResponse:
    return JSONResponse(
        status_code=status_code,
        content={
            "success": False,
            "status_code": status_code,
            "message": message,
            "data": None,
            "errors": errors or [message]
        }
    )


def get_current_user_mobile(
    request: Request,
    auth_header: Optional[HTTPAuthorizationCredentials] = Depends(bearer_scheme),
    db: Session = Depends(get_db)
) -> User:
    """
    Extract and validate JWT access token from Authorization header or cookie.
    Raises standard 401 HTTPException if invalid or missing.
    """
    token_str = None
    if auth_header and auth_header.credentials:
        token_str = auth_header.credentials.strip()
    elif request.headers.get("authorization", "").startswith("Bearer "):
        token_str = request.headers.get("authorization")[7:].strip()
    elif request.cookies.get("access_token"):
        token_str = request.cookies.get("access_token")

    if not token_str:
        raise HTTPException(
            status_code=401,
            detail="Authentication credentials were not provided.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    credentials_exception = HTTPException(
        status_code=401,
        detail="Could not validate credentials or session has expired.",
        headers={"WWW-Authenticate": "Bearer"},
    )

    token_data = AuthService.verify_access_token(
        db=db,
        access_token=token_str,
        credentials_exception=credentials_exception,
    )

    user = User.fetch_by_id(db=db, id=token_data.user_id)
    if not user or not user.is_active:
        raise HTTPException(
            status_code=401,
            detail="Account is inactive or does not exist.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    return user


def require_roles_mobile(*allowed_roles: str) -> Callable:
    """
    Dependency factory to enforce role-based access control.
    Treats 'admin' and 'coordinator' interchangeably.
    """
    roles_set = set(allowed_roles)
    if UserRole.COORDINATOR.value in roles_set or 'admin' in roles_set or UserRole.ADMIN.value in roles_set:
        roles_set.add(UserRole.COORDINATOR.value)
        roles_set.add(UserRole.ADMIN.value)

    def role_checker(current_user: User = Depends(get_current_user_mobile)) -> User:
        if current_user.role not in roles_set:
            raise HTTPException(
                status_code=403,
                detail="You do not have permission to access this resource."
            )
        return current_user

    return role_checker
