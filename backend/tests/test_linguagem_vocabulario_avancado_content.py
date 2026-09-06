"""
Mundo_da_Linguagem/README.md — 100 desafios de vocabulário
avançado/jargão (geral, jurídico, política, negócios), curadoria de
Rhoney (palavras_dificeis_bloco{1..4}.json, pasta Mundo_da_Linguagem/), convertidos
por scripts/convert_palavras_dificeis_content.py em
content/linguagem_vocabulario_avancado.json e carregados no território
"palavras" via app/seed.py. Cobre o que é próprio desta leva — mesma
trava de difficulty_level=1 do lote de gramática densa (ver comentário
em app/seed.py) — não repete o critério geral de volume já coberto por
test_content_volume.py.
"""

import json
import uuid
from pathlib import Path

from app.seed import CHALLENGES

from .conftest import auth_header

CONTENT_PATH = Path(__file__).resolve().parent.parent / "content" / "linguagem_vocabulario_avancado.json"


def _load_content() -> list[dict]:
    return json.loads(CONTENT_PATH.read_text(encoding="utf-8"))


def test_hundred_vocabulary_challenges_are_loaded():
    items = _load_content()
    assert len(items) == 100
    for item in items:
        assert item["territory_id"] == "palavras"
        # Mesmo motivo do lote de gramática densa (ver app/seed.py):
        # respostas de formato A são definições completas, incompatíveis
        # com a síntese de alternativas do Palavras Relâmpago.
        assert item["difficulty_level"] == 1
        assert len(item["options"]) == 4
        assert item["correct_answer"] in item["options"]

    loaded_prompts = {c["prompt"] for c in CHALLENGES if c["territory_id"] == "palavras"}
    for item in items:
        assert item["prompt"] in loaded_prompts


def test_relampago_never_serves_the_vocabulary_batch_since_it_targets_level_2_and_3(client):
    dense_prompts = {item["prompt"] for item in _load_content()}

    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    for _ in range(15):
        resp = client.get(
            "/challenges/next", params={"territory_id": "palavras", "mode": "relampago"}, headers=headers
        )
        assert resp.json()["prompt"] not in dense_prompts


def test_answering_a_vocabulary_challenge_correctly_works_like_any_normal_challenge(client):
    dense = {item["prompt"]: item["correct_answer"] for item in _load_content()}

    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    challenge = None
    for _ in range(80):
        candidate = client.get("/challenges/next", params={"territory_id": "palavras"}, headers=headers).json()
        if candidate["prompt"] in dense:
            challenge = candidate
            break
    assert challenge is not None, "não encontrou nenhum desafio do lote novo em 80 tentativas"

    resp = client.post(
        f"/challenges/{challenge['challenge_id']}/answer",
        json={"attempt_id": challenge["attempt_id"], "submitted_answer": dense[challenge["prompt"]]},
        headers=headers,
    )
    result = resp.json()
    assert resp.status_code == 200
    assert result["is_correct"] is True
    assert result["xp_awarded"] > 0
