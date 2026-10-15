from fastapi import APIRouter, Depends, HTTPException, Request
from fastapi.responses import RedirectResponse
from sqlalchemy.orm import Session

from api.core.dependencies.flash_messages import MessageCategory, flash
from api.db.database import get_db
from api.utils.payload_builder import build_payload
from api.v1.models.user import User, UserRole
from api.v1.services.user import UserService
from api.utils.loggers import create_logger

user_router = APIRouter(prefix='/users', tags=['User'])
logger = create_logger(__name__)

@user_router.post('/{id}/edit')
async def edit_user(
    id: str,
    request: Request,
    db: Session=Depends(get_db), 
):
    """Endpoint to a user to update their details"""
    
    try:
        current_user = getattr(request.state, 'current_user', None)
        if not current_user:
            raise HTTPException(401, 'Authentication required')
        UserService.check_user_role(db, current_user.id, [UserRole.ADMIN.value, UserRole.COORDINATOR.value])
        user = User.fetch_by_id(db, id, 'User does not exist')
        
        payload = await build_payload(request, boolean_fields=['is_active'])
        
        if payload.get('email') and payload.get('email') != user.email:
            existing_user = User.fetch_one_by_field(db, throw_error=False, email=payload.get('email'))
            if existing_user:
                raise HTTPException(400, 'Email already in use')

        user = User.update(
            db,
            id=id,
            **payload
        )
                
    except HTTPException as e:
        logger.warning(f"User update failed: {e.detail}")
        flash(request, e.detail, MessageCategory.ERROR)
    except Exception as e:
        logger.error(f"Unexpected error updating user {id}: {e}", exc_info=True)
        flash(request, f"Update failed: {str(e)}", MessageCategory.ERROR)

    return RedirectResponse(url='/dashboard/users', status_code=303)


@user_router.post('/{id}/delete')
async def delete_user(
    id: str,
    request: Request,
    db: Session=Depends(get_db), 
):
    """Endpoint to a user to update their details"""
    
    try:
        current_user = getattr(request.state, 'current_user', None)
        if not current_user:
            raise HTTPException(401, 'Authentication required')
        UserService.check_user_role(db, current_user.id, [UserRole.ADMIN.value, UserRole.COORDINATOR.value])
        user = User.fetch_by_id(db, id, 'User does not exist')
        
        user = User.delete(
            db,
            id=id,
        )
    except HTTPException as e:
        logger.warning(f"User delete failed: {e.detail}")
        flash(request, e.detail, MessageCategory.ERROR)
    except Exception as e:
        logger.error(f"Unexpected error deleting user {id}: {e}", exc_info=True)
        flash(request, f"Delete failed: {str(e)}", MessageCategory.ERROR)
            
    return RedirectResponse(url='/dashboard/users', status_code=303)
