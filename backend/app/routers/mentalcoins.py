"""
MentalCoins — moeda de prestígio semanal (U.I/MENTALCOINS_V1.md).
Saldo/histórico/Hall da Fama são só leitura pelo client; o resgate de
item é a única escrita disponível ao jogador. A apuração semanal em si
roda pelo agendador (app/scheduler.py); o endpoint admin aqui só serve
para disparo manual/teste, nunca é chamado pelo app do jogador.
"""

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from .. import mentalcoins, models, schemas, services
from ..auth import require_age_confirmed_user_id
from ..db import get_db

router = APIRouter()


@router.get("/mentalcoins/balance", response_model=schemas.MentalCoinsBalanceOut)
def get_balance(user_id: str = Depends(require_age_confirmed_user_id), db: Session = Depends(get_db)):
    balance = mentalcoins.get_or_create_balance(db, user_id)
    cycle_start, cycle_end = mentalcoins.current_cycle_bounds()
    return schemas.MentalCoinsBalanceOut(balance=balance.balance, cycle_start=cycle_start, cycle_end=cycle_end)


@router.get("/mentalcoins/transactions", response_model=schemas.MentalCoinsTransactionsResponse)
def get_transactions(user_id: str = Depends(require_age_confirmed_user_id), db: Session = Depends(get_db)):
    return schemas.MentalCoinsTransactionsResponse(
        transactions=[
            schemas.MentalCoinsTransactionOut(amount=t.amount, reason=t.reason, created_at=t.created_at)
            for t in mentalcoins.list_transactions(db, user_id)
        ]
    )


@router.get("/mentalcoins/hall-of-fame", response_model=schemas.MentalCoinsHallOfFameResponse)
def get_hall_of_fame(user_id: str = Depends(require_age_confirmed_user_id), db: Session = Depends(get_db)):
    entries = mentalcoins.get_current_hall_of_fame(db)
    # nickname vem congelado no registro histórico (snapshot de quando o
    # ciclo fechou), mas real_name é sempre lido ao vivo do perfil
    # (29/08/2026, pedido de Rhoney: nome real substitui o apelido
    # gerado pelo sistema assim que existir) — lista sempre pequena
    # (no máximo ~23 linhas), um get por linha não pesa.
    def _real_name(target_user_id: str) -> str | None:
        profile = db.get(models.Profile, target_user_id)
        return profile.real_name if profile else None

    return schemas.MentalCoinsHallOfFameResponse(
        entries=[
            schemas.MentalCoinsHallOfFameEntryOut(
                category=entry.category,
                rank=entry.rank,
                reference_date=entry.reference_date,
                user_id=entry.user_id,
                nickname=entry.nickname,
                real_name=_real_name(entry.user_id),
                amount=entry.amount,
                metric_value=entry.metric_value,
            )
            for entry in entries
        ]
    )


@router.get("/mentalcoins/catalog", response_model=schemas.MentalCoinsCatalogResponse)
def get_catalog(user_id: str = Depends(require_age_confirmed_user_id), db: Session = Depends(get_db)):
    return schemas.MentalCoinsCatalogResponse(
        items=[
            schemas.MentalCoinsCatalogItemOut(
                id=row["item"].id,
                name=row["item"].name,
                description=row["item"].description,
                cost=row["item"].cost,
                item_type=row["item"].item_type,
                redeemed=row["redeemed"],
            )
            for row in mentalcoins.list_catalog(db, user_id)
        ]
    )


@router.post("/mentalcoins/catalog/redeem", response_model=schemas.MentalCoinsBalanceOut)
def redeem(
    body: schemas.RedeemMentalCoinsItemRequest,
    user_id: str = Depends(require_age_confirmed_user_id),
    db: Session = Depends(get_db),
):
    try:
        balance = mentalcoins.redeem_item(db, user_id, body.item_id)
    except mentalcoins.MentalCoinsError as exc:
        raise HTTPException(status_code=422, detail={"error": {"code": exc.code, "message": exc.message}}) from exc

    cycle_start, cycle_end = mentalcoins.current_cycle_bounds()
    return schemas.MentalCoinsBalanceOut(balance=balance.balance, cycle_start=cycle_start, cycle_end=cycle_end)


@router.post("/admin/mentalcoins/run-apuration")
def run_apuration(user_id: str = Depends(require_age_confirmed_user_id), db: Session = Depends(get_db)):
    services.require_admin(db, user_id)

    cycle_start, cycle_end = mentalcoins.closed_cycle_bounds()
    return mentalcoins.run_weekly_apuration(db, cycle_start, cycle_end)
