import uuid

from .conftest import auth_header


def test_full_core_loop_correct_answer(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)

    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers)

    resp = client.get("/challenges/next", params={"territory_id": "numeros"}, headers=headers)
    assert resp.status_code == 200
    challenge = resp.json()
    assert challenge["territory_id"] == "numeros"
    assert "prompt" in challenge

    attempt_id = str(uuid.uuid4())

    # Backend nunca envia a resposta correta antes da confirmação.
    assert "correct_answer" not in challenge

    answer_resp = client.post(
        f"/challenges/{challenge['challenge_id']}/answer",
        json={"attempt_id": attempt_id, "submitted_answer": "wrong-on-purpose"},
        headers=headers,
    )
    assert answer_resp.status_code == 200
    result = answer_resp.json()
    assert result["is_correct"] is False
    assert result["xp_awarded"] == 0
    assert "explanation" in result

    progress = client.get("/progress", headers=headers).json()
    assert progress["xp_total"] == 0


def test_correct_answer_awards_xp_and_updates_territory_progress(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers)

    challenge = client.get("/challenges/next", params={"territory_id": "numeros"}, headers=headers).json()

    # Descobre a resposta certa lendo diretamente o seed (teste conhece o
    # conteúdo fixo, o cliente real nunca teria acesso a isso).
    from app.seed import CHALLENGES

    prompt = challenge["prompt"]
    correct = next(c["correct_answer"] for c in CHALLENGES if c["prompt"] == prompt)

    attempt_id = str(uuid.uuid4())
    result = client.post(
        f"/challenges/{challenge['challenge_id']}/answer",
        json={"attempt_id": attempt_id, "submitted_answer": correct},
        headers=headers,
    ).json()

    assert result["is_correct"] is True
    assert result["xp_awarded"] > 0

    progress = client.get("/progress", headers=headers).json()
    assert progress["xp_total"] == result["xp_awarded"]
    territory = next(t for t in progress["territories"] if t["territory_id"] == "numeros")
    assert territory["xp_in_territory"] == result["xp_awarded"]


def test_paid_territory_allows_free_sample_then_locks(client):
    # TERRITORIES.md §2 / MONETIZATION.md §2: territórios pagos têm amostra
    # grátis (free_sample_count=2 para 'logica' no seed). As 2 primeiras
    # tentativas respondidas passam; a 3ª exige assinatura.
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers)

    for _ in range(2):
        resp = client.get("/challenges/next", params={"territory_id": "logica"}, headers=headers)
        assert resp.status_code == 200
        challenge = resp.json()
        client.post(
            f"/challenges/{challenge['challenge_id']}/answer",
            json={"attempt_id": str(uuid.uuid4()), "submitted_answer": "qualquer coisa"},
            headers=headers,
        )

    resp = client.get("/challenges/next", params={"territory_id": "logica"}, headers=headers)
    assert resp.status_code == 403
    assert resp.json()["error"]["code"] == "TERRITORY_LOCKED"
