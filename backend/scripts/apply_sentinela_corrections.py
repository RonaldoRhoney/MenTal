"""
Aplica as correções de conteúdo aprovadas por Rhoney (Agente Sentinela,
AGENTE_SENTINELA_CONTEUDO_V1.md §4.2) — nunca correção automática, sempre
a partir de um arquivo já revisado e aprovado item a item.

Casa cada correção por (territory_id, prompt ORIGINAL) — não por challenge_id,
porque o arquivo de correções foi gerado contra uma base local, cujos IDs não
existem em produção. Se o prompt original não bater exatamente (ex.: alguém
editou o item nesse meio tempo), a correção é pulada e reportada, nunca
aplicada "no chute".

Uso:
    export MENTAL_DATABASE_URL="postgresql+psycopg://..."   # sem isso usa o SQLite local de dev
    cd backend && python3 scripts/apply_sentinela_corrections.py                       # só reporta (dry-run)
    python3 scripts/apply_sentinela_corrections.py --aplicar                           # aplica de verdade
"""

import argparse
import json
import pathlib
import sys

sys.path.insert(0, ".")

from sqlalchemy import select  # noqa: E402

from app import models  # noqa: E402
from app.db import SessionLocal  # noqa: E402

CORRECOES_PATH = pathlib.Path(__file__).resolve().parent.parent.parent / "Auditorias_Pre_Producao" / "sentinela" / "correcoes_20261004.json"


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--aplicar", action="store_true", help="aplica de verdade (sem isso, só reporta o que seria feito)")
    args = ap.parse_args()

    fixes = json.loads(CORRECOES_PATH.read_text(encoding="utf-8"))

    aplicados, nao_encontrados = 0, []
    with SessionLocal() as db:
        for fx in fixes:
            challenge = db.execute(
                select(models.Challenge).where(
                    models.Challenge.territory_id == fx["territory_id"],
                    models.Challenge.prompt == fx["prompt_original"],
                )
            ).scalar_one_or_none()
            if challenge is None:
                nao_encontrados.append(fx)
                continue

            if fx["tipo"] == "prompt":
                if challenge.prompt != fx["antigo"]:
                    nao_encontrados.append(fx)
                    continue
                if args.aplicar:
                    challenge.prompt = fx["novo"]
                aplicados += 1
            elif fx["tipo"] == "hint":
                hints = db.execute(
                    select(models.ChallengeHint)
                    .where(models.ChallengeHint.challenge_id == challenge.id)
                    .order_by(models.ChallengeHint.hint_level)
                ).scalars().all()
                idx = fx["hint_index"]
                if idx >= len(hints) or hints[idx].content != fx["antigo"]:
                    nao_encontrados.append(fx)
                    continue
                if args.aplicar:
                    hints[idx].content = fx["novo"]
                aplicados += 1

        if args.aplicar:
            db.commit()

    print(f"{'Aplicados' if args.aplicar else 'Encontrados (dry-run, nada aplicado)'}: {aplicados} de {len(fixes)}")
    if nao_encontrados:
        print(f"Não encontrados/não bateram (pulados, revisar manualmente): {len(nao_encontrados)}")
        for fx in nao_encontrados:
            print(f"  - {fx['territory_id']} · {fx['prompt_original'][:70]!r}")


if __name__ == "__main__":
    main()
