from datetime import datetime, timezone, timedelta
from typing import Optional
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from api.db.database import get_db
from api.v1.models.user import User
from api.v1.models.notification import Notification
from api.v1.models.token import Token
from api.mobile.v1.schemas import DeviceTokenPayload
from api.mobile.v1.dependencies import (
    mobile_response, get_current_user_mobile
)


notifications_mobile_router = APIRouter(prefix="/notifications", tags=["Mobile Notifications"])


@notifications_mobile_router.get("")
def list_notifications(
    current_user: User = Depends(get_current_user_mobile),
    db: Session = Depends(get_db)
):
    """Retrieve notifications for the authenticated user."""
    notifications = db.query(Notification).filter(
        Notification.user_id == current_user.id,
        Notification.is_deleted == False,
    ).order_by(Notification.created_at.desc()).all()

    unread_count = sum(1 for n in notifications if not n.is_read)

    items = [
        {
            "id": n.id,
            "title": n.title,
            "content": n.content,
            "type": n.type,
            "is_read": n.is_read,
            "link": n.link,
            "created_at": str(n.created_at) if n.created_at else None,
        }
        for n in notifications
    ]

    return mobile_response(
        data={
            "unread_count": unread_count,
            "notifications": items,
        },
        message="Notifications retrieved."
    )


@notifications_mobile_router.post("/read-all")
def mark_all_notifications_read(
    current_user: User = Depends(get_current_user_mobile),
    db: Session = Depends(get_db)
):
    """Mark all notifications for the user as read."""
    db.query(Notification).filter(
        Notification.user_id == current_user.id,
        Notification.is_read == False,
    ).update({"is_read": True})
    db.commit()

    return mobile_response(message="All notifications marked as read.")


@notifications_mobile_router.post("/{notification_id}/read")
def mark_notification_read(
    notification_id: str,
    current_user: User = Depends(get_current_user_mobile),
    db: Session = Depends(get_db)
):
    """Mark an individual notification as read."""
    n = db.query(Notification).filter(
        Notification.id == notification_id,
        Notification.user_id == current_user.id,
    ).first()

    if n:
        n.is_read = True
        db.commit()

    return mobile_response(message="Notification marked as read.")


@notifications_mobile_router.post("/device-token")
def register_device_token(
    payload: DeviceTokenPayload,
    current_user: User = Depends(get_current_user_mobile),
    db: Session = Depends(get_db)
):
    """Register or refresh an Android Firebase Cloud Messaging (FCM) device push token."""
    fcm_token = payload.fcm_token.strip()

    # Check if token already registered for this user
    existing = db.query(Token).filter(
        Token.user_id == current_user.id,
        Token.token == fcm_token,
        Token.token_type == "fcm_device",
    ).first()

    if not existing:
        Token.create(
            db=db,
            token=fcm_token,
            token_type="fcm_device",
            user_id=current_user.id,
            expiry_time=datetime.now(timezone.utc) + timedelta(days=180),
        )

    return mobile_response(message="FCM device token registered successfully.")
