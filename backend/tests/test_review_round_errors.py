"""
REGRA_REVISAO_ERROS_FIM_RODADA.md — GET /challenges/{id}/reattempt serve
de novo um desafio já visto (revisão de erro). A resposta nunca gera
XP/streak/badge/progresso de território ("apenas confirmar o
aprendizado") e nunca conta pro limite diário.
"""

import uuid

from app import config, models
from app.db import SessionLocal

from .conftest import auth_header


def test_reattempt_serves_the_same_challenge_with_a_fresh_attempt_id(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    original = client.get("/challenges/next", params={"territory_id": "numeros"}, headers=headers).json()

    reattempted = client.get(f"/challenges/{original['challenge_id']}/reattempt", headers=headers).json()

    assert reattempted["challenge_id"] == original["challenge_id"]
    assert reattempted["prompt"] == original["prompt"]
    assert reattempted["attempt_id"] != original["attempt_id"]


def test_correct_answer_on_reattempt_grants_zero_xp_and_no_side_effects(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    from app.seed import CHALLENGES

    original = client.get("/challenges/next", params={"territory_id": "numeros"}, headers=headers).json()
    correct = next(
        c["correct_answer"] for c in CHALLENGES if c["territory_id"] == "numeros" and c["prompt"] == original["prompt"]
    )

    with SessionLocal() as db:
        xp_before = db.get(models.Profile, user.replace("-", "")).xp_total

    reattempted = client.get(f"/challenges/{original['challenge_id']}/reattempt", headers=headers).json()
    resp = client.post(
        f"/challenges/{reattempted['challenge_id']}/answer",
        json={"attempt_id": reattempted["attempt_id"], "submitted_answer": correct},
        headers=headers,
    )
    result = resp.json()

    assert resp.status_code == 200
    assert result["is_correct"] is True
    assert result["xp_awarded"] == 0
    assert result["batch_exhausted"] is False

    with SessionLocal() as db:
        xp_after = db.get(models.Profile, user.replace("-", "")).xp_total
    assert xp_after == xp_before


def test_reattempt_never_counts_toward_daily_limit(client, monkeypatch):
    monkeypatch.setattr(config, "DAILY_FREE_CHALLENGE_LIMIT", 1)
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    from app.seed import CHALLENGES

    original = client.get("/challenges/next", params={"territory_id": "numeros"}, headers=headers).json()
    correct = next(
        c["correct_answer"] for c in CHALLENGES if c["territory_id"] == "numeros" and c["prompt"] == original["prompt"]
    )
    # Consome o único slot diário disponível respondendo o desafio normal.
    client.post(
        f"/challenges/{original['challenge_id']}/answer",
        json={"attempt_id": original["attempt_id"], "submitted_answer": correct},
        headers=headers,
    )

    # Mesmo com o limite diário esgotado, revisar o mesmo desafio (via
    # reattempt) continua funcionando — nunca é bloqueado por
    # DAILY_LIMIT_REACHED, porque não é um desafio "novo".
    reattempted = client.get(f"/challenges/{original['challenge_id']}/reattempt", headers=headers)
    assert reattempted.status_code == 200

    answer_resp = client.post(
        f"/challenges/{original['challenge_id']}/answer",
        json={"attempt_id": reattempted.json()["attempt_id"], "submitted_answer": correct},
        headers=headers,
    )
    assert answer_resp.status_code == 200


def test_reattempt_of_unknown_challenge_returns_404(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    resp = client.get("/challenges/00000000-0000-0000-0000-000000000000/reattempt", headers=headers)
    assert resp.status_code == 404
