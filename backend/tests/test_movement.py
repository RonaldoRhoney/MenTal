"""
V2 item 9 — Contador de passos & movimento (STEP_COUNTER_MOVIMENTO.md).
O sensor de passos vive no cliente (Android), então estes testes chamam
app.movement diretamente com `now` explícito para simular a passagem de
ciclos de 24h sem esperar tempo real — mesmo padrão já usado em
test_notifications.py para simular janelas de inatividade.
"""

import sqlite3
import uuid
from datetime import datetime, timedelta
from app.timeutil import utcnow

from app import config, models, movement, notifications
from app.db import SessionLocal

from .conftest import auth_header


def _set_anchor(user_id: str, when: datetime) -> None:
    db_path = config.DATABASE_URL.removeprefix("sqlite:///")
    con = sqlite3.connect(db_path)
    cur = con.cursor()
    cur.execute(
        "update profiles set movement_cycle_anchor_at=? where user_id=?",
        (when.isoformat(), user_id.replace("-", "")),
    )
    con.commit()
    con.close()


def _fake_sender(sent_log):
    def _send(push_token, title, body):
        sent_log.append({"push_token": push_token, "title": title, "body": body})
        return True

    return _send


def test_enable_sets_anchor_once_disable_preserves_it(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers)

    resp = client.post("/movement/enable", headers=headers)
    assert resp.status_code == 200

    with SessionLocal() as db:
        profile = db.get(models.Profile, user.replace("-", ""))
        first_anchor = profile.movement_cycle_anchor_at
        assert profile.movement_enabled is True
        assert first_anchor is not None

    client.post("/movement/disable", headers=headers)
    client.post("/movement/enable", headers=headers)

    with SessionLocal() as db:
        profile = db.get(models.Profile, user.replace("-", ""))
        assert profile.movement_enabled is True
        # Reativar não reseta o horário-âncora original (§2).
        assert profile.movement_cycle_anchor_at == first_anchor


def test_status_shows_current_cycle_after_enable(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers)
    client.post("/movement/enable", headers=headers)

    status = client.get("/movement/status", headers=headers).json()
    assert status["movement_enabled"] is True
    assert status["current_cycle"] is not None
    assert status["current_cycle"]["steps_collected"] == 0
    assert status["pending_report_cycle"] is None


def test_collect_disabled_is_rejected(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers)

    resp = client.post("/movement/collect", json={"steps": 1000}, headers=headers)
    assert resp.status_code == 400
    assert resp.json()["error"]["code"] == "MOVEMENT_DISABLED"


def test_negative_steps_rejected_by_schema(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers)
    client.post("/movement/enable", headers=headers)

    resp = client.post("/movement/collect", json={"steps": -5}, headers=headers)
    assert resp.status_code == 422


def test_partial_collections_sum_tiers_without_double_awarding(client):
    """
    STEP_COUNTER_MOVIMENTO.md §4: bônus escalonado por faixa TOTAL do
    ciclo. Duas coletas parciais que juntas cruzam de uma faixa pra outra
    devem premiar só a DIFERENÇA entre os bônus de faixa, nunca somar os
    dois bônus inteiros (mesmo princípio de level_up_true_only_on_the_
    answer_that_crosses_the_level_boundary já usado em challenges).
    """
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers)
    client.post("/movement/enable", headers=headers)

    with SessionLocal() as db:
        profile_before = db.get(models.Profile, user.replace("-", ""))
        xp_before = profile_before.xp_total

    # 3.000 passos -> faixa 2.000-4.999 -> bônus base x1 = 20 XP.
    r1 = client.post("/movement/collect", json={"steps": 3000}, headers=headers).json()
    assert r1["cycle"]["steps_collected"] == 3000
    assert r1["xp_awarded"] == config.MOVEMENT_XP_BASE * 1

    # +3.000 (total 6.000) -> faixa 5.000-9.999 -> bônus base x2 = 40 XP
    # total do ciclo; xp_awarded desta chamada é só a diferença (20).
    r2 = client.post("/movement/collect", json={"steps": 3000}, headers=headers).json()
    assert r2["cycle"]["steps_collected"] == 6000
    assert r2["xp_awarded"] == config.MOVEMENT_XP_BASE * 1

    with SessionLocal() as db:
        profile_after = db.get(models.Profile, user.replace("-", ""))
        assert profile_after.xp_total - xp_before == config.MOVEMENT_XP_BASE * 2


