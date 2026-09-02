"""
V4 — Ouvido Afiado (V4/V4_NOVOS_TERRITORIOS.md §3). Primeiro bloco a
mudar a MODALIDADE SENSORIAL do desafio: o áudio vem na resposta de
GET /challenges/next (audio_url + atribuição de fonte), o client é quem
decide como tocar — mas o CONTEÚDO em si é sempre entregue pelo
backend, mesmo princípio de autoridade de servidor de todo o resto do
app. Território normal de MCQ em tudo o mais.
"""

import uuid

from .conftest import auth_header


def test_next_challenge_includes_audio_fields_for_ouvido_afiado(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    resp = client.get("/challenges/next", params={"territory_id": "ouvido_afiado"}, headers=headers)
    body = resp.json()

    assert resp.status_code == 200
    assert isinstance(body["audio_url"], str) and body["audio_url"].startswith("https://")
    assert isinstance(body["audio_source_name"], str) and body["audio_source_name"]
    assert isinstance(body["audio_source_url"], str) and body["audio_source_url"].startswith("https://")
    assert body["options"] is not None
    assert len(body["options"]) == 4


def test_next_challenge_omits_audio_fields_for_regular_territories(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    resp = client.get("/challenges/next", params={"territory_id": "numeros"}, headers=headers)
    body = resp.json()

    assert resp.status_code == 200
    assert body["audio_url"] is None
    assert body["audio_source_name"] is None
    assert body["audio_source_url"] is None


def test_ouvido_afiado_relampago_mode_still_includes_audio(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    resp = client.get(
        "/challenges/next", params={"territory_id": "ouvido_afiado", "mode": "relampago"}, headers=headers
    )
    body = resp.json()

    assert resp.status_code == 200
    assert body["audio_url"] is not None
    assert body["time_limit_seconds"] is not None


def test_ouvido_afiado_answer_flow_works_like_any_other_mcq_territory(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    from app.seed import CHALLENGES

    challenge = client.get("/challenges/next", params={"territory_id": "ouvido_afiado"}, headers=headers).json()
    correct = next(
        c["correct_answer"]
        for c in CHALLENGES
        if c["territory_id"] == "ouvido_afiado" and c["prompt"] == challenge["prompt"]
    )

    resp = client.post(
        f"/challenges/{challenge['challenge_id']}/answer",
        json={"attempt_id": challenge["attempt_id"], "submitted_answer": correct},
        headers=headers,
    )
    result = resp.json()

    assert resp.status_code == 200
    assert result["is_correct"] is True
    assert result["xp_awarded"] > 0
