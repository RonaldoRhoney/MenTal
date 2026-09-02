"""
V4 — Detetive Mental (V4/V4_NOVOS_TERRITORIOS.md §4). Primeiro bloco a
mudar a ESTRUTURA do desafio: 2-3 pistas ("clues") vêm na resposta de
GET /challenges/next, além do prompt/options normais — o client decide
como/quando revelar cada uma, mas quem entrega o CONTEÚDO das pistas é
sempre o backend (mesmo princípio de "autoridade do servidor" de todo
o resto do app). Território normal de MCQ em tudo o mais: XP, hint,
resposta e Relâmpago funcionam exatamente como qualquer outro território.
"""

import uuid

from .conftest import auth_header


def test_next_challenge_includes_clues_for_detetive_mental(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    resp = client.get("/challenges/next", params={"territory_id": "detetive_mental"}, headers=headers)
    body = resp.json()

    assert resp.status_code == 200
    assert isinstance(body["clues"], list)
    assert 2 <= len(body["clues"]) <= 3
    assert all(isinstance(c, str) and c.strip() for c in body["clues"])
    assert body["options"] is not None
    assert len(body["options"]) == 4


def test_next_challenge_omits_clues_for_regular_territories(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    resp = client.get("/challenges/next", params={"territory_id": "numeros"}, headers=headers)
    body = resp.json()

    assert resp.status_code == 200
    assert body["clues"] is None


def test_detetive_mental_relampago_mode_still_includes_clues(client):
    """As pistas continuam vindo mesmo no modo Relâmpago (cronômetro) —
    é o client quem decide adiar o início da contagem até a pergunta
    aparecer, o backend não muda o que entrega por causa do modo."""
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    resp = client.get(
        "/challenges/next", params={"territory_id": "detetive_mental", "mode": "relampago"}, headers=headers
    )
    body = resp.json()

    assert resp.status_code == 200
    assert isinstance(body["clues"], list)
    assert body["time_limit_seconds"] is not None


def test_detetive_mental_answer_flow_works_like_any_other_mcq_territory(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    from app.seed import CHALLENGES

    challenge = client.get("/challenges/next", params={"territory_id": "detetive_mental"}, headers=headers).json()
    correct = next(
        c["correct_answer"]
        for c in CHALLENGES
        if c["territory_id"] == "detetive_mental" and c["prompt"] == challenge["prompt"]
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
