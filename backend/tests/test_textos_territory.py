"""
V2 item 3 — Textos/interpretação (V2_KICKOFF.md §6A). Reaproveita 100% do
fluxo de desafio existente — o parágrafo-base vive no campo "prompt" já
existente, sem modelo/campo novo. Estes testes provam que o território
está de fato integrado (progresso, amostra grátis, resposta, dica).
"""

import uuid

import app.services as services_module

from .conftest import auth_header


def test_textos_territory_appears_in_progress(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    progress = client.get("/progress", headers=headers).json()
    territory_ids = {t["territory_id"] for t in progress["territories"]}
    assert "textos" in territory_ids


def test_textos_free_sample_then_lock(client, monkeypatch):
    # free_sample_count=2 (mesmo tier de logica/conhecimento/enigmas) — as
    # duas primeiras chamadas devem funcionar mesmo sem assinatura.
    monkeypatch.setattr(services_module.config, "MONETIZATION_ENABLED", True)
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    for _ in range(2):
        resp = client.get("/challenges/next", params={"territory_id": "textos"}, headers=headers)
        assert resp.status_code == 200
        challenge = resp.json()
        assert challenge["territory_id"] == "textos"
        assert "correct_answer" not in challenge
        client.post(
            f"/challenges/{challenge['challenge_id']}/answer",
            json={"attempt_id": challenge["attempt_id"], "submitted_answer": "qualquer coisa"},
            headers=headers,
        )

    locked_resp = client.get("/challenges/next", params={"territory_id": "textos"}, headers=headers)
    assert locked_resp.status_code == 403
    assert locked_resp.json()["error"]["code"] == "TERRITORY_LOCKED"


def test_textos_full_answer_and_hint_flow(client):
    from app.seed import CHALLENGES

    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    challenge = client.get("/challenges/next", params={"territory_id": "textos"}, headers=headers).json()
    # Confirma que o desafio de fato carrega um parágrafo-base (bem mais
    # longo que um enunciado de charada), não só uma pergunta curta.
    assert len(challenge["prompt"]) > 150

    correct = next(c["correct_answer"] for c in CHALLENGES if c["prompt"] == challenge["prompt"])
    attempt_id = challenge["attempt_id"]

    hint_resp = client.post(
        f"/challenges/{challenge['challenge_id']}/hint",
        json={"attempt_id": attempt_id},
        headers=headers,
    )
    assert hint_resp.status_code == 200
    assert "content" in hint_resp.json()

    answer_resp = client.post(
        f"/challenges/{challenge['challenge_id']}/answer",
        json={"attempt_id": attempt_id, "submitted_answer": correct},
        headers=headers,
    )
    result = answer_resp.json()
    assert result["is_correct"] is True
    assert result["hints_used"] == 1
    assert result["xp_awarded"] == round(result["xp_base"] * 0.75)
