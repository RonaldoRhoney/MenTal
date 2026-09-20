"""
SubMundo "Palavras Raras" (Mundo da Linguagem, pedido de Rhoney, 20/09/2026):
100 palavras em 10 áreas -> 200 desafios (palavra->significado e
significado->palavra), 10 territórios no Bloco `palavras_raras`.
Cobre o que é próprio desta leva; o critério geral de volume está em test_content_volume.py.
"""

import json
from pathlib import Path

from app.seed import BLOCKS, CHALLENGES, TERRITORIES

CONTENT_DIR = Path(__file__).resolve().parent.parent / "content"
SOURCE = Path(__file__).resolve().parents[2] / "MUNDO" / "Mundo_da_Linguagem" / "100_palavras_raras_portugues.json"


def _items() -> list[dict]:
    items = []
    for path in sorted(CONTENT_DIR.glob("linguagem_palavras_raras_*.json")):
        items.extend(json.loads(path.read_text(encoding="utf-8")))
    return items


def test_bloco_e_10_territorios_no_mundo_da_linguagem():
    assert any(b["id"] == "palavras_raras" and b["name"] == "Palavras Raras" for b in BLOCKS)
    territories = [t for t in TERRITORIES if t.get("block_id") == "palavras_raras"]
    assert len(territories) == 10
    assert all(t["world_id"] == "linguagem" for t in territories)


def test_200_desafios_20_por_territorio_todos_nivel_3_e_no_seed():
    items = _items()
    assert len(items) == 200
    ids = {t["id"] for t in TERRITORIES if t.get("block_id") == "palavras_raras"}
    for tid in ids:
        assert len([i for i in items if i["territory_id"] == tid]) == 20
    assert all(i["difficulty_level"] == 3 for i in items)
    seeded = [c for c in CHALLENGES if c["territory_id"] in ids]
    assert len(seeded) == 200


def test_estrutura_de_cada_desafio_e_dicas_nao_entregam_a_resposta():
    for item in _items():
        assert len(item["options"]) == 4 and len(set(item["options"])) == 4
        assert item["correct_answer"] in item["options"]
        assert len(item["hints"]) == 2
        assert item["age_reviewed"] is True
        for hint in item["hints"]:
            assert item["correct_answer"].lower() not in hint.lower()


def test_cada_palavra_gera_as_duas_direcoes_com_o_significado_do_arquivo_fonte():
    source = json.loads(SOURCE.read_text(encoding="utf-8"))
    items = _items()
    prompts = {i["prompt"] for i in items}
    assert len(prompts) == 200  # nenhum prompt repetido
    for area in source["areas"]:
        for entry in area["palavras"]:
            word, meaning = entry["palavra"], entry["significado"]
            forward = [i for i in items if i["prompt"] == f"Qual é o significado de '{word}'?"]
            assert len(forward) == 1 and forward[0]["correct_answer"] == meaning
            reverse = [i for i in items if i["correct_answer"] == word]
            assert len(reverse) == 1 and meaning.rstrip(".") in reverse[0]["prompt"]


def test_distratores_vem_da_mesma_area_e_nunca_de_fora():
    source = json.loads(SOURCE.read_text(encoding="utf-8"))
    slugs = ["filosofia", "psicologia", "medicina", "fisica_quimica", "matematica", "linguistica", "historia", "geografia", "direito", "eruditas"]
    items = _items()
    for slug, area in zip(slugs, source["areas"]):
        words = {e["palavra"] for e in area["palavras"]}
        meanings = {e["significado"] for e in area["palavras"]}
        for item in (i for i in items if i["territory_id"] == f"palavras_raras_{slug}"):
            assert set(item["options"]) <= (words | meanings)


def test_mais_longa_nao_e_sempre_a_certa():
    # Viés conhecido de conteúdo (achado do agente de conteúdo): distratores de tamanho parecido.
    forward = [i for i in _items() if i["prompt"].startswith("Qual é o significado de")]
    longest_is_correct = sum(1 for i in forward if max(i["options"], key=len) == i["correct_answer"])
    assert longest_is_correct <= 0.5 * len(forward)
