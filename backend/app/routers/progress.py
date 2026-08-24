from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.orm import Session

from .. import config, models, schemas, services
from ..auth import get_current_user_id
from ..db import get_db

router = APIRouter()


@router.get("/progress", response_model=schemas.ProgressResponse)
def get_progress(user_id: str = Depends(get_current_user_id), db: Session = Depends(get_db)):
    profile = services.get_or_create_profile(db, user_id)
    # V2 item 8 — Notificações: GET /progress é chamado toda vez que a
    # Home carrega, então é o sinal mais confiável de "o jogador de fato
    # abriu o app agora" — usado pelo job de reengajamento pra saber há
    # quanto tempo o jogador está inativo.
    services.update_last_seen(db, user_id)
    streak = services.get_or_create_streak(db, user_id)
    territories = db.execute(select(models.Territory).order_by(models.Territory.display_order)).scalars().all()

    out = []
    for territory in territories:
        progress = db.get(models.UserTerritoryProgress, (user_id, territory.id))
        # V2 item 13 — Disputa territorial: sempre relativo a você + seus
        # amigos confirmados (services.get_territory_detentor), nunca
        # global.
        detentor = services.get_territory_detentor(db, user_id, territory.id)
        out.append(
            schemas.ProgressTerritoryOut(
                territory_id=territory.id,
                xp_in_territory=progress.xp_in_territory if progress else 0,
                unlocked=services.is_territory_unlocked(db, user_id, territory),
                conquered=bool(progress and progress.conquered_at),
                conquest_threshold=config.CONQUEST_XP_THRESHOLD,
                detentor_nickname=detentor.nickname if detentor else None,
                is_detentor=bool(detentor and detentor.user_id == user_id),
            )
        )

    worlds = [
        schemas.WorldProgressOut(
            world_id=w["world_id"], name=w["name"], territory_ids=w["territory_ids"], completed=w["completed"]
        )
        for w in services.get_worlds_progress(db, user_id)
    ]
    blocks = [
        schemas.BlockOut(block_id=b["block_id"], name=b["name"], territory_ids=b["territory_ids"])
        for b in services.get_blocks(db)
    ]

    return schemas.ProgressResponse(
        xp_total=profile.xp_total,
        level=profile.level,
        xp_per_level=config.XP_PER_LEVEL,
        territories=out,
        worlds=worlds,
        blocks=blocks,
        streak=schemas.StreakOut(current_streak=streak.current_streak, freeze_available=streak.freeze_available),
    )
