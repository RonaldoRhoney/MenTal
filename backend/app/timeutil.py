"""
Substituto de datetime.utcnow() (V2_KICKOFF.md §8 — pendência de
manutenção registrada desde o início da V2, resolvida agora que a V2
inteira fechou). datetime.utcnow() está deprecado no Python e será
removido numa versão futura.

Retorna naive (sem tzinfo), com o MESMO valor que datetime.utcnow() já
sempre retornou — preserva 100% o comportamento existente (comparações,
armazenamento em colunas DateTime sem timezone, serialização) sem
nenhuma mudança de arquitetura. Adotar timezone-awareness de verdade em
todo o banco (colunas TIMESTAMPTZ) é uma decisão arquitetural maior,
fora do escopo desta limpeza mecânica pré-lançamento.
"""

from datetime import datetime, timezone


def utcnow() -> datetime:
    return datetime.now(timezone.utc).replace(tzinfo=None)
