"""
Auditoria de segurança pré-lançamento mundial (17/09/2026) — achado A3:
nenhum caminho que credita XP travava a linha antes de somar, abrindo
janela de corrida (duas requisições concorrentes lendo o mesmo estado
"ainda não creditado" antes de qualquer commit, ambas creditando).

SQLite (banco dos testes) não tem lock de linha de verdade — o próprio
agente de auditoria confirmou isso ("os testes não pegam isso... SQLite
local serializa tudo"). Não dá pra provar aqui que o lock IMPEDE a
corrida em produção sem um Postgres real com conexões concorrentes de
verdade. O que estes testes provam, e é o suficiente pra evitar
regressão silenciosa (alguém remover o `with_for_update`/
`for_update=True` sem perceber, numa refatoração futura): que a
chamada com o lock está de fato presente no código-fonte dos pontos
que a auditoria apontou.
"""

import inspect

from app import movement
from app.routers import challenges, social


def test_answer_endpoint_locks_attempt_and_profile_rows():
    """routers/challenges.py::submit_answer — o único caminho que
    credita XP a partir de uma resposta de desafio."""
    source = inspect.getsource(challenges.submit_answer)
    assert "_get_or_create_pending_attempt(db, body.attempt_id, user_id, challenge_id, for_update=True)" in source
    assert "services.get_or_create_profile(db, user_id, for_update=True)" in source


def test_movement_collect_locks_the_cycle_row():
    """app/movement.py::collect_steps — os dois caminhos (ciclo atual
    inferido, e ciclo explícito por cycle_id)."""
    source = inspect.getsource(movement.collect_steps)
    assert "get_current_cycle(db, profile, now, for_update=True)" in source
    assert "db.get(models.MovementCycle, cycle_id, with_for_update=True)" in source


def test_share_reward_endpoints_lock_the_profile_row():
    """routers/social.py::reward_share/reward_app_invite_share — teto
    de 1 recompensa/dia, sem lock a corrida permitia 2+."""
    reward_share_source = inspect.getsource(social.reward_share)
    reward_invite_source = inspect.getsource(social.reward_app_invite_share)
    assert "db.get(models.Profile, user_id, with_for_update=True)" in reward_share_source
    assert "db.get(models.Profile, user_id, with_for_update=True)" in reward_invite_source
