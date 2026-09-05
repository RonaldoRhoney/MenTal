"""
REGRA_REVISAO_ERROS_FIM_RODADA.md — GET /challenges/{id}/reattempt serve
de novo um desafio já visto (revisão de erro). A resposta nunca gera
XP/streak/badge/progresso de território ("apenas confirmar o
aprendizado") e nunca conta pro limite diário.

Achado de auditoria de segurança CRÍTICO (05/09/2026): o endpoint
aceitava reattempt de QUALQUER challenge_id, mesmo nunca servido/errado
pelo usuário, e o caminho is_review de POST /answer devolve
correct_answer/explanation sem consumir limite diário — um oráculo de
respostas de custo zero pra todo o banco de conteúdo. A correção exige
um Attempt real e recente deste usuário neste desafio com
is_correct=False antes de liberar o reattempt — todos os testes abaixo
precisam errar de propósito o desafio original primeiro.
"""

import uuid

from app import config, models
from app.db import SessionLocal

from .conftest import auth_header


def _answer_wrong(client, headers, challenge):
    """Responde de propósito com algo garantidamente incorreto, pra criar
    o Attempt(is_correct=False) que o reattempt agora exige."""
    return client.post(
        f"/challenges/{challenge['challenge_id']}/answer",
        json={"attempt_id": challenge["attempt_id"], "submitted_answer": "__resposta_propositalmente_errada__"},
        headers=headers,
    )


