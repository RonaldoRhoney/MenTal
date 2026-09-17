"""
MUNDO_ESPORTES_ARQUITETURA_V1.md — Mundo dos Esportes, SubMundo "Copa do
Mundo" (14/09/2026 — implementado reaproveitando o mecanismo de Bloco,
mesmo padrão já usado no SubMundo Internet de Tecnologia).
Converte os arquivos brutos de conteúdo (Mundo_dos_Esportes/<SubMundo>/
mundo_esportes_<submundo>_bloco*_desafio*.json, formato "meta +
perguntas", SEM níveis de dificuldade — diferente do SubMundo Internet:
aqui cada bloco tem 5 desafios de 5 perguntas cada, direto, conforme
doc §2).

territory_id = bloco inteiro (1 bloco = 1 território, mesmo padrão do
SubMundo Internet) — os 5 desafios dentro do bloco não viram
territórios separados, só agrupam as perguntas na curadoria bruta.
difficulty_level sempre 1 (sem trilha de dificuldade neste Mundo,
mesmo critério já usado em convert_gastronomia_content.py/
convert_espaco_content.py pra conteúdo "flat").

Só blocos com os 5 desafios presentes são processados — um bloco com
desafio faltando fica de fora até a curadoria completar (nunca carrega
território pela metade). Só blocos já em BLOCO_TO_TERRITORY (por
SubMundo) são processados — SubMundos/blocos novos entram aqui (e em
app/seed.py BLOCKS/TERRITORIES/migração correspondente) só quando a
curadoria estiver completa e Rhoney confirmar, nunca antes.

hints NÃO existem no arquivo bruto — gerados aqui, mesmo padrão já
usado nos outros scripts de conversão. explanation fica vazio (não há
campo "saiba_mais" no formato deste Mundo — perguntas diretas, sem
cápsula de contexto).

Uso:
    cd backend && python3 scripts/convert_esportes_content.py
"""

import json
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
SOURCE_DIR = REPO_ROOT / "Mundo_dos_Esportes"
OUTPUT_DIR = REPO_ROOT / "backend" / "content"

DIFFICULTY_LEVEL = 1  # sem trilha de dificuldade neste Mundo

# (submundo, numero_bloco) -> territory_id (app/seed.py TERRITORIES,
# world_id="esportes", block_id=submundo). Só inclua uma combinação
# nova aqui depois que Rhoney confirmar que a curadoria daquele bloco
# terminou (5 desafios completos).
BLOCO_TO_TERRITORY = {
    ("copa_do_mundo", 1): "copa_mundo_primeiras_copas",
    ("copa_do_mundo", 2): "copa_mundo_expansao",
    ("copa_do_mundo", 3): "copa_mundo_era_moderna",
    ("copa_do_mundo", 4): "copa_mundo_curiosidades",
    ("futebol", 1): "futebol_origens",
    ("futebol", 2): "futebol_grandes_nomes",
    ("futebol", 3): "futebol_regras_curiosidades",
    ("futebol", 4): "futebol_atualidade",
}

EXPECTED_DESAFIOS_PER_BLOCO = 5


def _question_challenge(pergunta: dict, territory_id: str, tema_desafio: str) -> dict:
    correct = pergunta["resposta_correta"]
    return {
        "territory_id": territory_id,
        "difficulty_level": DIFFICULTY_LEVEL,
        "prompt": pergunta["pergunta"],
        "options": pergunta["opcoes"],
        "correct_answer": correct,
        "explanation": "",
        "hints": [
            f"Pense no tema: '{tema_desafio}'.",
            f"Começa com '{correct[0]}'.",
        ],
        "age_reviewed": True,
    }


def main() -> None:
    seen_prompts: set[str] = set()
    by_bloco: dict[tuple[str, int], list[Path]] = {}

    source_files = sorted(SOURCE_DIR.glob("*/mundo_esportes_*_bloco*_desafio*.json"))
    if not source_files:
        print(f"Nenhum arquivo encontrado em {SOURCE_DIR}")
        return

    for source_path in source_files:
        data = json.loads(source_path.read_text(encoding="utf-8"))
        meta = data["meta"]
        key = (meta["submundo"], meta["numero_bloco"])
        by_bloco.setdefault(key, []).append(source_path)

    by_territory: dict[str, list[dict]] = {}
    total_excluded = 0
    skipped_incomplete: list[tuple[str, int, int]] = []
    skipped_unmapped: list[tuple[str, int]] = []

    for (submundo, numero_bloco), paths in sorted(by_bloco.items()):
        if len(paths) != EXPECTED_DESAFIOS_PER_BLOCO:
            skipped_incomplete.append((submundo, numero_bloco, len(paths)))
            continue
        territory_id = BLOCO_TO_TERRITORY.get((submundo, numero_bloco))
        if territory_id is None:
            skipped_unmapped.append((submundo, numero_bloco))
            continue

        for source_path in sorted(paths):
            data = json.loads(source_path.read_text(encoding="utf-8"))
            meta = data["meta"]
            tema_desafio = meta["tema_desafio"]
            for pergunta in data["perguntas"]:
                prompt_key = pergunta["pergunta"]
                if prompt_key in seen_prompts:
                    print(f"  [excluído] prompt duplicado entre blocos/desafios: {prompt_key!r}")
                    total_excluded += 1
                    continue
                seen_prompts.add(prompt_key)

                options = pergunta["opcoes"]
                correct = pergunta["resposta_correta"]
                if len(set(options)) != len(options):
                    print(f"  [excluído] opções repetidas em {prompt_key!r}: {options}")
                    total_excluded += 1
                    continue
                if correct not in options:
                    print(f"  [excluído] resposta correta {correct!r} não está em options, {prompt_key!r}")
                    total_excluded += 1
                    continue

                by_territory.setdefault(territory_id, []).append(
                    _question_challenge(pergunta, territory_id, tema_desafio)
                )
            print(f"{source_path.name} -> território {territory_id}")

    if skipped_incomplete:
        print("\n[ignorados, curadoria incompleta]")
        for submundo, numero_bloco, count in skipped_incomplete:
            print(f"  {submundo} bloco {numero_bloco}: {count}/{EXPECTED_DESAFIOS_PER_BLOCO} desafios presentes")
    if skipped_unmapped:
        print("\n[ignorados, ainda não estão em BLOCO_TO_TERRITORY]")
        for submundo, numero_bloco in skipped_unmapped:
            print(f"  {submundo} bloco {numero_bloco}")

    total_challenges = 0
    for territory_id, challenges in by_territory.items():
        output_path = OUTPUT_DIR / f"{territory_id}.json"
        output_path.write_text(json.dumps(challenges, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print(f"  {output_path.name}: {len(challenges)} desafios no total")
        total_challenges += len(challenges)

    print(f"\nTotal: {total_challenges} desafios em {len(by_territory)} território(s), {total_excluded} excluídos.")


if __name__ == "__main__":
    main()
