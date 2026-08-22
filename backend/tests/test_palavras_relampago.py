"""
V2 item 15 — Palavras Relâmpago (PALAVRAS_RELAMPAGO.md, aprovado
2026-08-22). Múltipla escolha com tempo regressivo, só em Palavras
médio/difícil. Reaproveita 100% o banco de desafios já curado — as
alternativas erradas são correct_answer REAIS de outros desafios do
mesmo território/nível, nunca geradas/inventadas.
"""

import uuid

from app import config

from .conftest import auth_header


def test_relampago_mode_returns_three_options_and_time_limit(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers)

    resp = client.get(
        "/challenges/next", params={"territory_id": "palavras", "mode": "relampago"}, headers=headers
    )
    body = resp.json()

    assert resp.status_code == 200
    assert len(body["options"]) == 3
    assert "correct_answer" not in body  # API_CONTRACT.md §3 continua valendo no modo relâmpago
    assert body["difficulty_level"] in (2, 3)  # nunca fácil, mesmo começando do nível 1
    assert body["time_limit_seconds"] == config.PALAVRAS_RELAMPAGO_TIME_LIMIT_SECONDS[body["difficulty_level"]]


def test_relampago_never_serves_easy_level_even_for_brand_new_user(client):
    # Usuário novo sem histórico começa no nível 1 (fácil) — modo
    # relâmpago precisa ignorar isso e nunca servir fácil.
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers)

    for _ in range(10):
        resp = client.get(
            "/challenges/next", params={"territory_id": "palavras", "mode": "relampago"}, headers=headers
        )
        assert resp.json()["difficulty_level"] != 1


def test_relampago_options_include_correct_answer_from_seed(client):
    from app.seed import CHALLENGES

    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers)

    body = client.get(
        "/challenges/next", params={"territory_id": "palavras", "mode": "relampago"}, headers=headers
    ).json()

    matching = [
        c for c in CHALLENGES
        if c["territory_id"] == "palavras" and c["prompt"] == body["prompt"] and c["difficulty_level"] == body["difficulty_level"]
    ]
    assert len(matching) == 1
    assert matching[0]["correct_answer"] in body["options"]
    # As outras 2 opções são respostas REAIS de outros desafios do
    # mesmo nível — nunca texto inventado.
    same_level_answers = {
        c["correct_answer"] for c in CHALLENGES
        if c["territory_id"] == "palavras" and c["difficulty_level"] == body["difficulty_level"]
    }
    assert set(body["options"]).issubset(same_level_answers)


def test_other_territories_ignore_relampago_mode(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers)

    body = client.get(
        "/challenges/next", params={"territory_id": "numeros", "mode": "relampago"}, headers=headers
    ).json()
    assert body["time_limit_seconds"] is None


def test_normal_mode_unaffected_no_time_limit(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers)

    body = client.get("/challenges/next", params={"territory_id": "palavras"}, headers=headers).json()
    assert body["time_limit_seconds"] is None


def _get_relampago_challenge_and_answer(client, headers):
    from app.seed import CHALLENGES

    ch = client.get(
        "/challenges/next", params={"territory_id": "palavras", "mode": "relampago"}, headers=headers
    ).json()
    correct = next(
        c["correct_answer"] for c in CHALLENGES
        if c["territory_id"] == "palavras" and c["prompt"] == ch["prompt"] and c["difficulty_level"] == ch["difficulty_level"]
    )
    return ch, correct


def test_timed_out_never_counts_as_correct_even_if_submitted_answer_matches(client):
    """
    Defesa contra cliente malicioso/com bug: timed_out=True nunca confia
    em submitted_answer pra decidir acerto, mesmo que ele bata com a
    resposta certa.
    """
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers)
    ch, correct = _get_relampago_challenge_and_answer(client, headers)

    result = client.post(
        f"/challenges/{ch['challenge_id']}/answer",
        json={"attempt_id": str(uuid.uuid4()), "submitted_answer": correct, "timed_out": True},
        headers=headers,
    ).json()

    assert result["is_correct"] is False
    assert result["timed_out"] is True
    assert result["xp_awarded"] == 0
    assert result["speed_bonus_xp"] == 0


def test_fast_correct_answer_gets_max_speed_bonus(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers)
    ch, correct = _get_relampago_challenge_and_answer(client, headers)

    time_limit_ms = ch["time_limit_seconds"] * 1000
    fast_time = int(time_limit_ms * 0.1)  # bem dentro dos primeiros 30%

    result = client.post(
        f"/challenges/{ch['challenge_id']}/answer",
        json={"attempt_id": str(uuid.uuid4()), "submitted_answer": correct, "response_time_ms": fast_time},
        headers=headers,
    ).json()

    from app import scoring

    xp_base = scoring.xp_base_for(ch["difficulty_level"])
    assert result["is_correct"] is True
    assert result["speed_bonus_xp"] == xp_base  # bônus máximo = 100% do xp_base
    assert result["xp_awarded"] == xp_base + xp_base


def test_slow_correct_answer_gets_no_speed_bonus_but_still_counts(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers)
    ch, correct = _get_relampago_challenge_and_answer(client, headers)

    time_limit_ms = ch["time_limit_seconds"] * 1000
    slow_time = int(time_limit_ms * 0.95)  # bem depois dos 70%

    result = client.post(
        f"/challenges/{ch['challenge_id']}/answer",
        json={"attempt_id": str(uuid.uuid4()), "submitted_answer": correct, "response_time_ms": slow_time},
        headers=headers,
    ).json()

    from app import scoring

    xp_base = scoring.xp_base_for(ch["difficulty_level"])
    assert result["is_correct"] is True
    assert result["speed_bonus_xp"] == 0
    assert result["xp_awarded"] == xp_base


def test_idempotent_replay_returns_same_timed_out_and_speed_bonus(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers)
    ch, correct = _get_relampago_challenge_and_answer(client, headers)

    attempt_id = str(uuid.uuid4())
    time_limit_ms = ch["time_limit_seconds"] * 1000
    body = {"attempt_id": attempt_id, "submitted_answer": correct, "response_time_ms": int(time_limit_ms * 0.1)}

    first = client.post(f"/challenges/{ch['challenge_id']}/answer", json=body, headers=headers).json()
    second = client.post(f"/challenges/{ch['challenge_id']}/answer", json=body, headers=headers).json()

    assert first["speed_bonus_xp"] == second["speed_bonus_xp"]
    assert first["timed_out"] == second["timed_out"] == False
    assert first["xp_awarded"] == second["xp_awarded"]
