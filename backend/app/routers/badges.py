from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.orm import Session

from .. import models, schemas
from ..auth import get_current_user_id
from ..db import get_db

router = APIRouter()


@router.get("/badges", response_model=schemas.BadgesResponse)
def list_badges(user_id: str = Depends(get_current_user_id), db: Session = Depends(get_db)):
    """
    Catálogo completo com status de conquista do usuário atual — V2 item 1
    (V2_KICKOFF.md §6A). Nunca concede badge aqui (leitura pura); a
    concessão acontece em services.check_and_award_badges, chamado após
    cada resposta de desafio.
    """
    all_badges = db.execute(select(models.Badge).order_by(models.Badge.display_order)).scalars().all()
    earned = {
        ub.badge_id: ub.earned_at
        for ub in db.execute(select(models.UserBadge).where(models.UserBadge.user_id == user_id)).scalars().all()
    }

    out = [
        schemas.BadgeOut(
            code=badge.code,
            name=badge.name,
            description=badge.description,
            earned=badge.id in earned,
            earned_at=earned[badge.id].isoformat() if badge.id in earned else None,
        )
        for badge in all_badges
    ]
    return schemas.BadgesResponse(badges=out)
