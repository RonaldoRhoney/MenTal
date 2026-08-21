"""
V2 item 1 — Badges/Conquistas (V2_KICKOFF.md §6A). Cada avaliador em
services.py lê dado que já existe (Attempt, UserTerritoryProgress,
Streak) — estes testes provam que a concessão de verdade acontece a
partir de ações reais do jogador, não apenas que o catálogo existe.
"""

import uuid

from .conftest import auth_header


def _answer_correctly(client, headers, territory_id, use_hint=False):
    from app.seed import CHALLENGES

    challenge = client.get("/challenges/next", params={"territory_id": territory_id}, headers=headers).json()
    correct = next(c["correct_answer"] for c in CHALLENGES if c["prompt"] == challenge["prompt"])
    attempt_id = str(uuid.uuid4())
    if use_hint:
        client.post(f"/challenges/{challenge['challenge_id']}/hint", json={"attempt_id": attempt_id}, headers=headers)
    return client.post(
        f"/challenges/{challenge['challenge_id']}/answer",
        json={"attempt_id": attempt_id, "submitted_answer": correct},
        headers=headers,
    ).json()


def test_badges_catalog_starts_unearned(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers)

    badges = client.get("/badges", headers=headers).json()["badges"]
    codes = {b["code"] for b in badges}
    assert codes == {"first_conquest", "collector", "iron_streak", "sharp_mind", "no_help_needed"}
    assert all(b["earned"] is False and b["earned_at"] is None for b in badges)


def test_first_conquest_badge_awarded_when_territory_conquered(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers)

    # CONQUEST_XP_THRESHOLD=200, XP base varia por dificuldade — repete até
    # conquistar (teto de 20 tentativas, bem acima do necessário na prática).
    for _ in range(20):
        progress = client.get("/progress", headers=headers).json()
        palavras = next(t for t in progress["territories"] if t["territory_id"] == "palavras")
        if palavras["conquered"]:
            break
        _answer_correctly(client, headers, "palavras")

    badges = client.get("/badges", headers=headers).json()["badges"]
    first_conquest = next(b for b in badges if b["code"] == "first_conquest")
    assert first_conquest["earned"] is True
    assert first_conquest["earned_at"] is not None


def test_no_help_needed_badge_awarded_after_10_hint_free_corrects(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers)

    for _ in range(10):
        result = _answer_correctly(client, headers, "numeros", use_hint=False)
        assert result["is_correct"] is True
        assert result["hints_used"] == 0

    badges = client.get("/badges", headers=headers).json()["badges"]
    badge = next(b for b in badges if b["code"] == "no_help_needed")
    assert badge["earned"] is True


def test_sharp_mind_badge_requires_50_correct_answers(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers)
    # Bypassa o limite diário (24) via assinatura ativa — só pra viabilizar
    # o teste; a regra de negócio do limite não é o que está sendo testado.
    client.post("/subscription/parental-gate", headers=headers)
    client.post("/subscription/validate-receipt", json={"purchase_token": "TEST_TOKEN_VALID"}, headers=headers)

    for _ in range(49):
        _answer_correctly(client, headers, "numeros")

    badges_before = client.get("/badges", headers=headers).json()["badges"]
    assert next(b for b in badges_before if b["code"] == "sharp_mind")["earned"] is False

    _answer_correctly(client, headers, "numeros")  # 50ª resposta correta

    badges_after = client.get("/badges", headers=headers).json()["badges"]
    assert next(b for b in badges_after if b["code"] == "sharp_mind")["earned"] is True
