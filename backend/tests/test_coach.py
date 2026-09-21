"""
My_Mental_AI (agente do usuário, 21/09/2026): recomendações por REGRAS sobre o desempenho do
próprio usuário. Cada regra tem o caso que dispara e o caso que NÃO dispara.
"""

import uuid
from datetime import date, datetime, timedelta

from app import config, models
from app.db import SessionLocal
from app.timeutil import utcnow

from .conftest import auth_header
from .test_rewards_fase2 import _new_user


def _attempts(user: str, territory: str, correct: int, wrong: int, hints: int = 0) -> None:
    with SessionLocal() as db:
        challenge = db.query(models.Challenge).filter(models.Challenge.territory_id == territory).first()
        for i in range(correct + wrong):
            db.add(
                models.Attempt(
                    attempt_id=str(uuid.uuid4()), user_id=user, challenge_id=challenge.id,
                    is_correct=i < correct, hints_used=hints, xp_awarded=3 if i < correct else 0, created_at=utcnow(),
                )
            )
        db.commit()


def _coach(client, headers) -> dict:
    resp = client.get("/coach", headers=headers)
    assert resp.status_code == 200
    return resp.json()


def _ids(body: dict) -> set[str]:
    return {c["id"] for c in body["cards"]}


def test_usuario_novo_recebe_boas_vindas_e_como_usar(client):
    _, headers = _new_user(client)
    body = _coach(client, headers)
    assert body["name"] == "My_Mental_AI"
    assert {"newcomer", "how_to"} <= _ids(body)
    assert body["daily_tip"]["id"] == body["cards"][0]["id"]
    assert body["summary"]["total_answers"] == 0


def test_aponta_onde_reforcar_e_onde_vai_melhor(client):
    user, headers = _new_user(client)
    _attempts(user, "numeros", correct=4, wrong=8)  # 33% com 12 respostas
    _attempts(user, "logica", correct=10, wrong=2)  # 83%
    body = _coach(client, headers)
    weakest = next(c for c in body["cards"] if c["id"] == "weakest")
    strongest = next(c for c in body["cards"] if c["id"] == "strongest")
    assert weakest["territory_id"] == "numeros" and weakest["action"]["territory_id"] == "numeros"
    assert strongest["territory_id"] == "logica" and strongest["action"].get("relampago") is True
    assert "newcomer" not in _ids(body)  # já tem mais de 10 respostas


def test_sem_amostra_minima_nao_afirma_nada_sobre_taxa_de_acerto(client):
    user, headers = _new_user(client)
    _attempts(user, "numeros", correct=1, wrong=5)  # só 6 respostas
    ids = _ids(_coach(client, headers))
    assert "weakest" not in ids and "strongest" not in ids


def test_territorio_perto_de_conquista(client):
    user, headers = _new_user(client)
    with SessionLocal() as db:
        db.add(models.UserTerritoryProgress(user_id=user, territory_id="numeros", xp_in_territory=int(config.CONQUEST_XP_THRESHOLD * 0.8)))
        db.commit()
    card = next(c for c in _coach(client, headers)["cards"] if c["id"] == "close_to_conquest")
    assert card["territory_id"] == "numeros" and "Faltam" in card["body"]


def test_teto_diario_aparece_perto_e_ao_bater(client):
    user, headers = _new_user(client)
    from app.timeutil import brasilia_today

    with SessionLocal() as db:
        db.add(models.DailyAnswerXp(user_id=user, xp_date=brasilia_today(), xp_earned=int(config.DAILY_ANSWER_XP_CAP * 0.85)))
        db.commit()
    assert next(c for c in _coach(client, headers)["cards"] if c["id"] == "daily_cap")["priority"] == 88
    with SessionLocal() as db:
        row = db.get(models.DailyAnswerXp, (user, brasilia_today()))
        row.xp_earned = config.DAILY_ANSWER_XP_CAP
        db.commit()
    assert next(c for c in _coach(client, headers)["cards"] if c["id"] == "daily_cap")["priority"] == 92


def test_reparo_de_sequencia_e_a_dica_mais_prioritaria(client):
    user, headers = _new_user(client)
    with SessionLocal() as db:
        streak = db.get(models.Streak, user) or models.Streak(user_id=user)
        streak.current_streak = 8
        streak.last_played_date = utcnow().date() - timedelta(days=3)
        streak.week_anchor = utcnow().date() - timedelta(days=utcnow().date().weekday())
        streak.freeze_available = False
        streak.freeze_used_this_week = True
        db.add(streak)
        db.commit()
    body = _coach(client, headers)
    assert body["daily_tip"]["id"] == "streak_repair"
    assert str(config.STREAK_REPAIR_COST) in body["daily_tip"]["body"]


def test_ranking_da_semana_mostra_so_numeros_nunca_identidade(client):
    user, headers = _new_user(client)
    other, _ = _new_user(client)
    _attempts(user, "numeros", correct=3, wrong=0)   # 9 XP
    _attempts(other, "numeros", correct=5, wrong=0)  # 15 XP
    body = _coach(client, headers)
    card = next(c for c in body["cards"] if c["id"] == "ranking")
    assert "#" in card["body"] and "Faltam" in card["body"]
    assert other not in str(body) and body["summary"]["weekly_rank"] >= 2


def test_muitas_dicas_gera_conselho(client):
    user, headers = _new_user(client)
    _attempts(user, "numeros", correct=12, wrong=0, hints=1)
    assert "hints" in _ids(_coach(client, headers))
    other, other_headers = _new_user(client)
    _attempts(other, "numeros", correct=12, wrong=0, hints=0)
    assert "hints" not in _ids(_coach(client, other_headers))


def test_sem_movimento_sugere_ativar_e_nao_sugere_se_ja_ativo(client):
    user, headers = _new_user(client)
    assert "explore_movement" in _ids(_coach(client, headers))
    with SessionLocal() as db:
        db.get(models.Profile, user).movement_enabled = True
        db.commit()
    ids = _ids(_coach(client, headers))
    assert "explore_movement" not in ids and "explore_friends" in ids


def test_rate_limit_e_exige_maioridade(client, monkeypatch):
    assert client.get("/coach", headers=auth_header(str(uuid.uuid4()))).status_code == 403  # sem age gate
    _, headers = _new_user(client)
    monkeypatch.setattr(config, "RATE_LIMIT_COACH", (2, 60.0))
    codes = [client.get("/coach", headers=headers).status_code for _ in range(4)]
    assert codes[:2] == [200, 200] and 429 in codes[2:]
