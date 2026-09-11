"""
Selo "Novo" (06/09/2026, pedido de Rhoney) — os 230 desafios de
content/linguagem_gramatica_densa.json, linguagem_vocabulario_avancado.json
e linguagem_interpretacao_textos.json já existiam em produção ANTES da
migration 066 (que criou Challenge.created_at) e por isso nasceram com
created_at NULL — nunca seriam elegíveis pro selo "Novo"
(services.is_challenge_new) mesmo tendo sido, de fato, a leva mais
recente do Mundo da Linguagem. Este script faz o UPDATE pontual de
created_at=agora só nessas linhas, identificadas por (territory_id,
prompt) — nunca insere nem duplica nada. Roda uma vez só: se rodado de
novo, só reescreveria created_at pra um valor mais recente, sem quebrar
nada, mas não há necessidade de rodar mais de uma vez.

Uso:
    export MENTAL_DATABASE_URL="postgresql+psycopg://..."
    cd backend && python3 scripts/mark_linguagem_challenges_as_new.py
"""

import json
import sys
from pathlib import Path

sys.path.insert(0, ".")

from app import models  # noqa: E402
from app.db import SessionLocal  # noqa: E402
from app.timeutil import utcnow  # noqa: E402

FILES = [
    "content/linguagem_gramatica_densa.json",
    "content/linguagem_vocabulario_avancado.json",
    "content/linguagem_interpretacao_textos.json",
]


def main() -> None:
    now = utcnow()
    with SessionLocal() as db:
        marked = 0
        not_found = 0
        for filename in FILES:
            items = json.loads(Path(filename).read_text(encoding="utf-8"))
            for item in items:
                challenge = (
                    db.query(models.Challenge)
                    .filter(
                        models.Challenge.territory_id == item["territory_id"],
                        models.Challenge.prompt == item["prompt"],
                    )
                    .one_or_none()
                )
                if challenge is None:
                    not_found += 1
                    print(f"  ⚠️  não encontrado no banco: [{item['territory_id']}] {item['prompt'][:60]!r}")
                    continue
                challenge.created_at = now
                marked += 1
            db.commit()

        print(f"✅ {marked} desafio(s) marcado(s) como novo(s), {not_found} não encontrado(s) no banco.")


if __name__ == "__main__":
    main()
