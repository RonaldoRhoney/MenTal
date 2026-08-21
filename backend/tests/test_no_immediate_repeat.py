"""
Regressão: achado testando no celular real (2026-08-20) — "Próximo
desafio" retornava o mesmo desafio respondido, com chance alta (~50% com
2 candidatos por nível de dificuldade). Causa raiz: random.choice puro no
sorteio de GET /challenges/next, sem excluir o último desafio já servido.
Confirmado com 20 chamadas manuais seguidas, saiu sequência de 5 iguais.

Corrigido em routers/challenges.py: exclui o challenge_id do Attempt mais
recente do usuário naquele território do pool de candidatos, só quando
sobra pelo menos 1 outro — nunca bloqueia o único desafio existente.
"""

import uuid

from .conftest import auth_header


def test_next_challenge_never_immediately_repeats_when_alternative_exists(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers)

    # 'palavras' difficulty_level=1 tem 2 candidatos no seed — suficiente
    # para provar a regra sem depender do volume de conteúdo real.
    previous_id = None
    for _ in range(10):
        resp = client.get("/challenges/next", params={"territory_id": "palavras"}, headers=headers)
        assert resp.status_code == 200
        challenge = resp.json()
        current_id = challenge["challenge_id"]

        if previous_id is not None:
            assert current_id != previous_id, "repetiu o desafio imediatamente anterior, havendo alternativa"

        client.post(
            f"/challenges/{current_id}/answer",
            json={"attempt_id": str(uuid.uuid4()), "submitted_answer": "qualquer"},
            headers=headers,
        )
        previous_id = current_id


def test_next_challenge_still_works_with_single_candidate(client):
    # 'logica' tem só 1 desafio na dificuldade mais alta do seed atual —
    # a regra de "não repetir" não pode bloquear o único candidato
    # existente (senão o endpoint quebraria com NO_CHALLENGES_AVAILABLE
    # mesmo tendo conteúdo).
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers)

    for _ in range(3):
        resp = client.get("/challenges/next", params={"territory_id": "numeros"}, headers=headers)
        assert resp.status_code == 200
        challenge = resp.json()
        client.post(
            f"/challenges/{challenge['challenge_id']}/answer",
            json={"attempt_id": str(uuid.uuid4()), "submitted_answer": "qualquer"},
            headers=headers,
        )
