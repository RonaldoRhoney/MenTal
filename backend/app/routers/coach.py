"""
My_Mental_AI — agente do usuário (pedido de Rhoney, 21/09/2026). Só leitura, só dados do
próprio usuário, sem IA paga (ver app/coach.py).
"""

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from .. import coach, config, schemas, services
from ..auth import require_age_confirmed_user_id
from ..db import get_db

router = APIRouter()


@router.get("/coach", response_model=schemas.CoachOut)
def get_coach(user_id: str = Depends(require_age_confirmed_user_id), db: Session = Depends(get_db)):
    services.enforce_rate_limit("coach", user_id, max_calls=config.RATE_LIMIT_COACH[0], window_seconds=config.RATE_LIMIT_COACH[1])
    return schemas.CoachOut(**coach.build_coach(db, user_id))


@router.get("/coach/world/{world_id}", response_model=schemas.WorldCoachOut)
def get_world_coach(world_id: str, user_id: str = Depends(require_age_confirmed_user_id), db: Session = Depends(get_db)):
    services.enforce_rate_limit("coach", user_id, max_calls=config.RATE_LIMIT_COACH[0], window_seconds=config.RATE_LIMIT_COACH[1])
    return schemas.WorldCoachOut(name="My_Mental_AI", card=coach.build_world_coach_tip(db, user_id, world_id))
