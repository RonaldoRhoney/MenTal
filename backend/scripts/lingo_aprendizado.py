"""
Curadoria do aprendizado do Mental Lingo (pedido de Rhoney, 26/09/2026).

  python3 scripts/lingo_aprendizado.py perguntas [N]          -> as N perguntas não entendidas mais frequentes
  python3 scripts/lingo_aprendizado.py padrao <intencao> "<regex>" ["pergunta de teste"]
        -> valida a regex (e testa contra a pergunta) e cadastra como APROVADA (vale sem deploy)
  python3 scripts/lingo_aprendizado.py descartar "<texto>"     -> tira a pergunta da fila

intencao: traducao (grupo 1 = termo, grupo 2 opcional = idioma) | exemplo (grupo 1 = termo).
O texto das perguntas é agregado e sem usuário. Nada é aprendido sozinho: só entra o que você aprovar aqui.
"""

import re
import sys

sys.path.insert(0, ".")

from app import models  # noqa: E402
from app.db import SessionLocal  # noqa: E402


def main() -> None:
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    cmd = sys.argv[1]
    with SessionLocal() as db:
        if cmd == "perguntas":
            limit = int(sys.argv[2]) if len(sys.argv) > 2 else 30
            rows = (
                db.query(models.MentalLingoUnknownQuestion)
                .filter(models.MentalLingoUnknownQuestion.status == "aberta")
                .order_by(models.MentalLingoUnknownQuestion.vezes.desc(), models.MentalLingoUnknownQuestion.ultima_vez.desc())
                .limit(limit)
                .all()
            )
            print(f"{len(rows)} pergunta(s) não entendida(s) em aberto:")
            for r in rows:
                print(f"  {r.vezes:>4}x  {r.texto}")
        elif cmd == "padrao":
            intent, regex = sys.argv[2], sys.argv[3]
            example = sys.argv[4] if len(sys.argv) > 4 else None
            if intent not in ("traducao", "exemplo"):
                sys.exit("intencao deve ser 'traducao' ou 'exemplo'")
            pattern = re.compile(regex, re.IGNORECASE)  # levanta erro se inválida
            if len(regex) > 300 or pattern.groups < 1:
                sys.exit("regex precisa ter ao menos 1 grupo (o termo) e até 300 caracteres")
            if example is not None:
                m = pattern.match(example)
                if not m:
                    sys.exit(f"a regex NÃO casa com o exemplo {example!r} — nada foi cadastrado")
                print(f"testado: termo = {m.group(1)!r}")
            db.add(models.MentalLingoPattern(intencao=intent, regex=regex, exemplo=example, status="approved"))
            db.commit()
            print("✅ padrão cadastrado e ativo (vale sem deploy).")
        elif cmd == "descartar":
            row = db.get(models.MentalLingoUnknownQuestion, sys.argv[2].strip().lower())
            if row is None:
                sys.exit("pergunta não encontrada")
            row.status = "descartada"
            db.commit()
            print("descartada.")
        else:
            print(__doc__)


if __name__ == "__main__":
    main()
