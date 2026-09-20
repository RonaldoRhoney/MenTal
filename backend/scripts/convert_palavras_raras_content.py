"""
SubMundo "Palavras Raras" (Mundo da Linguagem) — pedido de Rhoney (20/09/2026).
Converte MUNDO/Mundo_da_Linguagem/100_palavras_raras_portugues.json (100 palavras
+ significado, em 10 áreas de 10) em desafios de múltipla escolha, 1 território
por área (bloco `palavras_raras`, mesmo mecanismo de Bloco do SubMundo Internet).

Cada palavra gera DOIS desafios (duas direções de estudo, 20 por território —
exigência do critério de volume >= 15 por território, test_content_volume.py):
  (A) palavra -> significado;  (B) significado -> palavra.

Formato do desafio (A):
- prompt: "Qual é o significado de 'Palavra'?"
- options: o significado certo + 3 significados de OUTRAS palavras da MESMA área
  (distratores plausíveis, nunca inventados). Os 3 distratores são sorteados entre
  os 5 significados de tamanho mais parecido com o certo (evita o viés "a opção
  mais longa é a certa"); sorteio com semente fixa -> geração reproduzível.
- difficulty_level = 3 (palavras raras; decisão de Rhoney). Como options nunca é
  None, o Relâmpago usa as opções como estão (nada é sintetizado).
- hints nunca entregam a resposta; explanation traz o significado e a orientação
  de conferência em dicionários (a própria fonte pede: "confira cada acepção").

Uso:
    cd backend && python3 scripts/convert_palavras_raras_content.py
Saída: backend/content/linguagem_palavras_raras_<area>.json (10 arquivos), carregados
por seed.py (glob linguagem_*.json) e por scripts/append_production_content.py.
"""

import json
import random
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
SOURCE = REPO_ROOT / "MUNDO" / "Mundo_da_Linguagem" / "100_palavras_raras_portugues.json"
OUTPUT_DIR = REPO_ROOT / "backend" / "content"

DIFFICULTY_LEVEL = 3

# Ordem = ordem das áreas no arquivo fonte. (slug do território, rótulo curto p/ dica)
AREAS = [
    ("filosofia", "filosofia, pensamento e comportamento"),
    ("psicologia", "psicologia, emoções e relações humanas"),
    ("medicina", "medicina, biologia e corpo humano"),
    ("fisica_quimica", "física, química e astronomia"),
    ("matematica", "matemática, lógica e estatística"),
    ("linguistica", "linguística, gramática e literatura"),
    ("historia", "história, arqueologia e antropologia"),
    ("geografia", "geografia, geologia e meio ambiente"),
    ("direito", "direito, política institucional e administração"),
    ("eruditas", "palavras eruditas, abstratas e pouco usuais"),
]

SOURCES_NOTE = "Confira a acepção em dicionários como Priberam, Michaelis ou Caldas Aulete."


def build_challenge(area_slug: str, area_label: str, entry: dict, others: list[dict]) -> dict:
    word = entry["palavra"]
    correct = entry["significado"]
    rng = random.Random(entry["numero"])
    closest = sorted(others, key=lambda o: abs(len(o["significado"]) - len(correct)))[:5]
    distractors = [o["significado"] for o in rng.sample(closest, 3)]
    options = [correct, *distractors]
    rng.shuffle(options)
    return {
        "territory_id": f"palavras_raras_{area_slug}",
        "difficulty_level": DIFFICULTY_LEVEL,
        "prompt": f"Qual é o significado de '{word}'?",
        "options": options,
        "correct_answer": correct,
        "explanation": f"'{word}' significa: {correct} {SOURCES_NOTE}",
        "age_reviewed": True,
        "hints": [
            f"É um termo da área de {area_label}.",
            f"A palavra começa com '{word[0].upper()}' e tem {len(word)} letras.",
        ],
    }


def build_reverse_challenge(area_slug: str, area_label: str, entry: dict, others: list[dict]) -> dict:
    """(B) O enunciado é o significado; as opções são PALAVRAS da mesma área."""
    word = entry["palavra"]
    meaning = entry["significado"]
    rng = random.Random(1000 + entry["numero"])
    distractors = [o["palavra"] for o in rng.sample(others, 3)]
    options = [word, *distractors]
    rng.shuffle(options)
    return {
        "territory_id": f"palavras_raras_{area_slug}",
        "difficulty_level": DIFFICULTY_LEVEL,
        "prompt": f"Qual palavra corresponde a este significado: \"{meaning.rstrip('.')}\"?",
        "options": options,
        "correct_answer": word,
        "explanation": f"'{word}' significa: {meaning} {SOURCES_NOTE}",
        "age_reviewed": True,
        "hints": [
            f"É um termo da área de {area_label}.",
            f"A palavra procurada começa com '{word[0].upper()}'.",
        ],
    }


def main() -> None:
    data = json.loads(SOURCE.read_text(encoding="utf-8"))
    assert len(data["areas"]) == len(AREAS), "número de áreas mudou no arquivo fonte"
    total = 0
    for (slug, label), area in zip(AREAS, data["areas"]):
        words = area["palavras"]
        challenges = []
        for entry in words:
            others = [o for o in words if o is not entry]
            challenges.append(build_challenge(slug, label, entry, others))
            challenges.append(build_reverse_challenge(slug, label, entry, others))
        out = OUTPUT_DIR / f"linguagem_palavras_raras_{slug}.json"
        out.write_text(json.dumps(challenges, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        total += len(challenges)
        print(f"{out.name}: {len(challenges)} desafios ({area['area']})")
    print(f"Total: {total}")


if __name__ == "__main__":
    main()
