"""
REGRA_OFICIAL_GAMIFICACAO_MENTAL.md — Fase 3 (20/09/2026): teto diário de
XP de resposta, boost de +20% e reparo de streak. Como na Fase 2, o que
mais importa são os casos anti-abuso (não passar do teto, não gastar
duas vezes, não reparar fora da janela).
"""

import uuid
from datetime import date, datetime, timedelta

from app import config, economy, mentalcoins, models, timeutil
from app.db import SessionLocal
from app.timeutil import utcnow

from .conftest import auth_header
from .test_celebration_signals import _answer_correctly
from .test_rewards_fase2 import _coins, _new_user


def _give_coins(user: str, amount: int) -> None:
    with SessionLocal() as db:
        mentalcoins.credit(db, user, amount, "teste")


def _set_streak(user: str, current: int, last_played: date, **extra) -> None:
    with SessionLocal() as db:
        streak = db.get(models.Streak, user) or models.Streak(user_id=user)
        streak.current_streak = current
        streak.last_played_date = last_played
        streak.week_anchor = last_played - timedelta(days=last_played.weekday())
        streak.freeze_available = extra.get("freeze_available", False)
        streak.freeze_used_this_week = extra.get("freeze_used_this_week", True)
        db.add(streak)
        db.commit()


# ------------------------------------------------------------- teto diário
def test_teto_paga_so_o_que_falta_e_depois_zera_mas_territorio_segue(client):
    user, _ = _new_user(client)
    today = utcnow().date()
    with SessionLocal() as db:
        first = economy.apply_answer_xp(db, user, 10, today)
        db.commit()
    assert (first.profile_xp, first.territory_xp, first.cap_reached) == (10, 10, False)
    with SessionLocal() as db:
        db.add(models.DailyAnswerXp(user_id=user, xp_date=date(2000, 1, 1), xp_earned=1))  # outro dia não conta
        row = db.get(models.DailyAnswerXp, (user, today))
        row.xp_earned = config.DAILY_ANSWER_XP_CAP - 4
        db.commit()
    with SessionLocal() as db:
        edge = economy.apply_answer_xp(db, user, 10, today)  # faltam 4
        db.commit()
    assert (edge.profile_xp, edge.territory_xp, edge.cap_reached) == (4, 10, True)
    with SessionLocal() as db:
        after = economy.apply_answer_xp(db, user, 10, today)
        db.commit()
    assert (after.profile_xp, after.territory_xp, after.cap_reached) == (0, 10, True)


def test_teto_no_endpoint_zera_xp_de_perfil_e_mantem_progresso_do_territorio(client, monkeypatch):
    user, headers = _new_user(client)
    base = client.get("/progress", headers=headers).json()["xp_total"]
    monkeypatch.setattr(config, "DAILY_ANSWER_XP_CAP", 0)
    result = _answer_correctly(client, headers, "numeros")
    assert result["is_correct"] is True
    assert result["xp_awarded"] == 0
    assert result["xp_cap_reached"] is True
    assert client.get("/progress", headers=headers).json()["xp_total"] == base
    assert result["territory_progress"]["xp_in_territory"] > 0  # progresso segue contando
    assert result["streak_just_extended"] is True  # streak/estatística também


def test_status_mostra_xp_do_dia_e_teto(client):
    user, headers = _new_user(client)
    _answer_correctly(client, headers, "numeros")
    status = client.get("/economy/status", headers=headers).json()
    assert status["daily_xp_cap"] == config.DAILY_ANSWER_XP_CAP
    assert 0 < status["daily_xp_earned"] <= config.DAILY_ANSWER_XP_CAP
    assert status["boost_active"] is False and status["repair"] is None


# ------------------------------------------------------------- boost
def test_boost_custa_80_ativa_24h_e_nao_empilha(client):
    user, headers = _new_user(client)
    _give_coins(user, config.XP_BOOST_COST * 2)
    resp = client.post("/economy/xp-boost", headers=headers)
    assert resp.status_code == 200
    assert resp.json()["balance"] == config.XP_BOOST_COST
    assert _coins(user) == config.XP_BOOST_COST
    # 2ª compra com boost ativo: bloqueada e NÃO gasta moeda.
    again = client.post("/economy/xp-boost", headers=headers)
    assert again.status_code == 422
    assert again.json()["error"]["code"] == "BOOST_ALREADY_ACTIVE"
    assert _coins(user) == config.XP_BOOST_COST
    status = client.get("/economy/status", headers=headers).json()
    assert status["boost_active"] is True


