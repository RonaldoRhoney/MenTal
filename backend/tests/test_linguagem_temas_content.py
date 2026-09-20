"""
SubMundos de gramática do Mundo da Linguagem (MUNDO_LINGUAGEM_ARQUITETURA_V1.md, 20/09/2026):
1 SubMundo (bloco lg_<slug>) por tema, com 1 território linguagem_<slug> de 50 perguntas
(25 nível 1 + 15 nível 2 + 10 nível 3). Só temas "ativo" no plano são registrados.
"""

import json
from collections import Counter
from pathlib import Path

from app.seed import BLOCKS, CHALLENGES, TERRITORIES

CONTENT_DIR = Path(__file__).resolve().parent.parent / "content"
PLAN = json.loads((CONTENT_DIR / "plano_temas_linguagem.json").read_text(encoding="utf-8"))["temas"]
ACTIVE = [t for t in PLAN if t["status"] == "ativo"]


def test_plano_tem_os_19_temas_do_documento_sem_repeticao():
    assert len(PLAN) == 19
    assert len({t["slug"] for t in PLAN}) == 19
    assert {"Crase", "Preposição", "Regência Verbal", "Regência Nominal", "Concordância Verbal", "Concordância Nominal",
            "Colocação Pronominal", "Pronomes", "Pontuação", "Ortografia", "Acentuação Gráfica", "Numerais", "Interjeições",
            "Morfologia", "Sintaxe", "Semântica", "Orações Coordenadas e Subordinadas", "Figuras de Linguagem",
            "Interpretação de Texto"} == {t["nome"] for t in PLAN}
    assert all(t["status"] in {"ativo", "planejado"} for t in PLAN)


def test_so_temas_ativos_viram_bloco_e_territorio_no_mundo_da_linguagem():
    block_ids = {b["id"] for b in BLOCKS if b["id"].startswith("lg_")}
    territory_ids = {t["id"] for t in TERRITORIES if t["id"].startswith("linguagem_")}
    assert block_ids == {f"lg_{t['slug']}" for t in ACTIVE}
    assert territory_ids == {f"linguagem_{t['slug']}" for t in ACTIVE}
    for t in TERRITORIES:
        if t["id"].startswith("linguagem_"):
            assert t["world_id"] == "linguagem" and t["block_id"] == f"lg_{t['id'].removeprefix('linguagem_')}"


def test_cada_tema_ativo_tem_50_perguntas_25_15_10_e_estrutura_valida():
    for tema in ACTIVE:
        items = json.loads((CONTENT_DIR / f"linguagem_tema_{tema['slug']}.json").read_text(encoding="utf-8"))
        assert len(items) == 50, tema["slug"]
        assert Counter(i["difficulty_level"] for i in items) == {1: 25, 2: 15, 3: 10}
        assert len({i["prompt"] for i in items}) == 50  # nenhum prompt repetido
        assert len([c for c in CHALLENGES if c["territory_id"] == f"linguagem_{tema['slug']}"]) == 50
        for item in items:
            assert item["territory_id"] == f"linguagem_{tema['slug']}"
            assert len(item["options"]) == 4 and len(set(item["options"])) == 4
            assert item["correct_answer"] in item["options"]
            assert item["explanation"].strip() and len(item["hints"]) == 2
            assert item["age_reviewed"] is True
            if len(item["correct_answer"]) >= 6:  # dica não entrega resposta (curtas como "a"/"à" seriam falso positivo)
                assert all(item["correct_answer"].lower() not in h.lower() for h in item["hints"]), item["prompt"]


def test_crase_lote_fonte_bate_com_o_conteudo_convertido():
    source = json.loads(
        (Path(__file__).resolve().parents[2] / "MUNDO" / "Mundo_da_Linguagem" / "temas" / "crase_lote1.json").read_text(encoding="utf-8")
    )
    converted = json.loads((CONTENT_DIR / "linguagem_tema_crase.json").read_text(encoding="utf-8"))
    assert [d["prompt"] for d in source["desafios"]] == [c["prompt"] for c in converted]
    assert [d["correct_answer"] for d in source["desafios"]] == [c["correct_answer"] for c in converted]


def test_crase_completar_lacuna_tem_uma_lacuna_e_resposta_certa_unica_nas_opcoes():
    items = json.loads((CONTENT_DIR / "linguagem_tema_crase.json").read_text(encoding="utf-8"))
    gaps = [i for i in items if "___" in i["prompt"]]
    assert len(gaps) >= 40
    for item in gaps:
        assert item["prompt"].count("___") == 1
        assert item["options"].count(item["correct_answer"]) == 1
