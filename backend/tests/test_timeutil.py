"""
Achado real em produção (2026-08-23): colunas timestamptz (movement_
cycle_anchor_at, last_seen_at, parental_gate_passed_at) voltam do driver
psycopg3 como datetime AWARE, enquanto utcnow() é deliberadamente naive
(timeutil.py). Isso nunca apareceu nos testes locais (SQLite não tem esse
conceito), só na primeira vez que o backend conseguiu falar de verdade
com o Postgres em produção. naive() existe pra normalizar esse valor
antes de qualquer subtração/comparação com utcnow().
"""

from datetime import datetime, timezone

from app.movement import _cycle_window_for
from app.timeutil import naive, utcnow


def test_naive_strips_tzinfo_from_aware_datetime():
    aware = datetime(2026, 8, 23, 12, 0, 0, tzinfo=timezone.utc)
    result = naive(aware)
    assert result.tzinfo is None
    assert result == datetime(2026, 8, 23, 12, 0, 0)


def test_naive_leaves_naive_datetime_unchanged():
    already_naive = datetime(2026, 8, 23, 12, 0, 0)
    assert naive(already_naive) == already_naive
    assert naive(already_naive).tzinfo is None


def test_naive_passes_through_none():
    assert naive(None) is None


def test_cycle_window_for_accepts_aware_now_without_raising():
    """Reprodução direta do TypeError real visto em produção: comparar/
    subtrair um datetime aware (vindo do driver psycopg3) com um naive
    (utcnow()) lançava 'can't subtract offset-naive and offset-aware
    datetimes' — sem isso, /movement/status ficava permanentemente
    quebrado (500) pra qualquer usuário com o contador de passos ativo.
    _cycle_window_for não recebe mais anchor (MENTAL_ESPECIFICACAO_
    TECNICA_APROVADA_MOVIMENTO_v2.docx §4 — ciclo é sempre meia-noite de
    Brasília, igual pra todo mundo), mas `now` em si ainda pode chegar
    aware de algum chamador — a função precisa continuar tolerando isso."""
    aware_now = datetime(2026, 8, 20, 15, 0, 0, tzinfo=timezone.utc)

    cycle_start, cycle_end = _cycle_window_for(aware_now)

    assert cycle_start.tzinfo is None
    assert cycle_end.tzinfo is None
    assert cycle_start <= naive(aware_now) < cycle_end
