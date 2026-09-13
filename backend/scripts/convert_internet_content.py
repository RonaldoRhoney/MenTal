"""
Mundo_da_Tecnologia/Internet/README.md — Internet, SubMundo de
Tecnologia (ARQUITETURA_SUBMUNDOS_V1.md, 13/09/2026 — implementado
reaproveitando o Bloco "internet" já existente, sem Mundo próprio).
Converte os arquivos brutos de conteúdo (Mundo_da_Tecnologia/Internet/
mundo_internet_bloco*_desafio*_<nivel>.json, formato "meta + saiba_mais
+ perguntas", DIFERENTE das "cápsulas de texto" dos últimos Mundos:
aqui cada bloco é dividido em desafios, e cada desafio tem uma pergunta
em 4 níveis de dificuldade (Facil/Media/Dificil/Muito Dificil) — 1º
conteúdo curado a usar 4 níveis em vez de 3 (config.XP_BASE_BY_DIFFICULTY
e ADAPTIVE_DIFFICULTY_MAX_LEVEL já suportavam até 5; content_validation.py
foi atualizado nesta mesma leva pra aceitar até 4).

territory_id = bloco inteiro (1 bloco = 1 território, mesmo padrão de
todos os Mundos anteriores) — os desafios dentro do bloco não viram
territórios separados, só agrupam as perguntas em dificuldades. Só
blocos já em BLOCO_TO_TERRITORY são processados — blocos novos entram
aqui (e em app/seed.py TERRITORIES/migração correspondente) só quando a
curadoria daquele bloco estiver completa e Rhoney confirmar, nunca
antes (blocos com desafio incompleto ficam de fora até completarem).

saiba_mais alimenta "explanation" (reforço mostrado depois de responder)
— mesma reaproveitamento de texto já usado em convert_espaco_content.py/
convert_gastronomia_content.py, aqui compartilhado entre as 20 perguntas
do mesmo bloco+desafio+dificuldade. NÃO alimenta reading_passage: ao
contrário das cápsulas (onde o texto contém a resposta e é lido ANTES
da pergunta), aqui é uma curiosidade correlata, não pré-requisito pra
responder.

hints NÃO existem no arquivo bruto — gerados aqui, mesmo padrão já
usado nos outros scripts de conversão.

Uso:
    cd backend && python3 scripts/convert_internet_content.py
"""

import json
import unicodedata
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
SOURCE_DIR = REPO_ROOT / "Mundo_da_Tecnologia" / "Internet"
OUTPUT_DIR = REPO_ROOT / "backend" / "content"

NIVEL_TO_DIFFICULTY = {
    "Facil": 1,
    "Media": 2,
    "Dificil": 3,
    "Muito Dificil": 4,
}

# numero_bloco (do campo "meta") -> territory_id (app/seed.py TERRITORIES,
# world_id="tecnologia", block_id="internet"). Só inclua um bloco novo
# aqui depois que Rhoney confirmar que a curadoria dele terminou.
BLOCO_TO_TERRITORY = {
    1: "internet_origens",
    2: "internet_sistemas_operacionais",
}


def _slug(text: str) -> str:
    normalized = unicodedata.normalize("NFKD", text).encode("ascii", "ignore").decode("ascii")
    return "_".join(normalized.lower().split())


def _question_challenge(pergunta: dict, territory_id: str, difficulty_level: int, tema_desafio: str, saiba_mais: str) -> dict:
    correct = pergunta["resposta_correta"]
    return {
        "territory_id": territory_id,
        "difficulty_level": difficulty_level,
        "prompt": pergunta["pergunta"],
        "options": pergunta["opcoes"],
        "correct_answer": correct,
        "explanation": saiba_mais,
        "hints": [
            f"Pense no tema: '{tema_desafio}'.",
            f"Começa com '{correct[0]}'.",
        ],
        "age_reviewed": True,
    }


def convert_file(source_path: Path, seen_prompts: set[str]) -> tuple[str | None, list[dict], int]:
    data = json.loads(source_path.read_text(encoding="utf-8"))
    meta = data["meta"]
    territory_id = BLOCO_TO_TERRITORY.get(meta["numero_bloco"])
    if territory_id is None:
        return None, [], 0
    difficulty_level = NIVEL_TO_DIFFICULTY[meta["nivel_dificuldade"]]
    tema_desafio = meta["tema_desafio"]
    saiba_mais = data["saiba_mais"]

    challenges = []
    excluded = 0
    for pergunta in data["perguntas"]:
        prompt_key = pergunta["pergunta"]
        if prompt_key in seen_prompts:
            print(f"  [excluído] prompt duplicado entre blocos/desafios: {prompt_key!r}")
            excluded += 1
            continue
        seen_prompts.add(prompt_key)

        options = pergunta["opcoes"]
        correct = pergunta["resposta_correta"]
        if len(set(options)) != len(options):
            print(f"  [excluído] opções repetidas em {prompt_key!r}: {options}")
            excluded += 1
            continue
        if correct not in options:
            print(f"  [excluído] resposta correta {correct!r} não está em options, {prompt_key!r}")
            excluded += 1
            continue

        challenges.append(_question_challenge(pergunta, territory_id, difficulty_level, tema_desafio, saiba_mais))

    return territory_id, challenges, excluded


def main() -> None:
    seen_prompts: set[str] = set()
    by_territory: dict[str, list[dict]] = {}
    total_excluded = 0

    source_files = sorted(SOURCE_DIR.glob("mundo_internet_bloco*_desafio*_*.json"))
    if not source_files:
        print(f"Nenhum arquivo encontrado em {SOURCE_DIR}")
        return

    skipped_blocos: set[int] = set()
    for source_path in source_files:
        territory_id, challenges, excluded = convert_file(source_path, seen_prompts)
        if territory_id is None:
            numero_bloco = json.loads(source_path.read_text(encoding="utf-8"))["meta"]["numero_bloco"]
            skipped_blocos.add(numero_bloco)
            continue
        by_territory.setdefault(territory_id, []).extend(challenges)
        total_excluded += excluded
        print(f"{source_path.name} -> território {territory_id}: {len(challenges)} desafios, {excluded} excluídos")

    if skipped_blocos:
        print(f"\n[ignorados] bloco(s) {sorted(skipped_blocos)} — ainda não estão em BLOCO_TO_TERRITORY (curadoria em andamento).")

    total_challenges = 0
    for territory_id, challenges in by_territory.items():
        output_path = OUTPUT_DIR / f"{territory_id}.json"
        output_path.write_text(json.dumps(challenges, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print(f"  {output_path.name}: {len(challenges)} desafios no total")
        total_challenges += len(challenges)

    print(f"\nTotal: {total_challenges} desafios, {total_excluded} excluídos")


if __name__ == "__main__":
    main()
