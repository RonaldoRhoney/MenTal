"""
V2 item 13 — Disputa territorial (TERRITORY_DISPUTE.md, aprovado
2026-08-22). "Detentor" é sempre relativo a você + amigos confirmados
(nunca global) e é sempre derivado de UserTerritoryProgress.
xp_in_territory (já existente), nunca armazenado.
"""

import uuid

from .conftest import auth_header


def _make_friends(client, user_a, user_b):
    headers_a = auth_header(user_a)
    headers_b = auth_header(user_b)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers_a)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers_b)
    code = client.get("/social/invite-code", headers=headers_a).json()["invite_code"]
    client.post("/social/friends", json={"invite_code": code}, headers=headers_b)
    return headers_a, headers_b


def _answer_until_correct(client, headers, territory_id="palavras", tries=30):
    from app.seed import CHALLENGES

    for _ in range(tries):
        ch = client.get("/challenges/next", params={"territory_id": territory_id}, headers=headers).json()
        correct = next(
            c["correct_answer"] for c in CHALLENGES
            if c["territory_id"] == territory_id and c["prompt"] == ch["prompt"] and c["difficulty_level"] == ch["difficulty_level"]
        )
        result = client.post(
            f"/challenges/{ch['challenge_id']}/answer",
            json={"attempt_id": str(uuid.uuid4()), "submitted_answer": correct},
            headers=headers,
        ).json()
        if result["is_correct"]:
            return result
    raise AssertionError("não conseguiu acertar nenhuma tentativa")


def test_no_detentor_when_nobody_has_xp_in_territory(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers)

    progress = client.get("/progress", headers=headers).json()
    palavras = next(t for t in progress["territories"] if t["territory_id"] == "palavras")
    assert palavras["detentor_nickname"] is None
    assert palavras["is_detentor"] is False


def test_sole_scorer_becomes_detentor(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers)

    _answer_until_correct(client, headers)

    progress = client.get("/progress", headers=headers).json()
    palavras = next(t for t in progress["territories"] if t["territory_id"] == "palavras")
    assert palavras["is_detentor"] is True


def test_dispute_is_scoped_to_friends_never_global_strangers(client):
    user_a, stranger = str(uuid.uuid4()), str(uuid.uuid4())
    headers_a = auth_header(user_a)
    headers_stranger = auth_header(stranger)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers_a)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers_stranger)

    # Estranho acumula MUITO mais XP que user_a, mas nunca foram amigos.
    for _ in range(5):
        _answer_until_correct(client, headers_stranger)
    _answer_until_correct(client, headers_a)

    progress_a = client.get("/progress", headers=headers_a).json()
    palavras_a = next(t for t in progress_a["territories"] if t["territory_id"] == "palavras")
    # user_a continua detentor do próprio ponto de vista — o estranho
    # nunca entra na conta, por mais XP que tenha.
    assert palavras_a["is_detentor"] is True


def test_friend_with_more_xp_becomes_detentor_and_dethrones_previous(client):
    user_a, user_b = str(uuid.uuid4()), str(uuid.uuid4())
    headers_a, headers_b = _make_friends(client, user_a, user_b)

    _answer_until_correct(client, headers_a)  # A vira detentor primeiro

    progress_a = client.get("/progress", headers=headers_a).json()
    assert next(t for t in progress_a["territories"] if t["territory_id"] == "palavras")["is_detentor"] is True

    # B acerta várias vezes até assumir a liderança de XP no território.
    dethroned = False
    for _ in range(10):
        result = _answer_until_correct(client, headers_b)
        if result["territory_detentor_gained"]:
            dethroned = True
            assert result["dethroned_nickname"] is not None
            break

    assert dethroned, "B deveria ter assumido o território de A em algum momento"

    progress_a_after = client.get("/progress", headers=headers_a).json()
    palavras_a_after = next(t for t in progress_a_after["territories"] if t["territory_id"] == "palavras")
    assert palavras_a_after["is_detentor"] is False
    assert palavras_a_after["detentor_nickname"] is not None


def test_no_dethroned_nickname_on_first_ever_detentor(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers)

    result = _answer_until_correct(client, headers)
    if result["territory_detentor_gained"]:
        assert result["dethroned_nickname"] is None
