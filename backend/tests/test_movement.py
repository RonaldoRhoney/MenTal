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
from app.timeutil import naive, utcnow

from sqlalchemy import select

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


def _cycle_start_now() -> datetime:
    """Início do ciclo corrente (meia-noite de Brasília em UTC naive) —
    MENTAL_ESPECIFICACAO_TECNICA_APROVADA_MOVIMENTO_v2.docx §4 trocou o
    ciclo de "24h a partir de quando o usuário ativou" para "meia-noite
    de Brasília pra todo mundo". Sem fixar `now`, os testes de bônus/
    checkpoint ficam sujeitos à hora real do relógio de quem roda a
    suíte (se já passou das 6h/12h/18h do dia em Brasília, checkpoints
    "fecham" sozinhos e poluem o XP esperado) — usado via
    monkeypatch.setattr(movement, "utcnow", ...) nesses testes."""
    start, _ = movement._cycle_window_for(utcnow())
    return start + timedelta(minutes=1)


def _fake_sender(sent_log):
    def _send(push_token, title, body):
        sent_log.append({"push_token": push_token, "title": title, "body": body})
        return True

    return _send


def test_enable_sets_anchor_once_disable_preserves_it(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

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
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)
    client.post("/movement/enable", headers=headers)

    status = client.get("/movement/status", headers=headers).json()
    assert status["movement_enabled"] is True
    assert status["current_cycle"] is not None
    assert status["current_cycle"]["steps_collected"] == 0
    assert status["pending_report_cycle"] is None


def test_collect_disabled_is_rejected(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    resp = client.post("/movement/collect", json={"steps": 1000}, headers=headers)
    assert resp.status_code == 400
    assert resp.json()["error"]["code"] == "MOVEMENT_DISABLED"


def test_negative_steps_rejected_by_schema(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)
    client.post("/movement/enable", headers=headers)

    resp = client.post("/movement/collect", json={"steps": -5}, headers=headers)
    assert resp.status_code == 422


def test_partial_collections_sum_tiers_without_double_awarding(client, monkeypatch):
    """
    STEP_COUNTER_MOVIMENTO.md §4: bônus escalonado por faixa TOTAL do
    ciclo. Duas coletas parciais que juntas cruzam de uma faixa pra outra
    devem premiar só a DIFERENÇA entre os bônus de faixa, nunca somar os
    dois bônus inteiros (mesmo princípio de level_up_true_only_on_the_
    answer_that_crosses_the_level_boundary já usado em challenges).
    """
    monkeypatch.setattr(movement, "utcnow", _cycle_start_now)
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)
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


def test_steps_beyond_top_tier_never_exceed_top_bonus(client, monkeypatch):
    """
    §4: "quem andar 19.000 recebe o mesmo múltiplo da faixa mais alta" —
    é o próprio desenho que neutraliza valor client-side absurdo, sem
    precisar de anti-cheat adicional.
    """
    monkeypatch.setattr(movement, "utcnow", _cycle_start_now)
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)
    client.post("/movement/enable", headers=headers)

    resp = client.post("/movement/collect", json={"steps": 999_999}, headers=headers).json()
    assert resp["xp_awarded"] == config.MOVEMENT_XP_BASE * 4

    # Uma segunda coleta enorme na mesma faixa não deve premiar de novo.
    resp2 = client.post("/movement/collect", json={"steps": 999_999}, headers=headers).json()
    assert resp2["xp_awarded"] == 0


def test_repeated_small_collections_never_exceed_cycle_cap(client):
    """
    Achado real de produção (31/08/2026): sensor de passos corrompido +
    auto-coleta a cada ~20s inflou um ciclo pra ~165.000 passos em
    minutos, sem nenhum request isolado passar do teto por chamada —
    o problema era a SOMA. Simula a mesma sequência (muitas coletas
    pequenas e repetidas) e confirma que o total do ciclo nunca passa
    de MOVEMENT_MAX_STEPS_PER_CYCLE, mesmo entregando bem mais que isso.
    """
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)
    client.post("/movement/enable", headers=headers)

    for _ in range(30):
        client.post("/movement/collect", json={"steps": 10_000}, headers=headers)

    status = client.get("/movement/status", headers=headers).json()
    assert status["current_cycle"]["steps_collected"] == config.MOVEMENT_MAX_STEPS_PER_CYCLE


