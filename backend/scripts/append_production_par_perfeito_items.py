"""
Carga INCREMENTAL de itens do formato "Pares de cards" (Par Perfeito,
MUNDO_IDIOMAS_INGLES_PAR_PERFEITO_V1.md §3/§14) — mesmo espírito de
scripts/append_production_content.py, mas pra ParPerfeitoItem (tabela
própria, não Challenge). Idempotente por (territory_id, word_en): pula
silenciosamente o que já existe no banco, nunca duplica.

Uso:
    export MENTAL_DATABASE_URL="postgresql+psycopg://..."
    cd backend && python3 scripts/append_production_par_perfeito_items.py content/<arquivo>.json
"""

import json
import sys

sys.path.insert(0, ".")

from app import models  # noqa: E402
from app.db import SessionLocal  # noqa: E402
from app.seed import TERRITORIES  # noqa: E402

_REQUIRED_FIELDS = {"territory_id", "difficulty_level", "word_en", "meaning_pt", "age_reviewed"}


def main() -> None:
    if len(sys.argv) != 2:
        print("Uso: python3 scripts/append_production_par_perfeito_items.py content/<arquivo>.json")
        sys.exit(1)

    path = sys.argv[1]
    with open(path, encoding="utf-8") as f:
        items = json.load(f)

    known_territory_ids = {t["id"] for t in TERRITORIES}

    errors = []
    for i, item in enumerate(items):
        missing = _REQUIRED_FIELDS - item.keys()
        if missing:
            errors.append(f"item {i}: campos faltando {sorted(missing)}")
            continue
        if item["territory_id"] not in known_territory_ids:
            errors.append(f"item {i}: territory_id {item['territory_id']!r} não existe")
    if errors:
        print(f"❌ {len(errors)} erro(s) estrutural(is) — nada foi inserido:\n")
        for error in errors:
            print(f"  - {error}")
        sys.exit(1)

    with SessionLocal() as db:
        existing_rows = db.query(models.ParPerfeitoItem.territory_id, models.ParPerfeitoItem.word_en).all()
        existing = {(row[0], row[1]) for row in existing_rows}

        inserted = 0
        skipped = 0
        for item in items:
            key = (item["territory_id"], item["word_en"])
            if key in existing:
                skipped += 1
                continue
            db.add(models.ParPerfeitoItem(
                territory_id=item["territory_id"],
                difficulty_level=item["difficulty_level"],
                word_en=item["word_en"],
                meaning_pt=item["meaning_pt"],
                age_reviewed=item["age_reviewed"],
            ))
            existing.add(key)
            inserted += 1
        db.commit()

        print(f"✅ {inserted} item(ns) novo(s) inserido(s), {skipped} já existiam (pulado(s)).")
        if inserted:
            print(
                "\nLembrete: adicione o mesmo conteúdo em app/content/par_perfeito_*.json "
                "(já é a fonte única — seed.py carrega de lá via glob) pra dev local continuar igual."
            )


if __name__ == "__main__":
    main()
