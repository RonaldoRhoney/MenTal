"""
Carga INCREMENTAL de Caça-palavras já gerados por generate_word_search.py
(V3.3 §6) — mesmo padrão de append_production_content.py, só que pra
mental.word_puzzles em vez de mental.challenges. Idempotente por
(territory_id, theme).

Uso:
    export MENTAL_DATABASE_URL="postgresql+psycopg://..."  # ou sqlite pra testar em dev
    cd backend && python3 scripts/append_word_puzzles.py content/<arquivo>_grades.json
"""

import json
import sys

sys.path.insert(0, ".")

from app import models  # noqa: E402
from app.content_validation import validate_word_puzzles  # noqa: E402
from app.db import SessionLocal  # noqa: E402
from app.seed import TERRITORIES  # noqa: E402


def main() -> None:
    if len(sys.argv) != 2:
        print("Uso: python3 scripts/append_word_puzzles.py content/<arquivo>.json")
        sys.exit(1)

    path = sys.argv[1]
    with open(path, encoding="utf-8") as f:
        items = json.load(f)

    known_territory_ids = {t["id"] for t in TERRITORIES}

    with SessionLocal() as db:
        existing_rows = db.query(models.WordPuzzle.territory_id, models.WordPuzzle.theme).all()
        existing_themes = {(row[0], row[1]) for row in existing_rows}

        errors = validate_word_puzzles(items, known_territory_ids, existing_themes)
        blocking_errors = [e for e in errors if "já existe um Caça-palavras com esse tema" not in e]
        if blocking_errors:
            print(f"❌ {len(blocking_errors)} erro(s) estrutural(is) — nada foi inserido:\n")
            for error in blocking_errors:
                print(f"  - {error}")
            sys.exit(1)

        inserted = 0
        skipped = 0
        for item in items:
            key = (item["territory_id"], item["theme"])
            if key in existing_themes:
                skipped += 1
                continue

            db.add(
                models.WordPuzzle(
                    territory_id=item["territory_id"],
                    difficulty_level=item["difficulty_level"],
                    theme=item["theme"],
                    grid_size=item["grid_size"],
                    grid=item["grid"],
                    words=item["words"],
                    age_reviewed=item["age_reviewed"],
                )
            )
            db.commit()
            existing_themes.add(key)
            inserted += 1

        print(f"✅ {inserted} Caça-palavras novo(s) inserido(s), {skipped} já existiam (pulado(s)).")


if __name__ == "__main__":
    main()
