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


def naive(dt: datetime | None) -> datetime | None:
    """Remove o tzinfo de um datetime, se houver.

    Achado real em produção (2026-08-23, primeira vez que o backend
    conseguiu falar de verdade com o Postgres — antes disso a conexão
    nunca funcionava): colunas `timestamptz` (ex.: movement_cycle_
    anchor_at, last_seen_at, parental_gate_passed_at, challenger_served_
    at) voltam do driver psycopg3 como datetime AWARE, enquanto utcnow()
    aqui é deliberadamente naive (ver docstring do módulo). Subtrair um
    aware de um naive lança `TypeError: can't subtract offset-naive and
    offset-aware datetimes` — nunca apareceu em teste local (SQLite não
    tem esse conceito) nem em produção antes (a conexão em si já falhava
    por outro motivo). Usar em qualquer subtração/comparação entre
    utcnow() e um datetime vindo do banco.
    """
    return dt.replace(tzinfo=None) if dt is not None and dt.tzinfo is not None else dt
