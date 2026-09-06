"""
FEED_SOCIAL_V1.md — Feed de conquistas (piloto). Só leitura da listagem
aqui; os endpoints de seguir/deixar de seguir vivem em public_profile.py
(mesma área de Torcida/convite de Movimento, §4 do documento). Reação a
um evento do feed reaproveita 100% o endpoint de Torcida já existente
(POST /profile/{user_id}/torcida, usando o `user_id` do próprio evento)
— §7: "reaproveitar a lógica de envio/registro de Torcida já existente",
nenhum endpoint novo de reação.
"""

from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from .. import config, models, schemas, services
from ..auth import require_age_confirmed_user_id
from ..db import get_db

router = APIRouter()


@router.get("/feed", response_model=schemas.FeedListResponse)
def get_feed(
    before: str | None = Query(default=None, description="Cursor: created_at ISO do último evento da página anterior"),
    limit: int = Query(default=config.FEED_LIST_DEFAULT_LIMIT, ge=1, le=config.FEED_LIST_MAX_LIMIT),
    user_id: str = Depends(require_age_confirmed_user_id),
    db: Session = Depends(get_db),
):
    before_dt: datetime | None = None
    if before is not None:
        try:
            before_dt = datetime.fromisoformat(before)
        except ValueError:
            raise HTTPException(status_code=422, detail={"error": {"code": "INVALID_CURSOR", "message": before}})

    events = services.list_feed(db, user_id, limit=limit, before=before_dt)

    out = []
    for event in events:
        profile = db.get(models.Profile, event.user_id)
        if profile is None:
            continue
        out.append(
            schemas.FeedEventOut(
                id=event.id,
                user_id=event.user_id,
                nickname=profile.nickname,
                photo_url=services.public_photo_url(profile),
                event_type=event.event_type,
                text=services.build_feed_event_text(event, profile.nickname),
                created_at=event.created_at.isoformat(),
            )
        )

    next_cursor = events[-1].created_at.isoformat() if len(events) == limit else None
    return schemas.FeedListResponse(events=out, next_cursor=next_cursor)
