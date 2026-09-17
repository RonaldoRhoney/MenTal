"""
CENTRAL_DE_NOTIFICACOES_HOME_V1.md — histórico persistente dentro do
app, complementar ao push. services.create_notification unifica as
origens já existentes (Batalha, Torcida, Movimento, Amizade) numa única
tabela (mental.notifications); estes testes cobrem a criação em cada
origem, a listagem/contagem via HTTP, e o estado de leitura.
"""

import uuid

from sqlalchemy import select

from app import models
from app.db import SessionLocal

from .conftest import auth_header
from .test_battles import _make_friends


def test_battle_challenge_creates_a_central_entry_for_the_opponent(client):
    user_a, user_b = str(uuid.uuid4()), str(uuid.uuid4())
    headers_a, headers_b = _make_friends(client, user_a, user_b)
    # _make_friends já gera uma notificação "friend_accepted" pra
    # user_b — limpa antes pra isolar só o que a batalha gera.
    client.post("/notifications/mark-all-read", headers=headers_b)

    client.post(
        "/battles",
        json={"opponent_user_id": user_b, "territory_id": "palavras", "difficulty_level": 1},
        headers=headers_a,
    )

    body = client.get("/notifications", headers=headers_b).json()
    assert body["unread_count"] == 1
    battle_notifications = [n for n in body["notifications"] if n["type"] == "battle_challenge"]
    assert len(battle_notifications) == 1
    assert battle_notifications[0]["read"] is False
    assert battle_notifications[0]["data"] == {"navigate": "battles"}


def test_central_entry_is_created_even_without_push_token_or_preference(client):
    """
    Achado central do documento (§1): a Central NUNCA deve depender do
    FCM — precisa continuar útil pra quem desativou push ou não tem
    token no momento do evento. Torcida é o cenário mais simples pra
    provar isso (send_torcida não exige amizade prévia).
    """
    from_user, to_user = str(uuid.uuid4()), str(uuid.uuid4())
    headers_from = auth_header(from_user)
    headers_to = auth_header(to_user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers_from)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers_to)

    # Sem push_token nenhum registrado pro destinatário — send_push
    # calculado pelo chamador dá False, mas a linha da Central precisa
    # existir de qualquer forma.
    resp = client.post(f"/profile/{to_user}/torcida", json={"reaction_type": "joinha"}, headers=headers_from)
    assert resp.status_code == 200

    body = client.get("/notifications", headers=headers_to).json()
    assert body["unread_count"] == 1
    assert body["notifications"][0]["type"] == "torcida"


def test_friend_request_and_accept_both_create_central_entries(client):
    """
    Achado ao mapear as origens (14/09/2026): pedido/aceite de amizade
    nunca tinham NENHUM registro antes desta leva — nem push, nem
    Central. Este teste cobre os dois lados do fluxo.
    """
    requester, target = str(uuid.uuid4()), str(uuid.uuid4())
    headers_requester = auth_header(requester)
    headers_target = auth_header(target)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers_requester)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers_target)

    client.post("/social/friend-requests", json={"to_user_id": target}, headers=headers_requester)
    target_notifications = client.get("/notifications", headers=headers_target).json()
    assert any(n["type"] == "friend_request" for n in target_notifications["notifications"])

    friendship_id = client.get("/social/friend-requests", headers=headers_target).json()["requests"][0]["friendship_id"]
    client.post(f"/social/friend-requests/{friendship_id}/accept", headers=headers_target)

    requester_notifications = client.get("/notifications", headers=headers_requester).json()
    assert any(n["type"] == "friend_accepted" for n in requester_notifications["notifications"])


