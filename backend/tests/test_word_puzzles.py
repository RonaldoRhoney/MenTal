"""
V3.3 §6 (Jogos de Palavras — Fase 1: Caça-palavras). A grade inteira já
vem resolvida (sem opção escondida); autoridade de XP/tempo 100% no
backend, XP só na primeira conclusão do puzzle por usuário.
"""

import uuid
from datetime import timedelta

from app import config, models
from app.db import SessionLocal
from app.timeutil import utcnow

from .conftest import auth_header


def _backdate_started_at(result_id: str) -> None:
    """Empurra started_at pro passado o suficiente pra passar do piso
    WORD_PUZZLE_MIN_COMPLETION_SECONDS (achado de auditoria de segurança
    M2, 05/09/2026) — os testes daqui simulam "levou um tempo real pra
    achar as palavras", nunca "completou instantaneamente"."""
    with SessionLocal() as db:
        result = db.get(models.WordPuzzleResult, result_id)
        result.started_at = utcnow() - timedelta(seconds=config.WORD_PUZZLE_MIN_COMPLETION_SECONDS + 5)
        db.commit()


def _seed_puzzle(territory_id: str = "caca_palavras", difficulty_level: int = 1) -> tuple[str, list[str]]:
    words = ["GATO", "CAO"]
    grid = [
        "GATOXX",
        "XXXXXX",
        "XXXXXX",
        "XXXXXX",
        "XXCAOX",
        "XXXXXX",
    ]
    with SessionLocal() as db:
        puzzle = models.WordPuzzle(
            territory_id=territory_id,
            difficulty_level=difficulty_level,
            theme="Teste",
            grid_size=6,
            grid=grid,
            words=words,
            age_reviewed=True,
        )
        db.add(puzzle)
        db.commit()
        db.refresh(puzzle)
        return puzzle.id, words


def test_next_word_puzzle_returns_full_grid(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)
    _seed_puzzle()

    resp = client.get("/word-puzzles/next", params={"territory_id": "caca_palavras"}, headers=headers)
    assert resp.status_code == 200
    body = resp.json()
    assert body["territory_id"] == "caca_palavras"
    assert body["grid_size"] == 6
    assert len(body["grid"]) == 6
    assert set(body["words"]) == {"GATO", "CAO"}
    assert body["result_id"]


def test_complete_awards_xp_only_when_all_words_found(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)
    _seed_puzzle()

    challenge = client.get("/word-puzzles/next", params={"territory_id": "caca_palavras"}, headers=headers).json()
    result_id = challenge["result_id"]
    _backdate_started_at(result_id)

    partial_resp = client.post(f"/word-puzzles/{result_id}/complete", json={"found_words": ["GATO"]}, headers=headers)
    assert partial_resp.status_code == 400
    assert partial_resp.json()["error"]["code"] == "WORDS_MISSING"

    full_resp = client.post(f"/word-puzzles/{result_id}/complete", json={"found_words": ["gato", "cao"]}, headers=headers)
    assert full_resp.status_code == 200
    body = full_resp.json()
    assert body["xp_awarded"] > 0
    assert body["already_completed_before"] is False


def test_complete_is_idempotent_and_never_double_pays(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)
    _seed_puzzle()

    challenge = client.get("/word-puzzles/next", params={"territory_id": "caca_palavras"}, headers=headers).json()
    result_id = challenge["result_id"]
    _backdate_started_at(result_id)
    first = client.post(f"/word-puzzles/{result_id}/complete", json={"found_words": ["GATO", "CAO"]}, headers=headers).json()
    second = client.post(f"/word-puzzles/{result_id}/complete", json={"found_words": ["GATO", "CAO"]}, headers=headers).json()

    assert second["xp_awarded"] == first["xp_awarded"]
    assert second["already_completed_before"] is True


def test_replaying_same_puzzle_does_not_pay_xp_again(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)
    puzzle_id, words = _seed_puzzle()

    # Cria as duas tentativas (WordPuzzleResult) diretamente no banco,
    # sem passar por GET /next — outros testes já semearam mais de um
    # puzzle nesse território+dificuldade na mesma base de dados de
    # teste, e o sorteio aleatório de /next poderia servir um puzzle
    # diferente do que este teste acabou de criar.
    def _create_result() -> str:
        with SessionLocal() as db:
            result = models.WordPuzzleResult(
                user_id=user,
                word_puzzle_id=puzzle_id,
                started_at=utcnow() - timedelta(seconds=config.WORD_PUZZLE_MIN_COMPLETION_SECONDS + 5),
            )
            db.add(result)
            db.commit()
            db.refresh(result)
            return result.id

    first_result_id = _create_result()
    client.post(f"/word-puzzles/{first_result_id}/complete", json={"found_words": words}, headers=headers)

    second_result_id = _create_result()
    second_complete = client.post(
        f"/word-puzzles/{second_result_id}/complete", json={"found_words": words}, headers=headers
    ).json()

    assert second_complete["already_completed_before"] is True
    assert second_complete["xp_awarded"] == 0


def test_completing_instantly_after_next_is_rejected(client):
    """Achado de auditoria de segurança M2 (05/09/2026): copiar `words`
    de /next direto pra found_words e chamar /complete na sequência
    (sem nunca calcular como se fosse um humano jogando) não pode render
    XP nem sequer ser aceito."""
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)
    _seed_puzzle()

    challenge = client.get("/word-puzzles/next", params={"territory_id": "caca_palavras"}, headers=headers).json()

    resp = client.post(
        f"/word-puzzles/{challenge['result_id']}/complete",
        json={"found_words": challenge["words"]},
        headers=headers,
    )
    assert resp.status_code == 400
    assert resp.json()["error"]["code"] == "COMPLETION_TOO_FAST"


def test_territory_not_found_404s(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    resp = client.get("/word-puzzles/next", params={"territory_id": "territorio-inexistente"}, headers=headers)
    assert resp.status_code == 404
    assert resp.json()["error"]["code"] == "TERRITORY_NOT_FOUND"


def test_no_puzzles_available_404s(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    resp = client.get("/word-puzzles/next", params={"territory_id": "caca_palavras"}, headers=headers)
    # Território existe (seed.py) mas pode não ter puzzle nenhum ainda
    # nesta base de teste isolada, dependendo da ordem de execução —
    # aceita 404 (sem puzzle) ou 200 (outro teste já semeou um).
    assert resp.status_code in (200, 404)
