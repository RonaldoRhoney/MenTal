"""
Fase 3 da REGRA_OFICIAL_GAMIFICACAO_MENTAL.md — teto diário de XP,
reparo de streak e boost de XP. Só o servidor decide preço, janela e
efeito; o client só exibe e pede a compra.
"""

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from .. import config, economy, mentalcoins, schemas, services
from ..auth import require_age_confirmed_user_id
from ..db import get_db
from ..timeutil import brasilia_today, format_brasilia_time, utcnow

router = APIRouter()


def _error(exc: mentalcoins.MentalCoinsError) -> HTTPException:
    return HTTPException(status_code=422, detail={"error": {"code": exc.code, "message": exc.message}})


@router.get("/economy/status", response_model=schemas.EconomyStatusOut)
def get_status(user_id: str = Depends(require_age_confirmed_user_id), db: Session = Depends(get_db)):
    today = utcnow().date()  # reparo de sequência segue o dia UTC do streak
    expires = economy.active_boost_expiry(db, user_id)
    offer = economy.streak_repair_offer(services.get_or_create_streak(db, user_id), today)
    return schemas.EconomyStatusOut(
        daily_xp_earned=economy.daily_answer_xp_earned(db, user_id, brasilia_today()),
        daily_xp_cap=config.DAILY_ANSWER_XP_CAP,
        boost_active=expires is not None,
        boost_expires_at=expires,
        boost_cost=config.XP_BOOST_COST,
        boost_percent=config.XP_BOOST_PERCENT,
        repair=(
            schemas.StreakRepairOfferOut(
                streak_to_restore=offer.streak_to_restore, expires_on=offer.expires_on, cost=config.STREAK_REPAIR_COST
            )
            if offer
            else None
        ),
        balance=mentalcoins.get_or_create_balance(db, user_id).balance,
    )


@router.post("/economy/xp-boost", response_model=schemas.BuyBoostOut)
def buy_boost(user_id: str = Depends(require_age_confirmed_user_id), db: Session = Depends(get_db)):
    services.enforce_rate_limit("economy_buy", user_id, max_calls=config.RATE_LIMIT_ECONOMY_BUY[0], window_seconds=config.RATE_LIMIT_ECONOMY_BUY[1])
    try:
        expires_at = economy.buy_xp_boost(db, user_id)
    except mentalcoins.MentalCoinsError as exc:
        db.rollback()
        raise _error(exc) from exc
    # Pedido de Rhoney (23/09/2026): o chip de boost saiu da Home (poluía a
    # tela) e virou uma notificação na Central (sino), mesmo texto/horário
    # de Brasília que o chip já mostrava.
    services.create_notification(
        db,
        services.get_or_create_profile(db, user_id),
        "boost_active",
        "Boost de XP ativo",
        f"Seu boost de +{config.XP_BOOST_PERCENT}% está ativo até {format_brasilia_time(expires_at)}.",
    )
    return schemas.BuyBoostOut(boost_expires_at=expires_at, balance=mentalcoins.get_or_create_balance(db, user_id).balance)


@router.post("/economy/streak-repair", response_model=schemas.RepairStreakOut)
def repair(user_id: str = Depends(require_age_confirmed_user_id), db: Session = Depends(get_db)):
    services.enforce_rate_limit("economy_buy", user_id, max_calls=config.RATE_LIMIT_ECONOMY_BUY[0], window_seconds=config.RATE_LIMIT_ECONOMY_BUY[1])
    try:
        streak, mode = economy.repair_streak(db, user_id, utcnow().date())
    except mentalcoins.MentalCoinsError as exc:
        db.rollback()
        raise _error(exc) from exc
    return schemas.RepairStreakOut(
        current_streak=streak.current_streak,
        applied_immediately=mode == economy.MODE_AFTER_PLAY,
        balance=mentalcoins.get_or_create_balance(db, user_id).balance,
    )
