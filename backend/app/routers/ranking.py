from collections import Counter
from datetime import timedelta

from fastapi import APIRouter, Depends
from sqlalchemy import select, func
from sqlalchemy.orm import Session

from .. import models, services
from ..schemas import RankingResponse, RankingEntry
from ..auth import require_age_confirmed_user_id
from ..db import get_db
from ..seed import TERRITORIES, WORLDS
from ..timeutil import utcnow

router = APIRouter()

# RANKING_ENRIQUECIDO_V1.md §6 — "mundos completos/total" reaproveita a
# mesma definição de services.is_world_completed (todos os territórios
# do mundo conquistados), mas calculado em LOTE aqui pra evitar N+1
# (uma query por mundo por jogador seria 50 jogadores x ~6 mundos = 300
# queries). territory_to_world/world_territory_count são fixos (vêm do
# seed, não do banco) — só a contagem de território CONQUISTADO por
# usuário precisa vir do banco.
_TERRITORY_TO_WORLD = {t["id"]: t.get("world_id") for t in TERRITORIES}
_WORLD_TERRITORY_COUNT = Counter(w for w in _TERRITORY_TO_WORLD.values() if w is not None)
_WORLDS_TOTAL = len(WORLDS)


def _batched_ranking_extras(db: Session, user_ids: list[str]) -> dict[str, dict]:
    """Uma query por métrica (não por usuário) para o conjunto de user_ids
    que vai de fato aparecer na resposta (entries + me), nunca pra todos
    os jogadores do ranking global inteiro."""
    if not user_ids:
        return {}

    streak_by_user = dict(
        db.execute(
            select(models.Streak.user_id, models.Streak.current_streak).where(models.Streak.user_id.in_(user_ids))
        ).all()
    )
    badge_count_by_user = dict(
        db.execute(
            select(models.UserBadge.user_id, func.count(models.UserBadge.badge_id))
            .where(models.UserBadge.user_id.in_(user_ids))
            .group_by(models.UserBadge.user_id)
        ).all()
    )
    mentalcoins_by_user = dict(
        db.execute(
            select(models.MentalCoinsBalance.user_id, models.MentalCoinsBalance.balance).where(
                models.MentalCoinsBalance.user_id.in_(user_ids)
            )
        ).all()
    )
    steps_by_user = dict(
        db.execute(
            select(models.MovementCycle.user_id, func.sum(models.MovementCycle.steps_collected))
            .where(models.MovementCycle.user_id.in_(user_ids))
            .group_by(models.MovementCycle.user_id)
        ).all()
    )

    conquered_rows = db.execute(
        select(models.UserTerritoryProgress.user_id, models.UserTerritoryProgress.territory_id)
        .where(models.UserTerritoryProgress.user_id.in_(user_ids))
        .where(models.UserTerritoryProgress.conquered_at.is_not(None))
    ).all()
    conquered_worlds_by_user: dict[str, Counter] = {}
    for row_user_id, territory_id in conquered_rows:
        world_id = _TERRITORY_TO_WORLD.get(territory_id)
        if world_id is None:
            continue
        conquered_worlds_by_user.setdefault(row_user_id, Counter())[world_id] += 1

    extras = {}
    for uid in user_ids:
        conquered_by_world = conquered_worlds_by_user.get(uid, Counter())
        worlds_completed = sum(
            1 for world_id, total in _WORLD_TERRITORY_COUNT.items() if conquered_by_world.get(world_id, 0) >= total
        )
        extras[uid] = {
            "current_streak": streak_by_user.get(uid, 0),
            "worlds_completed": worlds_completed,
            "badges_count": badge_count_by_user.get(uid, 0),
            "mentalcoins_balance": mentalcoins_by_user.get(uid, 0),
            "total_steps": int(steps_by_user.get(uid) or 0),
        }
    return extras


@router.get("/ranking", response_model=RankingResponse)
def get_ranking(
    scope: str = "global",
    window: str = "weekly",
    user_id: str = Depends(require_age_confirmed_user_id),
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

    # Só busca os extras (streak/mundos/badges/coins/passos) pra quem
    # REALMENTE vai aparecer na resposta (top 50 + "eu", se estiver fora
    # do top 50) — nunca para os até milhares de outras linhas do
    # ranking global inteiro.
    ranked_rows = list(enumerate(rows, start=1))
    relevant_user_ids = [row_user_id for idx, (row_user_id, _xp) in ranked_rows if idx <= 50 or row_user_id == user_id]
    extras_by_user = _batched_ranking_extras(db, relevant_user_ids)

    entries = []
    me = None
    for idx, (row_user_id, xp) in ranked_rows:
        if idx > 50 and row_user_id != user_id:
            continue
        profile = db.get(models.Profile, row_user_id)
        nickname = profile.nickname if profile else "???"
        avatar_id = profile.avatar_id if profile else None
        real_name = profile.real_name if profile else None
        photo_url = services.public_photo_url(profile) if profile else None
        extras = extras_by_user.get(row_user_id, {})
        entry = RankingEntry(
            rank=idx,
            user_id=row_user_id,
            nickname=nickname,
            avatar_id=avatar_id,
            real_name=real_name,
            photo_url=photo_url,
            xp=int(xp or 0),
            level=profile.level if profile else 1,
            current_streak=extras.get("current_streak", 0),
            worlds_completed=extras.get("worlds_completed", 0),
            worlds_total=_WORLDS_TOTAL,
            badges_count=extras.get("badges_count", 0),
            mentalcoins_balance=extras.get("mentalcoins_balance", 0),
            total_steps=extras.get("total_steps", 0),
        )
        if idx <= 50:
            entries.append(entry)
        if row_user_id == user_id:
            me = entry

    return RankingResponse(window=window, entries=entries, me=me)
