"""
V2 item 8 — Notificações (NOTIFICATIONS.md). Backend é a única
autoridade sobre quando/se notificar. push.send_push_notification é
substituído por um fake nestes testes (monkeypatch) — sem credencial
Firebase configurada em teste, a função real sempre retornaria False, o
que impediria testar a lógica de decisão (quem notificar, com que
texto, sem repetir) independente da integração externa de verdade.
"""

import sqlite3
import uuid
from datetime import datetime, timedelta
from app.timeutil import utcnow

from sqlalchemy import select

from app import config, models, notifications
from app.db import SessionLocal

from .conftest import auth_header


def _fake_sender(sent_log):
    def _send(db, profile, title, body, data=None):
        sent_log.append({"push_token": profile.push_token, "title": title, "body": body})
        return True

    return _send


def _register_token(client, headers, token="fake-token"):
    resp = client.post("/notifications/register-token", json={"push_token": token}, headers=headers)
    assert resp.status_code == 200


def _set_weekly_xp_total(user_id: str, xp_total: int) -> None:
    """
    Achado B1 da auditoria de segurança pré-lançamento mundial
    (17/09/2026): `client` é fixture de sessão (banco SQLite
    compartilhado por TODA a suíte, não só este arquivo) —
    _check_social_overtakes soma Attempt.xp_awarded dos últimos 7 dias
    de TODO mundo, então o valor real e pequeno (~10-20 XP) de um único
    "numeros" respondido aqui podia colidir com o de usuários criados
    por outros testes, fazendo o "quem ultrapassou" apontar pra uma
    pessoa errada dependendo da ordem de execução da suíte (flake
    confirmado determinístico, não randômico). Empurra o XP real já
    creditado pra uma faixa artificialmente alta e exclusiva desta
    tentativa — mesmo princípio já usado em test_ranking_scale.py — sem
    inventar uma tentativa nova, só reatribuindo o xp_awarded que a
    resposta real já gravou.
    """
    with SessionLocal() as db:
        attempts = db.execute(select(models.Attempt).where(models.Attempt.user_id == user_id)).scalars().all()
        assert attempts, "esperava pelo menos uma tentativa já respondida pra este usuário"
        attempts[0].xp_awarded = xp_total
        for extra in attempts[1:]:
            extra.xp_awarded = 0
        db.commit()


def _set_last_seen(user_id: str, when: datetime) -> None:
    db_path = config.DATABASE_URL.removeprefix("sqlite:///")
    con = sqlite3.connect(db_path)
    cur = con.cursor()
    cur.execute("update profiles set last_seen_at=? where user_id=?", (when.isoformat(), user_id.replace("-", "")))
    con.commit()
    con.close()


def test_register_token_and_preferences_round_trip(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    default_prefs = client.get("/notifications/preferences", headers=headers).json()
    assert default_prefs == {"reengagement_enabled": True, "social_enabled": True}

    _register_token(client, headers, "abc123")

    updated = client.put(
        "/notifications/preferences",
        json={"reengagement_enabled": False, "social_enabled": True},
        headers=headers,
    ).json()
    assert updated == {"reengagement_enabled": False, "social_enabled": True}

    refetched = client.get("/notifications/preferences", headers=headers).json()
    assert refetched == {"reengagement_enabled": False, "social_enabled": True}


def test_progress_call_updates_last_seen(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)
    client.get("/progress", headers=headers)

    with SessionLocal() as db:
        from app import models

        profile = db.get(models.Profile, user.replace("-", ""))
        assert profile.last_seen_at is not None
        assert (utcnow() - profile.last_seen_at) < timedelta(minutes=1)


def test_reengagement_fires_once_per_window_24h_then_48h(client, monkeypatch):
    sent_log = []
    monkeypatch.setattr("app.push.send_push_notification", _fake_sender(sent_log))

    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)
    _register_token(client, headers)

    now = utcnow()
    _set_last_seen(user, now - timedelta(hours=25))

    with SessionLocal() as db:
        result = notifications.run_notification_checks(db, now=now)
    assert result["reengagement_sent"] == 1
    assert len(sent_log) == 1
    assert sent_log[0]["body"] == "Bora pensar um pouco hoje?"

    # Roda de novo com o MESMO estado de inatividade (ainda ~25h) — não
    # deve notificar de novo (NOTIFICATIONS.md §2: no máximo uma por janela).
    with SessionLocal() as db:
        result = notifications.run_notification_checks(db, now=now)
    assert result["reengagement_sent"] == 0
    assert len(sent_log) == 1

    # Passa para a janela de 48h — dispara a segunda mensagem, mais calorosa.
    _set_last_seen(user, now - timedelta(hours=49))
    with SessionLocal() as db:
        result = notifications.run_notification_checks(db, now=now)
    assert result["reengagement_sent"] == 1
    assert len(sent_log) == 2
    assert "Nível" in sent_log[1]["body"]
    assert sent_log[1]["title"] == "Sentimos sua falta!"