def test_cycle_cap_bounds_mentalcoins_from_runaway_sensor(client):
    """
    A mesma corrupção de sensor também inflava MentalCoins de verdade
    (marco de 1000 passos = 5 moedas, sem teto próprio) — o teto por
    ciclo em steps_collected precisa limitar isso também, não só o XP.
    """
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)
    client.post("/movement/enable", headers=headers)

    total_awarded = 0
    for _ in range(30):
        resp = client.post("/movement/collect", json={"steps": 10_000}, headers=headers).json()
        total_awarded += resp["mentalcoins_awarded"]

    max_possible = (config.MOVEMENT_MAX_STEPS_PER_CYCLE // config.MOVEMENT_STEPS_PER_MENTALCOIN) * config.MOVEMENT_MENTALCOINS_PER_MILESTONE
    assert total_awarded == max_possible
    balance = client.get("/mentalcoins/balance", headers=headers).json()
    assert balance["balance"] == max_possible


def test_single_huge_collection_still_clamped_but_reaches_top_xp_tier(client, monkeypatch):
    """Confirma que o clamp por ciclo não quebra o comportamento já
    validado em test_steps_beyond_top_tier_never_exceed_top_bonus: um
    valor absurdo numa única chamada ainda cai na faixa máxima de XP,
    mesmo com o total do ciclo sendo travado bem abaixo do valor bruto
    enviado."""
    monkeypatch.setattr(movement, "utcnow", _cycle_start_now)
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)
    client.post("/movement/enable", headers=headers)

    resp = client.post("/movement/collect", json={"steps": 999_999}, headers=headers).json()
    assert resp["xp_awarded"] == config.MOVEMENT_XP_BASE * 4
    assert resp["cycle"]["steps_collected"] == config.MOVEMENT_MAX_STEPS_PER_CYCLE


def test_previous_cycle_collectible_within_grace_then_expires(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)
    client.post("/movement/enable", headers=headers)

    # Anchor real deliberadamente bem no passado (MENTAL_ESPECIFICACAO_
    # TECNICA_APROVADA_MOVIMENTO_v2.docx §4: anchor não determina mais a
    # virada do ciclo, só continua servindo pra "desde quando o usuário
    # tem Movimento ativo" — sem isso, o "ciclo de ontem" simulado abaixo
    # cairia antes do anchor real de hoje e get_pending_report_cycle
    # rejeitaria como se fosse anterior à ativação).
    _set_anchor(user, utcnow() - timedelta(days=10))
    # Início do ciclo de ONTEM em Brasília — ponto de referência local a
    # este teste (não mais o anchor do usuário).
    anchor = _cycle_start_now() - timedelta(hours=24)

    # Coleta parcial DURANTE o 1º ciclo (é isso que cria o registro do
    # ciclo em primeiro lugar — sem nenhuma coleta, não há linha a
    # recuperar depois, mesmo que o ciclo tenha existido).
    with SessionLocal() as db:
        movement.collect_steps(db, user, 1000, now=anchor + timedelta(hours=2))

    with SessionLocal() as db:
        profile = db.get(models.Profile, user.replace("-", ""))
        # "now" (30h após o início do ciclo de ontem) já está dentro do
        # ciclo de hoje; o ciclo de ontem fechou 6h atrás — ainda dentro
        # da graça de 24h.
        pending = movement.get_pending_report_cycle(db, profile, now=anchor + timedelta(hours=30))
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
        cycle, xp_awarded, _, _, _, checkpoints_reached, _ = result
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
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)
    client.post("/movement/enable", headers=headers)
    client.post("/notifications/register-token", json={"push_token": "movement-token"}, headers=headers)

    # Anchor bem no passado (MENTAL_ESPECIFICACAO_TECNICA_APROVADA_
    # MOVIMENTO_v2.docx §4: anchor não determina mais a virada do ciclo,
    # só continua servindo pra "desde quando o usuário tem Movimento
    # ativo" — sem isso, o ciclo de ONTEM em Brasília, calculado agora
    # de forma independente do anchor, poderia cair antes dele e o
    # relatório nunca dispararia).
    _set_anchor(user, utcnow() - timedelta(days=10))
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
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

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
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    resp = client.put("/movement/goal", json={"daily_goal_steps": 0}, headers=headers)
    assert resp.status_code == 422


def test_daily_goal_rejects_trivial_value_below_minimum(client):
    """
    Achado de auditoria de segurança (28/08/2026): só validava "maior
    que zero" — uma meta de 1 passo garantia o bônus de meta
    (config.MOVEMENT_GOAL_BONUS_XP) com esforço zero, todo ciclo.
    """
    from app.config import MOVEMENT_MIN_DAILY_GOAL_STEPS

    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    resp = client.put("/movement/goal", json={"daily_goal_steps": 1}, headers=headers)
    assert resp.status_code == 422

    at_minimum = client.put(
        "/movement/goal", json={"daily_goal_steps": MOVEMENT_MIN_DAILY_GOAL_STEPS}, headers=headers
    )
    assert at_minimum.status_code == 200


