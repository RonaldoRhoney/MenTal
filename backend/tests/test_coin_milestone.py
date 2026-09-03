"""
Pedido de Rhoney (2026-09-02): "toda vez que o usuário somar 100 xp OU
somar 50 MentalCoins, sobem umas moedas" — reforço visual, calculado
pelo backend (services.crossed_coin_milestone) exatamente como todo
outro sinal de transição (level_up, territory_just_conquered etc.):
compara floor(antes/N) com floor(depois/N), nunca "o valor atual é
múltiplo".
"""

import uuid

from app import models, services
from app.db import SessionLocal

from .conftest import auth_header


def test_crossed_coin_milestone_detects_xp_and_mentalcoins_transitions():
    # Cruza o marco de 100 XP.
    assert services.crossed_coin_milestone(95, 105, 0, 0) is True
    # Cruza o marco de 50 MentalCoins.
    assert services.crossed_coin_milestone(0, 0, 48, 52) is True
    # Nenhum dos dois cruzou.
    assert services.crossed_coin_milestone(10, 20, 10, 20) is False
    # Já estava exatamente no múltiplo antes — não é uma transição nova.
    assert services.crossed_coin_milestone(100, 140, 0, 0) is False
    # Múltiplo exato sozinho, sem cruzar de baixo pra cima, não conta.
    assert services.crossed_coin_milestone(90, 100, 0, 0) is True


def test_answer_response_flags_coin_milestone_only_on_the_crossing_response(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    # Deixa o jogador a 5 XP do marco de 100 (mesma técnica de setup direto
    # no banco já usada nas demais suítes do MENTAL para forçar um estado
    # específico sem depender de dezenas de respostas reais).
    db = SessionLocal()
    profile = services.get_or_create_profile(db, user)
    profile.xp_total = 95
    profile.level = 1
    db.commit()
    db.close()

    from app.seed import CHALLENGES

    challenge = client.get("/challenges/next", params={"territory_id": "numeros"}, headers=headers).json()
    correct = next(
        c["correct_answer"]
        for c in CHALLENGES
        if c["territory_id"] == "numeros" and c["prompt"] == challenge["prompt"]
    )

    resp = client.post(
        f"/challenges/{challenge['challenge_id']}/answer",
        json={"attempt_id": challenge["attempt_id"], "submitted_answer": correct},
        headers=headers,
    )
    result = resp.json()

    assert resp.status_code == 200
    assert result["is_correct"] is True
    assert result["coin_milestone_reached"] is True

    # Reenvio idempotente do mesmo attempt_id nunca recalcula nem
    # re-celebra — mesma regra de todo outro sinal de transição.
    replay = client.post(
        f"/challenges/{challenge['challenge_id']}/answer",
        json={"attempt_id": challenge["attempt_id"], "submitted_answer": correct},
        headers=headers,
    ).json()
    assert replay["coin_milestone_reached"] is False


def test_answer_response_does_not_flag_coin_milestone_when_far_from_any_threshold(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    from app.seed import CHALLENGES

    challenge = client.get("/challenges/next", params={"territory_id": "numeros"}, headers=headers).json()
    correct = next(
        c["correct_answer"]
        for c in CHALLENGES
        if c["territory_id"] == "numeros" and c["prompt"] == challenge["prompt"]
    )

    result = client.post(
        f"/challenges/{challenge['challenge_id']}/answer",
        json={"attempt_id": challenge["attempt_id"], "submitted_answer": correct},
        headers=headers,
    ).json()

    assert result["coin_milestone_reached"] is False


def test_app_invite_share_reward_flags_coin_milestone_when_it_crosses_50_mentalcoins(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    db = SessionLocal()
    profile = services.get_or_create_profile(db, user)
    balance = models.MentalCoinsBalance(user_id=user, balance=47)
    db.add(balance)
    db.commit()
    db.close()

    result = client.post("/social/share-app-reward", headers=headers).json()

    assert result["mentalcoins_balance"] == 52
    assert result["coin_milestone_reached"] is True
