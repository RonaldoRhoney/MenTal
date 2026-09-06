"""
MUNDO_LINGUAGEM_CONTEUDO_DENSO_V1.md — 100 desafios de interpretação de
texto (textos originais + pergunta), curadoria de Rhoney
(interpretacao_textos_bloco{1..4}.json, raiz do repo), convertidos por
scripts/convert_interpretacao_textos_content.py em
content/linguagem_interpretacao_textos.json e carregados no território
"textos" já existente via app/seed.py. Cobre o que é próprio desta leva
— não repete o critério geral de volume já coberto por
test_content_volume.py.
"""

import json
import uuid
from pathlib import Path

from app.seed import CHALLENGES

from .conftest import auth_header

CONTENT_PATH = Path(__file__).resolve().parent.parent / "content" / "linguagem_interpretacao_textos.json"


def _load_content() -> list[dict]:
    return json.loads(CONTENT_PATH.read_text(encoding="utf-8"))


def test_hundred_text_interpretation_challenges_are_loaded():
    items = _load_content()
    assert len(items) == 100
    for item in items:
        assert item["territory_id"] == "textos"
        assert item["difficulty_level"] == 1
        assert len(item["options"]) == 4
        assert item["correct_answer"] in item["options"]
        # O texto-base entra dentro do próprio prompt (mesmo padrão já
        # usado no resto do território "textos") — nunca só a pergunta
        # sozinha, senão a mesma pergunta genérica se repetiria.
        assert "\n\n" in item["prompt"]

    loaded_prompts = {c["prompt"] for c in CHALLENGES if c["territory_id"] == "textos"}
    for item in items:
        assert item["prompt"] in loaded_prompts


def test_answering_a_text_interpretation_challenge_correctly_works_like_any_normal_challenge(client):
    dense = {item["prompt"]: item["correct_answer"] for item in _load_content()}

    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    challenge = None
    for _ in range(80):
        candidate = client.get("/challenges/next", params={"territory_id": "textos"}, headers=headers).json()
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
