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

from datetime import date, datetime, timedelta, timezone


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


def format_brasilia_time(dt: datetime) -> str:
    """Espelha client/lib/brasilia_time.dart::formatBrasiliaTime — mesmo
    texto ("05:13 da manhã", "17:13 da tarde"), agora também no servidor
    porque o corpo de notificação precisa vir pronto do backend
    (CENTRAL_DE_NOTIFICACOES_HOME_V1.md: "título/corpo montados no
    SERVIDOR, nunca formatado no client"). `dt` é UTC naive (mesmo
    contrato de utcnow()); UTC-3 fixo, sem horário de verão desde 2019."""
    br = naive(dt) - timedelta(hours=3)
    hh = f"{br.hour:02d}"
    mm = f"{br.minute:02d}"
    if br.hour < 5:
        period = "da madrugada"
    elif br.hour < 12:
        period = "da manhã"
    elif br.hour < 18:
        period = "da tarde"
    else:
        period = "da noite"
    return f"{hh}:{mm} {period}"


def week_anchor(d: date) -> date:
    """Segunda-feira da semana de `d` (âncora da folga semanal de streak)."""
    return d - timedelta(days=d.weekday())


def brasilia_today() -> date:
    """Data civil em Brasília (UTC-3 fixo — o Brasil não tem horário de
    verão desde 2019). Usada só pelo teto diário de XP (Fase 3, decisão de
    Rhoney 20/09/2026): o dia do jogador vira à meia-noite dele, não às
    21h. O resto do app segue em UTC."""
    return (utcnow() - timedelta(hours=3)).date()