def test_mark_one_read_and_mark_all_read(client):
    from_user, to_user = str(uuid.uuid4()), str(uuid.uuid4())
    headers_from = auth_header(from_user)
    headers_to = auth_header(to_user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers_from)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers_to)

    client.post(f"/profile/{to_user}/torcida", json={"reaction_type": "joinha"}, headers=headers_from)
    client.post(f"/profile/{to_user}/torcida", json={"reaction_type": "coracao"}, headers=headers_from)

    body = client.get("/notifications", headers=headers_to).json()
    assert body["unread_count"] == 2
    first_id = body["notifications"][0]["id"]

    read_resp = client.post(f"/notifications/{first_id}/read", headers=headers_to)
    assert read_resp.status_code == 200
    assert client.get("/notifications/unread-count", headers=headers_to).json()["unread_count"] == 1

    # Idempotente: marcar de novo a mesma não quebra nem muda a contagem.
    client.post(f"/notifications/{first_id}/read", headers=headers_to)
    assert client.get("/notifications/unread-count", headers=headers_to).json()["unread_count"] == 1

    mark_all = client.post("/notifications/mark-all-read", headers=headers_to)
    assert mark_all.json()["marked_read"] == 1
    assert client.get("/notifications/unread-count", headers=headers_to).json()["unread_count"] == 0


def test_cannot_mark_another_users_notification_as_read(client):
    from_user, to_user, stranger = str(uuid.uuid4()), str(uuid.uuid4()), str(uuid.uuid4())
    headers_from = auth_header(from_user)
    headers_to = auth_header(to_user)
    headers_stranger = auth_header(stranger)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers_from)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers_to)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers_stranger)

    client.post(f"/profile/{to_user}/torcida", json={"reaction_type": "joinha"}, headers=headers_from)
    notification_id = client.get("/notifications", headers=headers_to).json()["notifications"][0]["id"]

    resp = client.post(f"/notifications/{notification_id}/read", headers=headers_stranger)
    assert resp.status_code == 404
    assert client.get("/notifications/unread-count", headers=headers_to).json()["unread_count"] == 1


def test_reengagement_check_creates_central_entry_and_respects_push_success_for_retry_gating(client, monkeypatch):
    from app import notifications as notifications_module
    from app import push
    from app.timeutil import utcnow
    from datetime import timedelta

    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    with SessionLocal() as db:
        profile = db.get(models.Profile, user)
        profile.push_token = "some-token"
        profile.last_seen_at = utcnow() - timedelta(hours=30)
        db.commit()

    monkeypatch.setattr(push, "send_push_notification", lambda *a, **kw: True)
    with SessionLocal() as db:
        result = notifications_module.run_notification_checks(db, now=utcnow())
    assert result["reengagement_sent"] == 1

    body = client.get("/notifications", headers=headers).json()
    assert any(n["type"] == "system" for n in body["notifications"])


def test_purge_old_notifications_deletes_only_past_retention_window(client):
    """Achado A2 da auditoria de segurança pré-lançamento mundial
    (17/09/2026): a retenção de 30 dias (config.NOTIFICATION_RETENTION_
    DAYS) era só um filtro de leitura — nada apagava de fato. Este
    teste cobre services.purge_old_notifications, chamado pelo cron
    diário em app/scheduler.py."""
    from datetime import timedelta

    from app import config, services
    from app.timeutil import utcnow

    from_user, to_user = str(uuid.uuid4()), str(uuid.uuid4())
    headers_from = auth_header(from_user)
    headers_to = auth_header(to_user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers_from)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers_to)

    client.post(f"/profile/{to_user}/torcida", json={"reaction_type": "joinha"}, headers=headers_from)

    with SessionLocal() as db:
        notification = db.execute(select(models.Notification).where(models.Notification.user_id == to_user)).scalars().one()
        notification_id = notification.id
        notification.created_at = utcnow() - timedelta(days=config.NOTIFICATION_RETENTION_DAYS + 1)
        db.commit()

    with SessionLocal() as db:
        deleted = services.purge_old_notifications(db)
    assert deleted == 1

    with SessionLocal() as db:
        assert db.get(models.Notification, notification_id) is None


def test_purge_old_notifications_keeps_recent_ones(client):
    from app import services

    from_user, to_user = str(uuid.uuid4()), str(uuid.uuid4())
    headers_from = auth_header(from_user)
    headers_to = auth_header(to_user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers_from)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers_to)

    client.post(f"/profile/{to_user}/torcida", json={"reaction_type": "joinha"}, headers=headers_from)

    with SessionLocal() as db:
        deleted = services.purge_old_notifications(db)
    assert deleted == 0

    body = client.get("/notifications", headers=headers_to).json()
    assert len(body["notifications"]) == 1
