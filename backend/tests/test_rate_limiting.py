"""
Achado de auditoria de segurança M1 (05/09/2026): nenhum endpoint do
app tinha rate limiting — combinado com o oráculo de respostas (C1, já
corrigido), permitia varrer automaticamente todo o banco de conteúdo em
loop apertado. services.enforce_rate_limit() é aplicado nos endpoints
de pontuação/recompensa mais sensíveis; estes testes provam que o
limite de fato dispara (429 RATE_LIMIT_EXCEEDED) quando estourado, e
que se recupera depois que a janela passa.
"""

import time
import uuid

from app import config, services

from .conftest import auth_header


def test_answer_endpoint_is_rate_limited(client, monkeypatch):
    monkeypatch.setattr(config, "RATE_LIMIT_ANSWER_SUBMIT", (2, 60.0))
    services._rate_limit_hits.clear()

    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    def _answer_once():
        challenge = client.get("/challenges/next", params={"territory_id": "numeros"}, headers=headers).json()
        return client.post(
            f"/challenges/{challenge['challenge_id']}/answer",
            json={"attempt_id": challenge["attempt_id"], "submitted_answer": "__errado__"},
            headers=headers,
        )

    assert _answer_once().status_code == 200
    assert _answer_once().status_code == 200
    third = _answer_once()
    assert third.status_code == 429
    assert third.json()["error"]["code"] == "RATE_LIMIT_EXCEEDED"


def test_rate_limit_recovers_after_window_passes(monkeypatch):
    monkeypatch.setattr(config, "RATE_LIMIT_ANSWER_SUBMIT", (1, 60.0))
    services._rate_limit_hits.clear()

    fake_now = [1000.0]
    monkeypatch.setattr(time, "monotonic", lambda: fake_now[0])

    scope, user_id = "challenges_answer", str(uuid.uuid4())
    services.enforce_rate_limit(scope, user_id, max_calls=1, window_seconds=60.0)

    fake_now[0] += 30
    try:
        services.enforce_rate_limit(scope, user_id, max_calls=1, window_seconds=60.0)
        raised = False
    except services.RateLimitExceeded:
        raised = True
    assert raised is True

    fake_now[0] += 31  # total 61s desde a 1ª chamada — janela de 60s já passou
    services.enforce_rate_limit(scope, user_id, max_calls=1, window_seconds=60.0)


def test_rate_limit_scope_is_per_user(monkeypatch):
    monkeypatch.setattr(config, "RATE_LIMIT_ANSWER_SUBMIT", (1, 60.0))
    services._rate_limit_hits.clear()

    scope = "challenges_answer"
    user_a, user_b = str(uuid.uuid4()), str(uuid.uuid4())

    services.enforce_rate_limit(scope, user_a, max_calls=1, window_seconds=60.0)
    # Usuário diferente nunca é afetado pelo limite de outro.
    services.enforce_rate_limit(scope, user_b, max_calls=1, window_seconds=60.0)