def test_boost_sem_saldo_nao_ativa(client):
    user, headers = _new_user(client)
    _give_coins(user, config.XP_BOOST_COST - 1)
    resp = client.post("/economy/xp-boost", headers=headers)
    assert resp.status_code == 422
    assert resp.json()["error"]["code"] == "INSUFFICIENT_BALANCE"
    with SessionLocal() as db:
        assert db.get(models.XpBoost, user) is None
    assert _coins(user) == config.XP_BOOST_COST - 1


def test_boost_aumenta_20_por_cento_arredondando_pra_cima_e_expira(client):
    user, _ = _new_user(client)
    today = utcnow().date()
    with SessionLocal() as db:
        db.add(models.XpBoost(user_id=user, expires_at=utcnow() + timedelta(hours=1)))
        db.commit()
    with SessionLocal() as db:
        out = economy.apply_answer_xp(db, user, 7, today)  # 7*1.2=8.4 -> 9
        db.commit()
    assert (out.profile_xp, out.boost_applied) == (9, True)
    with SessionLocal() as db:
        boost = db.get(models.XpBoost, user)
        boost.expires_at = utcnow() - timedelta(minutes=1)
        db.commit()
    with SessionLocal() as db:
        out = economy.apply_answer_xp(db, user, 7, today)
        db.commit()
    assert (out.profile_xp, out.boost_applied) == (7, False)


def test_teto_vale_sobre_o_valor_com_boost(client):
    user, _ = _new_user(client)
    today = utcnow().date()
    with SessionLocal() as db:
        db.add(models.XpBoost(user_id=user, expires_at=utcnow() + timedelta(hours=1)))
        db.add(models.DailyAnswerXp(user_id=user, xp_date=today, xp_earned=config.DAILY_ANSWER_XP_CAP - 3))
        db.commit()
    with SessionLocal() as db:
        out = economy.apply_answer_xp(db, user, 10, today)  # boost 12, faltam 3
        db.commit()
    assert (out.profile_xp, out.territory_xp, out.cap_reached) == (3, 12, True)


# ------------------------------------------------------------- reparo de streak
def test_reparo_antes_de_jogar_paga_50_e_a_proxima_jogada_estende(client):
    user, headers = _new_user(client)
    _give_coins(user, 60)
    today = utcnow().date()
    _set_streak(user, 8, today - timedelta(days=3))  # quebrou: 2 dias sem jogar
    status = client.get("/economy/status", headers=headers).json()
    assert status["repair"]["streak_to_restore"] == 8 and status["repair"]["cost"] == config.STREAK_REPAIR_COST
    resp = client.post("/economy/streak-repair", headers=headers)
    assert resp.status_code == 200
    assert resp.json()["balance"] == 10
    result = _answer_correctly(client, headers, "numeros")
    assert result["streak"]["current_streak"] == 9
    # não repara duas vezes
    assert client.post("/economy/streak-repair", headers=headers).json()["error"]["code"] == "NOTHING_TO_REPAIR"
    assert _coins(user) == 10


def test_reparo_depois_de_recomecar_soma_a_sequencia_perdida(client):
    user, headers = _new_user(client)
    _give_coins(user, 50)
    today = utcnow().date()
    _set_streak(user, 8, today - timedelta(days=3))
    result = _answer_correctly(client, headers, "numeros")  # gap 3 sem folga: quebra e recomeça em 1
    assert result["streak"]["current_streak"] == 1
    offer = client.get("/economy/status", headers=headers).json()["repair"]
    assert offer["streak_to_restore"] == 8
    resp = client.post("/economy/streak-repair", headers=headers)
    assert resp.status_code == 200
    with SessionLocal() as db:
        streak = db.get(models.Streak, user)
        assert streak.current_streak == 9
        assert streak.lost_streak is None
    assert _coins(user) == 0


