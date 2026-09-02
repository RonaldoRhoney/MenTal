"""
MentalCoins — moeda de prestígio semanal (U.I/MENTALCOINS_V1.md).
Autoridade 100% do backend: saldo/apuração nunca calculados pelo client.
Attempt/MovementCycle são criados direto no banco (não via fluxo HTTP
completo) para controlar precisamente XP/passos de cada dia — SQLite de
teste não impõe FK, então challenge_id/território fictícios são
aceitáveis aqui (só o valor numérico agregado importa pra este teste).
"""

import uuid
from datetime import date, datetime, timedelta

from sqlalchemy import select

from app import config, mentalcoins, models
from app.db import SessionLocal

from .conftest import auth_header


def _midday(on_date: date) -> datetime:
    return datetime.combine(on_date, datetime.min.time()) + timedelta(hours=12)


def _make_attempt(db, user_id: str, xp: int, on_date: date, speed_bonus_xp: int = 0):
    when = _midday(on_date)
    db.add(
        models.Attempt(
            attempt_id=str(uuid.uuid4()),
            user_id=user_id,
            challenge_id=str(uuid.uuid4()),
            submitted_answer="x",
            is_correct=True,
            xp_base=xp,
            # xp já vem com o bônus de velocidade somado (mesma regra de
            # challenges.py: xp_final = xp_from_hints + speed_bonus_xp) —
            # speed_bonus_xp aqui é só o REGISTRO do quanto disso veio de
            # velocidade, nunca soma extra.
            xp_awarded=xp,
            speed_bonus_xp=speed_bonus_xp,
            created_at=when,
            served_at=when,
        )
    )


def _make_movement_cycle(db, user_id: str, steps: int, on_date: date):
    start = _midday(on_date)
    db.add(
        models.MovementCycle(
            user_id=user_id,
            cycle_start_at=start,
            cycle_end_at=start + timedelta(hours=24),
            steps_collected=steps,
        )
    )


