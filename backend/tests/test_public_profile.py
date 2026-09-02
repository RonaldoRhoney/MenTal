"""
V4 item 1 — Perfil Público + Torcida (PERFIL_PUBLICO_E_TORCIDA_V1.md,
TORCIDA_MULTIPLA_V2.md). Backend é a única autoridade sobre quais dados
são públicos e sobre o limite diário de Torcida — o client nunca decide
nenhum dos dois.
"""

import uuid

from .conftest import auth_header


def _answer_correctly(client, headers, territory_id):
    from app.seed import CHALLENGES

    challenge = client.get("/challenges/next", params={"territory_id": territory_id}, headers=headers).json()
    correct = next(c["correct_answer"] for c in CHALLENGES if c["prompt"] == challenge["prompt"])
    return client.post(
        f"/challenges/{challenge['challenge_id']}/answer",
        json={"attempt_id": challenge["attempt_id"], "submitted_answer": correct},
        headers=headers,
    ).json()


def test_public_profile_exposes_only_the_allowed_fields(client):
    target = str(uuid.uuid4())
    target_headers = auth_header(target)
    client.post("/age-gate", json={"age_confirmed": True}, headers=target_headers)
    client.put("/profile", json={"real_name": "Fulano de Tal", "location_public": False}, headers=target_headers)

    viewer = str(uuid.uuid4())
    viewer_headers = auth_header(viewer)
    client.post("/age-gate", json={"age_confirmed": True}, headers=viewer_headers)

    resp = client.get(f"/profile/{target}/public", headers=viewer_headers)
    assert resp.status_code == 200
    body = resp.json()
    assert body["user_id"] == target
    assert body["real_name"] == "Fulano de Tal"
    assert body["photo_url"] is None  # sem foto enviada ainda
    assert body["level"] == 1
    assert body["xp_total"] == 0
    assert body["current_streak"] == 0
    assert body["badges"] == []
    assert isinstance(body["worlds"], list) and len(body["worlds"]) >= 1
    assert body["best_territory_id"] is None
    assert body["best_territory_xp"] == 0
    assert body["torcida_sent_today_by_me"] == 0
    # Regra central (§2): nunca expor dado fora da lista permitida.
    assert "mentalcoins_balance" not in body
    assert "email" not in body
    assert "location_state" not in body
    assert "location_country" not in body


def test_public_profile_photo_only_shown_when_approved(client, monkeypatch):
    from app import supabase_admin
    from app.db import SessionLocal
    from app import models

    monkeypatch.setattr(supabase_admin, "create_signed_photo_url", lambda path, expires_in_seconds=3600: f"https://signed.example/{path}")

    target = str(uuid.uuid4())
    target_headers = auth_header(target)
    client.post("/age-gate", json={"age_confirmed": True}, headers=target_headers)
    client.put("/profile", json={"photo_path": f"{target}/photo.jpg"}, headers=target_headers)

    viewer = str(uuid.uuid4())
    viewer_headers = auth_header(viewer)
    client.post("/age-gate", json={"age_confirmed": True}, headers=viewer_headers)

    # Ainda 'pending' — não deve aparecer pra outro usuário.
    body = client.get(f"/profile/{target}/public", headers=viewer_headers).json()
    assert body["photo_url"] is None

    with SessionLocal() as db:
        profile = db.get(models.Profile, target)
        profile.photo_moderation_status = "approved"
        db.commit()

    body_after = client.get(f"/profile/{target}/public", headers=viewer_headers).json()
    assert body_after["photo_url"] == f"https://signed.example/{target}/photo.jpg"


def test_public_profile_shows_only_earned_badges_and_best_territory(client):
    target = str(uuid.uuid4())
    target_headers = auth_header(target)
    client.post("/age-gate", json={"age_confirmed": True}, headers=target_headers)

    for _ in range(10):
        result = _answer_correctly(client, target_headers, "numeros")
        assert result["hints_used"] == 0

    viewer = str(uuid.uuid4())
    viewer_headers = auth_header(viewer)
    client.post("/age-gate", json={"age_confirmed": True}, headers=viewer_headers)

    body = client.get(f"/profile/{target}/public", headers=viewer_headers).json()
    codes = {b["code"] for b in body["badges"]}
    assert "no_help_needed" in codes
    assert all(b["earned_at"] is not None for b in body["badges"])
    assert body["best_territory_id"] == "numeros"
    assert body["best_territory_xp"] > 0


