"""
Agente Sentinela de Conteúdo (AGENTE_SENTINELA_CONTEUDO_V1.md).

Uso:
    export MENTAL_DATABASE_URL="postgresql+psycopg://..."   # sem isso usa o SQLite local de dev
    cd backend && python3 scripts/sentinela.py                       # só reporta (não altera nada)
    python3 scripts/sentinela.py --territorio concursos_municipal_portugues
    python3 scripts/sentinela.py --aplicar-mecanico                  # corrige só espaço sobrando
Relatório em ../Auditorias_Pre_Producao/sentinela/RELATORIO_<data>.md
"""

import argparse
import datetime
import pathlib
import sys

sys.path.insert(0, ".")

from app.db import SessionLocal, engine  # noqa: E402
from app.sentinela import render_report, scan  # noqa: E402


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--territorio", action="append", help="limita a um território (repetível)")
    ap.add_argument("--aplicar-mecanico", action="store_true", help="aplica só as correções mecânicas")
    args = ap.parse_args()
    with SessionLocal() as db:
        findings = scan(db, args.territorio, apply=args.aplicar_mecanico)
    scope = ", ".join(args.territorio) if args.territorio else "todos os territórios"
    report = render_report(findings, f"{scope} (banco: {engine.dialect.name})")
    out_dir = pathlib.Path("../Auditorias_Pre_Producao/sentinela")
    out_dir.mkdir(parents=True, exist_ok=True)
    out = out_dir / f"RELATORIO_{datetime.datetime.now():%Y%m%d_%H%M}.md"
    out.write_text(report, encoding="utf-8")
    print(report.splitlines()[3])
    print(f"Relatório: {out}")


if __name__ == "__main__":
    main()