def test_goal_bonus_awarded_once_when_crossing_threshold(client, monkeypatch):
    """
    STEP_COUNTER_MOVIMENTO.md §4 (extensão, 2026-08-21): ultrapassar a
    PRÓPRIA meta paga um bônus extra, uma vez por ciclo, somado (não no
    lugar) ao bônus por faixa de MOVEMENT_STEP_TIERS.
    """
    monkeypatch.setattr(movement, "utcnow", _cycle_start_now)
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)
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


def test_no_goal_bonus_without_goal_set(client, monkeypatch):
    monkeypatch.setattr(movement, "utcnow", _cycle_start_now)
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)
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
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)
    client.post("/movement/enable", headers=headers)

    # Ponto de referência é o início do ciclo de HOJE em Brasília (não
    # mais o anchor por usuário, MENTAL_ESPECIFICACAO_TECNICA_APROVADA_
    # MOVIMENTO_v2.docx §4) — a primeira coleta abaixo cria o ciclo com
    # esse cycle_start_at.
    anchor = _cycle_start_now()

    # Checkpoint 0 fecha às 6h (1/4 do ciclo). Faixa proporcional (1/4):
    # 500/1.250/2.500/3.750. 600 passos cruza só a de 500 -> bônus x1.
    # Faixa CHEIA (600 sobre 2.000/5.000/...) não é cruzada -> bônus do
    # tier normal é 0; todo o xp desta chamada vem só do checkpoint.
    with SessionLocal() as db:
        _, xp1, _, _, _, checkpoints1, _ = movement.collect_steps(db, user, 600, now=anchor + timedelta(hours=7))
    assert checkpoints1 == 1
    assert xp1 == config.MOVEMENT_XP_BASE * 1

    # Nova coleta ainda na mesma janela já fechada — checkpoint 0 não é
    # pago de novo, e os passos ainda não bastam pra tier cheio nem
    # checkpoint 1 (que só fecha às 12h).
    with SessionLocal() as db:
        _, xp2, _, _, _, checkpoints2, _ = movement.collect_steps(db, user, 100, now=anchor + timedelta(hours=8))
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
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)
    client.post("/movement/enable", headers=headers)

    # Início do ciclo de HOJE em Brasília (não mais o anchor por
    # usuário) — a primeira coleta abaixo cria o ciclo com esse valor.
    anchor = _cycle_start_now()

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
        _, xp, _, _, _, checkpoints_reached, _ = movement.collect_steps(
            db, user, steps, now=anchor + timedelta(hours=20)
        )
    assert checkpoints_reached == 3
    assert xp == expected_checkpoint_xp + expected_main_tier_xp


def test_collect_steps_records_snapshot_history_for_intraday_chart(client):
    """
    Redesign da tela Movimento (26/08/2026): checkpoint_bonus_mask só
    sabia SE um bônus já foi pago, nunca QUANTOS passos existiam em cada
    ponto do dia — sem isso não dá pra desenhar a curva intradiária real
    (gráfico de linha). Cada coleta agora grava um snapshot com o total
    acumulado naquele momento.
    """
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)
    client.post("/movement/enable", headers=headers)

    client.post("/movement/collect", json={"steps": 1000}, headers=headers)
    resp = client.post("/movement/collect", json={"steps": 500}, headers=headers)
    assert resp.status_code == 200
    # A resposta da própria coleta não traz mais o histórico de snapshots
    # (30/08/2026, achado real: o client nunca lia isso daqui, só de
    # GET /movement/status — buscar de novo a cada coleta era trabalho
    # puro descartado, e piorava a cada snapshot acumulado no ciclo).
    assert resp.json()["cycle"]["snapshots"] == []

    status = client.get("/movement/status", headers=headers).json()
    snapshots = status["current_cycle"]["snapshots"]
    assert len(snapshots) == 2
    assert snapshots[0]["steps_total"] == 1000
    assert snapshots[1]["steps_total"] == 1500
    # Ordenado cronologicamente (o segundo veio depois do primeiro).
    assert snapshots[0]["recorded_at"] <= snapshots[1]["recorded_at"]


def test_movement_status_returns_recent_cycles_for_weekly_chart(client):
    """Gráfico semanal de barras (redesign 26/08/2026) — GET /movement/
    status precisa trazer os últimos ciclos, não só o atual."""
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)
    client.post("/movement/enable", headers=headers)
    client.post("/movement/collect", json={"steps": 3000}, headers=headers)

    status = client.get("/movement/status", headers=headers).json()
    assert len(status["recent_cycles"]) == 1
    assert status["recent_cycles"][0]["steps_collected"] == 3000


