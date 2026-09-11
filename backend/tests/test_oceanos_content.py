"""
Mundo_dos_Oceanos/README.md — Mundo dos Oceanos: 5 territórios
(oceano_mundo, oceano_vida_marinha, oceano_profundezas, oceano_clima,
oceano_brasil), conteúdo carregado de content/oceanos_*.json
(app/seed.py). Mesmo formato "cápsula de texto + perguntas" de
Valores/Trânsito/Gastronomia — cobre o que é NOVO nesta feature, não
repete o critério de volume já coberto por test_content_volume.py.
"""

import uuid

from app.config import NEVER_TIMED_TERRITORY_IDS
from app.seed import CHALLENGES, TERRITORIES

from .conftest import auth_header

OCEANOS_TERRITORY_IDS = {
    "oceano_mundo", "oceano_vida_marinha", "oceano_profundezas",
    "oceano_clima", "oceano_brasil",
}


def test_all_five_oceanos_territories_exist_in_seed():
    assert OCEANOS_TERRITORY_IDS <= {t["id"] for t in TERRITORIES}
    for t in TERRITORIES:
        if t["id"] in OCEANOS_TERRITORY_IDS:
            assert t["world_id"] == "oceanos"


def test_every_oceanos_challenge_has_a_reading_passage():
    oceanos_challenges = [c for c in CHALLENGES if c["territory_id"] in OCEANOS_TERRITORY_IDS]
    assert len(oceanos_challenges) == 120
    for c in oceanos_challenges:
        assert c.get("reading_passage"), f"desafio sem reading_passage: {c['prompt']!r}"


def test_oceanos_territories_are_registered_as_never_timed():
    assert OCEANOS_TERRITORY_IDS <= NEVER_TIMED_TERRITORY_IDS


def test_reading_passage_is_served_before_the_question(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    resp = client.get("/challenges/next", params={"territory_id": "oceano_mundo"}, headers=headers)
    assert resp.status_code == 200
    body = resp.json()
    assert body["reading_passage"]
    assert body["time_limit_seconds"] is None


def test_oceanos_challenge_is_never_timed_even_when_relampago_mode_is_requested(client):
    """Mesmo princípio de segurança já aplicado a Valores/Trânsito/
    Gastronomia: o backend nunca confia no client pra decidir isso,
    mesmo com mode=relampago pedido explicitamente."""
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    resp = client.get("/challenges/next", params={"territory_id": "oceano_profundezas", "mode": "relampago"}, headers=headers)
    assert resp.status_code == 200
    assert resp.json()["time_limit_seconds"] is None


def test_answering_a_oceanos_challenge_correctly_works_like_any_normal_challenge(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    challenge = client.get("/challenges/next", params={"territory_id": "oceano_brasil"}, headers=headers).json()
    correct = next(
        c["correct_answer"] for c in CHALLENGES
        if c["territory_id"] == "oceano_brasil" and c["prompt"] == challenge["prompt"]
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
