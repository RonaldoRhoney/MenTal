"""
Selo "Novo" em desafios (07/09/2026, pedido de Rhoney, ao ver os 230
desafios do Mundo da Linguagem redistribuídos entre níveis 1/2/3
"misturados" ao conteúdo antigo — sem nenhuma pista visual de que eram
recentes): Challenge.created_at (migration 066) alimenta
services.is_challenge_new, que decide se o desafio ainda está dentro da
janela de destaque (config.NEW_CONTENT_BADGE_WINDOW_DAYS). Autoridade
sempre no servidor — o client nunca decide isso sozinho.
"""

import uuid
from datetime import timedelta

from app import config, models
from app.db import SessionLocal
from app.seed import CHALLENGES
from app.services import is_challenge_new
from app.timeutil import utcnow

from .conftest import auth_header


def _get_challenge_row(prompt: str) -> models.Challenge:
    with SessionLocal() as db:
        challenge = db.query(models.Challenge).filter(models.Challenge.prompt == prompt).one()
        db.expunge(challenge)
        return challenge


def test_is_challenge_new_is_false_when_created_at_is_null():
    challenge = models.Challenge(created_at=None)
    assert is_challenge_new(challenge) is False


def test_is_challenge_new_is_true_within_the_badge_window():
    challenge = models.Challenge(created_at=utcnow() - timedelta(days=1))
    assert is_challenge_new(challenge) is True


def test_is_challenge_new_is_false_after_the_badge_window_expires():
    challenge = models.Challenge(created_at=utcnow() - timedelta(days=config.NEW_CONTENT_BADGE_WINDOW_DAYS + 1))
    assert is_challenge_new(challenge) is False


def test_challenges_next_reports_is_new_true_for_a_recently_created_challenge(client):
    sample = next(c for c in CHALLENGES if c["territory_id"] == "numeros")
    with SessionLocal() as db:
        row = db.query(models.Challenge).filter(models.Challenge.prompt == sample["prompt"]).one()
        row.created_at = utcnow()
        db.commit()

    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    # Achado real escrevendo este teste: a 1ª palavra do prompt (padrão
    # usado em test_content_search.py) não é garantidamente única — vários
    # desafios podem começar com "Qual"/"O"/"Como" etc., e a busca sempre
    # devolve o PRIMEIRO match (find_challenge_by_search não tem ranking),
    # que pode não ser a linha que este teste acabou de editar. Um trecho
    # mais longo do prompt reduz drasticamente essa chance de colisão.
    needle = sample["prompt"][:40]
    resp = client.get("/challenges/search", params={"q": needle}, headers=headers)
    body = resp.json()

    assert body["found"] is True
    assert body["challenge"]["is_new"] is True


def test_challenges_next_reports_is_new_false_for_old_content_without_created_at(client):
    sample = next(c for c in CHALLENGES if c["territory_id"] == "logica")

    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    # Achado real escrevendo este teste: a 1ª palavra do prompt (padrão
    # usado em test_content_search.py) não é garantidamente única — vários
    # desafios podem começar com "Qual"/"O"/"Como" etc., e a busca sempre
    # devolve o PRIMEIRO match (find_challenge_by_search não tem ranking),
    # que pode não ser a linha que este teste acabou de editar. Um trecho
    # mais longo do prompt reduz drasticamente essa chance de colisão.
    needle = sample["prompt"][:40]
    resp = client.get("/challenges/search", params={"q": needle}, headers=headers)
    body = resp.json()

    assert body["found"] is True
    # Conteúdo de seed (dev/test) nasce com created_at=utcnow() pelo
    # default do ORM — não representa o estado real de produção (onde
    # todo conteúdo pré-migration 066 tem created_at NULL). Este teste
    # cobre o outro lado: um created_at explicitamente NULL nunca é "novo".
    with SessionLocal() as db:
        row = db.query(models.Challenge).filter(models.Challenge.prompt == sample["prompt"]).one()
        row.created_at = None
        db.commit()

    resp2 = client.get("/challenges/search", params={"q": needle}, headers=headers)
    assert resp2.json()["challenge"]["is_new"] is False
