"""
Carga incremental dos 45 desafios do Mundo da Cultura Geral (V3.0 —
V3/V3.0_ESPORTES_REGIOES_CULTURA_POP.md): esportes, regiões e
cultura_pop, 15 por território. Roda DEPOIS de
migrations/036_v3_cultura_geral.sql (que cria o Mundo e os 3
territórios) — mesmo motivo de scripts/seed_production_content.py: o
conteúdo real dos desafios nunca é migrado via SQL nem gerado
automaticamente em produção, só inserido manualmente a partir de
app/seed.py.

Idempotente por (territory_id, prompt), mesma lógica de
scripts/append_production_content.py — pode ser rodado de novo sem
duplicar o que já foi inserido.

Uso:
    export MENTAL_DATABASE_URL="postgresql+psycopg://postgres:<senha>@db.daogwiqwqplcvehdhksf.supabase.co:5432/postgres?options=-csearch_path%3Dmental,public"
    cd backend && python3 scripts/seed_v3_cultura_geral_challenges.py
"""

import sys

sys.path.insert(0, ".")

from app import models  # noqa: E402
from app.db import SessionLocal  # noqa: E402
from app.seed import CHALLENGES  # noqa: E402

TERRITORY_IDS = {"esportes", "regioes", "cultura_pop"}


def main() -> None:
    with SessionLocal() as db:
        found_territories = {
            row[0] for row in db.query(models.Territory.id).filter(models.Territory.id.in_(TERRITORY_IDS)).all()
        }
        missing = TERRITORY_IDS - found_territories
        if missing:
            print(f"ABORTADO: território(s) {sorted(missing)} não existem no banco — rode migrations/036_v3_cultura_geral.sql antes.")
            return

        existing_rows = (
            db.query(models.Challenge.territory_id, models.Challenge.prompt)
            .filter(models.Challenge.territory_id.in_(TERRITORY_IDS))
            .all()
        )
        existing_prompts = {(row[0], row[1]) for row in existing_rows}

        new_items = [c for c in CHALLENGES if c["territory_id"] in TERRITORY_IDS]

        inserted = 0
        skipped = 0
        for item in new_items:
            key = (item["territory_id"], item["prompt"])
            if key in existing_prompts:
                skipped += 1
                continue

            hints = item["hints"]
            challenge = models.Challenge(**{k: v for k, v in item.items() if k != "hints"})
            db.add(challenge)
            db.commit()
            db.refresh(challenge)
            for level, content in enumerate(hints, start=1):
                db.add(models.ChallengeHint(challenge_id=challenge.id, hint_level=level, content=content))
            db.commit()
            existing_prompts.add(key)
            inserted += 1

        print(f"OK: {inserted} desafio(s) novo(s) inserido(s), {skipped} já existiam (pulado(s)).")


if __name__ == "__main__":
    main()
