"""
ARCHITECTURE_UPDATE_I18N_READY.md — critério de aceite (§4): endpoint de
desafio já aceita/filtra por idioma, mesmo com um único valor hoje.
"""

import uuid

from app.config import DEFAULT_LANGUAGE_CODE

from .conftest import auth_header


def test_default_language_is_pt_br():
    assert DEFAULT_LANGUAGE_CODE == "pt-BR"


def test_next_challenge_defaults_to_pt_br_without_explicit_param(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers)

    resp = client.get("/challenges/next", params={"territory_id": "numeros"}, headers=headers)
    assert resp.status_code == 200


def test_next_challenge_accepts_explicit_language_code_param(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers)

    resp = client.get(
        "/challenges/next",
        params={"territory_id": "numeros", "language_code": "pt-BR"},
        headers=headers,
    )
    assert resp.status_code == 200


def test_unsupported_language_code_returns_no_challenges_not_wrong_language(client):
    # Prova que o filtro é real (não decorativo): pedir um idioma que não
    # existe no banco não deve, silenciosamente, devolver conteúdo pt-BR.
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers)

    resp = client.get(
        "/challenges/next",
        params={"territory_id": "numeros", "language_code": "en-US"},
        headers=headers,
    )
    assert resp.status_code == 404
    assert resp.json()["error"]["code"] == "NO_CHALLENGES_AVAILABLE"
