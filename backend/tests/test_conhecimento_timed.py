"""
CONHECIMENTO_EXPANSAO_GERAL.md (aprovado 2026-08-22): expande o mecanismo
de tempo regressivo do Palavras Relâmpago (opcional lá) pra Conhecimento,
onde vira o formato ÚNICO e OBRIGATÓRIO — nunca digitado, independente do
parâmetro "mode". Diferente de Palavras, Conhecimento já tem options
curadas de verdade por desafio (nunca sintetizadas de outros).
"""

import uuid

from app import config

from .conftest import auth_header


def test_conhecimento_always_returns_time_limit_even_without_mode_param(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers)

    body = client.get("/challenges/next", params={"territory_id": "conhecimento"}, headers=headers).json()
    assert body["time_limit_seconds"] is not None
    assert body["time_limit_seconds"] == config.TIMED_MULTIPLE_CHOICE_TIME_LIMIT_SECONDS[body["difficulty_level"]]


def test_conhecimento_easy_level_is_also_timed_unlike_palavras_relampago(client):
    """Diferente de Palavras Relâmpago (nunca fácil), Conhecimento não tem piso de nível."""
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers)

    saw_easy = False
    for _ in range(15):
        body = client.get("/challenges/next", params={"territory_id": "conhecimento"}, headers=headers).json()
        if body["difficulty_level"] == 1:
            saw_easy = True
            assert body["time_limit_seconds"] is not None
            break
    assert saw_easy, "esperava ver nível fácil em Conhecimento em 15 tentativas"


def test_conhecimento_options_are_the_real_curated_ones_not_synthesized(client):
    """As opções são as curadas de verdade (mesmo conjunto) — a ORDEM não
    precisa bater: é embaralhada a cada chamada (ver teste de shuffle
    abaixo), então comparar como conjunto é o correto aqui."""
    from app.seed import CHALLENGES

    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers)

    body = client.get("/challenges/next", params={"territory_id": "conhecimento"}, headers=headers).json()
    matching = next(
        c for c in CHALLENGES
        if c["territory_id"] == "conhecimento" and c["prompt"] == body["prompt"]
    )
    assert sorted(body["options"]) == sorted(matching["options"])


def test_shuffled_options_produces_different_orders_and_never_mutates_input():
    """Achado real (2026-08-23, teste informal): opções curadas vinham
    sempre na mesma ordem do conteúdo — dava pra decorar a posição da
    resposta certa em vez de saber o conteúdo. Testa a função pura
    diretamente (determinístico) em vez de depender do sorteio aleatório
    de desafio via HTTP."""
    from app import services

    original = ["Frio", "Morno", "Ardente", "Quieto"]
    orders_seen = {tuple(services.shuffled_options(original)) for _ in range(30)}

    assert len(orders_seen) > 1, "esperava ver mais de uma ordem em 30 chamadas (shuffle ausente?)"
    assert original == ["Frio", "Morno", "Ardente", "Quieto"], "shuffled_options não deve mutar a lista original"
    for order in orders_seen:
        assert sorted(order) == sorted(original)


def test_conhecimento_speed_bonus_applies_like_palavras(client):
    from app.seed import CHALLENGES

    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers)

    ch = client.get("/challenges/next", params={"territory_id": "conhecimento"}, headers=headers).json()
    correct = next(c["correct_answer"] for c in CHALLENGES if c["territory_id"] == "conhecimento" and c["prompt"] == ch["prompt"])

    fast_time = int(ch["time_limit_seconds"] * 1000 * 0.1)
    result = client.post(
        f"/challenges/{ch['challenge_id']}/answer",
        json={"attempt_id": str(uuid.uuid4()), "submitted_answer": correct, "response_time_ms": fast_time},
        headers=headers,
    ).json()

    from app import scoring

    xp_base = scoring.xp_base_for(ch["difficulty_level"])
    assert result["is_correct"] is True
    assert result["speed_bonus_xp"] == xp_base


def test_palavras_normal_mode_still_untimed_unaffected_by_generalization(client):
    """Reafirma que a generalização não tornou Palavras obrigatoriamente cronometrado."""
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers)

    body = client.get("/challenges/next", params={"territory_id": "palavras"}, headers=headers).json()
    assert body["time_limit_seconds"] is None
