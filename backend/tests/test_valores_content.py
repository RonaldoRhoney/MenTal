"""
V6/README.md — Mundo dos Valores: 4 territórios (bolsa, criptomoedas,
cenario_global, financas_dia_a_dia), conteúdo carregado de
content/valores_*.json (app/seed.py). Cobre o que é NOVO nesta feature
— Challenge.reading_passage e a exigência de NUNCA cronometrado, mesmo
se o client pedir mode=relampago — não repete o critério de volume já
coberto por test_content_volume.py.
"""

import uuid

from app.config import NEVER_TIMED_TERRITORY_IDS
from app.seed import CHALLENGES, TERRITORIES

from .conftest import auth_header

VALORES_TERRITORY_IDS = {"bolsa", "criptomoedas", "cenario_global", "financas_dia_a_dia"}


def test_all_four_valores_territories_exist_in_seed():
    assert VALORES_TERRITORY_IDS <= {t["id"] for t in TERRITORIES}
    for t in TERRITORIES:
        if t["id"] in VALORES_TERRITORY_IDS:
            assert t["world_id"] == "valores"


def test_every_valores_challenge_has_a_reading_passage():
    valores_challenges = [c for c in CHALLENGES if c["territory_id"] in VALORES_TERRITORY_IDS]
    assert len(valores_challenges) == 159
    for c in valores_challenges:
        assert c.get("reading_passage"), f"desafio sem reading_passage: {c['prompt']!r}"


def test_valores_territories_are_registered_as_never_timed():
    assert VALORES_TERRITORY_IDS == NEVER_TIMED_TERRITORY_IDS


def test_reading_passage_is_served_before_the_question(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    resp = client.get("/challenges/next", params={"territory_id": "bolsa"}, headers=headers)
    assert resp.status_code == 200
    body = resp.json()
    assert body["reading_passage"]
    assert body["time_limit_seconds"] is None


def test_valores_challenge_is_never_timed_even_when_relampago_mode_is_requested(client):
    """Achado de auditoria de segurança (mesmo espírito de C1/A1, 05/09/2026):
    o backend nunca pode confiar no client pra decidir isso — mode=relampago
    pedido explicitamente não pode cronometrar um território de
    NEVER_TIMED_TERRITORY_IDS."""
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    resp = client.get("/challenges/next", params={"territory_id": "criptomoedas", "mode": "relampago"}, headers=headers)
    assert resp.status_code == 200
    assert resp.json()["time_limit_seconds"] is None


def test_answering_a_valores_challenge_correctly_works_like_any_normal_challenge(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    challenge = client.get("/challenges/next", params={"territory_id": "financas_dia_a_dia"}, headers=headers).json()
    correct = next(
        c["correct_answer"] for c in CHALLENGES
        if c["territory_id"] == "financas_dia_a_dia" and c["prompt"] == challenge["prompt"]
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
