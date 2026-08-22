"""
Carga única do conteúdo real de desafios (CHALLENGES em app/seed.py) no
banco de produção (Postgres/Supabase). NUNCA roda automaticamente — só
sob execução manual explícita, uma vez, logo depois das migrations
001-011 terem sido aplicadas.

Por quê este script existe: app/main.py só chama seed_if_empty() quando
MENTAL_DATABASE_URL começa com "sqlite" (RISKS_AND_OPEN_DECISIONS.md §2 —
conteúdo curado manualmente, nunca gerado/inserido automaticamente em
produção). As migrations SQL só inserem as linhas de mental.territories
(e o catálogo de mental.badges, via 004_badges.sql) — o conteúdo real dos
desafios (mental.challenges/challenge_hints) nunca foi migrado via SQL
(ver comentário em cada migrations/00X_*_territory.sql). Sem este passo,
o backend em produção sobe com territórios existindo mas sem nenhum
desafio pra jogar.

Idempotente por contagem: se mental.challenges já tiver qualquer linha,
o script aborta sem inserir nada — nunca duplica conteúdo em re-execução
acidental.

Uso:
    export MENTAL_DATABASE_URL="postgresql+psycopg://postgres:<senha>@db.daogwiqwqplcvehdhksf.supabase.co:5432/postgres?options=-csearch_path%3Dmental,public"
    cd backend && python3 scripts/seed_production_content.py
"""

import sys

sys.path.insert(0, ".")

from app import models  # noqa: E402
from app.db import SessionLocal  # noqa: E402
from app.seed import CHALLENGES  # noqa: E402


def main() -> None:
    with SessionLocal() as db:
        existing = db.query(models.Challenge).count()
        if existing > 0:
            print(f"ABORTADO: mental.challenges já tem {existing} linha(s). Nada foi inserido.")
            return

        territory_count = db.query(models.Territory).count()
        if territory_count == 0:
            print("ABORTADO: nenhum território encontrado — rode as migrations 001-011 antes deste script.")
            return

        inserted_challenges = 0
        inserted_hints = 0
        for c in CHALLENGES:
            hints = c["hints"]
            challenge = models.Challenge(**{k: v for k, v in c.items() if k != "hints"})
            db.add(challenge)
            db.commit()
            db.refresh(challenge)
            for level, content in enumerate(hints, start=1):
                db.add(models.ChallengeHint(challenge_id=challenge.id, hint_level=level, content=content))
                inserted_hints += 1
            db.commit()
            inserted_challenges += 1

        print(f"OK: {inserted_challenges} desafios e {inserted_hints} dicas inseridos em mental.challenges.")


if __name__ == "__main__":
    main()
