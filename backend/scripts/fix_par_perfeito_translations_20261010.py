"""
Correção pontual de 3 traduções imprecisas do Par Perfeito, achado 3.1
de mental-content-consistency (09/10/2026, aprovado por Rhoney
10/10/2026): "Compromise"/"Acordo" não captura o sentido de concessão;
"Convenient"/"Conveniente" é falso-cognato parcial; "Diligence"/
"Dedicação" ignora o cognato direto "Diligência". Script avulso
(não idempotente por natureza — roda uma vez e corrige o que já está
semeado em produção); backend/content/par_perfeito_*.json já está
corrigido na fonte, isso só sincroniza o banco de produção com ela.

Uso:
    export MENTAL_DATABASE_URL="postgresql+psycopg://..."
    cd backend && python3 scripts/fix_par_perfeito_translations_20261010.py
"""

import sys

sys.path.insert(0, ".")

from app import models  # noqa: E402
from app.db import SessionLocal  # noqa: E402

_FIXES = [
    ("ingles_parperfeito_avancado", "Compromise", "Acordo", "Concessão"),
    ("ingles_parperfeito_avancado", "Diligence", "Dedicação", "Diligência"),
    ("ingles_parperfeito_intermediario", "Convenient", "Conveniente", "Prático"),
]


def main() -> None:
    with SessionLocal() as db:
        updated = 0
        for territory_id, word_en, old_meaning, new_meaning in _FIXES:
            item = (
                db.query(models.ParPerfeitoItem)
                .filter(
                    models.ParPerfeitoItem.territory_id == territory_id,
                    models.ParPerfeitoItem.word_en == word_en,
                )
                .one_or_none()
            )
            if item is None:
                print(f"⚠️  não encontrado: {territory_id} / {word_en} (nada a corrigir)")
                continue
            if item.meaning_pt != old_meaning:
                print(f"⚠️  {territory_id} / {word_en} já está como {item.meaning_pt!r} (esperava {old_meaning!r}) — pulado, confira manualmente")
                continue
            item.meaning_pt = new_meaning
            updated += 1
            print(f"✅ {territory_id} / {word_en}: {old_meaning!r} -> {new_meaning!r}")
        db.commit()
        print(f"\n{updated} item(ns) corrigido(s).")


if __name__ == "__main__":
    main()
