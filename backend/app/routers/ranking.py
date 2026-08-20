from datetime import date, timedelta

from fastapi import APIRouter, Depends
from sqlalchemy import select, func
from sqlalchemy.orm import Session

from .. import models
from ..schemas import RankingResponse, RankingEntry
from ..auth import get_current_user_id
from ..db import get_db

router = APIRouter()


@router.get("/ranking", response_model=RankingResponse)
def get_ranking(
    scope: str = "global",
    window: str = "weekly",
    user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    # V1: ranking "semanal" soma XP ganho em attempts corretas dos últimos 7
    # dias (RANKING.md §2 recomendava janela semanal como padrão). "friends"
    # fica fora de escopo do Vertical Slice 01 (não há modelo de conexão de
    # amigo definido ainda) — tratado igual a "global" por ora.
    if window == "weekly":
        since = date.today() - timedelta(days=7)
        rows = (
            db.execute(
                select(models.Attempt.user_id, func.sum(models.Attempt.xp_awarded).label("xp"))
                .where(models.Attempt.created_at >= since)
                .where(models.Attempt.is_correct.is_(True))
                .group_by(models.Attempt.user_id)
                .order_by(func.sum(models.Attempt.xp_awarded).desc())
            ).all()
        )
    else:
        rows = (
            db.execute(select(models.Profile.user_id, models.Profile.xp_total.label("xp")).order_by(models.Profile.xp_total.desc())).all()
        )

    entries = []
    me = None
    for idx, (row_user_id, xp) in enumerate(rows, start=1):
        profile = db.get(models.Profile, row_user_id)
        nickname = profile.nickname if profile else "???"
        entry = RankingEntry(rank=idx, nickname=nickname, xp=int(xp or 0))
        if idx <= 50:
            entries.append(entry)
        if row_user_id == user_id:
            me = entry

    return RankingResponse(window=window, entries=entries, me=me)
