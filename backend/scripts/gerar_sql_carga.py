"""
Gera SQL de carga de conteúdo (idempotente) a partir de um JSON de content/ — equivalente ao
scripts/append_production_content.py, mas para colar no Supabase SQL Editor (sem URL de banco).

Uso:  python3 scripts/gerar_sql_carga.py <nome_saida> content/a.json [content/b.json ...]
Saída: content/sql/<nome_saida>.sql (vários JSON podem ir no mesmo arquivo)

Cada desafio só é inserido se ainda não existir (territory_id + prompt), com as 2 dicas; no fim
marca o território como "conteúdo atualizado" (mesmo gatilho do script Python). Textos entram
como strings entre dollar-quotes ($q$...$q$), que dispensam escape de aspas.
"""

import json
import pathlib
import sys

sys.path.insert(0, ".")
from app.content_validation import validate_content  # noqa: E402
from app.seed import TERRITORIES  # noqa: E402

SIMPLE_FIELDS = {"territory_id", "difficulty_level", "prompt", "options", "correct_answer", "explanation", "age_reviewed", "hints"}


def q(text: str) -> str:
    assert "$q$" not in text, text
    return f"$q${text}$q$"


def main() -> None:
    name = sys.argv[1]
    paths = [pathlib.Path(p) for p in sys.argv[2:]]
    items = [i for path in paths for i in json.loads(path.read_text(encoding="utf-8"))]
    errors = validate_content(items, {t["id"] for t in TERRITORIES}, set())
    if errors:
        print("\n".join(errors))
        sys.exit(1)
    extras = {k for i in items for k in i} - SIMPLE_FIELDS
    if extras:
        print(f"Campos não suportados neste gerador: {sorted(extras)} — use o script Python.")
        sys.exit(1)
    lines = [f"-- Carga de {', '.join(p.name for p in paths)}: {len(items)} desafios (idempotente: pula o que já existe).", "begin;"]
    territories: list[str] = []
    for it in items:
        t = it["territory_id"]
        if t not in territories:
            territories.append(t)
        hints = " union all ".join(f"select id, {n}, {q(h)} from c" for n, h in enumerate(it["hints"], start=1))
        lines.append(
            "with c as (insert into mental.challenges "
            "(territory_id, difficulty_level, prompt, options, correct_answer, explanation, age_reviewed) "
            f"select {q(t)}, {int(it['difficulty_level'])}, {q(it['prompt'])}, "
            f"{q(json.dumps(it['options'], ensure_ascii=False))}::jsonb, {q(it['correct_answer'])}, "
            f"{q(it['explanation'])}, {'true' if it['age_reviewed'] else 'false'} "
            f"where not exists (select 1 from mental.challenges where territory_id = {q(t)} and prompt = {q(it['prompt'])}) "
            "returning id) "
            f"insert into mental.challenge_hints (challenge_id, hint_level, content) {hints};"
        )
    ids = ", ".join(q(t) for t in territories)
    lines.append(f"update mental.territories set content_updated_at = (now() at time zone 'utc') where id in ({ids});")
    lines.append("commit;")
    out = pathlib.Path("content/sql")
    out.mkdir(exist_ok=True)
    target = out / (name + ".sql")
    target.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"{target} ({target.stat().st_size // 1024} KB, {len(items)} desafios)")


if __name__ == "__main__":
    main()
