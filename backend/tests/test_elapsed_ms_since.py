"""
Bug real em produção (28/08/2026), logo após o deploy da correção de
segurança que passou a calcular o bônus de velocidade a partir de
Attempt.served_at: em Postgres essa coluna é `timestamptz` e volta do
driver como datetime AWARE, enquanto `utcnow()` deste projeto é
deliberadamente naive (timeutil.py) — subtrair aware de naive sem
`naive()` lança `TypeError: can't subtract offset-naive and
offset-aware datetimes`, quebrando TODA resposta nova (POST /answer)
com 500 em produção, não só em território cronometrado.

Um teste passando por client+SQLite nunca pegaria essa classe de bug:
SQLite sempre devolve o datetime naive depois de um round-trip pelo ORM
(confirmado manualmente), mesmo gravando um valor aware antes do
commit. Só um teste unitário direto, com um datetime aware de verdade
em memória (sem passar pelo banco), reproduz o cenário real do
Postgres — por isso services.elapsed_ms_since foi extraída como função
pura, exatamente para ser testável assim.
"""

from datetime import datetime, timedelta, timezone

from app.services import elapsed_ms_since
from app.timeutil import utcnow


def test_elapsed_ms_since_accepts_timezone_aware_datetime():
    served_at = datetime.now(timezone.utc) - timedelta(seconds=2)
    assert elapsed_ms_since(served_at) >= 2000


def test_elapsed_ms_since_accepts_naive_datetime():
    served_at = utcnow() - timedelta(seconds=1)
    assert elapsed_ms_since(served_at) >= 1000


def test_elapsed_ms_since_never_negative():
    served_at = datetime.now(timezone.utc) + timedelta(seconds=5)
    assert elapsed_ms_since(served_at) == 0
