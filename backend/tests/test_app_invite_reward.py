"""
Recompensa do botão de convidar amigos (ao lado do wordmark MENTAL,
pedido de Rhoney): 20 XP + 5 MentalCoins, teto de 1x/dia PRÓPRIO —
distinto do teto de /social/share-reward (compartilhar conquista), que
usa outro campo/coluna e não deve ser afetado por este botão nem
vice-versa.
"""

import uuid

from app import config

from .conftest import auth_header


def test_first_app_invite_share_of_the_day_awards_xp_and_mentalcoins(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    resp = client.post("/social/share-app-reward", headers=headers)
    body = resp.json()

    assert resp.status_code == 200
    assert body["xp_awarded"] == config.APP_INVITE_XP_REWARD
    assert body["mentalcoins_awarded"] == config.APP_INVITE_MENTALCOINS_REWARD
    assert body["already_rewarded_today"] is False
    assert body["xp_total"] == config.APP_INVITE_XP_REWARD
    assert body["mentalcoins_balance"] == config.APP_INVITE_MENTALCOINS_REWARD


def test_second_app_invite_share_same_day_awards_nothing_extra(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    client.post("/social/share-app-reward", headers=headers)
    second = client.post("/social/share-app-reward", headers=headers).json()

    assert second["xp_awarded"] == 0
    assert second["mentalcoins_awarded"] == 0
    assert second["already_rewarded_today"] is True
    assert second["xp_total"] == config.APP_INVITE_XP_REWARD
    assert second["mentalcoins_balance"] == config.APP_INVITE_MENTALCOINS_REWARD


def test_app_invite_reward_and_achievement_share_reward_have_independent_daily_caps(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    app_invite = client.post("/social/share-app-reward", headers=headers).json()
    achievement_share = client.post("/social/share-reward", headers=headers).json()

    # Os dois tetos são independentes — usar um não consome o outro no
    # mesmo dia, porque são botões/recompensas diferentes.
    assert app_invite["already_rewarded_today"] is False
    assert achievement_share["already_rewarded_today"] is False
    assert achievement_share["xp_awarded"] == config.SHARE_XP_REWARD
    assert achievement_share["xp_total"] == config.APP_INVITE_XP_REWARD + config.SHARE_XP_REWARD
