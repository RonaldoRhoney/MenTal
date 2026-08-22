"""
Valida um arquivo de conteúdo curado (backend/content/README.md) ANTES
de qualquer coisa tocar o banco. Só checa estrutura — nunca julga se o
conteúdo em si está correto (RISKS_AND_OPEN_DECISIONS.md §2).

Uso:
    cd backend && python3 scripts/validate_content.py content/<arquivo>.json
"""

import json
import sys

sys.path.insert(0, ".")

from app.content_validation import validate_content  # noqa: E402
from app.seed import CHALLENGES, TERRITORIES  # noqa: E402


def main() -> None:
    if len(sys.argv) != 2:
        print("Uso: python3 scripts/validate_content.py content/<arquivo>.json")
        sys.exit(1)

    path = sys.argv[1]
    with open(path, encoding="utf-8") as f:
        items = json.load(f)

    known_territory_ids = {t["id"] for t in TERRITORIES}
    existing_prompts = {(c["territory_id"], c["prompt"]) for c in CHALLENGES}

    errors = validate_content(items, known_territory_ids, existing_prompts)

    if errors:
        print(f"❌ {len(errors)} erro(s) encontrado(s) em {path}:\n")
        for error in errors:
            print(f"  - {error}")
        sys.exit(1)

    print(f"✅ {path}: {len(items)} desafio(s) validado(s), nenhum erro estrutural.")


if __name__ == "__main__":
    main()
