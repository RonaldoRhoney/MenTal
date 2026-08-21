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

from app import config, notifications
from app.db import SessionLocal

from .conftest import auth_header


def _fake_sender(sent_log):
    def _send(push_token, title, body):
        sent_log.append({"push_token": push_token, "title": title, "body": body})
        return True

    return _send


def _register_token(client, headers, token="fake-token"):
    resp = client.post("/notifications/register-token", json={"push_token": token}, headers=headers)
    assert resp.status_code == 200


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
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers)

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
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers)
    client.get("/progress", headers=headers)

    with SessionLocal() as db:
        from app import models

        profile = db.get(models.Profile, user.replace("-", ""))
        assert profile.last_seen_at is not None
        assert (datetime.utcnow() - profile.last_seen_at) < timedelta(minutes=1)


def test_reengagement_fires_once_per_window_24h_then_48h(client, monkeypatch):
    sent_log = []
    monkeypatch.setattr("app.notifications.push.send_push_notification", _fake_sender(sent_log))

    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers)
    _register_token(client, headers)

    now = datetime.utcnow()
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
    monkeypatch.setattr("app.notifications.push.send_push_notification", _fake_sender(sent_log))

    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers)
    _register_token(client, headers)
    client.put("/notifications/preferences", json={"reengagement_enabled": False, "social_enabled": True}, headers=headers)

    now = datetime.utcnow()
    _set_last_seen(user, now - timedelta(hours=30))

    with SessionLocal() as db:
        result = notifications.run_notification_checks(db, now=now)
    assert result["reengagement_sent"] == 0
    assert sent_log == []


def test_social_overtake_fires_with_nickname_for_adult(client, monkeypatch):
    from app.seed import CHALLENGES

    sent_log = []
    monkeypatch.setattr("app.notifications.push.send_push_notification", _fake_sender(sent_log))

    loser = str(uuid.uuid4())
    winner = str(uuid.uuid4())
    loser_headers = auth_header(loser)
    winner_headers = auth_header(winner)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=loser_headers)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=winner_headers)
    _register_token(client, loser_headers, "loser-token")
    _register_token(client, winner_headers, "winner-token")

    def _answer(headers):
        ch = client.get("/challenges/next", params={"territory_id": "numeros"}, headers=headers).json()
        correct = next(c["correct_answer"] for c in CHALLENGES if c["prompt"] == ch["prompt"] and c["options"] == ch["options"])
        client.post(
            f"/challenges/{ch['challenge_id']}/answer",
            json={"attempt_id": str(uuid.uuid4()), "submitted_answer": correct},
            headers=headers,
        )

    # Loser joga uma vez (fica na frente por enquanto).
    _answer(loser_headers)

    now = datetime.utcnow()
    with SessionLocal() as db:
        notifications.run_notification_checks(db, now=now)
    assert sent_log == []  # primeira checagem só grava a posição, nunca notifica

    # Winner joga mais (mesma dificuldade, mesmo XP por resposta) até
    # ultrapassar loser no ranking semanal.
    for _ in range(2):
        _answer(winner_headers)

    with SessionLocal() as db:
        result = notifications.run_notification_checks(db, now=now)

    # `client` é uma fixture de sessão (todos os testes deste arquivo
    # compartilham o mesmo banco) — o ranking semanal inclui usuários de
    # outros testes que também responderam em "numeros" na última semana,
    # então não dá pra travar o total exato de notificações, só que ESTE
    # usuário específico recebeu a dele.
    assert result["social_sent"] >= 1
    loser_events = [e for e in sent_log if e["push_token"] == "loser-token"]
    assert len(loser_events) == 1
    assert "passou você no ranking" in loser_events[0]["body"]


def test_social_overtake_is_anonymized_for_child_safe_mode(client, monkeypatch):
    from app.seed import CHALLENGES

    sent_log = []
    monkeypatch.setattr("app.notifications.push.send_push_notification", _fake_sender(sent_log))

    loser = str(uuid.uuid4())
    winner = str(uuid.uuid4())
    loser_headers = auth_header(loser)
    winner_headers = auth_header(winner)
    # child_safe_mode=True é o default de perfil recém-criado (models.Profile).
    client.post("/age-gate", json={"age_mode": "child"}, headers=loser_headers)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=winner_headers)
    _register_token(client, loser_headers, "child-token")
    _register_token(client, winner_headers, "winner-token")

    def _answer(headers):
        ch = client.get("/challenges/next", params={"territory_id": "numeros"}, headers=headers).json()
        correct = next(c["correct_answer"] for c in CHALLENGES if c["prompt"] == ch["prompt"] and c["options"] == ch["options"])
        client.post(
            f"/challenges/{ch['challenge_id']}/answer",
            json={"attempt_id": str(uuid.uuid4()), "submitted_answer": correct},
            headers=headers,
        )

    _answer(loser_headers)
    now = datetime.utcnow()
    with SessionLocal() as db:
        notifications.run_notification_checks(db, now=now)

    for _ in range(2):
        _answer(winner_headers)
    with SessionLocal() as db:
        result = notifications.run_notification_checks(db, now=now)

    # Mesma ressalva de isolamento de teste do cenário adulto acima: só
    # confere o evento deste usuário específico, não o total global.
    assert result["social_sent"] >= 1
    child_events = [e for e in sent_log if e["push_token"] == "child-token"]
    assert len(child_events) == 1
    # Nunca cita nome de outro jogador para perfil child_safe_mode.
    assert "passou você" not in child_events[0]["body"]
    assert child_events[0]["title"] == "A disputa está acirrada"
