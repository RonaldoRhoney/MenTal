import uuid

from .conftest import auth_header


def test_daily_free_limit_blocks_after_8(client):
    user = f"user-limit-{uuid.uuid4()}"
    headers = auth_header(user)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers)

    for i in range(8):
        resp = client.get("/challenges/next", params={"territory_id": "numeros"}, headers=headers)
        assert resp.status_code == 200, f"deveria permitir a tentativa {i + 1}/8"
        challenge = resp.json()
        client.post(
            f"/challenges/{challenge['challenge_id']}/answer",
            json={"attempt_id": str(uuid.uuid4()), "submitted_answer": "qualquer"},
            headers=headers,
        )

    ninth = client.get("/challenges/next", params={"territory_id": "numeros"}, headers=headers)
    assert ninth.status_code == 429
    assert ninth.json()["error"]["code"] == "DAILY_LIMIT_REACHED"


def test_active_subscription_bypasses_daily_limit(client):
    user = f"user-sub-limit-{uuid.uuid4()}"
    headers = auth_header(user)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers)
    client.post("/subscription/parental-gate", headers=headers)
    client.post("/subscription/validate-receipt", json={"purchase_token": "TEST_TOKEN_VALID"}, headers=headers)

    for _ in range(9):
        resp = client.get("/challenges/next", params={"territory_id": "numeros"}, headers=headers)
        assert resp.status_code == 200
        challenge = resp.json()
        client.post(
            f"/challenges/{challenge['challenge_id']}/answer",
            json={"attempt_id": str(uuid.uuid4()), "submitted_answer": "qualquer"},
            headers=headers,
        )


def test_validate_receipt_requires_parental_gate(client):
    user = f"user-noparental-{uuid.uuid4()}"
    headers = auth_header(user)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers)

    resp = client.post("/subscription/validate-receipt", json={"purchase_token": "TEST_TOKEN_VALID"}, headers=headers)
    assert resp.status_code == 403
    assert resp.json()["error"]["code"] == "PARENTAL_GATE_REQUIRED"


def test_ranking_never_exposes_user_id_or_email(client):
    user = f"user-rank-{uuid.uuid4()}"
    headers = auth_header(user)
    client.post("/age-gate", json={"age_mode": "child"}, headers=headers)

    challenge = client.get("/challenges/next", params={"territory_id": "numeros"}, headers=headers).json()
    from app.seed import CHALLENGES

    correct = next(c["correct_answer"] for c in CHALLENGES if c["prompt"] == challenge["prompt"])
    client.post(
        f"/challenges/{challenge['challenge_id']}/answer",
        json={"attempt_id": str(uuid.uuid4()), "submitted_answer": correct},
        headers=headers,
    )

    ranking = client.get("/ranking", params={"scope": "global", "window": "weekly"}, headers=headers).json()
    for entry in ranking["entries"]:
        assert set(entry.keys()) == {"rank", "nickname", "xp"}
        assert user not in entry["nickname"]  # nunca expõe o user_id bruto
