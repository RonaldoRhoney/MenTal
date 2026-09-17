from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from .. import config, schemas, services
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


# CENTRAL_DE_NOTIFICACOES_HOME_V1.md — histórico persistente dentro do
# app, complementar ao push (que continua disparando normalmente,
# endpoints acima). Ver services.create_notification/list_notifications
# pro raciocínio completo.
@router.get("/notifications", response_model=schemas.NotificationsResponse)
def list_notifications(
    before: str | None = Query(default=None, description="Cursor: created_at ISO da última notificação da página anterior"),
    limit: int = Query(default=config.NOTIFICATION_LIST_DEFAULT_LIMIT, ge=1, le=config.NOTIFICATION_LIST_MAX_LIMIT),
    user_id: str = Depends(require_age_confirmed_user_id),
    db: Session = Depends(get_db),
):
    before_dt: datetime | None = None
    if before is not None:
        try:
            before_dt = datetime.fromisoformat(before)
        except ValueError:
            raise HTTPException(status_code=422, detail={"error": {"code": "INVALID_CURSOR", "message": before}})

    notifications = services.list_notifications(db, user_id, limit=limit, before=before_dt)
    unread_count = services.count_unread_notifications(db, user_id)

    out = [
        schemas.NotificationOut(
            id=n.id,
            type=n.type,
            title=n.title,
            body=n.body,
            data=n.data,
            read=n.read_at is not None,
            created_at=n.created_at,
        )
        for n in notifications
    ]
    next_cursor = notifications[-1].created_at.isoformat() if len(notifications) == limit else None
    return schemas.NotificationsResponse(notifications=out, unread_count=unread_count, next_cursor=next_cursor)


@router.get("/notifications/unread-count")
def get_unread_notification_count(user_id: str = Depends(require_age_confirmed_user_id), db: Session = Depends(get_db)):
    # Endpoint dedicado e leve pro badge da Home — não precisa da lista
    # inteira só pra saber o número (mesmo raciocínio de FeedActivityService
    # no client, mas aqui é sempre um COUNT real do servidor, nunca
    # derivado localmente, já que a Central tem estado de leitura
    # persistido no banco, diferente do "unseen desde a última visita"
    # do Feed).
    return {"unread_count": services.count_unread_notifications(db, user_id)}


@router.post("/notifications/{notification_id}/read")
def mark_notification_read(
    notification_id: str,
    user_id: str = Depends(require_age_confirmed_user_id),
    db: Session = Depends(get_db),
):
    notification = services.mark_notification_read(db, user_id, notification_id)
    if notification is None:
        raise HTTPException(status_code=404, detail={"error": {"code": "NOTIFICATION_NOT_FOUND", "message": notification_id}})
    return {"status": "ok"}


@router.post("/notifications/mark-all-read")
def mark_all_notifications_read(user_id: str = Depends(require_age_confirmed_user_id), db: Session = Depends(get_db)):
    count = services.mark_all_notifications_read(db, user_id)
    return {"marked_read": count}
