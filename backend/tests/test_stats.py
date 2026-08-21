"""
V2 item 5 — Estatísticas (V2_KICKOFF.md §6A). GET /stats agrega dado que
já existe (Attempt, UserTerritoryProgress, Streak, Badge) — nenhuma
contagem nova é persistida só para esta tela. Estes testes provam que os
números batem com ações reais do jogador, não só que o endpoint responde.
"""

import uuid
from datetime import datetime, timedelta

from .conftest import auth_header


def _answer(client, headers, territory_id, correct=True, use_hint=False):
    from app.seed import CHALLENGES

    challenge = client.get("/challenges/next", params={"territory_id": territory_id}, headers=headers).json()
    attempt_id = str(uuid.uuid4())
    if use_hint:
        client.post(f"/challenges/{challenge['challenge_id']}/hint", json={"attempt_id": attempt_id}, headers=headers)
    if correct:
        answer = next(c["correct_answer"] for c in CHALLENGES if c["prompt"] == challenge["prompt"] and c["options"] == challenge["options"])
    else:
        answer = "resposta-errada-de-propósito"
    return client.post(
        f"/challenges/{challenge['challenge_id']}/answer",
        json={"attempt_id": attempt_id, "submitted_answer": answer},
        headers=headers,
    ).json()


def test_stats_starts_zeroed_for_new_user(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers)

    stats = client.get("/stats", headers=headers).json()
    assert stats["xp_total"] == 0
    assert stats["level"] == 1
    assert stats["total_attempts"] == 0
    assert stats["accuracy"] == 0.0
    assert stats["current_streak"] == 0
    assert stats["longest_streak"] == 0
    assert stats["badges_earned"] == 0
    assert stats["badges_total"] == 5
    territory_ids = {t["territory_id"] for t in stats["by_territory"]}
    assert "numeros" in territory_ids and "visual" in territory_ids


def test_stats_reflects_real_correct_and_incorrect_answers(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers)

    _answer(client, headers, "numeros", correct=True)
    _answer(client, headers, "numeros", correct=False)
    _answer(client, headers, "numeros", correct=True, use_hint=True)

    stats = client.get("/stats", headers=headers).json()
    assert stats["total_attempts"] == 3
    assert stats["total_correct"] == 2
    assert stats["accuracy"] == 2 / 3
    assert stats["total_hints_used"] == 1
    # 2 corretas, mas só 1 sem dica (a segunda correta usou 1 dica).
    assert stats["hint_free_correct"] == 1

    numeros_stats = next(t for t in stats["by_territory"] if t["territory_id"] == "numeros")
    assert numeros_stats["total_attempts"] == 3
    assert numeros_stats["total_correct"] == 2
    assert numeros_stats["accuracy"] == 2 / 3


def test_stats_current_difficulty_level_matches_next_challenge_logic(client):
    # A dificuldade em /stats precisa vir exatamente da mesma função que
    # /challenges/next usa (services.pick_difficulty_for), não de uma
    # cópia que pode divergir. Só 3 respostas (= ADAPTIVE_DIFFICULTY_MIN_SAMPLE)
    # de propósito: sobe de 1 pra 2, nível pra que "numeros" tem conteúdo
    # real no seed — subir além disso faria /challenges/next cair no
    # fallback de "sem candidato nesse nível, sorteia de outro" (gap de
    # conteúdo já conhecido e fora do escopo deste item, ver item 7 do
    # V2_KICKOFF), que tornaria a comparação direta inválida.
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers)

    for _ in range(3):
        _answer(client, headers, "numeros", correct=True)

    stats = client.get("/stats", headers=headers).json()
    numeros_stats = next(t for t in stats["by_territory"] if t["territory_id"] == "numeros")
    assert numeros_stats["current_difficulty_level"] == 2

    next_challenge = client.get("/challenges/next", params={"territory_id": "numeros"}, headers=headers).json()
    assert numeros_stats["current_difficulty_level"] == next_challenge["difficulty_level"]


def test_stats_badges_earned_reflects_real_grant(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers)

    for _ in range(10):
        _answer(client, headers, "numeros", correct=True)

    stats = client.get("/stats", headers=headers).json()
    # no_help_needed dispara na 10ª resposta correta sem dica.
    assert stats["badges_earned"] >= 1


def test_current_streak_never_exceeds_longest_streak(client):
    # Invariante lógica: a sequência atual é sempre parte da sequência
    # mais longa já vivida, então current_streak > longest_streak é
    # sempre um bug. Achado real implementando este item: Attempt.created_at
    # é gravado em UTC (datetime.utcnow()) mas o limite diário/streak
    # usava date.today() (fuso LOCAL do servidor) — perto da virada do
    # dia, os dois discordavam sobre "qual dia é hoje" e produziam esse
    # exato cenário impossível. Corrigido padronizando os dois em UTC.
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers)

    for _ in range(3):
        _answer(client, headers, "numeros", correct=True)

    stats = client.get("/stats", headers=headers).json()
    assert stats["current_streak"] <= stats["longest_streak"]


def test_stats_longest_streak_survives_a_broken_streak(client):
    # "Sequência mais longa" é derivada de Attempt.created_at (services.py
    # _longest_streak_ever) — mais simples e robusto testar reescrevendo
    # os timestamps direto no banco de teste do que tentar congelar
    # date.today() dentro do módulo (que é chamado no router, não em
    # services.py, e re-implementar esse encadeamento só pro teste
    # adicionaria acoplamento que não existe no código real).
    import sqlite3

    from app import config

    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers)

    for _ in range(4):
        _answer(client, headers, "numeros", correct=True)

    db_path = config.DATABASE_URL.removeprefix("sqlite:///")
    con = sqlite3.connect(db_path)
    cur = con.cursor()
    # UUIDType (Uuid(as_uuid=False)) grava sem hífens no SQLite — achado
    # comparando com o valor real de outro debug de sessão.
    cur.execute("select attempt_id from attempts where user_id=? order by created_at", (user.replace("-", ""),))
    attempt_ids = [row[0] for row in cur.fetchall()]
    assert len(attempt_ids) == 4

    # 3 dias consecutivos (sequência real de 3) + 1 dia isolado bem depois
    # (quebra a sequência) — "mais longa já vivida" continua sendo 3,
    # mesmo que a sequência atual (Streak.current_streak, não tocada aqui)
    # seja outra coisa.
    base = datetime(2026, 1, 1, 12, 0, 0)
    synthetic_dates = [base, base + timedelta(days=1), base + timedelta(days=2), base + timedelta(days=10)]
    for attempt_id, dt in zip(attempt_ids, synthetic_dates):
        cur.execute("update attempts set created_at=? where attempt_id=?", (dt.isoformat(), attempt_id))
    con.commit()
    con.close()

    stats = client.get("/stats", headers=headers).json()
    assert stats["longest_streak"] == 3
