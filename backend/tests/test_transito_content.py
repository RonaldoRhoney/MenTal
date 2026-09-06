"""
Mundo_do_Transito/README.md — Mundo do Trânsito: 5 territórios
(educacao_legislacao, historia_curiosidades, transportes_terrestres,
economia_transito, prevencao_seguranca), conteúdo carregado de
content/transito_*.json (app/seed.py). Mesmo formato "cápsula de texto
+ perguntas" do Mundo dos Valores — cobre o que é NOVO nesta feature,
não repete o critério de volume já coberto por test_content_volume.py.
"""

import uuid

from app.config import NEVER_TIMED_TERRITORY_IDS
from app.seed import CHALLENGES, TERRITORIES

from .conftest import auth_header

TRANSITO_TERRITORY_IDS = {
    "educacao_legislacao", "historia_curiosidades", "transportes_terrestres",
    "economia_transito", "prevencao_seguranca",
}


def test_all_five_transito_territories_exist_in_seed():
    assert TRANSITO_TERRITORY_IDS <= {t["id"] for t in TERRITORIES}
    for t in TERRITORIES:
        if t["id"] in TRANSITO_TERRITORY_IDS:
            assert t["world_id"] == "transito"


def test_every_transito_challenge_has_a_reading_passage():
    transito_challenges = [c for c in CHALLENGES if c["territory_id"] in TRANSITO_TERRITORY_IDS]
    assert len(transito_challenges) == 120
    for c in transito_challenges:
        assert c.get("reading_passage"), f"desafio sem reading_passage: {c['prompt']!r}"


def test_transito_territories_are_registered_as_never_timed():
    assert TRANSITO_TERRITORY_IDS <= NEVER_TIMED_TERRITORY_IDS


def test_reading_passage_is_served_before_the_question(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    resp = client.get("/challenges/next", params={"territory_id": "educacao_legislacao"}, headers=headers)
    assert resp.status_code == 200
    body = resp.json()
    assert body["reading_passage"]
    assert body["time_limit_seconds"] is None


def test_transito_challenge_is_never_timed_even_when_relampago_mode_is_requested(client):
    """Mesmo princípio de segurança já aplicado ao Mundo dos Valores: o
    backend nunca confia no client pra decidir isso, mesmo com
    mode=relampago pedido explicitamente."""
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    resp = client.get("/challenges/next", params={"territory_id": "prevencao_seguranca", "mode": "relampago"}, headers=headers)
    assert resp.status_code == 200
    assert resp.json()["time_limit_seconds"] is None


def test_answering_a_transito_challenge_correctly_works_like_any_normal_challenge(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    challenge = client.get("/challenges/next", params={"territory_id": "transportes_terrestres"}, headers=headers).json()
    correct = next(
        c["correct_answer"] for c in CHALLENGES
        if c["territory_id"] == "transportes_terrestres" and c["prompt"] == challenge["prompt"]
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
