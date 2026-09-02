"""
V2 item 6 — Dificuldade adaptativa evoluída (V2_KICKOFF.md §2). A janela,
amostra mínima e limiares continuam os mesmos do Vertical Slice 01 — o
que evoluiu é o significado de "acerto": agora pondera pelo uso de dica
(reaproveitando scoring.hint_penalty_factor, a mesma fórmula já usada
para XP), não mais um binário correto/errado puro. Estes testes provam a
diferença de comportamento real entre a fórmula antiga (que estes
cenários teriam tratado como 100% de acerto) e a evoluída.
"""

import uuid

from .conftest import auth_header


def _answer(client, headers, territory_id, use_hints=0):
    from app.seed import CHALLENGES

    challenge = client.get("/challenges/next", params={"territory_id": territory_id}, headers=headers).json()
    attempt_id = challenge["attempt_id"]
    for _ in range(use_hints):
        client.post(f"/challenges/{challenge['challenge_id']}/hint", json={"attempt_id": attempt_id}, headers=headers)
    correct = next(
        c["correct_answer"]
        for c in CHALLENGES
        if c["prompt"] == challenge["prompt"] and sorted(c["options"]) == sorted(challenge["options"])
    )
    return client.post(
        f"/challenges/{challenge['challenge_id']}/answer",
        json={"attempt_id": attempt_id, "submitted_answer": correct},
        headers=headers,
    ).json()


def _current_difficulty(client, headers, territory_id):
    stats = client.get("/stats", headers=headers).json()
    return next(t for t in stats["by_territory"] if t["territory_id"] == territory_id)["current_difficulty_level"]


def test_heavy_hint_usage_does_not_count_as_full_mastery(client):
    # 3 respostas corretas (= ADAPTIVE_DIFFICULTY_MIN_SAMPLE), todas com 2
    # dicas cada — HINT_PENALTY_FACTOR=0.25, então cada uma vale
    # 1 - 0.25*2 = 0.5 de domínio, média 0.5. Isso fica ABAIXO de
    # ADAPTIVE_DIFFICULTY_UP_THRESHOLD (0.8): a fórmula antiga (acerto
    # binário) teria visto 100% de acerto aqui e subido de nível; a
    # evoluída não sobe, porque o jogador só acertou com muita ajuda.
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    for _ in range(3):
        result = _answer(client, headers, "numeros", use_hints=2)
        assert result["is_correct"] is True

    assert _current_difficulty(client, headers, "numeros") == 1


def test_hint_free_correct_answers_still_level_up_as_before(client):
    # Caso base inalterado pela evolução: acerto sem nenhuma dica sempre
    # valeu domínio 1.0, então 3 respostas assim ainda sobem de nível
    # exatamente como na fórmula original.
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    for _ in range(3):
        result = _answer(client, headers, "numeros", use_hints=0)
        assert result["is_correct"] is True

    assert _current_difficulty(client, headers, "numeros") == 2


def test_mixed_hint_usage_produces_intermediate_mastery(client):
    # 3 corretas: 1 sem dica (domínio 1.0), 1 com 1 dica (0.75), 1 com 2
    # dicas (0.5) — média = (1.0 + 0.75 + 0.5) / 3 = 0.75. Fica abaixo do
    # limiar de subida (0.8) mas não abaixo do de descida (0.4): mantém o
    # nível, nem sobe nem desce.
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    _answer(client, headers, "numeros", use_hints=0)
    _answer(client, headers, "numeros", use_hints=1)
    _answer(client, headers, "numeros", use_hints=2)

    assert _current_difficulty(client, headers, "numeros") == 1


def test_incorrect_answers_still_lower_difficulty_regardless_of_hints(client):
    # Erro sempre vale domínio 0.0, com ou sem dica usada antes de errar —
    # esse ponto não mudou com a evolução (mesma regra de scoring.py:
    # dica só afeta XP/domínio de resposta CORRETA). Sobe pra nível 2 com
    # 3 acertos limpos, depois confirma que uma janela ruim ainda desce:
    # com window=5, os 5 mais recentes após 3 corretas + 4 erradas são
    # [correta#3, errada, errada, errada, errada] → domínio médio 0.2,
    # abaixo do limiar de descida (0.4).
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    for _ in range(3):
        _answer(client, headers, "numeros", use_hints=0)
    assert _current_difficulty(client, headers, "numeros") == 2

    for _ in range(4):
        challenge = client.get("/challenges/next", params={"territory_id": "numeros"}, headers=headers).json()
        client.post(
            f"/challenges/{challenge['challenge_id']}/answer",
            json={"attempt_id": challenge["attempt_id"], "submitted_answer": "resposta-errada-de-propósito"},
            headers=headers,
        )

    assert _current_difficulty(client, headers, "numeros") == 1
