"""
MentalCoins — moeda de prestígio semanal (U.I/MENTALCOINS_V1.md).

Não é criptomoeda real, não tem valor monetário, não é comprável com
dinheiro nem convertível em dinheiro (§1). Saldo e histórico são 100%
autoridade do backend, mesmo princípio já usado para XP/Score — o client
nunca calcula nem decide saldo, só exibe o que a API devolve.

Simplificação de fuso registrada aqui (§2 do documento pede horário de
Brasília; "a confirmar formalmente com Claude Code na implementação"):
os limites de ciclo usam a DATA em UTC (utcnow().date()), não convertida
para America/Sao_Paulo — a diferença de fuso (3h) pode deslocar em até um
dia a fronteira exata do ciclo para atividade feita bem próxima da
virada, mas não afeta a integridade da apuração em si (cada dia/semana
ainda fecha exatamente uma vez, via mentalcoins_processed_cycles). O
JOB agendado (app/scheduler.py) já dispara no horário certo do fuso via
APScheduler timezone=config.MENTALCOINS_TIMEZONE — só o cálculo de QUAIS
datas compõem o ciclo usa UTC internamente.
"""

from datetime import date, datetime, timedelta

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from . import config, models
from .timeutil import utcnow


class MentalCoinsError(Exception):
    def __init__(self, code: str, message: str):
        self.code = code
        self.message = message


def get_or_create_balance(db: Session, user_id: str) -> models.MentalCoinsBalance:
    balance = db.get(models.MentalCoinsBalance, user_id)
    if balance is None:
        balance = models.MentalCoinsBalance(user_id=user_id, balance=0)
        db.add(balance)
        db.commit()
        db.refresh(balance)
    return balance


def credit(db: Session, user_id: str, amount: int, reason: str) -> None:
    balance = get_or_create_balance(db, user_id)
    balance.balance += amount
    balance.updated_at = utcnow()
    db.add(models.MentalCoinsTransaction(user_id=user_id, amount=amount, reason=reason))
    db.commit()


def list_transactions(db: Session, user_id: str, limit: int = 30) -> list[models.MentalCoinsTransaction]:
    return (
        db.execute(
            select(models.MentalCoinsTransaction)
            .where(models.MentalCoinsTransaction.user_id == user_id)
            .order_by(models.MentalCoinsTransaction.created_at.desc())
            .limit(limit)
        )
        .scalars()
        .all()
    )


def current_cycle_bounds(now: datetime | None = None) -> tuple[date, date]:
    """Ciclo em andamento (segunda a domingo) — usado para exibir ao
    usuário quando o ciclo atual fecha."""
    now = now or utcnow()
    today = now.date()
    cycle_start = today - timedelta(days=today.weekday())
    cycle_end = cycle_start + timedelta(days=6)
    return cycle_start, cycle_end


def closed_cycle_bounds(now: datetime | None = None) -> tuple[date, date]:
    """Ciclo que ACABOU DE FECHAR — usado pelo job agendado, que dispara
    toda segunda-feira depois da virada (§2)."""
    now = now or utcnow()
    cycle_end = now.date() - timedelta(days=1)
    cycle_start = cycle_end - timedelta(days=6)
    return cycle_start, cycle_end


def _nickname_for(db: Session, user_id: str) -> str:
    profile = db.get(models.Profile, user_id)
    return profile.nickname if profile and profile.nickname else "?"


