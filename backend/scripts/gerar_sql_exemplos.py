"""
Gera o SQL de carga das frases-exemplo do Mental Lingo (fase 2), para colar no Supabase SQL Editor.
Inclui a criação da tabela (idêntica à migration 105, com `if not exists`) e os inserts
idempotentes (`on conflict do nothing`), já como `approved` — só rode depois da aprovação de Rhoney.

Uso: python3 scripts/gerar_sql_exemplos.py <saida> <json_de_exemplos> [<json2> <json3> ...]
Aceita um ou mais arquivos JSON — todos entram no mesmo arquivo .sql de saída.
"""

import json
import pathlib
import sys

DDL = pathlib.Path(__file__).resolve().parents[1] / "migrations" / "105_mental_lingo_exemplos.sql"


def q(text: str) -> str:
    assert "$q$" not in text, text
    return f"$q${text}$q$"


def main() -> None:
    name = sys.argv[1]
    srcs = [pathlib.Path(p) for p in sys.argv[2:]]
    rows = [r for src in srcs for r in json.loads(src.read_text(encoding="utf-8"))]
    names = ", ".join(src.name for src in srcs)
    lines = [f"-- Frases-exemplo do Mental Lingo: {names} ({len(rows)} frases). Idempotente.", "begin;", DDL.read_text(encoding="utf-8")]
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
