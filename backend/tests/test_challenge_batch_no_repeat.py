"""
BUG_PERGUNTAS_REPETINDO_SEQUENCIA.md — sequência sem repetição real
dentro de um lote (todos os candidatos de um território+dificuldade+
timed), com reembaralhamento só depois de esgotado, e sinalização de
fim de lote (batch_exhausted) na resposta.
"""

import uuid

from app import models, services
from app.db import SessionLocal
from app.seed import CHALLENGES

from .conftest import auth_header


def test_batch_never_repeats_until_exhausted_then_reshuffles_without_boundary_repeat():
    user = str(uuid.uuid4())
    with SessionLocal() as db:
        candidates = (
            db.query(models.Challenge)
            .filter(models.Challenge.territory_id == "visual", models.Challenge.difficulty_level == 1)
            .all()
        )
        assert len(candidates) >= 2, "precisa de pelo menos 2 candidatos para o teste fazer sentido"
        batch_size = len(candidates)

        served_ids = []
        for _ in range(batch_size * 3):
            challenge, is_last = services.pick_next_challenge_from_batch(db, user, "visual", 1, False, candidates)
            served_ids.append(challenge.id)
            services.create_served_attempt(db, models.new_uuid(), user, challenge.id, timed=False, was_last_of_batch=is_last)

        # Nenhuma repetição dentro de cada lote de `batch_size` itens.
        for start in range(0, len(served_ids), batch_size):
            window = served_ids[start : start + batch_size]
            assert len(set(window)) == batch_size, f"lote {window} tem repetição interna"

        # Fronteira entre lotes: o primeiro item do lote seguinte nunca é
        # igual ao último item do lote anterior (achado de borda corrigido
        # nesta mesma mudança — lote pequeno podia reembaralhar de volta
        # pro mesmo item que acabou de fechar o lote anterior).
        for start in range(batch_size, len(served_ids), batch_size):
            assert served_ids[start] != served_ids[start - 1], "repetiu na fronteira entre lotes"


def test_batch_exhausted_flag_true_only_on_last_item_of_batch():
    user = str(uuid.uuid4())
    with SessionLocal() as db:
        candidates = (
            db.query(models.Challenge)
            .filter(models.Challenge.territory_id == "visual", models.Challenge.difficulty_level == 1)
            .all()
        )
        batch_size = len(candidates)

        flags = []
        for _ in range(batch_size):
            challenge, is_last = services.pick_next_challenge_from_batch(db, user, "visual", 1, False, candidates)
            flags.append(is_last)
            services.create_served_attempt(db, models.new_uuid(), user, challenge.id, timed=False, was_last_of_batch=is_last)

        assert flags[:-1] == [False] * (batch_size - 1)
        assert flags[-1] is True


def test_answer_response_reports_batch_exhausted(client):
    """Ponta a ponta via HTTP: o último item do lote em POST /answer
    devolve batch_exhausted=true; os demais, false."""
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    with SessionLocal() as db:
        batch_size = (
            db.query(models.Challenge).filter(models.Challenge.territory_id == "visual", models.Challenge.difficulty_level == 1).count()
        )

    flags = []
    for _ in range(batch_size):
        challenge = client.get("/challenges/next", params={"territory_id": "visual"}, headers=headers).json()
        assert challenge["difficulty_level"] == 1, "teste assume dificuldade estável em 1 para usuário novo"
        result = client.post(
            f"/challenges/{challenge['challenge_id']}/answer",
            json={"attempt_id": challenge["attempt_id"], "submitted_answer": "qualquer"},
            headers=headers,
        ).json()
        flags.append(result["batch_exhausted"])

    assert flags[:-1] == [False] * (batch_size - 1)
    assert flags[-1] is True


def test_flat_territory_never_repeats_even_when_player_performs_well(client):
    """
    CORRECAO_REPETICAO_PERGUNTAS_V1.md — causa raiz encontrada
    14/09/2026: territórios "flat" (curadoria só em difficulty_level=1,
    ex.: oceano_mundo) não tinham conteúdo no nível pra onde a
    dificuldade adaptativa sobe quando o jogador acerta bem (nível 2+).
    Isso fazia GET /challenges/next cair no fallback "território
    inteiro" mas gravar o progresso do lote na chave do nível
    inexistente — cada subida de nível abria uma fila NOVA sobre o
    MESMO conjunto de perguntas, repetindo itens já vistos. A correção
    trava pick_difficulty_for pra nunca recomendar um nível sem
    conteúdo curado; este teste joga um território flat inteiro
    acertando tudo (justamente o que dispara a subida de nível) e
    confirma que nenhuma pergunta se repete antes do lote esgotar.
    """
    territory_id = "oceano_mundo"
    total = sum(1 for c in CHALLENGES if c["territory_id"] == territory_id)
    assert total >= 4, "teste assume um território flat com volume suficiente pra expor a subida de nível"

    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    seen_challenge_ids = []
    for _ in range(total):
        challenge = client.get("/challenges/next", params={"territory_id": territory_id}, headers=headers).json()
        assert challenge["difficulty_level"] == 1, "território flat: dificuldade nunca deveria sair do único nível curado"
        assert challenge["challenge_id"] not in seen_challenge_ids, "repetiu pergunta antes do lote esgotar"
        seen_challenge_ids.append(challenge["challenge_id"])

        correct = next(c["correct_answer"] for c in CHALLENGES if c["territory_id"] == territory_id and c["prompt"] == challenge["prompt"])
        client.post(
            f"/challenges/{challenge['challenge_id']}/answer",
            json={"attempt_id": challenge["attempt_id"], "submitted_answer": correct},
            headers=headers,
        )

    assert len(set(seen_challenge_ids)) == total