def test_reattempt_serves_the_same_challenge_with_a_fresh_attempt_id(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    original = client.get("/challenges/next", params={"territory_id": "numeros"}, headers=headers).json()
    _answer_wrong(client, headers, original)

    reattempted = client.get(f"/challenges/{original['challenge_id']}/reattempt", headers=headers).json()

    assert reattempted["challenge_id"] == original["challenge_id"]
    assert reattempted["prompt"] == original["prompt"]
    assert reattempted["attempt_id"] != original["attempt_id"]


def test_correct_answer_on_reattempt_grants_zero_xp_and_no_side_effects(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    from app.seed import CHALLENGES

    original = client.get("/challenges/next", params={"territory_id": "numeros"}, headers=headers).json()
    correct = next(
        c["correct_answer"] for c in CHALLENGES if c["territory_id"] == "numeros" and c["prompt"] == original["prompt"]
    )
    _answer_wrong(client, headers, original)

    with SessionLocal() as db:
        xp_before = db.get(models.Profile, user.replace("-", "")).xp_total

    reattempted = client.get(f"/challenges/{original['challenge_id']}/reattempt", headers=headers).json()
    resp = client.post(
        f"/challenges/{reattempted['challenge_id']}/answer",
        json={"attempt_id": reattempted["attempt_id"], "submitted_answer": correct},
        headers=headers,
    )
    result = resp.json()

    assert resp.status_code == 200
    assert result["is_correct"] is True
    assert result["xp_awarded"] == 0
    assert result["batch_exhausted"] is False

    with SessionLocal() as db:
        xp_after = db.get(models.Profile, user.replace("-", "")).xp_total
    assert xp_after == xp_before


def test_reattempt_never_counts_toward_daily_limit(client, monkeypatch):
    monkeypatch.setattr(config, "DAILY_FREE_CHALLENGE_LIMIT", 1)
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    from app.seed import CHALLENGES

    original = client.get("/challenges/next", params={"territory_id": "numeros"}, headers=headers).json()
    correct = next(
        c["correct_answer"] for c in CHALLENGES if c["territory_id"] == "numeros" and c["prompt"] == original["prompt"]
    )
    # Consome o único slot diário disponível errando de propósito o
    # desafio normal (o limite é consumido por qualquer tentativa NOVA,
    # certa ou errada) — e já cria o Attempt(is_correct=False) exigido
    # pelo reattempt.
    _answer_wrong(client, headers, original)

    # Mesmo com o limite diário esgotado, revisar o mesmo desafio (via
    # reattempt) continua funcionando — nunca é bloqueado por
    # DAILY_LIMIT_REACHED, porque não é um desafio "novo".
    reattempted = client.get(f"/challenges/{original['challenge_id']}/reattempt", headers=headers)
    assert reattempted.status_code == 200

    answer_resp = client.post(
        f"/challenges/{original['challenge_id']}/answer",
        json={"attempt_id": reattempted.json()["attempt_id"], "submitted_answer": correct},
        headers=headers,
    )
    assert answer_resp.status_code == 200


def test_reattempt_of_unknown_challenge_returns_404(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    resp = client.get("/challenges/00000000-0000-0000-0000-000000000000/reattempt", headers=headers)
    assert resp.status_code == 404


def test_reattempt_of_challenge_never_gotten_wrong_is_rejected(client):
    """Regressão do achado CRÍTICO de 05/09/2026 — sem nunca ter errado
    (nem sequer jogado) um desafio, reattempt não pode virar um oráculo
    de resposta de graça."""
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    original = client.get("/challenges/next", params={"territory_id": "numeros"}, headers=headers).json()

    resp = client.get(f"/challenges/{original['challenge_id']}/reattempt", headers=headers)
    assert resp.status_code == 403
    assert resp.json()["error"]["code"] == "REVIEW_NOT_ALLOWED"


def test_reattempt_of_challenge_answered_correctly_is_also_rejected(client):
    """Ter acertado de primeira não dá direito a reattempt — só erro
    real qualifica pra revisão."""
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    from app.seed import CHALLENGES

    original = client.get("/challenges/next", params={"territory_id": "numeros"}, headers=headers).json()
    correct = next(
        c["correct_answer"] for c in CHALLENGES if c["territory_id"] == "numeros" and c["prompt"] == original["prompt"]
    )
    client.post(
        f"/challenges/{original['challenge_id']}/answer",
        json={"attempt_id": original["attempt_id"], "submitted_answer": correct},
        headers=headers,
    )

    resp = client.get(f"/challenges/{original['challenge_id']}/reattempt", headers=headers)
    assert resp.status_code == 403
    assert resp.json()["error"]["code"] == "REVIEW_NOT_ALLOWED"


def test_search_vector_cannot_be_used_as_reattempt_oracle(client):
    """APROVACAO_CORRECOES_PRE_AAB_V1.md §1.1 — /challenges/search deixa
    escolher DIRIGIDAMENTE qual desafio será servido; sem nunca ter
    errado esse desafio, reattempt continua bloqueado mesmo vindo por
    esse caminho."""
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    from app.seed import CHALLENGES

    sample = next(c for c in CHALLENGES if c["territory_id"] == "numeros")
    needle = sample["prompt"][:12]

    found = client.get("/challenges/search", params={"q": needle}, headers=headers).json()
    assert found["found"] is True

    resp = client.get(f"/challenges/{found['challenge']['challenge_id']}/reattempt", headers=headers)
    assert resp.status_code == 403
    assert resp.json()["error"]["code"] == "REVIEW_NOT_ALLOWED"


def test_battle_opponent_challenge_cannot_be_used_as_reattempt_oracle(client):
    """APROVACAO_CORRECOES_PRE_AAB_V1.md §1.1 — GET /battles/{id}/
    my-challenge devolve o challenge_id do lado do oponente; sem esse
    lado ter errado de verdade, reattempt continua bloqueado."""
    user_a, user_b = str(uuid.uuid4()), str(uuid.uuid4())
    headers_a = auth_header(user_a)
    headers_b = auth_header(user_b)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers_a)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers_b)
    code = client.get("/social/invite-code", headers=headers_a).json()["invite_code"]
    client.post("/social/friends", json={"invite_code": code}, headers=headers_b)
    friendship_id = client.get("/social/friend-requests", headers=headers_a).json()["requests"][0]["friendship_id"]
    client.post(f"/social/friend-requests/{friendship_id}/accept", headers=headers_a)

    battle = client.post(
        "/battles",
        json={"opponent_user_id": user_b, "territory_id": "palavras", "difficulty_level": 1},
        headers=headers_a,
    ).json()

    opponent_challenge = client.get(f"/battles/{battle['battle_id']}/my-challenge", headers=headers_b).json()

    resp = client.get(f"/challenges/{opponent_challenge['challenge_id']}/reattempt", headers=headers_b)
    assert resp.status_code == 403
    assert resp.json()["error"]["code"] == "REVIEW_NOT_ALLOWED"


def test_reattempt_cannot_chain_off_a_previous_review_attempt(client):
    """Um Attempt is_review=True não pode, por si só, qualificar um NOVO
    reattempt — só um erro real (is_review=False) conta."""
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    original = client.get("/challenges/next", params={"territory_id": "numeros"}, headers=headers).json()
    _answer_wrong(client, headers, original)

    first_review = client.get(f"/challenges/{original['challenge_id']}/reattempt", headers=headers).json()
    client.post(
        f"/challenges/{original['challenge_id']}/answer",
        json={"attempt_id": first_review["attempt_id"], "submitted_answer": "__ainda_errado__"},
        headers=headers,
    )

    # Continua permitido, mas por causa do erro ORIGINAL (is_review=False)
    # dentro da janela de recência, não por causa do erro na revisão.
    second_review = client.get(f"/challenges/{original['challenge_id']}/reattempt", headers=headers)
    assert second_review.status_code == 200
