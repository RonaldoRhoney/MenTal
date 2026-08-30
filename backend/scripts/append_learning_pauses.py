"""
Carga INCREMENTAL de "Pausa para Aprender" curada (V3/V3.2_TECNOLOGIA.md
§3, backend/content/README.md) — mesmo padrão de
append_production_content.py, só que pra mental.learning_pauses em vez
de mental.challenges (estrutura de conteúdo diferente: sem options/
correct_answer/hints). Idempotente por (territory_id, text).

Uso:
    export MENTAL_DATABASE_URL="postgresql+psycopg://..."  # ou sqlite pra testar em dev
    cd backend && python3 scripts/append_learning_pauses.py content/<arquivo>.json
"""

import json
import sys

sys.path.insert(0, ".")

from app import models  # noqa: E402
from app.content_validation import validate_learning_pauses  # noqa: E402
from app.db import SessionLocal  # noqa: E402
from app.seed import TERRITORIES  # noqa: E402


def main() -> None:
    if len(sys.argv) != 2:
        print("Uso: python3 scripts/append_learning_pauses.py content/<arquivo>.json")
        sys.exit(1)

    path = sys.argv[1]
    with open(path, encoding="utf-8") as f:
        items = json.load(f)

    known_territory_ids = {t["id"] for t in TERRITORIES}

    with SessionLocal() as db:
        existing_rows = db.query(models.LearningPause.territory_id, models.LearningPause.text).all()
        existing_texts = {(row[0], row[1]) for row in existing_rows}

        errors = validate_learning_pauses(items, known_territory_ids, existing_texts)
        blocking_errors = [e for e in errors if "já existe uma Pausa para Aprender com esse texto" not in e]
        if blocking_errors:
            print(f"❌ {len(blocking_errors)} erro(s) estrutural(is) — nada foi inserido:\n")
            for error in blocking_errors:
                print(f"  - {error}")
            sys.exit(1)

        inserted = 0
        skipped = 0
        for item in items:
            key = (item["territory_id"], item["text"])
            if key in existing_texts:
                skipped += 1
                continue

            db.add(
                models.LearningPause(
                    territory_id=item["territory_id"],
                    difficulty_level=item["difficulty_level"],
                    text=item["text"],
                    prompt_image=item.get("prompt_image"),
                    age_reviewed=item["age_reviewed"],
                )
            )
            db.commit()
            existing_texts.add(key)
            inserted += 1

        print(f"✅ {inserted} Pausa(s) para Aprender nova(s) inserida(s), {skipped} já existiam (pulada(s)).")


if __name__ == "__main__":
    main()
