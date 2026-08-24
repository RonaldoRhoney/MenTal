"""
MICROINTERACTIONS.md — sinais de evento raro/significativo na resposta de
/challenges/{id}/answer (level_up, territory_just_conquered,
streak_just_extended, newly_awarded_badges). O backend é a única
autoridade sobre "isso realmente acabou de acontecer" — estes testes
provam a TRANSIÇÃO exata (dispara uma vez, nunca de novo depois), não só
o estado absoluto.
"""

import uuid

from .conftest import auth_header


def _answer_correctly(client, headers, territory_id):
    from app.seed import CHALLENGES

    challenge = client.get("/challenges/next", params={"territory_id": territory_id}, headers=headers).json()
    correct = next(c["correct_answer"] for c in CHALLENGES if c["prompt"] == challenge["prompt"] and (challenge["options"] is None or sorted(c["options"] or []) == sorted(challenge["options"])))
    attempt_id = str(uuid.uuid4())
    return client.post(
        f"/challenges/{challenge['challenge_id']}/answer",
        json={"attempt_id": attempt_id, "submitted_answer": correct},
        headers=headers,
    ).json()


def test_streak_just_extended_only_on_first_play_of_the_day(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    first = _answer_correctly(client, headers, "numeros")
    assert first["streak_just_extended"] is True

    # Segundo desafio no MESMO dia — streak já contabilizado, não é um
    # evento novo, não deve celebrar de novo.
    second = _answer_correctly(client, headers, "numeros")
    assert second["streak_just_extended"] is False


def test_territory_just_conquered_fires_once_at_the_exact_threshold(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    conquered_events = []
    for _ in range(20):
        progress = client.get("/progress", headers=headers).json()
        palavras = next(t for t in progress["territories"] if t["territory_id"] == "palavras")
        if palavras["conquered"]:
            break
        result = _answer_correctly(client, headers, "palavras")
        conquered_events.append(result["territory_just_conquered"])

    # A conquista dispara exatamente uma vez, na resposta que cruza o
    # limiar — nunca antes, nunca de novo depois (embora o loop pare assim
    # que conquered=True, então não há "depois" pra testar aqui além de
    # garantir que não disparou mais de uma vez até esse ponto).
    assert conquered_events.count(True) == 1


def _answer_wrong(client, headers, territory_id):
    challenge = client.get("/challenges/next", params={"territory_id": territory_id}, headers=headers).json()
    attempt_id = str(uuid.uuid4())
    return client.post(
        f"/challenges/{challenge['challenge_id']}/answer",
        json={"attempt_id": attempt_id, "submitted_answer": "resposta errada de propósito"},
        headers=headers,
    ).json()


def test_wrong_answer_after_conquest_never_shows_false_positive_conquered(client):
    """
    Achado real testando no aparelho (2026-08-22): was_conquered_before só
    era recalculado dentro do bloco `if is_correct`, então uma resposta
    ERRADA a um território JÁ conquistado antes ficava com
    was_conquered_before preso em False — territory_just_conquered dava
    um falso positivo, mostrando "Território conquistado!" numa resposta
    errada, num território conquistado há muito tempo.
    """
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    for _ in range(20):
        progress = client.get("/progress", headers=headers).json()
        palavras = next(t for t in progress["territories"] if t["territory_id"] == "palavras")
        if palavras["conquered"]:
            break
        _answer_correctly(client, headers, "palavras")

    wrong = _answer_wrong(client, headers, "palavras")
    assert wrong["is_correct"] is False
    assert wrong["territory_just_conquered"] is False


def test_newly_awarded_badges_included_once_in_answer_response(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    results = []
    for _ in range(10):
        results.append(_answer_correctly(client, headers, "numeros"))

    badge_events = [r["newly_awarded_badges"] for r in results if r["newly_awarded_badges"]]
    # no_help_needed dispara na 10ª resposta correta sem dica — deve
    # aparecer em newly_awarded_badges exatamente uma vez ao longo dos 10.
    codes = [b["code"] for event in badge_events for b in event]
    assert codes.count("no_help_needed") == 1


def test_level_up_true_only_on_the_answer_that_crosses_the_level_boundary(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)
    # Bypassa o limite diário pra viabilizar XP suficiente pra subir de
    # nível (XP_PER_LEVEL=100) sem depender da regra de negócio do limite.
    client.post("/subscription/parental-gate", headers=headers)
    client.post("/subscription/validate-receipt", json={"purchase_token": "TEST_TOKEN_VALID"}, headers=headers)

    level_up_events = []
    for _ in range(15):
        progress = client.get("/progress", headers=headers).json()
        if progress["level"] >= 2:
            break
        result = _answer_correctly(client, headers, "numeros")
        level_up_events.append(result["level_up"])

    assert level_up_events.count(True) == 1


def test_new_level_only_populated_when_level_up_is_true(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)
    client.post("/subscription/parental-gate", headers=headers)
    client.post("/subscription/validate-receipt", json={"purchase_token": "TEST_TOKEN_VALID"}, headers=headers)

    for _ in range(15):
        progress = client.get("/progress", headers=headers).json()
        if progress["level"] >= 2:
            break
        result = _answer_correctly(client, headers, "numeros")
        if result["level_up"]:
            assert result["new_level"] == 2
        else:
            assert result["new_level"] is None