def test_reengagement_respects_disabled_preference(client, monkeypatch):
    sent_log = []
    monkeypatch.setattr("app.push.send_push_notification", _fake_sender(sent_log))

    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)
    _register_token(client, headers)
    client.put("/notifications/preferences", json={"reengagement_enabled": False, "social_enabled": True}, headers=headers)

    now = utcnow()
    _set_last_seen(user, now - timedelta(hours=30))

    with SessionLocal() as db:
        result = notifications.run_notification_checks(db, now=now)
    assert result["reengagement_sent"] == 0
    assert sent_log == []


def test_social_overtake_fires_with_nickname_for_adult(client, monkeypatch):
    from app.seed import CHALLENGES

    sent_log = []
    monkeypatch.setattr("app.push.send_push_notification", _fake_sender(sent_log))

    loser = str(uuid.uuid4())
    winner = str(uuid.uuid4())
    loser_headers = auth_header(loser)
    winner_headers = auth_header(winner)
    client.post("/age-gate", json={"age_confirmed": True}, headers=loser_headers)
    client.post("/age-gate", json={"age_confirmed": True}, headers=winner_headers)
    _register_token(client, loser_headers, "loser-token")
    _register_token(client, winner_headers, "winner-token")
    # ADENDO_NOTIFICACAO_RANKING_NOME_REAL.md (12/09/2026): achado real
    # em produção — esta notificação usava o apelido gerado
    # ("Jogador-XXXXX") em vez do nome real de quem ultrapassou.
    client.put("/profile", json={"real_name": "Fulano Vencedor"}, headers=winner_headers)

    def _answer(headers):
        ch = client.get("/challenges/next", params={"territory_id": "numeros"}, headers=headers).json()
        correct = next(c["correct_answer"] for c in CHALLENGES if c["prompt"] == ch["prompt"] and sorted(c["options"]) == sorted(ch["options"]))
        client.post(
            f"/challenges/{ch['challenge_id']}/answer",
            json={"attempt_id": ch["attempt_id"], "submitted_answer": correct},
            headers=headers,
        )

    # Loser joga uma vez (fica na frente por enquanto) — XP real
    # empurrado pra uma faixa alta e exclusiva desta tentativa (ver
    # _set_weekly_xp_total), pra nenhum usuário de outro teste do banco
    # compartilhado cair entre loser e winner por acaso.
    _answer(loser_headers)
    _set_weekly_xp_total(loser, 50_000_000)

    now = utcnow()
    with SessionLocal() as db:
        notifications.run_notification_checks(db, now=now)
    assert sent_log == []  # primeira checagem só grava a posição, nunca notifica

    # Winner joga mais até ultrapassar loser no ranking semanal — XP
    # real também empurrado pra cima da faixa do loser, mesma exclusividade.
    for _ in range(2):
        _answer(winner_headers)
    _set_weekly_xp_total(winner, 60_000_000)

    with SessionLocal() as db:
        result = notifications.run_notification_checks(db, now=now)

    assert result["social_sent"] >= 1
    loser_events = [e for e in sent_log if e["push_token"] == "loser-token"]
    assert len(loser_events) == 1
    assert "passou você no ranking" in loser_events[0]["body"]
    assert "Fulano Vencedor" in loser_events[0]["body"]
    assert "Jogador-" not in loser_events[0]["body"]


# test_social_overtake_is_anonymized_for_child_safe_mode removido
# (MENTAL-DIR-001, 24/08/2026): MENTAL passa a ser exclusivo pra
# maiores de 18 anos — não existe mais variante anonimizada de
# notificação, testada aqui. Ver test_social_overtake_fires_with_
# nickname_for_adult acima, que cobre o único comportamento restante.
