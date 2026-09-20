"""
Mundo_Acima_de_Nos/README.md — Mundo Acima de Nós (Espaço). Converte os
5 arquivos brutos de conteúdo (Mundo_Acima_de_Nos/mundo_espaco_
bloco*.json, formato "cápsula de texto + perguntas", mesmo de Valores/
Trânsito/Gastronomia/Oceanos) pro formato plano exigido por
app/content_validation.py e scripts/append_production_content.py.

Cada "pergunta" de uma cápsula vira um Challenge normal — mesma decisão
de arquitetura já usada em Valores/Trânsito/Gastronomia/Oceanos:
reaproveita 100% a infraestrutura já existente/auditada em vez de criar
uma mecânica nova. O texto da cápsula alimenta DOIS campos:
reading_passage (mostrado ANTES da pergunta) e explanation (reforça a
leitura DEPOIS de responder) — os arquivos fonte não têm um campo de
explicação próprio.

hints NÃO existem no arquivo bruto — gerados automaticamente aqui,
mesmo padrão já usado em convert_oceanos_content.py.

Uso:
    cd backend && python3 scripts/convert_espaco_content.py
"""

import json
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
SOURCE_DIR = REPO_ROOT / "MUNDO" / "Mundo_Acima_de_Nos"
OUTPUT_DIR = REPO_ROOT / "backend" / "content"

# nome do arquivo fonte -> territory_id (migrations/070_mundo_espaco.sql)
# Mesma convenção já usada em Valores/Trânsito/Gastronomia/Oceanos: id
# curto e específico do tema (sem repetir "espaco"), o prefixo entra só
# no nome do arquivo de conteúdo pra organização.
SOURCE_FILE_TO_TERRITORY = {
    "mundo_espaco_bloco1_universo.json": "espaco_universo",
    "mundo_espaco_bloco2_planetas.json": "espaco_planetas",
    "mundo_espaco_bloco3_estrelas.json": "espaco_estrelas",
    "mundo_espaco_bloco4_exploracao.json": "espaco_exploracao",
    "mundo_espaco_bloco5_brasil.json": "espaco_brasil",
}

DIFFICULTY_LEVEL = 1  # checagem de compreensão de leitura, não trilha de maestria por nível


def _question_challenge(pergunta: dict, territory_id: str, titulo: str, texto: str) -> dict:
    correct = pergunta["resposta_correta"]
    return {
        "territory_id": territory_id,
        "difficulty_level": DIFFICULTY_LEVEL,
        "prompt": pergunta["pergunta"],
        "options": pergunta["opcoes"],
        "correct_answer": correct,
        "explanation": texto,
        "reading_passage": texto,
        "hints": [
            f"Releia '{titulo}' — a resposta está no texto.",
            f"Começa com '{correct[0]}'.",
        ],
        "age_reviewed": True,
    }


def convert_file(source_path: Path, seen_prompts: set[str]) -> tuple[str, list[dict], int]:
    data = json.loads(source_path.read_text(encoding="utf-8"))
    territory_id = SOURCE_FILE_TO_TERRITORY[source_path.name]

    challenges = []
    excluded = 0
    for capsula in data["capsulas"]:
        titulo = capsula["titulo"]
        texto = capsula["texto"]
        for pergunta in capsula["perguntas"]:
            prompt_key = pergunta["pergunta"]
            if prompt_key in seen_prompts:
                print(f"  [excluído] prompt duplicado entre cápsulas/territórios: {prompt_key!r}")
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

            challenges.append(_question_challenge(pergunta, territory_id, titulo, texto))

    return territory_id, challenges, excluded


def main() -> None:
    seen_prompts: set[str] = set()
    total_challenges = 0
    total_excluded = 0

    for filename, territory_id in SOURCE_FILE_TO_TERRITORY.items():
        source_path = SOURCE_DIR / filename
        territory_id_check, challenges, excluded = convert_file(source_path, seen_prompts)
        assert territory_id_check == territory_id

        output_path = OUTPUT_DIR / f"espaco_{territory_id.removeprefix('espaco_')}.json"
        output_path.write_text(json.dumps(challenges, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print(f"{filename} -> {output_path.name}: {len(challenges)} desafios, {excluded} excluídos")
        total_challenges += len(challenges)
        total_excluded += excluded

    print(f"\nTotal: {total_challenges} desafios, {total_excluded} excluídos")


if __name__ == "__main__":
    main()