def test_get_movement_cycle_returns_snapshots_for_own_cycle(client):
    """MOVIMENTO_REFORMULACAO §11/§12 — card "Hoje ›" e tocar um dia na
    tela "Semana" precisam do histórico intradiário de um ciclo
    específico, diferente de recent_cycles (que nunca traz snapshots)."""
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)
    client.post("/movement/enable", headers=headers)
    client.post("/movement/collect", json={"steps": 2000}, headers=headers)
    status = client.get("/movement/status", headers=headers).json()
    cycle_id = status["current_cycle"]["id"]

    resp = client.get(f"/movement/cycles/{cycle_id}", headers=headers)
    assert resp.status_code == 200
    body = resp.json()
    assert body["steps_collected"] == 2000
    assert len(body["snapshots"]) == 1


def test_get_movement_cycle_rejects_another_users_cycle(client):
    owner_headers = auth_header(str(uuid.uuid4()))
    intruder_headers = auth_header(str(uuid.uuid4()))
    client.post("/age-gate", json={"age_confirmed": True}, headers=owner_headers)
    client.post("/age-gate", json={"age_confirmed": True}, headers=intruder_headers)
    client.post("/movement/enable", headers=owner_headers)
    client.post("/movement/collect", json={"steps": 2000}, headers=owner_headers)
    status = client.get("/movement/status", headers=owner_headers).json()
    cycle_id = status["current_cycle"]["id"]

    resp = client.get(f"/movement/cycles/{cycle_id}", headers=intruder_headers)
    assert resp.status_code == 404


def test_get_movement_cycle_rejects_nonexistent_id(client):
    headers = auth_header(str(uuid.uuid4()))
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)
    resp = client.get(f"/movement/cycles/{uuid.uuid4()}", headers=headers)
    assert resp.status_code == 404


def test_yearly_summary_aggregates_by_month_and_computes_best_month(client):
    """MOVIMENTO_REFORMULACAO §13 — card "Ano ›": meses, total, média por
    dia ativo, dias ativos, melhor mês e XP do ano."""
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)
    client.post("/movement/enable", headers=headers)

    now = utcnow()
    with SessionLocal() as db:
        profile = db.execute(select(models.Profile).where(models.Profile.user_id == user)).scalar_one()
        anchor = naive(profile.movement_cycle_anchor_at)
        # Um ciclo em janeiro (mês 1) e dois em fevereiro (mês 2) do
        # mesmo ano do anchor, todos independentes do ciclo real de hoje.
        year = anchor.year
        c1 = models.MovementCycle(
            user_id=user,
            cycle_start_at=datetime(year, 1, 10),
            cycle_end_at=datetime(year, 1, 11),
            steps_collected=5000,
            xp_awarded=40,
        )
        c2 = models.MovementCycle(
            user_id=user,
            cycle_start_at=datetime(year, 2, 5),
            cycle_end_at=datetime(year, 2, 6),
            steps_collected=8000,
            xp_awarded=60,
        )
        c3 = models.MovementCycle(
            user_id=user,
            cycle_start_at=datetime(year, 2, 12),
            cycle_end_at=datetime(year, 2, 13),
            steps_collected=2000,
            xp_awarded=20,
        )
        db.add_all([c1, c2, c3])
        db.commit()

    resp = client.get("/movement/yearly-summary", params={"year": year}, headers=headers)
    assert resp.status_code == 200
    body = resp.json()
    assert body["year"] == year
    assert body["total_steps"] == 15000
    assert body["active_days"] == 3
    assert body["average_steps_per_active_day"] == 5000
    assert body["best_month"] == 2
    assert body["total_xp_awarded"] == 120
    months_by_number = {m["month"]: m for m in body["months"]}
    assert months_by_number[1]["total_steps"] == 5000
    assert months_by_number[2]["total_steps"] == 10000
    assert months_by_number[2]["active_days"] == 2


def test_yearly_summary_best_month_none_when_no_steps_collected(client):
    """Achado real em teste no dispositivo (01/09/2026): ativar Movimento
    já cria o ciclo do dia corrente com steps_collected=0 — isso não pode
    contar como "melhor mês", senão a tela mostra 'Melhor mês: set' junto
    com 'Total de passos: 0', o que não faz sentido nenhum pro usuário."""
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)
    client.post("/movement/enable", headers=headers)

    resp = client.get("/movement/yearly-summary", headers=headers)
    assert resp.status_code == 200
    body = resp.json()
    assert body["total_steps"] == 0
    assert body["active_days"] == 0
    assert body["best_month"] is None


