"""
Gera o SQL de carga das frases-exemplo do Mental Lingo (fase 2), para colar no Supabase SQL Editor.
Inclui a criação da tabela (idêntica à migration 105, com `if not exists`) e os inserts
idempotentes (`on conflict do nothing`), já como `approved` — só rode depois da aprovação de Rhoney.

Uso: python3 scripts/gerar_sql_exemplos.py <saida> <json_de_exemplos> [nivel]
"""

import json
import pathlib
import sys

DDL = pathlib.Path(__file__).resolve().parents[1] / "migrations" / "105_mental_lingo_exemplos.sql"


def q(text: str) -> str:
    assert "$q$" not in text, text
    return f"$q${text}$q$"


def main() -> None:
    name, src = sys.argv[1], pathlib.Path(sys.argv[2])
    rows = json.loads(src.read_text(encoding="utf-8"))
    lines = [f"-- Frases-exemplo do Mental Lingo: {src.name} ({len(rows)} frases). Idempotente.", "begin;", DDL.read_text(encoding="utf-8")]
    for r in rows:
        assert r["level"] in ("basico", "intermediario", "avancado")
        assert r["word"].lower() in r["sentence"].lower(), r
        lines.append(
            "insert into mental.lingo_exemplos (idioma, nivel, palavra, palavra_pt, frase, traducao, review_status) values "
            f"({q(r['language'])}, {q(r['level'])}, {q(r['word'])}, {q(r['word_pt'])}, {q(r['sentence'])}, {q(r['translation'])}, 'approved') "
            "on conflict (idioma, palavra, frase) do nothing;"
        )
    lines.append("commit;")
    out = pathlib.Path("content/sql") / f"{name}.sql"
    out.parent.mkdir(exist_ok=True)
    out.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"{out} ({out.stat().st_size // 1024} KB, {len(rows)} frases)")


if __name__ == "__main__":
    main()