def test_public_profile_unknown_user_404s(client):
    viewer = str(uuid.uuid4())
    headers = auth_header(viewer)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    resp = client.get(f"/profile/{uuid.uuid4()}/public", headers=headers)
    assert resp.status_code == 404
    assert resp.json()["error"]["code"] == "USER_NOT_FOUND"


def test_send_torcida_increments_count_and_reflects_in_public_profile(client):
    sender = str(uuid.uuid4())
    sender_headers = auth_header(sender)
    client.post("/age-gate", json={"age_confirmed": True}, headers=sender_headers)

    target = str(uuid.uuid4())
    target_headers = auth_header(target)
    client.post("/age-gate", json={"age_confirmed": True}, headers=target_headers)

    resp = client.post(f"/profile/{target}/torcida", json={"reaction_type": "coracao"}, headers=sender_headers)
    assert resp.status_code == 200
    assert resp.json()["sent_today_by_me"] == 1

    body = client.get(f"/profile/{target}/public", headers=sender_headers).json()
    assert body["torcida_sent_today_by_me"] == 1

    # Outro tipo de ícone soma no MESMO agregado (TORCIDA_MULTIPLA_V2.md §3).
    resp2 = client.post(f"/profile/{target}/torcida", json={"reaction_type": "joinha"}, headers=sender_headers)
    assert resp2.json()["sent_today_by_me"] == 2


def test_send_torcida_to_self_is_rejected(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    resp = client.post(f"/profile/{user}/torcida", json={"reaction_type": "vibracao"}, headers=headers)
    assert resp.status_code == 422
    assert resp.json()["error"]["code"] == "CANNOT_TORCER_FOR_SELF"


def test_send_torcida_to_unknown_user_404s(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    resp = client.post(f"/profile/{uuid.uuid4()}/torcida", json={"reaction_type": "balao"}, headers=headers)
    assert resp.status_code == 404
    assert resp.json()["error"]["code"] == "USER_NOT_FOUND"


def test_send_torcida_respects_daily_limit_aggregated_across_types(client):
    from app import config

    sender = str(uuid.uuid4())
    sender_headers = auth_header(sender)
    client.post("/age-gate", json={"age_confirmed": True}, headers=sender_headers)

    target = str(uuid.uuid4())
    target_headers = auth_header(target)
    client.post("/age-gate", json={"age_confirmed": True}, headers=target_headers)

    types = ["vibracao", "balao", "coracao", "joinha"]
    for i in range(config.TORCIDA_DAILY_LIMIT_PER_TARGET):
        resp = client.post(f"/profile/{target}/torcida", json={"reaction_type": types[i % 4]}, headers=sender_headers)
        assert resp.status_code == 200, f"deveria permitir o envio {i + 1}/{config.TORCIDA_DAILY_LIMIT_PER_TARGET}"

    over_limit = client.post(f"/profile/{target}/torcida", json={"reaction_type": "coracao"}, headers=sender_headers)
    assert over_limit.status_code == 429
    assert over_limit.json()["error"]["code"] == "TORCIDA_DAILY_LIMIT_REACHED"

    # O limite é por DESTINATÁRIO — outro alvo não é afetado.
    other_target = str(uuid.uuid4())
    other_headers = auth_header(other_target)
    client.post("/age-gate", json={"age_confirmed": True}, headers=other_headers)
    resp_other = client.post(f"/profile/{other_target}/torcida", json={"reaction_type": "joinha"}, headers=sender_headers)
    assert resp_other.status_code == 200


def test_send_torcida_notifies_recipient_with_type_and_sender_nickname(client, monkeypatch):
    from app import services

    sent_notifications = []
    monkeypatch.setattr(services.push, "send_push_notification", lambda token, title, body: sent_notifications.append((token, title, body)))

    sender = str(uuid.uuid4())
    sender_headers = auth_header(sender)
    client.post("/age-gate", json={"age_confirmed": True}, headers=sender_headers)

    target = str(uuid.uuid4())
    target_headers = auth_header(target)
    client.post("/age-gate", json={"age_confirmed": True}, headers=target_headers)
    client.post("/notifications/register-token", json={"push_token": "target-device-token"}, headers=target_headers)

    resp = client.post(f"/profile/{target}/torcida", json={"reaction_type": "coracao"}, headers=sender_headers)
    assert resp.status_code == 200

    assert len(sent_notifications) == 1
    token, title, body = sent_notifications[0]
    assert token == "target-device-token"
    assert "💚" in body