def test_yearly_summary_default_year_respects_brasilia_not_utc(client, monkeypatch):
    """Achado de revisão de código (01/09/2026): o endpoint usava
    datetime.utcnow().year pra 'ano atual' quando nenhum ?year= é
    passado — perto da virada, UTC (00h-03h de 1º de janeiro) já está
    num ano novo enquanto Brasília (UTC-3) ainda está em 31 de
    dezembro. §17 exige 'ano atual segundo a regra temporal' (Brasília,
    não UTC puro, mesmo princípio de §4)."""
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    # 01:30 UTC de 1º de janeiro de 2027 = 22:30 de 31/12/2026 em
    # Brasília — "ano atual" ainda deveria ser 2026, não 2027.
    monkeypatch.setattr("app.routers.movement.utcnow", lambda: datetime(2027, 1, 1, 1, 30, 0))

    resp = client.get("/movement/yearly-summary", headers=headers)
    assert resp.status_code == 200
    assert resp.json()["year"] == 2026


def test_cycle_window_matches_exact_brasilia_midnight_boundary():
    """MENTAL_ESPECIFICACAO_TECNICA_APROVADA_MOVIMENTO_v2.docx §4/§22 —
    teste explícito de 23:59:59 -> 00:00:00 de Brasília. Brasília é
    UTC-3 fixo (sem horário de verão desde 2019), então meia-noite lá é
    sempre 03:00 UTC, ano inteiro."""
    # 23:59:59 de Brasília em 15/06/2026 = 02:59:59 UTC em 16/06 — ainda
    # pertence ao ciclo do dia 15.
    just_before_midnight = datetime(2026, 6, 16, 2, 59, 59)
    start, end = movement._cycle_window_for(just_before_midnight)
    assert start == datetime(2026, 6, 15, 3, 0, 0)
    assert end == datetime(2026, 6, 16, 3, 0, 0)
    assert start <= just_before_midnight < end

    # 00:00:00 de Brasília em 16/06/2026 = 03:00:00 UTC — já é o
    # próximo ciclo, 1 segundo depois do caso acima.
    exactly_midnight = datetime(2026, 6, 16, 3, 0, 0)
    start2, end2 = movement._cycle_window_for(exactly_midnight)
    assert start2 == datetime(2026, 6, 16, 3, 0, 0)
    assert start2 == end  # o fim do ciclo anterior É o início do novo
    assert start2 != start


def test_cycle_window_uses_fixed_offset_never_daylight_saving():
    """Brasil aboliu horário de verão em 2019 (§4: 'confirmar que a
    biblioteca de timezone usada não aplica transição de horário de
    verão por engano') — datas de verão (jan/fev, quando o DST antigo
    valia) não podem usar offset diferente de -03:00."""
    # Meio-dia UTC em janeiro = 09:00 em Brasília (-3h) — mesmo dia.
    summer_now = datetime(2026, 1, 15, 12, 0, 0)
    start, _ = movement._cycle_window_for(summer_now)
    assert start == datetime(2026, 1, 15, 3, 0, 0)


def test_pending_cycle_preserved_across_midnight_transition(client):
    """§4: 'passos do ciclo anterior não podem desaparecer na virada' e
    'a virada não pode duplicar passos, XP ou recompensas' — coleta
    parcial antes da meia-noite, depois confirma que os passos
    continuam intactos e coletáveis no ciclo pendente após a virada."""
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)
    client.post("/movement/enable", headers=headers)
    _set_anchor(user, utcnow() - timedelta(days=10))

    # yesterday_start já embute +1min de folga (_cycle_start_now) — usa
    # 23h57 (não 23h59) pra garantir margem clara antes da virada real.
    yesterday_start = _cycle_start_now() - timedelta(hours=24)
    just_before_midnight = yesterday_start + timedelta(hours=23, minutes=57)
    with SessionLocal() as db:
        movement.collect_steps(db, user, 4000, now=just_before_midnight)

    # 2 minutos depois, já virou o dia — os 4.000 passos não desaparecem
    # nem se duplicam, e ficam disponíveis como ciclo pendente.
    just_after_midnight = yesterday_start + timedelta(hours=24, minutes=2)
    with SessionLocal() as db:
        profile = db.get(models.Profile, user.replace("-", ""))
        pending = movement.get_pending_report_cycle(db, profile, now=just_after_midnight)
        assert pending is not None
        assert pending.steps_collected == 4000

        current = movement.get_current_cycle(db, profile, now=just_after_midnight)
        assert current.id != pending.id
        assert current.steps_collected == 0