def test_new_user_has_zero_balance_and_empty_catalog_redemptions(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    balance = client.get("/mentalcoins/balance", headers=headers).json()
    assert balance["balance"] == 0

    catalog = client.get("/mentalcoins/catalog", headers=headers).json()["items"]
    assert len(catalog) >= 2
    assert all(item["redeemed"] is False for item in catalog)


def test_redeem_debits_balance_and_blocks_duplicate(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    with SessionLocal() as db:
        mentalcoins.credit(db, user, 200, "teste")

    catalog = client.get("/mentalcoins/catalog", headers=headers).json()["items"]
    item_id = catalog[0]["id"]
    cost = catalog[0]["cost"]

    resp = client.post("/mentalcoins/catalog/redeem", json={"item_id": item_id}, headers=headers)
    assert resp.status_code == 200
    assert resp.json()["balance"] == 200 - cost

    resp = client.post("/mentalcoins/catalog/redeem", json={"item_id": item_id}, headers=headers)
    assert resp.status_code == 422
    assert resp.json()["error"]["code"] == "ALREADY_REDEEMED"


def test_redeem_blocked_when_balance_insufficient(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    catalog = client.get("/mentalcoins/catalog", headers=headers).json()["items"]
    resp = client.post("/mentalcoins/catalog/redeem", json={"item_id": catalog[0]["id"]}, headers=headers)
    assert resp.status_code == 422
    assert resp.json()["error"]["code"] == "INSUFFICIENT_BALANCE"


def test_redeem_unknown_item_returns_not_found(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    resp = client.post("/mentalcoins/catalog/redeem", json={"item_id": "nao_existe"}, headers=headers)
    assert resp.status_code == 422
    assert resp.json()["error"]["code"] == "ITEM_NOT_FOUND"


def test_weekly_apuration_credits_top3_xp_per_day():
    """§3.1: top 3 de XP de CADA um dos 7 dias do ciclo, 10/5/3 coins."""
    cycle_start = date(2026, 8, 3)  # segunda-feira
    cycle_end = cycle_start + timedelta(days=6)
    first, second, third, fourth = (str(uuid.uuid4()) for _ in range(4))

    with SessionLocal() as db:
        _make_attempt(db, first, 100, cycle_start)
        _make_attempt(db, second, 50, cycle_start)
        _make_attempt(db, third, 30, cycle_start)
        _make_attempt(db, fourth, 10, cycle_start)  # 4º lugar, não deve ganhar nada
        db.commit()

        result = mentalcoins.run_weekly_apuration(db, cycle_start, cycle_end)
        assert result["already_processed"] is False

        assert mentalcoins.get_or_create_balance(db, first).balance == config.MENTALCOINS_XP_DAILY_REWARDS[0]
        assert mentalcoins.get_or_create_balance(db, second).balance == config.MENTALCOINS_XP_DAILY_REWARDS[1]
        assert mentalcoins.get_or_create_balance(db, third).balance == config.MENTALCOINS_XP_DAILY_REWARDS[2]
        assert mentalcoins.get_or_create_balance(db, fourth).balance == 0

        hall = mentalcoins.get_current_hall_of_fame(db)
        xp_entries = [e for e in hall if e.category == "xp_daily" and e.reference_date == cycle_start]
        assert {e.user_id for e in xp_entries} == {first, second, third}


def test_weekly_apuration_does_not_double_count_speed_bonus_xp():
    """Achado de auditoria (01/09/2026): attempt.xp_awarded JÁ inclui o
    bônus de velocidade (challenges.py: xp_final = xp_from_hints +
    speed_bonus_xp, salvo em xp_awarded) — a apuração não pode somar
    speed_bonus_xp de novo, senão conta esse bônus duas vezes. Sem
    o bug, o 2º lugar (xp_awarded=60, sem bônus) NUNCA deveria superar
    o 1º (xp_awarded=80, com 20 de bônus já embutido); com o bug antigo
    o 1º contaria como 100 (80+20 de novo), mas o resultado seria o
    mesmo rank aqui — o teste checa o valor exato creditado, não só o
    rank, pra pegar a duplicação mesmo quando não muda quem fica em 1º."""
    # Data anterior a todas as outras deste arquivo de propósito:
    # get_current_hall_of_fame (usado por outros testes) devolve só o
    # cycle_start mais recente no banco compartilhado da suíte — um
    # cycle_start mais novo aqui "esconderia" as entradas dos outros
    # testes que rodam depois deste.
    cycle_start = date(2026, 7, 27)
    cycle_end = cycle_start + timedelta(days=6)
    fast_user, slow_user = str(uuid.uuid4()), str(uuid.uuid4())

    with SessionLocal() as db:
        # xp_awarded=80 já inclui os 20 de bônus de velocidade — total
        # real de XP ganho no dia é 80, nunca 100.
        _make_attempt(db, fast_user, 80, cycle_start, speed_bonus_xp=20)
        _make_attempt(db, slow_user, 79, cycle_start, speed_bonus_xp=0)
        db.commit()

        mentalcoins.run_weekly_apuration(db, cycle_start, cycle_end)

        # Consulta direta por cycle_start (não get_current_hall_of_fame,
        # que só devolve o cycle_start mais recente entre TODOS os testes
        # que compartilham este banco — usar essa função aqui deixaria o
        # teste dependente da ordem de execução dos demais testes deste
        # arquivo).
        entry = db.execute(
            select(models.MentalCoinsHallOfFameEntry).where(
                models.MentalCoinsHallOfFameEntry.cycle_start == cycle_start,
                models.MentalCoinsHallOfFameEntry.category == "xp_daily",
                models.MentalCoinsHallOfFameEntry.user_id == fast_user,
            )
        ).scalar_one()
        assert entry.metric_value == 80


def test_weekly_apuration_is_idempotent():
    cycle_start = date(2026, 8, 10)
    cycle_end = cycle_start + timedelta(days=6)
    user = str(uuid.uuid4())

    with SessionLocal() as db:
        _make_attempt(db, user, 100, cycle_start)
        db.commit()

        first_run = mentalcoins.run_weekly_apuration(db, cycle_start, cycle_end)
        assert first_run["already_processed"] is False
        balance_after_first = mentalcoins.get_or_create_balance(db, user).balance

        second_run = mentalcoins.run_weekly_apuration(db, cycle_start, cycle_end)
        assert second_run["already_processed"] is True
        assert mentalcoins.get_or_create_balance(db, user).balance == balance_after_first


def test_weekly_apuration_credits_steps_champion_and_daily_record():
    """§3.2: campeão da semana (soma) e recordista do dia (pico único)."""
    cycle_start = date(2026, 8, 17)
    cycle_end = cycle_start + timedelta(days=6)
    consistent_walker, single_day_spike = str(uuid.uuid4()), str(uuid.uuid4())

    with SessionLocal() as db:
        # consistent_walker: 5000 passos em 3 dias diferentes = 15000 total.
        for i in range(3):
            _make_movement_cycle(db, consistent_walker, 5000, cycle_start + timedelta(days=i))
        # single_day_spike: um único pico de 12000 passos num dia só.
        _make_movement_cycle(db, single_day_spike, 12000, cycle_start + timedelta(days=1))
        db.commit()

        mentalcoins.run_weekly_apuration(db, cycle_start, cycle_end)

        # Campeão da semana: consistent_walker (15000 > 12000 no total).
        assert (
            mentalcoins.get_or_create_balance(db, consistent_walker).balance
            == config.MENTALCOINS_STEPS_WEEK_CHAMPION_REWARD
        )
        # Recordista do dia: single_day_spike (12000 > qualquer pico único de 5000).
        assert (
            mentalcoins.get_or_create_balance(db, single_day_spike).balance
            == config.MENTALCOINS_STEPS_DAY_RECORD_REWARD
        )

        hall = mentalcoins.get_current_hall_of_fame(db)
        week_entry = next(e for e in hall if e.category == "steps_week")
        day_entry = next(e for e in hall if e.category == "steps_day")
        assert week_entry.user_id == consistent_walker
        assert week_entry.metric_value == 15000
        assert day_entry.user_id == single_day_spike
        assert day_entry.metric_value == 12000


def test_admin_run_apuration_endpoint_requires_admin_role(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    resp = client.post("/admin/mentalcoins/run-apuration", headers=headers)
    assert resp.status_code == 403
    assert resp.json()["error"]["code"] == "ADMIN_ONLY"
