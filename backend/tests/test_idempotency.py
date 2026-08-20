import uuid

from .conftest import auth_header


def test_resubmitting_same_attempt_id_does_not_duplicate_xp(client):
    user = f"user-idem-{uuid.uuid4()}"
    headers = auth_header(user)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers)

    challenge = client.get("/challenges/next", params={"territory_id": "numeros"}, headers=headers).json()

    from app.seed import CHALLENGES

    correct = next(c["correct_answer"] for c in CHALLENGES if c["prompt"] == challenge["prompt"])

    attempt_id = str(uuid.uuid4())
    payload = {"attempt_id": attempt_id, "submitted_answer": correct}

    first = client.post(f"/challenges/{challenge['challenge_id']}/answer", json=payload, headers=headers).json()
    assert first["is_correct"] is True
    xp_after_first = client.get("/progress", headers=headers).json()["xp_total"]
    assert xp_after_first == first["xp_awarded"]

    # Reenvio exato do mesmo attempt_id (simulando retry de rede).
    second = client.post(f"/challenges/{challenge['challenge_id']}/answer", json=payload, headers=headers).json()
    assert second == first

    xp_after_second = client.get("/progress", headers=headers).json()["xp_total"]
    assert xp_after_second == xp_after_first, "XP não pode dobrar por reenvio do mesmo attempt_id"

    # Terceiro reenvio, agora tentando mudar a resposta enviada — mesmo
    # assim o resultado já travado é o que prevalece (não recalcula).
    tampered = client.post(
        f"/challenges/{challenge['challenge_id']}/answer",
        json={"attempt_id": attempt_id, "submitted_answer": "resposta-diferente"},
        headers=headers,
    ).json()
    assert tampered["is_correct"] is True
    assert tampered["xp_awarded"] == first["xp_awarded"]


def test_hint_penalty_applied_and_persisted_via_attempt_id(client):
    user = f"user-hint-{uuid.uuid4()}"
    headers = auth_header(user)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers)

    challenge = client.get("/challenges/next", params={"territory_id": "numeros"}, headers=headers).json()

    from app.seed import CHALLENGES

    correct = next(c["correct_answer"] for c in CHALLENGES if c["prompt"] == challenge["prompt"])

    attempt_id = str(uuid.uuid4())

    hint_resp = client.post(
        f"/challenges/{challenge['challenge_id']}/hint",
        json={"attempt_id": attempt_id},
        headers=headers,
    )
    assert hint_resp.status_code == 200
    assert hint_resp.json()["hint_level"] == 1

    result = client.post(
        f"/challenges/{challenge['challenge_id']}/answer",
        json={"attempt_id": attempt_id, "submitted_answer": correct},
        headers=headers,
    ).json()

    assert result["hints_used"] == 1
    assert result["xp_awarded"] == round(result["xp_base"] * 0.75)


def test_cannot_request_hint_after_answering(client):
    user = f"user-hint-after-{uuid.uuid4()}"
    headers = auth_header(user)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers)

    challenge = client.get("/challenges/next", params={"territory_id": "numeros"}, headers=headers).json()
    attempt_id = str(uuid.uuid4())

    client.post(
        f"/challenges/{challenge['challenge_id']}/answer",
        json={"attempt_id": attempt_id, "submitted_answer": "x"},
        headers=headers,
    )

    hint_resp = client.post(
        f"/challenges/{challenge['challenge_id']}/hint",
        json={"attempt_id": attempt_id},
        headers=headers,
    )
    assert hint_resp.status_code == 409
