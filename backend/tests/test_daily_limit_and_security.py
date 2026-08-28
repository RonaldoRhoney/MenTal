import uuid
from datetime import datetime, timedelta
from app.timeutil import utcnow

from app.config import DAILY_FREE_CHALLENGE_LIMIT

from .conftest import auth_header


def test_daily_free_limit_blocks_after_limit(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    for i in range(DAILY_FREE_CHALLENGE_LIMIT):
        resp = client.get("/challenges/next", params={"territory_id": "numeros"}, headers=headers)
        assert resp.status_code == 200, f"deveria permitir a tentativa {i + 1}/{DAILY_FREE_CHALLENGE_LIMIT}"
        challenge = resp.json()
        client.post(
            f"/challenges/{challenge['challenge_id']}/answer",
            json={"attempt_id": str(uuid.uuid4()), "submitted_answer": "qualquer"},
            headers=headers,
        )

    over_limit = client.get("/challenges/next", params={"territory_id": "numeros"}, headers=headers)
    assert over_limit.status_code == 429
    assert over_limit.json()["error"]["code"] == "DAILY_LIMIT_REACHED"


def test_active_subscription_bypasses_daily_limit(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)
    client.post("/subscription/parental-gate", headers=headers)
    client.post("/subscription/validate-receipt", json={"purchase_token": "TEST_TOKEN_VALID"}, headers=headers)

    for _ in range(DAILY_FREE_CHALLENGE_LIMIT + 1):
        resp = client.get("/challenges/next", params={"territory_id": "numeros"}, headers=headers)
        assert resp.status_code == 200
        challenge = resp.json()
        client.post(
            f"/challenges/{challenge['challenge_id']}/answer",
            json={"attempt_id": str(uuid.uuid4()), "submitted_answer": "qualquer"},
            headers=headers,
        )


def test_validate_receipt_requires_parental_gate(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    resp = client.post("/subscription/validate-receipt", json={"purchase_token": "TEST_TOKEN_VALID"}, headers=headers)
    assert resp.status_code == 403
    assert resp.json()["error"]["code"] == "PARENTAL_GATE_REQUIRED"


def test_parental_gate_expires_and_requires_revalidation_per_purchase_attempt(client):
    # Cenário de risco identificado na revisão de Rhoney: adulto passa o
    # gate uma vez; meses depois, uma criança usa o celular já logado e
    # tenta comprar. O gate antigo NÃO pode autorizar essa nova tentativa.
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)
    client.post("/subscription/parental-gate", headers=headers)

    from app.config import PARENTAL_GATE_VALIDITY_MINUTES
    from app.db import SessionLocal
    from app import models

    with SessionLocal() as db:
        profile = db.get(models.Profile, user)
        profile.parental_gate_passed_at = utcnow() - timedelta(
            minutes=PARENTAL_GATE_VALIDITY_MINUTES + 1
        )
        db.commit()

    resp = client.post(
        "/subscription/validate-receipt", json={"purchase_token": "TEST_TOKEN_VALID"}, headers=headers
    )
    assert resp.status_code == 403
    assert resp.json()["error"]["code"] == "PARENTAL_GATE_EXPIRED"

    # Revalidando o gate agora (nova tentativa de compra), a compra passa.
    client.post("/subscription/parental-gate", headers=headers)
    resp2 = client.post(
        "/subscription/validate-receipt", json={"purchase_token": "TEST_TOKEN_VALID"}, headers=headers
    )
    assert resp2.status_code == 200
    assert resp2.json()["status"] == "active"


def test_ranking_never_exposes_user_id_or_email(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

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
        # avatar_id/real_name/photo_url: USER_PROFILE.md, aprovado — nunca
        # expõe user_id/email. real_name e photo_url (revisão 26/08/2026)
        # são o mesmo tipo de dado público que nickname já expunha; photo_url
        # ainda passa pelo filtro fail-closed de moderação (services.
        # public_photo_url), nunca o dado bruto.
        assert set(entry.keys()) == {"rank", "nickname", "avatar_id", "real_name", "photo_url", "xp"}
        assert user not in entry["nickname"]  # nunca expõe o user_id bruto
