"""
Recompensa por compartilhar conquista (pedido de Rhoney, 2026-08-22):
compartilhar rende XP, com teto de 1 recompensa por dia civil (UTC) —
o app não confirma que o compartilhamento no SO foi de fato concluído,
então a defesa contra farm é o teto diário, não uma verificação do
compartilhamento em si.
"""

import uuid

from app import config

from .conftest import auth_header


def test_first_share_of_the_day_awards_xp(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers)

    resp = client.post("/social/share-reward", headers=headers)
    body = resp.json()

    assert resp.status_code == 200
    assert body["xp_awarded"] == config.SHARE_XP_REWARD
    assert body["already_rewarded_today"] is False
    assert body["xp_total"] == config.SHARE_XP_REWARD


def test_second_share_same_day_awards_no_extra_xp(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers)

    client.post("/social/share-reward", headers=headers)
    second = client.post("/social/share-reward", headers=headers).json()

    assert second["xp_awarded"] == 0
    assert second["already_rewarded_today"] is True
    assert second["xp_total"] == config.SHARE_XP_REWARD


def test_repeated_taps_never_exceed_daily_cap(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers)

    for _ in range(5):
        client.post("/social/share-reward", headers=headers)

    final = client.post("/social/share-reward", headers=headers).json()
    assert final["xp_total"] == config.SHARE_XP_REWARD