def run_weekly_apuration(db: Session, cycle_start: date, cycle_end: date) -> dict:
    """
    Apura e credita os dois rankings independentes do ciclo fechado
    (§3), grava o congelamento no Hall da Fama (§6) e marca o ciclo como
    processado. Idempotente: se `cycle_start` já foi processado, não
    credita de novo — proteção contra o job rodar duas vezes (reinício
    do processo, redeploy no meio do horário agendado).
    """
    if db.get(models.MentalCoinsProcessedCycle, cycle_start) is not None:
        return {"already_processed": True, "cycle_start": cycle_start.isoformat(), "entries_created": 0}

    entries_created = 0

    # §3.1 — ranking diário de XP, um top-3 por cada um dos 7 dias do ciclo.
    xp_expr = func.sum(func.coalesce(models.Attempt.xp_awarded, 0) + models.Attempt.speed_bonus_xp)
    day = cycle_start
    while day <= cycle_end:
        next_day = day + timedelta(days=1)
        rows = db.execute(
            select(models.Attempt.user_id, xp_expr.label("xp"))
            .where(models.Attempt.created_at >= day, models.Attempt.created_at < next_day)
            .group_by(models.Attempt.user_id)
            .order_by(xp_expr.desc())
            .limit(3)
        ).all()
        for rank, row in enumerate(rows, start=1):
            user_id, xp = row[0], row[1]
            if not xp or xp <= 0:
                continue
            reward = config.MENTALCOINS_XP_DAILY_REWARDS[rank - 1]
            credit(db, user_id, reward, f"Top {rank} de XP do dia {day.isoformat()}")
            db.add(
                models.MentalCoinsHallOfFameEntry(
                    cycle_start=cycle_start,
                    cycle_end=cycle_end,
                    category="xp_daily",
                    rank=rank,
                    reference_date=day,
                    user_id=user_id,
                    nickname=_nickname_for(db, user_id),
                    amount=reward,
                    metric_value=int(xp),
                )
            )
            entries_created += 1
        day = next_day

    # §3.2 — campeão da semana (soma de passos absolutos no ciclo).
    week_row = db.execute(
        select(models.MovementCycle.user_id, func.sum(models.MovementCycle.steps_collected).label("total_steps"))
        .where(
            func.date(models.MovementCycle.cycle_start_at) >= cycle_start,
            func.date(models.MovementCycle.cycle_start_at) <= cycle_end,
        )
        .group_by(models.MovementCycle.user_id)
        .order_by(func.sum(models.MovementCycle.steps_collected).desc())
        .limit(1)
    ).first()
    if week_row and week_row[1]:
        user_id, total_steps = week_row[0], week_row[1]
        credit(db, user_id, config.MENTALCOINS_STEPS_WEEK_CHAMPION_REWARD, "Campeão da semana em passos")
        db.add(
            models.MentalCoinsHallOfFameEntry(
                cycle_start=cycle_start,
                cycle_end=cycle_end,
                category="steps_week",
                rank=None,
                reference_date=None,
                user_id=user_id,
                nickname=_nickname_for(db, user_id),
                amount=config.MENTALCOINS_STEPS_WEEK_CHAMPION_REWARD,
                metric_value=int(total_steps),
            )
        )
        entries_created += 1

    # §3.2 — recordista do dia (maior pico diário isolado dentro da semana).
    day_row = db.execute(
        select(models.MovementCycle.user_id, models.MovementCycle.cycle_start_at, models.MovementCycle.steps_collected)
        .where(
            func.date(models.MovementCycle.cycle_start_at) >= cycle_start,
            func.date(models.MovementCycle.cycle_start_at) <= cycle_end,
        )
        .order_by(models.MovementCycle.steps_collected.desc())
        .limit(1)
    ).first()
    if day_row and day_row[2]:
        user_id, cycle_start_at, steps = day_row[0], day_row[1], day_row[2]
        credit(db, user_id, config.MENTALCOINS_STEPS_DAY_RECORD_REWARD, "Recordista do dia em passos")
        db.add(
            models.MentalCoinsHallOfFameEntry(
                cycle_start=cycle_start,
                cycle_end=cycle_end,
                category="steps_day",
                rank=None,
                reference_date=cycle_start_at.date(),
                user_id=user_id,
                nickname=_nickname_for(db, user_id),
                amount=config.MENTALCOINS_STEPS_DAY_RECORD_REWARD,
                metric_value=int(steps),
            )
        )
        entries_created += 1

    db.add(models.MentalCoinsProcessedCycle(cycle_start=cycle_start, cycle_end=cycle_end))
    db.commit()
    return {
        "already_processed": False,
        "cycle_start": cycle_start.isoformat(),
        "cycle_end": cycle_end.isoformat(),
        "entries_created": entries_created,
    }


def get_current_hall_of_fame(db: Session) -> list[models.MentalCoinsHallOfFameEntry]:
    latest = db.execute(
        select(models.MentalCoinsHallOfFameEntry.cycle_start).order_by(models.MentalCoinsHallOfFameEntry.cycle_start.desc()).limit(1)
    ).scalar_one_or_none()
    if latest is None:
        return []
    rows = (
        db.execute(select(models.MentalCoinsHallOfFameEntry).where(models.MentalCoinsHallOfFameEntry.cycle_start == latest))
        .scalars()
        .all()
    )
    # Ordenação em Python (não em SQL): a lista é sempre pequena (no
    # máximo 7 dias x 3 + 2 = 23 linhas) e o comportamento de NULLS
    # FIRST/LAST em ORDER BY diverge entre SQLite e Postgres — mais
    # simples e portável tratar rank=None (steps_week/steps_day) como
    # "depois dos top-3 diários" aqui do que depender de sintaxe
    # específica de cada dialeto.
    category_order = {"xp_daily": 0, "steps_week": 1, "steps_day": 2}
    rows.sort(key=lambda r: (category_order.get(r.category, 99), r.rank or 0))
    return rows


def list_catalog(db: Session, user_id: str) -> list[dict]:
    items = db.execute(select(models.MentalCoinsItem).order_by(models.MentalCoinsItem.display_order)).scalars().all()
    redeemed_ids = {
        r.item_id for r in db.execute(select(models.MentalCoinsRedemption).where(models.MentalCoinsRedemption.user_id == user_id)).scalars().all()
    }
    return [{"item": item, "redeemed": item.id in redeemed_ids} for item in items]


def redeem_item(db: Session, user_id: str, item_id: str) -> models.MentalCoinsBalance:
    item = db.get(models.MentalCoinsItem, item_id)
    if item is None:
        raise MentalCoinsError("ITEM_NOT_FOUND", "Item não encontrado")

    if db.get(models.MentalCoinsRedemption, (user_id, item_id)) is not None:
        raise MentalCoinsError("ALREADY_REDEEMED", "Item já resgatado")

    balance = get_or_create_balance(db, user_id)
    if balance.balance < item.cost:
        raise MentalCoinsError("INSUFFICIENT_BALANCE", "Saldo insuficiente")

    balance.balance -= item.cost
    balance.updated_at = utcnow()
    db.add(models.MentalCoinsRedemption(user_id=user_id, item_id=item_id))
    db.add(models.MentalCoinsTransaction(user_id=user_id, amount=-item.cost, reason=f"Resgate: {item.name}"))
    db.commit()
    db.refresh(balance)
    return balance
