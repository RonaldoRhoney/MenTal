import uuid

from .conftest import auth_header


def test_resubmitting_same_attempt_id_does_not_duplicate_xp(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    challenge = client.get("/challenges/next", params={"territory_id": "numeros"}, headers=headers).json()

    from app.seed import CHALLENGES

    correct = next(c["correct_answer"] for c in CHALLENGES if c["prompt"] == challenge["prompt"])

    attempt_id = challenge["attempt_id"]
    payload = {"attempt_id": attempt_id, "submitted_answer": correct}

    first = client.post(f"/challenges/{challenge['challenge_id']}/answer", json=payload, headers=headers).json()
    assert first["is_correct"] is True
    xp_after_first = client.get("/progress", headers=headers).json()["xp_total"]
    assert xp_after_first == first["xp_awarded"]

    # Reenvio exato do mesmo attempt_id (simulando retry de rede). O
    # resultado do jogo (XP, acerto, progresso) é idêntico — mas os sinais
    # de celebração (MICROINTERACTIONS.md) nunca retriggam num reenvio,
    # mesmo que a primeira resposta genuinamente tenha sido um evento raro
    # (aqui, streak_just_extended=True no primeiro play do dia).
    second = client.post(f"/challenges/{challenge['challenge_id']}/answer", json=payload, headers=headers).json()
    celebration_fields = {
        "level_up",
        "territory_just_conquered",
        "streak_just_extended",
        "newly_awarded_badges",
        "territory_detentor_gained",
        "dethroned_nickname",
    }
    assert {k: v for k, v in second.items() if k not in celebration_fields} == {
        k: v for k, v in first.items() if k not in celebration_fields
    }
    assert second["level_up"] is False
    assert second["territory_just_conquered"] is False
    assert second["streak_just_extended"] is False
    assert second["newly_awarded_badges"] == []
    assert second["territory_detentor_gained"] is False

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
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    challenge = client.get("/challenges/next", params={"territory_id": "numeros"}, headers=headers).json()

    from app.seed import CHALLENGES

    correct = next(c["correct_answer"] for c in CHALLENGES if c["prompt"] == challenge["prompt"])

    attempt_id = challenge["attempt_id"]

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
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    challenge = client.get("/challenges/next", params={"territory_id": "numeros"}, headers=headers).json()
    attempt_id = challenge["attempt_id"]

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