def test_steps_beyond_top_tier_never_exceed_top_bonus(client):
    """
    §4: "quem andar 19.000 recebe o mesmo múltiplo da faixa mais alta" —
    é o próprio desenho que neutraliza valor client-side absurdo, sem
    precisar de anti-cheat adicional.
    """
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers)
    client.post("/movement/enable", headers=headers)

    resp = client.post("/movement/collect", json={"steps": 999_999}, headers=headers).json()
    assert resp["xp_awarded"] == config.MOVEMENT_XP_BASE * 4

    # Uma segunda coleta enorme na mesma faixa não deve premiar de novo.
    resp2 = client.post("/movement/collect", json={"steps": 999_999}, headers=headers).json()
    assert resp2["xp_awarded"] == 0


def test_previous_cycle_collectible_within_grace_then_expires(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers)
    client.post("/movement/enable", headers=headers)

    anchor = utcnow() - timedelta(hours=30)
    _set_anchor(user, anchor)

    # Coleta parcial DURANTE o 1º ciclo (é isso que cria o registro do
    # ciclo em primeiro lugar — sem nenhuma coleta, não há linha a
    # recuperar depois, mesmo que o ciclo tenha existido).
    with SessionLocal() as db:
        movement.collect_steps(db, user, 1000, now=anchor + timedelta(hours=2))

    with SessionLocal() as db:
        profile = db.get(models.Profile, user.replace("-", ""))
        # "now" real (30h após o anchor) já está dentro do 2º ciclo;
        # o 1º ciclo fechou 6h atrás — ainda dentro da graça de 24h.
        pending = movement.get_pending_report_cycle(db, profile)
        assert pending is not None
        assert pending.steps_collected == 1000

        # A coleta final acontece bem depois dos 3 checkpoints intradiários
        # (6h/12h/18h) já terem fechado — eles também são pagos nesta
        # mesma chamada (achado esperado da arquitetura "catch-up": uma
        # coleta tardia acerta as contas de tudo que ficou pendente).
        collect_now = anchor + timedelta(hours=30)

        def _expected_tier_bonus(total_steps: int, fraction: float) -> int:
            for threshold, multiplier in config.MOVEMENT_STEP_TIERS:
                if total_steps >= threshold * fraction:
                    return config.MOVEMENT_XP_BASE * multiplier
            return 0

        expected_checkpoint_xp = sum(_expected_tier_bonus(6000, (i + 1) / 4) for i in range(3))
        expected_main_tier_xp = _expected_tier_bonus(6000, 1.0) - _expected_tier_bonus(1000, 1.0)

        result = movement.collect_steps(db, user, 5000, cycle_id=pending.id, now=collect_now)
        cycle, xp_awarded, _, _, _, checkpoints_reached = result
        # 1.000 (já coletado) + 5.000 (coleta final) = 6.000 no total do
        # ciclo -> faixa 5.000-9.999 -> bônus x2 pelo tier normal, mais
        # os 3 bônus de checkpoint (calculados na fração de tempo de
        # cada um, com o total acumulado de 6.000).
        assert cycle.steps_collected == 6000
        assert checkpoints_reached == 3
        assert xp_awarded == expected_checkpoint_xp + expected_main_tier_xp

    # Passado o prazo de graça (>48h desde o anchor original), a coleta
    # no mesmo cycle_id deve ser recusada — passos perdidos de vez.
    with SessionLocal() as db:
        try:
            movement.collect_steps(db, user, 100, cycle_id=pending.id, now=anchor + timedelta(hours=49))
            assert False, "esperava MovementError CYCLE_EXPIRED"
        except movement.MovementError as e:
            assert e.code == "CYCLE_EXPIRED"


