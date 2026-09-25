"""
Lista as palavras/frases mais pedidas ao MENTAL LINGO que o vocabulário curado
ainda não tem (fila de curadoria, aprovada por Rhoney em 25/09/2026).

    cd backend && export MENTAL_DATABASE_URL=... && python3 scripts/list_mental_lingo_gaps.py [N]

Só agregado (palavra, idioma, vezes) — a tabela não guarda usuário nem áudio.
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from sqlalchemy import select  # noqa: E402

from app import models  # noqa: E402
from app.db import SessionLocal  # noqa: E402


def main() -> None:
    limit = int(sys.argv[1]) if len(sys.argv) > 1 else 50
    with SessionLocal() as db:
        rows = db.execute(
            select(models.MentalLingoGap)
            .order_by(models.MentalLingoGap.times_asked.desc(), models.MentalLingoGap.last_asked_at.desc())
            .limit(limit)
        ).scalars().all()
    if not rows:
        print("Nenhuma lacuna registrada ainda.")
        return
    print(f"{'vezes':>5}  {'idioma':<9} palavra/frase")
    for r in rows:
        print(f"{r.times_asked:>5}  {r.target_language or '(não dito)':<9} {r.word}")


if __name__ == "__main__":
    main()
