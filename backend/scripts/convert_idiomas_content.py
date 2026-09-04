"""
V5/README.md — converte os 9 arquivos brutos de conteúdo do Mundo dos
Idiomas (V5/mundo_dos_idiomas_<idioma>_<nivel>.json, formato de
blocos/vocabulario/desafio_frase) pro formato plano exigido por
app/content_validation.py e scripts/append_production_content.py.

Roda uma vez (conteúdo já é fixo/curado) e escreve os 9 arquivos em
backend/content/idiomas_<idioma>_<nivel>.json. hints e explanation NÃO
existem no arquivo bruto — gerados automaticamente aqui (genéricos:
tema do bloco + primeira letra/palavra da resposta), decisão registrada
em V5/README.md.

Uso:
    cd backend && python3 scripts/convert_idiomas_content.py
"""

import json
import re
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
SOURCE_DIR = REPO_ROOT / "V5"
OUTPUT_DIR = REPO_ROOT / "backend" / "content"

NIVEL_TO_DIFFICULTY = {"basico": 1, "intermediario": 2, "avancado": 3}
IDIOMA_DISPLAY = {"ingles": "inglês", "espanhol": "espanhol", "frances": "francês"}


def _quoted_pt_term(pergunta: str) -> str:
    match = re.search(r"'([^']+)'", pergunta)
    return match.group(1) if match else pergunta


def _vocab_challenge(item: dict, territory_id: str, difficulty: int, tema: str, idioma: str) -> dict:
    pt_term = _quoted_pt_term(item["pergunta"])
    correct = item["resposta_correta"]
    return {
        "territory_id": territory_id,
        "difficulty_level": difficulty,
        "prompt": item["pergunta"],
        "options": item["opcoes"],
        "correct_answer": correct,
        "explanation": f"'{pt_term}' se traduz como '{correct}' em {IDIOMA_DISPLAY[idioma]}.",
        "hints": [
            f"É uma palavra do tema '{tema}'.",
            f"Começa com '{correct[0]}'.",
        ],
        "age_reviewed": True,
    }


def _frase_challenge(item: dict, territory_id: str, difficulty: int, tema: str) -> dict:
    resposta = item["resposta_esperada"]
    primeira_palavra = resposta.split()[0] if resposta.split() else resposta
    return {
        "territory_id": territory_id,
        "difficulty_level": difficulty,
        "prompt": item["enunciado"],
        "options": None,
        "correct_answer": resposta,
        "accepted_answers": item.get("aceita_variacoes") or None,
        "explanation": item["feedback_explicativo"],
        "hints": [
            f"Relembre o vocabulário do tema '{tema}' que você acabou de ver.",
            f"A frase começa com '{primeira_palavra}'.",
        ],
        "age_reviewed": True,
    }


def convert_file(source_path: Path, seen_prompts: set[str]) -> tuple[str, list[dict]]:
    # seen_prompts é COMPARTILHADO entre os 9 arquivos (não reiniciado por
    # território) — achado real: "Como se escreve 'a menos que' em
    # inglês?" apareceu idêntico em ingles_intermediario E ingles_avancado
    # (mesma frase ensinada duas vezes, curadoria descuidada entre
    # níveis). test_no_duplicate_prompts_within_text_based_territories
    # (backend/tests/test_content_volume.py) verifica prompt duplicado em
    # TODO o CHALLENGES, não só dentro do território.
    data = json.loads(source_path.read_text(encoding="utf-8"))
    idioma = data["meta"]["idioma"]
    nivel = data["meta"]["nivel"]
    territory_id = f"{idioma}_{nivel}"
    difficulty = NIVEL_TO_DIFFICULTY[nivel]

    items: list[dict] = []
    excluded: list[str] = []
    for bloco in data["blocos"]:
        tema = bloco["tema"]
        for vocab_item in bloco["vocabulario"]:
            challenge = _vocab_challenge(vocab_item, territory_id, difficulty, tema, idioma)
            options = challenge["options"]
            if len(set(options)) != len(options):
                excluded.append(f"{challenge['prompt']!r}: alternativa duplicada em options {options}")
                continue
            if challenge["prompt"] in seen_prompts:
                excluded.append(f"{challenge['prompt']!r}: prompt duplicado (já usado em outro território/nível)")
                continue
            seen_prompts.add(challenge["prompt"])
            items.append(challenge)
        frase_challenge = _frase_challenge(bloco["desafio_frase"], territory_id, difficulty, tema)
        if frase_challenge["prompt"] in seen_prompts:
            excluded.append(f"{frase_challenge['prompt']!r}: prompt duplicado (já usado em outro território/nível)")
            continue
        seen_prompts.add(frase_challenge["prompt"])
        items.append(frase_challenge)

    return territory_id, items, excluded


def main() -> None:
    OUTPUT_DIR.mkdir(exist_ok=True)
    total = 0
    all_excluded: list[str] = []
    seen_prompts: set[str] = set()
    for source_path in sorted(SOURCE_DIR.glob("mundo_dos_idiomas_*.json")):
        territory_id, items, excluded = convert_file(source_path, seen_prompts)
        output_path = OUTPUT_DIR / f"idiomas_{territory_id}.json"
        output_path.write_text(json.dumps(items, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print(f"{source_path.name} -> {output_path.relative_to(REPO_ROOT)} ({len(items)} desafios, {len(excluded)} excluídos)")
        total += len(items)
        all_excluded.extend(f"{territory_id}: {e}" for e in excluded)
    print(f"\nTotal: {total} desafios carregados, {len(all_excluded)} excluídos por bug estrutural na fonte:")
    for e in all_excluded:
        print(f"  - {e}")


if __name__ == "__main__":
    main()
