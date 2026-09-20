"""
SubMundos de gramática do Mundo da Linguagem (MUNDO_LINGUAGEM_ARQUITETURA_V1.md,
pedido de Rhoney 20/09/2026). Converte o(s) lote(s) curado(s) de UM tema —
MUNDO/Mundo_da_Linguagem/temas/<slug>_lote<N>.json — no formato plano de
backend/content/linguagem_tema_<slug>.json (território `linguagem_<slug>`).

Lote fonte: {"tema","slug","lote","observacao","desafios":[{difficulty_level,prompt,
options,correct_answer,explanation,hints}]} — escrito para revisão humana de Rhoney
(nenhum conteúdo vai ao ar sem ela). Valida com app/content_validation antes de gravar.

Uso:
    cd backend && python3 scripts/convert_linguagem_tema_content.py crase
"""

import glob
import json
import sys
from pathlib import Path

sys.path.insert(0, ".")

REPO_ROOT = Path(__file__).resolve().parents[2]
SOURCE_DIR = REPO_ROOT / "MUNDO" / "Mundo_da_Linguagem" / "temas"
OUTPUT_DIR = REPO_ROOT / "backend" / "content"


def convert(slug: str) -> Path:
    items = []
    for path in sorted(glob.glob(str(SOURCE_DIR / f"{slug}_lote*.json"))):
        lote = json.loads(Path(path).read_text(encoding="utf-8"))
        for d in lote["desafios"]:
            items.append(
                {
                    "territory_id": f"linguagem_{slug}",
                    "difficulty_level": d["difficulty_level"],
                    "prompt": d["prompt"],
                    "options": d["options"],
                    "correct_answer": d["correct_answer"],
                    "explanation": d["explanation"],
                    "age_reviewed": True,
                    "hints": d["hints"],
                }
            )
    if not items:
        raise SystemExit(f"nenhum lote encontrado para '{slug}' em {SOURCE_DIR}")
    out = OUTPUT_DIR / f"linguagem_tema_{slug}.json"
    out.write_text(json.dumps(items, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"{out.name}: {len(items)} desafios")
    return out


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Uso: python3 scripts/convert_linguagem_tema_content.py <slug>")
        sys.exit(1)
    convert(sys.argv[1])
