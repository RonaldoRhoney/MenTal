"""
V5/README.md — Mundo dos Idiomas: 9 territórios (inglês/espanhol/
francês x básico/intermediário/avançado), conteúdo carregado de
content/idiomas_*.json (app/seed.py). Cobre especificamente o que é
NOVO nesta feature — Challenge.accepted_answers e a comparação de
resposta em texto livre com variações aceitas — não repete o critério
de volume já coberto por test_content_volume.py.
"""

import uuid

from app.seed import CHALLENGES, TERRITORIES

from .conftest import auth_header

IDIOMAS_TERRITORY_IDS = {
    "ingles_basico", "ingles_intermediario", "ingles_avancado",
    "espanhol_basico", "espanhol_intermediario", "espanhol_avancado",
    "frances_basico", "frances_intermediario", "frances_avancado",
}


def test_all_nine_idiomas_territories_exist_in_seed():
    assert IDIOMAS_TERRITORY_IDS <= {t["id"] for t in TERRITORIES}
    for t in TERRITORIES:
        if t["id"] in IDIOMAS_TERRITORY_IDS:
            assert t["world_id"] == "idiomas"


def _find_frase_challenge(territory_id: str) -> dict:
    return next(
        c for c in CHALLENGES
        if c["territory_id"] == territory_id and c["options"] is None and c.get("accepted_answers")
    )


def test_submitting_an_accepted_variation_counts_as_correct(client):
    # O desafio de tradução aceita mais de uma resposta certa (ex.: com
    # ou sem ponto final) — submeter uma VARIAÇÃO (não o correct_answer
    # exato) precisa contar como acerto.
    challenge = _find_frase_challenge("ingles_basico")
    variation = challenge["accepted_answers"][0]
    assert variation != challenge["correct_answer"]

    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    served = None
    for _ in range(70):
        candidate = client.get("/challenges/next", params={"territory_id": "ingles_basico"}, headers=headers).json()
        if candidate["prompt"] == challenge["prompt"]:
            served = candidate
            break
    assert served is not None, "desafio de frase não sorteado em 70 tentativas — território sem esse item?"

    resp = client.post(
        f"/challenges/{served['challenge_id']}/answer",
        json={"attempt_id": served["attempt_id"], "submitted_answer": variation},
        headers=headers,
    )
    result = resp.json()
    assert resp.status_code == 200
    assert result["is_correct"] is True


def test_submitting_something_outside_correct_answer_and_variations_is_wrong(client):
    challenge = _find_frase_challenge("espanhol_basico")

    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    served = None
    for _ in range(70):
        candidate = client.get("/challenges/next", params={"territory_id": "espanhol_basico"}, headers=headers).json()
        if candidate["prompt"] == challenge["prompt"]:
            served = candidate
            break
    assert served is not None

    resp = client.post(
        f"/challenges/{served['challenge_id']}/answer",
        json={"attempt_id": served["attempt_id"], "submitted_answer": "resposta claramente errada"},
        headers=headers,
    )
    assert resp.json()["is_correct"] is False
