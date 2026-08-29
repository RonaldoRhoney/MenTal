"""
V2 item 15 — Palavras Relâmpago (PALAVRAS_RELAMPAGO.md, aprovado
2026-08-22). Múltipla escolha com tempo regressivo, só em Palavras
médio/difícil. Reaproveita 100% o banco de desafios já curado — as
alternativas erradas são correct_answer REAIS de outros desafios do
mesmo território/nível, nunca geradas/inventadas.
"""

import uuid
from datetime import timedelta

from app import config, models
from app.db import SessionLocal
from app.timeutil import utcnow

from .conftest import auth_header


def test_relampago_mode_returns_three_options_and_time_limit(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    resp = client.get(
        "/challenges/next", params={"territory_id": "palavras", "mode": "relampago"}, headers=headers
    )
    body = resp.json()

    assert resp.status_code == 200
    assert len(body["options"]) == 3
    assert "correct_answer" not in body  # API_CONTRACT.md §3 continua valendo no modo relâmpago
    assert body["difficulty_level"] in (2, 3)  # nunca fácil, mesmo começando do nível 1
    assert body["time_limit_seconds"] == config.TIMED_MULTIPLE_CHOICE_TIME_LIMIT_SECONDS[body["difficulty_level"]]


def test_relampago_never_serves_easy_level_even_for_brand_new_user(client):
    # Usuário novo sem histórico começa no nível 1 (fácil) — modo
    # relâmpago precisa ignorar isso e nunca servir fácil.
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    for _ in range(10):
        resp = client.get(
            "/challenges/next", params={"territory_id": "palavras", "mode": "relampago"}, headers=headers
        )
        assert resp.json()["difficulty_level"] != 1


def test_relampago_options_include_correct_answer_from_seed(client):
    from app.seed import CHALLENGES

    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

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


def test_relampago_generalized_to_other_territories_with_curated_options(client):
    """
    Generalização (29/08/2026, pedido de Rhoney: "em todos os módulos
    tem que haver um relâmpago"): qualquer território com opções
    curadas (todos, exceto "palavras") ganha timer no modo relâmpago,
    reaproveitando as próprias opções curadas — sem sintetizar nada.
    """
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    body = client.get(
        "/challenges/next", params={"territory_id": "numeros", "mode": "relampago"}, headers=headers
    ).json()
    assert body["time_limit_seconds"] is not None
    assert len(body["options"]) >= 2
    assert "correct_answer" not in body


def test_relampago_speed_bonus_applies_to_generalized_territories_too(client):
    """
    Achado real (29/08/2026, pedido de Rhoney: "quanto menos tempo o
    jogador acertar melhor será seus pontos"): antes desta correção, o
    bônus de velocidade só valia pra "palavras"/"conhecimento" (allowlist
    fixa TIMED_MULTIPLE_CHOICE_TERRITORIES) — um território generalizado
    como "numeros" mostrava o timer no modo relâmpago mas nunca pagava
    bônus por resposta rápida. Corrigido: elegibilidade agora vem de
    attempt.timed (gravado pelo servidor em /next), não mais da lista
    fixa de territórios.
    """
    from app.seed import CHALLENGES

    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    ch = client.get("/challenges/next", params={"territory_id": "numeros", "mode": "relampago"}, headers=headers).json()
    correct = next(
        c["correct_answer"] for c in CHALLENGES
        if c["territory_id"] == "numeros" and c["prompt"] == ch["prompt"] and c["difficulty_level"] == ch["difficulty_level"]
    )
    fast_time = int(ch["time_limit_seconds"] * 1000 * 0.1)

    result = client.post(
        f"/challenges/{ch['challenge_id']}/answer",
        json={"attempt_id": ch["attempt_id"], "submitted_answer": correct, "response_time_ms": fast_time},
        headers=headers,
    ).json()

    from app import scoring

    xp_base = scoring.xp_base_for(ch["difficulty_level"])
    assert result["is_correct"] is True
    assert result["speed_bonus_xp"] == xp_base


def test_normal_mode_unaffected_no_time_limit(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

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
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)
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
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)
    ch, correct = _get_relampago_challenge_and_answer(client, headers)

    time_limit_ms = ch["time_limit_seconds"] * 1000
    fast_time = int(time_limit_ms * 0.1)  # bem dentro dos primeiros 30%

    # attempt_id precisa ser o mesmo devolvido por /next (não um uuid
    # qualquer) — só assim a tentativa carrega attempt.timed=True gravado
    # no momento em que o desafio foi servido. Achado real (29/08/2026,
    # ao generalizar o bônus de velocidade pra além da allowlist fixa de
    # territórios): um attempt_id inventado cai no fallback de
    # _get_or_create_pending_attempt, que cria a tentativa com
    # timed=False e mascarava esta asserção usando a checagem antiga.
    result = client.post(
        f"/challenges/{ch['challenge_id']}/answer",
        json={"attempt_id": ch["attempt_id"], "submitted_answer": correct, "response_time_ms": fast_time},
        headers=headers,
    ).json()

    from app import scoring

    xp_base = scoring.xp_base_for(ch["difficulty_level"])
    assert result["is_correct"] is True
    assert result["speed_bonus_xp"] == xp_base  # bônus máximo = 100% do xp_base
    assert result["xp_awarded"] == xp_base + xp_base


def test_slow_correct_answer_gets_no_speed_bonus_but_still_counts(client):
    """
    Achado de auditoria de segurança (28/08/2026): response_time_ms do
    corpo da requisição não alimenta mais o bônus de velocidade — o
    servidor calcula sozinho a partir de Attempt.served_at (gravado em
    GET /challenges/next), pra não confiar em nenhum valor que o client
    possa forjar. Pra simular uma resposta "lenta" de verdade neste
    teste, backdate served_at direto no banco.
    """
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)
    ch, correct = _get_relampago_challenge_and_answer(client, headers)

    time_limit_ms = ch["time_limit_seconds"] * 1000
    slow_time = int(time_limit_ms * 0.95)  # bem depois dos 70%

    with SessionLocal() as db:
        attempt = db.get(models.Attempt, ch["attempt_id"])
        attempt.served_at = utcnow() - timedelta(milliseconds=slow_time)
        db.commit()

    result = client.post(
        f"/challenges/{ch['challenge_id']}/answer",
        json={"attempt_id": ch["attempt_id"], "submitted_answer": correct},
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
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)
    ch, correct = _get_relampago_challenge_and_answer(client, headers)

    attempt_id = str(uuid.uuid4())
    time_limit_ms = ch["time_limit_seconds"] * 1000
    body = {"attempt_id": attempt_id, "submitted_answer": correct, "response_time_ms": int(time_limit_ms * 0.1)}

    first = client.post(f"/challenges/{ch['challenge_id']}/answer", json=body, headers=headers).json()
    second = client.post(f"/challenges/{ch['challenge_id']}/answer", json=body, headers=headers).json()

    assert first["speed_bonus_xp"] == second["speed_bonus_xp"]
    assert first["timed_out"] == second["timed_out"] == False
    assert first["xp_awarded"] == second["xp_awarded"]
