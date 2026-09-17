"""
Auditoria de segurança pré-lançamento mundial (17/09/2026) — achado M5:
GET /ranking trazia a base INTEIRA de usuários pra memória do Python só
pra numerar posição via enumerate() e descartar tudo fora do top 50.
Correção: row_number() calculado no banco, WHERE já filtra pra só
trazer o top 50 + a própria linha do usuário. Este teste prova que o
contrato (rank correto, "me" presente mesmo fora do top 50, resposta
limitada a 50 entries) continua valendo com mais de 50 usuários — nada
disso era exercitado antes (nenhum teste existente passava de ~10
usuários).
"""

import uuid

from app import models
from app.db import SessionLocal

from .conftest import auth_header


# Base alta e bem acima de qualquer XP real que outros testes desta
# mesma suíte possam gravar no fixture `client` compartilhado (session-
# scoped, banco único — mesmo cuidado já documentado em
# test_social_overtake_fires_with_nickname_for_adult) — garante que
# NINGUÉM de outro teste entra no meio do ranking sintético destes 55
# jogadores.
_XP_BASE = 10_000_000


def _make_player_with_xp(client, xp: int) -> str:
    user_id = str(uuid.uuid4())
    client.post("/age-gate", json={"age_confirmed": True}, headers=auth_header(user_id))
    with SessionLocal() as db:
        profile = db.get(models.Profile, user_id)
        profile.xp_total = xp
        db.commit()
    return user_id


def test_global_all_time_ranking_limits_to_top_50_but_still_reports_my_rank_outside_it(client):
    # 55 jogadores com XP decrescente — o último criado (o "eu" deste
    # teste) fica em 55º lugar, fora do top 50.
    user_ids = [_make_player_with_xp(client, xp=_XP_BASE - i * 10) for i in range(55)]
    me = user_ids[-1]

    body = client.get("/ranking", params={"scope": "global", "window": "all_time"}, headers=auth_header(me)).json()

    assert len(body["entries"]) == 50, "resposta nunca deve trazer mais que o top 50"
    assert body["entries"][0]["rank"] == 1
    assert body["entries"][0]["user_id"] == user_ids[0]

    assert body["me"] is not None, "usuário fora do top 50 ainda precisa aparecer em 'me'"
    assert body["me"]["user_id"] == me
    assert body["me"]["rank"] == 55
    assert not any(e["user_id"] == me for e in body["entries"]), "fora do top 50, não deveria estar duplicado em entries"


def test_global_all_time_ranking_me_inside_top_50_appears_once_not_duplicated(client):
    # Base diferente da usada no teste acima (mesmo banco compartilhado
    # entre os dois, na mesma sessão de pytest) — evita colisão/empate
    # entre os dois lotes sintéticos de XP.
    xp_base = _XP_BASE + 1_000_000
    user_ids = [_make_player_with_xp(client, xp=xp_base - i * 10) for i in range(10)]
    me = user_ids[3]  # 4º lugar, dentro do top 50

    body = client.get("/ranking", params={"scope": "global", "window": "all_time"}, headers=auth_header(me)).json()

    assert body["me"]["rank"] == 4
    matches = [e for e in body["entries"] if e["user_id"] == me]
    assert len(matches) == 1
    assert matches[0]["rank"] == 4
