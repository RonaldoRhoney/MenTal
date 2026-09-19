"""
AUDITORIA_GLOBAL_CONTEUDO_V1.md — leva pro banco (produção ou dev) as
correções feitas diretamente nos arquivos backend/content/*.json depois
que o conteúdo já tinha sido carregado antes (diferente de
append_production_content.py, que só INSERE item novo — aqui o item já
existe, só o campo mudou). Casa por (territory_id, prompt), igual à
chave de idempotência já usada em todo o resto do app.

Dois campos corrigidos nesta auditoria:
- explanation (Challenge.explanation): estava vazia em 200 itens de
  Copa do Mundo/Futebol.
- hints[0] (ChallengeHint com hint_level=1): em 624 itens com
  reading_passage, citava um título que o jogador nunca via na tela.

Idempotente: rodar de novo não faz nada além de reconfirmar o valor já
corrigido (sempre grava o valor atual do JSON, nunca acumula).

Uso:
    export MENTAL_DATABASE_URL="postgresql+psycopg://..."  # ou sqlite pra testar em dev
    cd backend && python3 scripts/apply_content_audit_fixes.py content/<arquivo>.json [content/<arquivo2>.json ...]
"""

import json
import sys

sys.path.insert(0, ".")

from app import models  # noqa: E402
from app.db import SessionLocal  # noqa: E402


def main() -> None:
    if len(sys.argv) < 2:
        print("Uso: python3 scripts/apply_content_audit_fixes.py content/<arquivo>.json [...]")
        sys.exit(1)

    explanation_updated = 0
    hint_updated = 0
    not_found = 0

    with SessionLocal() as db:
        for path in sys.argv[1:]:
            with open(path, encoding="utf-8") as f:
                items = json.load(f)

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
                    print(f"⚠️  não encontrado no banco: {item['territory_id']!r} / {item['prompt'][:60]!r}")
                    continue

                new_explanation = item.get("explanation")
                if new_explanation and challenge.explanation != new_explanation:
                    challenge.explanation = new_explanation
                    explanation_updated += 1

                new_hints = item.get("hints") or []
                if new_hints:
                    first_hint = (
                        db.query(models.ChallengeHint)
                        .filter(
                            models.ChallengeHint.challenge_id == challenge.id,
                            models.ChallengeHint.hint_level == 1,
                        )
                        .one_or_none()
                    )
                    if first_hint is not None and first_hint.content != new_hints[0]:
                        first_hint.content = new_hints[0]
                        hint_updated += 1

            db.commit()
            print(f"✅ {path}: processado")

    print(f"\nexplanation atualizada: {explanation_updated}")
    print(f"hints[0] atualizado: {hint_updated}")
    print(f"não encontrado no banco (prompt não bate): {not_found}")


if __name__ == "__main__":
    main()