def test_reparo_fora_da_janela_ou_sem_saldo_ou_sem_sequencia_nao_funciona(client):
    user, headers = _new_user(client)
    today = utcnow().date()
    _give_coins(user, 500)
    _set_streak(user, 8, today - timedelta(days=4))  # janela acabou (até last+3)
    assert client.get("/economy/status", headers=headers).json()["repair"] is None
    assert client.post("/economy/streak-repair", headers=headers).status_code == 422

    _set_streak(user, 1, today - timedelta(days=3))  # sequência de 1 dia não vale reparo
    assert client.get("/economy/status", headers=headers).json()["repair"] is None

    _set_streak(user, 8, today - timedelta(days=3))
    with SessionLocal() as db:
        balance = db.get(models.MentalCoinsBalance, user)
        balance.balance = config.STREAK_REPAIR_COST - 1
        db.commit()
    resp = client.post("/economy/streak-repair", headers=headers)
    assert resp.status_code == 422
    assert resp.json()["error"]["code"] == "INSUFFICIENT_BALANCE"
    with SessionLocal() as db:
        assert db.get(models.Streak, user).last_played_date == today - timedelta(days=3)  # nada mudou


def test_folga_semanal_gratis_cobre_um_dia_perdido_sem_oferecer_reparo(client):
    user, headers = _new_user(client)
    today = utcnow().date()
    _set_streak(user, 8, today - timedelta(days=2), freeze_available=True, freeze_used_this_week=False)
    # Semana da folga precisa ser a atual pra ela valer
    with SessionLocal() as db:
        streak = db.get(models.Streak, user)
        streak.week_anchor = today - timedelta(days=today.weekday())
        db.commit()
    assert client.get("/economy/status", headers=headers).json()["repair"] is None


def test_reparo_depois_de_recomecar_paga_o_marco_que_a_sequencia_restaurada_alcanca(client):
    # Achado M2 da revisão de segurança: 29 dias + reparo = 30, e o marco
    # de 30 dias (+75 moedas) precisa ser pago — igual ao reparo antes de jogar.
    user, headers = _new_user(client)
    _give_coins(user, config.STREAK_REPAIR_COST)
    today = utcnow().date()
    _set_streak(user, 29, today - timedelta(days=3))
    _answer_correctly(client, headers, "numeros")  # quebra e recomeça em 1
    resp = client.post("/economy/streak-repair", headers=headers)
    assert resp.status_code == 200 and resp.json()["applied_immediately"] is True
    assert resp.json()["current_streak"] == 30
    assert _coins(user) == config.STREAK_MILESTONE_REWARDS[30][1]  # gastou 50, recebeu 75 (saldo era 50)


def test_reparo_antes_de_jogar_avisa_que_o_efeito_vem_na_proxima_jogada(client):
    user, headers = _new_user(client)
    _give_coins(user, config.STREAK_REPAIR_COST)
    _set_streak(user, 8, utcnow().date() - timedelta(days=3))
    resp = client.post("/economy/streak-repair", headers=headers).json()
    assert resp["applied_immediately"] is False


def test_dia_do_teto_e_o_dia_de_brasilia(client, monkeypatch):
    # 01:00 UTC de 21/09 ainda é 22:00 de 20/09 em Brasília: o teto NÃO zera às 21h.
    monkeypatch.setattr(timeutil, "utcnow", lambda: datetime(2026, 9, 21, 1, 0))
    assert timeutil.brasilia_today() == date(2026, 9, 20)
    monkeypatch.setattr(timeutil, "utcnow", lambda: datetime(2026, 9, 21, 3, 0))
    assert timeutil.brasilia_today() == date(2026, 9, 21)  # meia-noite em Brasília


def test_resposta_grava_o_contador_no_dia_de_brasilia(client):
    user, headers = _new_user(client)
    _answer_correctly(client, headers, "numeros")
    with SessionLocal() as db:
        row = db.get(models.DailyAnswerXp, (user, timeutil.brasilia_today()))
        assert row is not None and row.xp_earned > 0