def test_movement_cycle_report_fires_once_per_cycle(client, monkeypatch):
    sent_log = []
    monkeypatch.setattr("app.notifications.push.send_push_notification", _fake_sender(sent_log))

    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers)
    client.post("/movement/enable", headers=headers)
    client.post("/notifications/register-token", json={"push_token": "movement-token"}, headers=headers)

    anchor = utcnow() - timedelta(hours=25)
    _set_anchor(user, anchor)
    now = utcnow()

    with SessionLocal() as db:
        result = notifications.run_notification_checks(db, now=now)
    movement_events = [e for e in sent_log if e["push_token"] == "movement-token"]
    assert result["movement_sent"] >= 1
    assert len(movement_events) == 1
    assert movement_events[0]["title"] == "Seu ciclo fechou!"

    # Mesmo estado, segunda checagem — não reenvia o mesmo relatório.
    with SessionLocal() as db:
        notifications.run_notification_checks(db, now=now)
    movement_events = [e for e in sent_log if e["push_token"] == "movement-token"]
    assert len(movement_events) == 1


def test_daily_goal_round_trip(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers)

    default_status = client.get("/movement/status", headers=headers).json()
    assert default_status["daily_goal_steps"] is None

    set_resp = client.put("/movement/goal", json={"daily_goal_steps": 20000}, headers=headers)
    assert set_resp.status_code == 200
    assert set_resp.json()["daily_goal_steps"] == 20000

    status = client.get("/movement/status", headers=headers).json()
    assert status["daily_goal_steps"] == 20000

    cleared = client.put("/movement/goal", json={"daily_goal_steps": None}, headers=headers)
    assert cleared.json()["daily_goal_steps"] is None


def test_daily_goal_rejects_zero_or_negative(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers)

    resp = client.put("/movement/goal", json={"daily_goal_steps": 0}, headers=headers)
    assert resp.status_code == 422


def test_goal_bonus_awarded_once_when_crossing_threshold(client):
    """
    STEP_COUNTER_MOVIMENTO.md §4 (extensão, 2026-08-21): ultrapassar a
    PRÓPRIA meta paga um bônus extra, uma vez por ciclo, somado (não no
    lugar) ao bônus por faixa de MOVEMENT_STEP_TIERS.
    """
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers)
    client.post("/movement/enable", headers=headers)
    client.put("/movement/goal", json={"daily_goal_steps": 5000}, headers=headers)

    # 3.000 passos: abaixo da meta, só o bônus de faixa (2.000-4.999 -> x1).
    r1 = client.post("/movement/collect", json={"steps": 3000}, headers=headers).json()
    assert r1["goal_reached"] is False
    assert r1["xp_awarded"] == config.MOVEMENT_XP_BASE * 1

    # +3.000 (total 6.000): cruza a meta de 5.000 -> bônus de faixa
    # (5.000-9.999 -> x2, diferença de x1) + bônus de meta, na MESMA
    # resposta.
    r2 = client.post("/movement/collect", json={"steps": 3000}, headers=headers).json()
    assert r2["goal_reached"] is True
    assert r2["xp_awarded"] == config.MOVEMENT_XP_BASE * 1 + config.MOVEMENT_GOAL_BONUS_XP

    # Nova coleta na mesma faixa, meta já superada — não paga o bônus de
    # meta de novo.
    r3 = client.post("/movement/collect", json={"steps": 100}, headers=headers).json()
    assert r3["goal_reached"] is False
    assert r3["xp_awarded"] == 0


