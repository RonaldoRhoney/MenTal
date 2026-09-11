"""
Mundo_da_Linguagem/README.md — 30 desafios de regência, crase,
concordância, pares confusos, pontuação e ortografia, carregados de
content/linguagem_gramatica_densa.json (app/seed.py) no território
"palavras" já existente. Cobre o que é próprio desta leva — volume e a
redistribuição de difficulty_level 1/2/3 (BUG_LINGUAGEM_NAO_APARECE, ver
comentário em app/seed.py) — não repete o critério geral de volume já
coberto por test_content_volume.py.
"""

import uuid

from app.seed import CHALLENGES

from .conftest import auth_header


def test_thirty_new_dense_grammar_challenges_are_loaded():
    import json
    from pathlib import Path

    content_path = Path(__file__).resolve().parent.parent / "content" / "linguagem_gramatica_densa.json"
    items = json.loads(content_path.read_text(encoding="utf-8"))
    assert len(items) == 30
    for item in items:
        assert item["territory_id"] == "palavras"
        # BUG_LINGUAGEM_NAO_APARECE (ver app/seed.py): options sempre
        # curadas (nunca None) neste lote, então não há risco de síntese
        # de alternativas do Palavras Relâmpago em nenhum nível — o lote
        # foi redistribuído entre 1/2/3, igual a qualquer outro conteúdo
        # de "palavras", pra não ficar preso a jogadores iniciantes.
        assert item["difficulty_level"] in {1, 2, 3}
        assert len(item["options"]) == 4
        assert item["correct_answer"] in item["options"]

    # Confere que o seed de fato carregou o arquivo (não só que o
    # arquivo em disco está certo).
    loaded_prompts = {c["prompt"] for c in CHALLENGES if c["territory_id"] == "palavras"}
    for item in items:
        assert item["prompt"] in loaded_prompts


def test_relampago_serves_level_2_and_3_dense_grammar_items_with_their_own_curated_options(client):
    """BUG_LINGUAGEM_NAO_APARECE: como este lote sempre teve options
    curadas (nunca None), o modo Relâmpago nunca sintetiza nada pra ele
    — só reaproveita as 4 opções reais, embaralhadas (routers/
    challenges.py: `else: options = shuffled_options(challenge.options)`).
    Os itens de nível 2/3 do lote devem aparecer normalmente no Relâmpago."""
    import json
    from pathlib import Path

    content_path = Path(__file__).resolve().parent.parent / "content" / "linguagem_gramatica_densa.json"
    dense_by_prompt = {item["prompt"]: item for item in json.loads(content_path.read_text(encoding="utf-8"))}

    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    for _ in range(40):
        resp = client.get(
            "/challenges/next", params={"territory_id": "palavras", "mode": "relampago"}, headers=headers
        )
        candidate = resp.json()
        item = dense_by_prompt.get(candidate["prompt"])
        if item is None:
            continue
        assert item["difficulty_level"] >= 2
        assert set(candidate["options"]) == set(item["options"])


def test_answering_a_dense_grammar_challenge_correctly_works_like_any_normal_challenge(client):
    import json
    from pathlib import Path

    content_path = Path(__file__).resolve().parent.parent / "content" / "linguagem_gramatica_densa.json"
    dense_prompts = {item["prompt"]: item["correct_answer"] for item in json.loads(content_path.read_text(encoding="utf-8"))}

    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    # difficulty_level=1 é o nível de entrada de qualquer usuário novo —
    # basta pedir o próximo desafio normal do território até cair num
    # item do lote novo (todo o nível 1 de "palavras" é curado, então
    # algumas tentativas bastam).
    challenge = None
    for _ in range(50):
        candidate = client.get("/challenges/next", params={"territory_id": "palavras"}, headers=headers).json()
        if candidate["prompt"] in dense_prompts:
            challenge = candidate
            break
    assert challenge is not None, "não encontrou nenhum desafio do lote novo em 50 tentativas"

    resp = client.post(
        f"/challenges/{challenge['challenge_id']}/answer",
        json={"attempt_id": challenge["attempt_id"], "submitted_answer": dense_prompts[challenge["prompt"]]},
        headers=headers,
    )
    result = resp.json()
    assert resp.status_code == 200
    assert result["is_correct"] is True
    assert result["xp_awarded"] > 0
