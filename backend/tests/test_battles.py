"""
V2 item 14 — Batalha assíncrona (ASYNC_BATTLE.md, aprovado 2026-08-22).
A resposta em si reaproveita POST /challenges/{id}/answer sem mudar seu
cálculo de XP — os testes aqui cobrem só a coordenação entre os dois
lados (criação, limite diário, vencedor por acerto/velocidade, empate).
"""

import uuid

from app import config

from .conftest import auth_header


def _make_friends(client, user_a, user_b):
    headers_a = auth_header(user_a)
    headers_b = auth_header(user_b)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers_a)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers_b)
    code = client.get("/social/invite-code", headers=headers_a).json()["invite_code"]
    client.post("/social/friends", json={"invite_code": code}, headers=headers_b)
    return headers_a, headers_b


def test_cannot_battle_a_non_friend(client):
    user_a, user_b = str(uuid.uuid4()), str(uuid.uuid4())
    headers_a = auth_header(user_a)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers_a)

    resp = client.post(
        "/battles",
        json={"opponent_user_id": user_b, "territory_id": "palavras", "difficulty_level": 1},
        headers=headers_a,
    )
    assert resp.status_code == 400
    assert resp.json()["error"]["code"] == "NOT_FRIENDS"


def test_create_battle_returns_challenger_challenge_and_notifies_opponent(client):
    user_a, user_b = str(uuid.uuid4()), str(uuid.uuid4())
    headers_a, headers_b = _make_friends(client, user_a, user_b)

    resp = client.post(
        "/battles",
        json={"opponent_user_id": user_b, "territory_id": "palavras", "difficulty_level": 1},
        headers=headers_a,
    )
    body = resp.json()

    assert resp.status_code == 200
    assert "battle_id" in body
    assert body["challenge"]["territory_id"] == "palavras"
    assert body["challenge"]["difficulty_level"] == 1
    assert "correct_answer" not in body["challenge"]


def test_opponent_gets_a_different_challenge_than_challenger(client):
    user_a, user_b = str(uuid.uuid4()), str(uuid.uuid4())
    headers_a, headers_b = _make_friends(client, user_a, user_b)

    created = client.post(
        "/battles",
        json={"opponent_user_id": user_b, "territory_id": "palavras", "difficulty_level": 1},
        headers=headers_a,
    ).json()
    battle_id = created["battle_id"]
    challenger_prompt = created["challenge"]["prompt"]

    opponent_challenge = client.get(f"/battles/{battle_id}/my-challenge", headers=headers_b).json()
    assert opponent_challenge["prompt"] != challenger_prompt


def test_daily_send_limit_enforced(client):
    user_a, user_b = str(uuid.uuid4()), str(uuid.uuid4())
    headers_a, headers_b = _make_friends(client, user_a, user_b)

    for _ in range(config.BATTLE_DAILY_SEND_LIMIT):
        resp = client.post(
            "/battles",
            json={"opponent_user_id": user_b, "territory_id": "palavras", "difficulty_level": 1},
            headers=headers_a,
        )
        assert resp.status_code == 200

    over_limit = client.post(
        "/battles",
        json={"opponent_user_id": user_b, "territory_id": "palavras", "difficulty_level": 1},
        headers=headers_a,
    )
    assert over_limit.status_code == 429
    assert over_limit.json()["error"]["code"] == "BATTLE_DAILY_LIMIT_REACHED"


def _answer(client, headers, challenge_id, submitted_answer):
    return client.post(
        f"/challenges/{challenge_id}/answer",
        json={"attempt_id": str(uuid.uuid4()), "submitted_answer": submitted_answer},
        headers=headers,
    ).json()


def test_winner_is_whoever_answers_correctly_when_other_is_wrong(client):
    from app.seed import CHALLENGES

    user_a, user_b = str(uuid.uuid4()), str(uuid.uuid4())
    headers_a, headers_b = _make_friends(client, user_a, user_b)

    created = client.post(
        "/battles",
        json={"opponent_user_id": user_b, "territory_id": "palavras", "difficulty_level": 1},
        headers=headers_a,
    ).json()
    battle_id = created["battle_id"]
    challenger_challenge_id = created["challenge"]["challenge_id"]
    opponent_challenge = client.get(f"/battles/{battle_id}/my-challenge", headers=headers_b).json()

    correct = next(c["correct_answer"] for c in CHALLENGES if c["prompt"] == created["challenge"]["prompt"])
    _answer(client, headers_a, challenger_challenge_id, correct)
    _answer(client, headers_b, opponent_challenge["challenge_id"], "resposta errada de propósito")

    battles_a = client.get("/battles", headers=headers_a).json()["battles"]
    mine = next(b for b in battles_a if b["battle_id"] == battle_id)
    assert mine["status"] == "resolved"
    assert mine["winner"] == "me"
    assert mine["win_bonus_xp"] == config.BATTLE_WIN_BONUS_XP


def test_tie_when_both_answer_wrong(client):
    user_a, user_b = str(uuid.uuid4()), str(uuid.uuid4())
    headers_a, headers_b = _make_friends(client, user_a, user_b)

    created = client.post(
        "/battles",
        json={"opponent_user_id": user_b, "territory_id": "palavras", "difficulty_level": 1},
        headers=headers_a,
    ).json()
    battle_id = created["battle_id"]
    opponent_challenge = client.get(f"/battles/{battle_id}/my-challenge", headers=headers_b).json()

    _answer(client, headers_a, created["challenge"]["challenge_id"], "errado a")
    _answer(client, headers_b, opponent_challenge["challenge_id"], "errado b")

    battles_a = client.get("/battles", headers=headers_a).json()["battles"]
    mine = next(b for b in battles_a if b["battle_id"] == battle_id)
    assert mine["status"] == "resolved"
    assert mine["winner"] == "tie"
    assert mine["win_bonus_xp"] == 0


def test_battle_stays_pending_until_both_answer(client):
    user_a, user_b = str(uuid.uuid4()), str(uuid.uuid4())
    headers_a, headers_b = _make_friends(client, user_a, user_b)

    created = client.post(
        "/battles",
        json={"opponent_user_id": user_b, "territory_id": "palavras", "difficulty_level": 1},
        headers=headers_a,
    ).json()
    battle_id = created["battle_id"]

    _answer(client, headers_a, created["challenge"]["challenge_id"], "qualquer coisa")

    battles_a = client.get("/battles", headers=headers_a).json()["battles"]
    mine = next(b for b in battles_a if b["battle_id"] == battle_id)
    assert mine["status"] == "pending"
    assert mine["i_answered"] is True
    assert mine["opponent_answered"] is False
