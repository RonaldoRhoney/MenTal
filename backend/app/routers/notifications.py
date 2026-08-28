from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from .. import schemas, services
from ..auth import require_age_confirmed_user_id
from ..db import get_db

router = APIRouter()


@router.post("/notifications/register-token")
def register_push_token(
    body: schemas.PushTokenRequest,
    user_id: str = Depends(require_age_confirmed_user_id),
    db: Session = Depends(get_db),
):
    services.set_push_token(db, user_id, body.push_token)
    return {"status": "ok"}


@router.get("/notifications/preferences", response_model=schemas.NotificationPreferencesResponse)
def get_notification_preferences(user_id: str = Depends(require_age_confirmed_user_id), db: Session = Depends(get_db)):
    profile = services.get_or_create_profile(db, user_id)
    return schemas.NotificationPreferencesResponse(
        reengagement_enabled=profile.notif_reengagement_enabled,
        social_enabled=profile.notif_social_enabled,
    )


@router.put("/notifications/preferences", response_model=schemas.NotificationPreferencesResponse)
def update_notification_preferences(
    body: schemas.NotificationPreferencesRequest,
    user_id: str = Depends(require_age_confirmed_user_id),
    db: Session = Depends(get_db),
):
    profile = services.set_notification_preferences(db, user_id, body.reengagement_enabled, body.social_enabled)
    return schemas.NotificationPreferencesResponse(
        reengagement_enabled=profile.notif_reengagement_enabled,
        social_enabled=profile.notif_social_enabled,
    )
