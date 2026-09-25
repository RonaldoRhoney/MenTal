"""
Revisão das sugestões do MENTAL LINGO vindas do Wikcionário (aprovado por
Rhoney, 25/09/2026). Só o que você aprovar deixa de exibir "ainda não revisado".

    cd backend && export MENTAL_DATABASE_URL=...
    python3 scripts/review_mental_lingo_suggestions.py list [pending|approved|rejected]
    python3 scripts/review_mental_lingo_suggestions.py approve <palavra> [idioma=ingles]
    python3 scripts/review_mental_lingo_suggestions.py reject  <palavra> [idioma=ingles]
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from sqlalchemy import select  # noqa: E402

from app import models  # noqa: E402
from app.db import SessionLocal  # noqa: E402


def main() -> None:
    cmd = sys.argv[1] if len(sys.argv) > 1 else "list"
    with SessionLocal() as db:
        if cmd == "list":
            status = sys.argv[2] if len(sys.argv) > 2 else "pending"
            rows = db.execute(
                select(models.MentalLingoSuggestion)
                .where(models.MentalLingoSuggestion.status == status)
                .order_by(models.MentalLingoSuggestion.useful_votes.desc(), models.MentalLingoSuggestion.wrong_votes.asc())
            ).scalars().all()
            for r in rows:
                print(f"[{r.status}] +{r.useful_votes}/-{r.wrong_votes}  {r.word} ({r.target_language}): {r.answer_text}")
            if not rows:
                print("Nada nessa fila.")
        elif cmd in ("approve", "reject"):
            word = sys.argv[2].lower()
            lang = sys.argv[3] if len(sys.argv) > 3 else "ingles"
            row = db.get(models.MentalLingoSuggestion, (word, lang))
            if row is None:
                print("Sugestão não encontrada.")
                return
            row.status = "approved" if cmd == "approve" else "rejected"
            db.commit()
            print(f"{word} ({lang}) -> {row.status}")
        else:
            print(__doc__)


if __name__ == "__main__":
    main()
