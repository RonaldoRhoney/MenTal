"""
Mundo_da_Linguagem/README.md — converte os 4 blocos brutos de
vocabulário avançado/jargão (Mundo_da_Linguagem/palavras_dificeis_bloco{1..4}.json,
curadoria de Rhoney) pro formato plano exigido por
app/content_validation.py e scripts/append_production_content.py.

100 palavras (25 por bloco), território "palavras" (Mundo da Linguagem
já existente) — duas variantes de formato alternadas no arquivo fonte:

  (A) pergunta = "O que significa 'PALAVRA'?", opções = definições.
  (B) contexto descreve a palavra sem citá-la; pergunta = "A palavra
      é:", opções = palavras candidatas. Aqui o contexto vira parte do
      PROMPT (mesmo padrão já usado no território "textos" — o
      parágrafo-base fica dentro do campo prompt, sem campo novo),
      porque a pergunta sozinha ("A palavra é:") se repete em todos os
      itens formato B e violaria a unicidade de prompt por território.

explanation/hints não existem no arquivo fonte — gerados aqui (mesmo
padrão de convert_idiomas_content.py/convert_valores_content.py):
hints nunca entregam a resposta.

difficulty_level=1 em TODOS os itens, mesma decisão e mesmo motivo já
registrado para o lote de regência/crase/concordância (ver comentário
em app/seed.py): o modo Palavras Relâmpago sintetiza alternativas a
partir do correct_answer de QUALQUER outro desafio do mesmo nível,
assumindo respostas curtas/intercambiáveis — as respostas do formato A
são definições completas, incompatíveis com essa síntese. Nível 1
nunca entra no Relâmpago, então o problema nem chega a existir.

Uso:
    cd backend && python3 scripts/convert_palavras_dificeis_content.py
"""

import json
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
OUTPUT_PATH = REPO_ROOT / "backend" / "content" / "linguagem_vocabulario_avancado.json"

SOURCE_FILES = [
    REPO_ROOT / "Mundo_da_Linguagem" / f"palavras_dificeis_bloco{n}.json" for n in (1, 2, 3, 4)
]

TERRITORY_ID = "palavras"
DIFFICULTY_LEVEL = 1

AREA_LABELS = {
    "geral": "vocabulário geral",
    "juridico": "área jurídica",
    "politica": "ciência política",
    "negocios": "negócios",
}


def _area_label(area: str) -> str:
    return AREA_LABELS.get(area, area)


def _format_a_challenge(item: dict) -> dict:
    palavra = item["palavra"]
    correct = item["resposta_correta"]
    area = item["area"]
    return {
        "territory_id": TERRITORY_ID,
        "difficulty_level": DIFFICULTY_LEVEL,
        "prompt": item["pergunta"],
        "options": item["opcoes"],
        "correct_answer": correct,
        "explanation": f"'{palavra}' significa: {correct.rstrip('.')}.",
        "age_reviewed": True,
        "hints": [
            f"É um termo usado principalmente em contextos de {_area_label(area)}.",
            f"Pense em frases onde você já ouviu ou leu a palavra '{palavra}'.",
        ],
    }


def _format_b_challenge(item: dict) -> dict:
    contexto = item["contexto"]
    correct = item["resposta_correta"]
    area = item["area"]
    return {
        "territory_id": TERRITORY_ID,
        "difficulty_level": DIFFICULTY_LEVEL,
        "prompt": f"{contexto}\n\nA palavra é:",
        "options": item["opcoes"],
        "correct_answer": correct,
        "explanation": f"'{correct}' é a palavra que combina com a descrição: {contexto}",
        "age_reviewed": True,
        "hints": [
            f"É um termo usado principalmente em contextos de {_area_label(area)}.",
            f"A palavra procurada começa com '{correct[0]}'.",
        ],
    }


def main() -> None:
    challenges: list[dict] = []
    for source_path in SOURCE_FILES:
        data = json.loads(source_path.read_text(encoding="utf-8"))
        for item in data["itens"]:
            if item["formato"] == "A":
                challenges.append(_format_a_challenge(item))
            elif item["formato"] == "B":
                challenges.append(_format_b_challenge(item))
            else:
                raise ValueError(f"formato desconhecido: {item['formato']!r} (id={item['id']!r})")

    OUTPUT_PATH.write_text(json.dumps(challenges, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"✅ {len(challenges)} desafio(s) convertido(s) para {OUTPUT_PATH}")


if __name__ == "__main__":
    main()