def test_no_goal_bonus_without_goal_set(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers)
    client.post("/movement/enable", headers=headers)

    resp = client.post("/movement/collect", json={"steps": 20000}, headers=headers).json()
    assert resp["goal_reached"] is False
    assert resp["xp_awarded"] == config.MOVEMENT_XP_BASE * 4


def test_checkpoint_bonus_awarded_once_when_window_closes(client):
    """
    STEP_COUNTER_MOVIMENTO.md §4 (extensão, 2026-08-21): 24h divididas em
    4 partes iguais (6h cada); os 3 primeiros fechamentos pagam bônus
    extra se o total acumulado até ali já bate a faixa de
    MOVEMENT_STEP_TIERS proporcional ao tempo decorrido (1/4, 2/4, 3/4).
    A 4ª parte coincide com o fim do ciclo — já coberta pelo bônus de
    faixa cheio, não é um checkpoint separado.
    """
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers)
    client.post("/movement/enable", headers=headers)

    with SessionLocal() as db:
        profile = db.get(models.Profile, user.replace("-", ""))
        anchor = profile.movement_cycle_anchor_at

    # Checkpoint 0 fecha às 6h (1/4 do ciclo). Faixa proporcional (1/4):
    # 500/1.250/2.500/3.750. 600 passos cruza só a de 500 -> bônus x1.
    # Faixa CHEIA (600 sobre 2.000/5.000/...) não é cruzada -> bônus do
    # tier normal é 0; todo o xp desta chamada vem só do checkpoint.
    with SessionLocal() as db:
        _, xp1, _, _, _, checkpoints1 = movement.collect_steps(db, user, 600, now=anchor + timedelta(hours=7))
    assert checkpoints1 == 1
    assert xp1 == config.MOVEMENT_XP_BASE * 1

    # Nova coleta ainda na mesma janela já fechada — checkpoint 0 não é
    # pago de novo, e os passos ainda não bastam pra tier cheio nem
    # checkpoint 1 (que só fecha às 12h).
    with SessionLocal() as db:
        _, xp2, _, _, _, checkpoints2 = movement.collect_steps(db, user, 100, now=anchor + timedelta(hours=8))
    assert checkpoints2 == 0
    assert xp2 == 0


def test_checkpoint_bonus_catches_up_multiple_windows_in_one_lazy_collection(client):
    """
    Se o usuário só abre o app no fim do dia (arquitetura "catch-up",
    decisão de Rhoney 2026-08-21 — nunca serviço em segundo plano), uma
    única coleta tardia pode fechar vários checkpoints de uma vez.
    """
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers)
    client.post("/movement/enable", headers=headers)

    with SessionLocal() as db:
        profile = db.get(models.Profile, user.replace("-", ""))
        anchor = profile.movement_cycle_anchor_at

    # now = 20h depois do anchor: os 3 checkpoints (6h/12h/18h) já
    # fecharam de uma vez. Cada um usa a faixa proporcional à SUA fração
    # de tempo (1/4, 2/4, 3/4) — calculado aqui a partir da mesma tabela
    # de configuração usada pela implementação, não reproduzindo a conta
    # manualmente (evita erro de aritmética divergir do real).
    def _expected_tier_bonus(total_steps: int, fraction: float) -> int:
        for threshold, multiplier in config.MOVEMENT_STEP_TIERS:
            if total_steps >= threshold * fraction:
                return config.MOVEMENT_XP_BASE * multiplier
        return 0

    steps = 8000
    expected_checkpoint_xp = sum(_expected_tier_bonus(steps, (i + 1) / 4) for i in range(3))
    expected_main_tier_xp = _expected_tier_bonus(steps, 1.0)

    with SessionLocal() as db:
        _, xp, _, _, _, checkpoints_reached = movement.collect_steps(
            db, user, steps, now=anchor + timedelta(hours=20)
        )
    assert checkpoints_reached == 3
    assert xp == expected_checkpoint_xp + expected_main_tier_xp
