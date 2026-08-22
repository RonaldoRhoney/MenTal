from datetime import timedelta

from fastapi import APIRouter, Depends
from sqlalchemy import select, func
from sqlalchemy.orm import Session

from .. import models, services
from ..schemas import RankingResponse, RankingEntry
from ..auth import get_current_user_id
from ..db import get_db
from ..timeutil import utcnow

router = APIRouter()


@router.get("/ranking", response_model=RankingResponse)
def get_ranking(
    scope: str = "global",
    window: str = "weekly",
    user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    # V2 item 12 (V2_KICKOFF.md §6A) — "friends" agora filtra de verdade
    # (mesma query de sempre, restrita a amigos + eu mesmo), fechando o
    # gap deixado desde o Vertical Slice 01 (scope existia na assinatura
    # mas nunca era aplicado).
    allowed_user_ids = None
    if scope == "friends":
        allowed_user_ids = set(services.get_friend_user_ids(db, user_id)) | {user_id}

    if window == "weekly":
        # utcnow(), não date.today(): Attempt.created_at é gravado
        # em UTC (utcnow() em toda a base) — usar a data LOCAL do
        # servidor aqui criava uma janela "semana" que não batia com o
        # fuso em que os timestamps foram gravados, um descompasso real
        # achado implementando Estatísticas (item 5), onde o mesmo
        # problema em register_play_for_streak produzia "sequência mais
        # longa" menor que "sequência atual" — logicamente impossível.
        since = utcnow() - timedelta(days=7)
        query = (
            select(models.Attempt.user_id, func.sum(models.Attempt.xp_awarded).label("xp"))
            .where(models.Attempt.created_at >= since)
            .where(models.Attempt.is_correct.is_(True))
        )
        if allowed_user_ids is not None:
            query = query.where(models.Attempt.user_id.in_(allowed_user_ids))
        query = query.group_by(models.Attempt.user_id).order_by(func.sum(models.Attempt.xp_awarded).desc())
        rows = db.execute(query).all()
    else:
        query = select(models.Profile.user_id, models.Profile.xp_total.label("xp"))
        if allowed_user_ids is not None:
            query = query.where(models.Profile.user_id.in_(allowed_user_ids))
        query = query.order_by(models.Profile.xp_total.desc())
        rows = db.execute(query).all()

    entries = []
    me = None
    for idx, (row_user_id, xp) in enumerate(rows, start=1):
        profile = db.get(models.Profile, row_user_id)
        nickname = profile.nickname if profile else "???"
        avatar_id = profile.avatar_id if profile else None
        entry = RankingEntry(rank=idx, nickname=nickname, avatar_id=avatar_id, xp=int(xp or 0))
        if idx <= 50:
            entries.append(entry)
        if row_user_id == user_id:
            me = entry

    return RankingResponse(window=window, entries=entries, me=me)
