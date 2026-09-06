"""
Mundo_da_Linguagem/README.md — converte os 4 blocos brutos de
interpretação de texto (Mundo_da_Linguagem/interpretacao_textos_bloco{1..4}.json,
curadoria de Rhoney, 100 textos originais + pergunta) pro formato
plano exigido por app/content_validation.py e
scripts/append_production_content.py.

Território "textos" (Mundo da Linguagem já existente, V2 item 3) — o
texto-base entra dentro do próprio campo prompt, mesmo padrão já usado
no resto do território (ver app/seed.py, bloco "textos"): nenhum campo
novo, só "texto\\n\\npergunta" como uma string só.

difficulty_level=1 em todos os itens: as respostas conferidas (amostra
manual) são sempre um fato dito de forma direta no texto (compreensão
literal), o mesmo critério já usado pros itens de nível 1 pré-
existentes deste território — não uma trava de Relâmpago como no
território "palavras" (aqui as opções continuam sendo reaproveitadas
diretamente no modo relâmpago, sem síntese cruzada entre perguntas).

explanation/hints não existem no arquivo fonte — gerados aqui (mesmo
padrão de convert_idiomas_content.py/convert_valores_content.py):
genéricos, mas nunca entregam a resposta.

Uso:
    cd backend && python3 scripts/convert_interpretacao_textos_content.py
"""

import json
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
OUTPUT_PATH = REPO_ROOT / "backend" / "content" / "linguagem_interpretacao_textos.json"

SOURCE_FILES = [
    REPO_ROOT / "Mundo_da_Linguagem" / f"interpretacao_textos_bloco{n}.json" for n in (1, 2, 3, 4)
]

TERRITORY_ID = "textos"
DIFFICULTY_LEVEL = 1

HINT_1 = "A resposta está dita de forma direta em algum trecho do texto."
HINT_2 = "Releia o texto uma segunda vez, prestando atenção às causas e decisões descritas."


def _challenge(item: dict) -> dict:
    correct = item["resposta_correta"]
    return {
        "territory_id": TERRITORY_ID,
        "difficulty_level": DIFFICULTY_LEVEL,
        "prompt": f"{item['texto']}\n\n{item['pergunta']}",
        "options": item["opcoes"],
        "correct_answer": correct,
        "explanation": f'O texto afirma isso diretamente: "{correct}".',
        "age_reviewed": True,
        "hints": [HINT_1, HINT_2],
    }


def main() -> None:
    challenges: list[dict] = []
    for source_path in SOURCE_FILES:
        data = json.loads(source_path.read_text(encoding="utf-8"))
        for item in data["itens"]:
            challenges.append(_challenge(item))

    OUTPUT_PATH.write_text(json.dumps(challenges, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"✅ {len(challenges)} desafio(s) convertido(s) para {OUTPUT_PATH}")


if __name__ == "__main__":
    main()
