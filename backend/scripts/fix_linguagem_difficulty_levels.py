"""
Correção pontual (06/09/2026, BUG_LINGUAGEM_NAO_APARECE — ver comentário
em app/seed.py acima do glob "linguagem_*.json"): os 230 desafios de
content/linguagem_gramatica_densa.json, linguagem_vocabulario_avancado.json
e linguagem_interpretacao_textos.json foram inseridos em produção com
difficulty_level=1 fixo por engano, deixando-os invisíveis pra qualquer
jogador já além do nível 1 em "palavras"/"textos". O conteúdo local já
foi redistribuído (round-robin) entre os níveis 1/2/3 — este script só
faz o UPDATE das linhas JÁ EXISTENTES no banco de produção pra refletir
o novo difficulty_level, identificando cada linha por (territory_id,
prompt) — nunca insere nem duplica nada.

Idempotente: rodar de novo depois de já corrigido não muda nada (o
UPDATE só reescreve o mesmo valor).

Uso:
    export MENTAL_DATABASE_URL="postgresql+psycopg://..."
    cd backend && python3 scripts/fix_linguagem_difficulty_levels.py
"""

import json
import sys
from pathlib import Path

sys.path.insert(0, ".")

from app import models  # noqa: E402
from app.db import SessionLocal  # noqa: E402

FILES = [
    "content/linguagem_gramatica_densa.json",
    "content/linguagem_vocabulario_avancado.json",
    "content/linguagem_interpretacao_textos.json",
]


def main() -> None:
    with SessionLocal() as db:
        updated = 0
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
                if challenge.difficulty_level != item["difficulty_level"]:
                    challenge.difficulty_level = item["difficulty_level"]
                    updated += 1
            db.commit()

        print(f"✅ {updated} desafio(s) atualizado(s), {not_found} não encontrado(s) no banco.")


if __name__ == "__main__":
    main()
