"""
Carga INCREMENTAL de conteúdo curado (backend/content/README.md), ao
contrário de scripts/seed_production_content.py (carga única inicial,
aborta se mental.challenges já tiver qualquer linha). Este script pode
ser rodado várias vezes, conforme novo conteúdo for curado ao longo do
tempo — idempotente por (territory_id, prompt): pula silenciosamente o
que já existe no banco, nunca duplica.

Sempre valida a estrutura de novo antes de inserir (defesa em
profundidade — não confia que quem chamou já rodou validate_content.py).

Uso:
    export MENTAL_DATABASE_URL="postgresql+psycopg://..."  # ou sqlite pra testar em dev
    cd backend && python3 scripts/append_production_content.py content/<arquivo>.json
"""

import json
import sys

sys.path.insert(0, ".")

from app import models  # noqa: E402
from app.content_validation import validate_content  # noqa: E402
from app.db import SessionLocal  # noqa: E402
from app.seed import TERRITORIES  # noqa: E402


def main() -> None:
    if len(sys.argv) != 2:
        print("Uso: python3 scripts/append_production_content.py content/<arquivo>.json")
        sys.exit(1)

    path = sys.argv[1]
    with open(path, encoding="utf-8") as f:
        items = json.load(f)

    known_territory_ids = {t["id"] for t in TERRITORIES}

    with SessionLocal() as db:
        existing_rows = db.query(models.Challenge.territory_id, models.Challenge.prompt).all()
        existing_prompts = {(row[0], row[1]) for row in existing_rows}

        errors = validate_content(items, known_territory_ids, existing_prompts)
        # Duplicata contra o que já está no BANCO não é erro aqui — é o
        # caso normal de rodar o script de novo com um arquivo que já
        # tem itens carregados antes junto com itens novos. Filtra esses
        # erros específicos antes de decidir abortar.
        blocking_errors = [e for e in errors if "já existe um desafio com esse prompt" not in e]
        if blocking_errors:
            print(f"❌ {len(blocking_errors)} erro(s) estrutural(is) — nada foi inserido:\n")
            for error in blocking_errors:
                print(f"  - {error}")
            sys.exit(1)

        inserted = 0
        skipped = 0
        for item in items:
            key = (item["territory_id"], item["prompt"])
            if key in existing_prompts:
                skipped += 1
                continue

            hints = item["hints"]
            challenge = models.Challenge(
                territory_id=item["territory_id"],
                difficulty_level=item["difficulty_level"],
                prompt=item["prompt"],
                options=item["options"],
                correct_answer=item["correct_answer"],
                explanation=item["explanation"],
                age_reviewed=item["age_reviewed"],
                prompt_image=item.get("prompt_image"),
                clues=item.get("clues"),
            )
            db.add(challenge)
            db.commit()
            db.refresh(challenge)
            for level, content in enumerate(hints, start=1):
                db.add(models.ChallengeHint(challenge_id=challenge.id, hint_level=level, content=content))
            db.commit()
            existing_prompts.add(key)
            inserted += 1

        print(f"✅ {inserted} desafio(s) novo(s) inserido(s), {skipped} já existiam (pulado(s)).")
        if inserted:
            print(
                "\nLembrete: adicione o mesmo conteúdo em app/seed.py CHALLENGES também, "
                "pra manter uma única fonte de verdade (dev local e validação de "
                "duplicata contra o histórico completo continuam corretas)."
            )


if __name__ == "__main__":
    main()
