"""
Busca na Home (pedido de Rhoney, 2026-09-03): "buscar por tema, frase
ou palavra... caso encontre, será levado direto aquele desafio... se
não, entra o que buscou, ele pode sugerir tal conteúdo".
"""

import uuid

from app import models
from app.db import SessionLocal
from app.seed import CHALLENGES

from .conftest import auth_header


def _promote_to_admin(user: str) -> None:
    with SessionLocal() as db:
        profile = db.get(models.Profile, user.replace("-", ""))
        profile.role = "admin"
        db.commit()


def test_search_finds_a_challenge_by_a_literal_word_in_the_prompt(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    sample = next(c for c in CHALLENGES if c["territory_id"] == "numeros")
    needle = sample["prompt"].split()[0]

    resp = client.get("/challenges/search", params={"q": needle}, headers=headers)
    body = resp.json()

    assert resp.status_code == 200
    assert body["found"] is True
    assert needle.lower() in body["challenge"]["prompt"].lower()
    assert body["challenge"]["attempt_id"] is not None


def test_search_found_challenge_can_be_answered_like_any_other(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    sample = next(c for c in CHALLENGES if c["territory_id"] == "numeros")
    needle = sample["prompt"].split()[0]

    found = client.get("/challenges/search", params={"q": needle}, headers=headers).json()["challenge"]
    correct = next(
        c["correct_answer"] for c in CHALLENGES if c["territory_id"] == "numeros" and c["prompt"] == found["prompt"]
    )

    resp = client.post(
        f"/challenges/{found['challenge_id']}/answer",
        json={"attempt_id": found["attempt_id"], "submitted_answer": correct},
        headers=headers,
    )
    result = resp.json()

    assert resp.status_code == 200
    assert result["is_correct"] is True


def test_search_with_no_match_returns_found_false_not_an_error(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    resp = client.get(
        "/challenges/search", params={"q": "termo-que-certamente-nao-existe-em-nenhum-desafio-xyz123"}, headers=headers
    )
    body = resp.json()

    assert resp.status_code == 200
    assert body["found"] is False
    assert body["challenge"] is None


def test_content_suggestion_is_registered_and_visible_only_to_admin(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    resp = client.post("/content-suggestions", json={"query_text": "Culinária japonesa"}, headers=headers)
    assert resp.status_code == 200
    assert resp.json()["ok"] is True

    # Usuário comum não pode listar sugestões — só admin.
    forbidden = client.get("/admin/content-suggestions", headers=headers)
    assert forbidden.status_code == 403
    assert forbidden.json()["error"]["code"] == "ADMIN_ONLY"

    admin = str(uuid.uuid4())
    admin_headers = auth_header(admin)
    client.post("/age-gate", json={"age_confirmed": True}, headers=admin_headers)
    _promote_to_admin(admin)

    listed = client.get("/admin/content-suggestions", headers=admin_headers).json()
    assert any(item["query_text"] == "Culinária japonesa" for item in listed["items"])


def test_content_suggestion_rejects_blank_query(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    resp = client.post("/content-suggestions", json={"query_text": "   "}, headers=headers)
    assert resp.status_code == 422
