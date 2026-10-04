"""
MENTAL_ESPECIFICACAO_FLUXO_PROGRESSAO_MAPA_RANKING_FEEDBACK_V1.1.md §4
(generalizada em 04/10/2026, pedido de Rhoney: "que ao entrar em um
mundo (todos), o desafio comece do mais básico e vá subindo em
progressão... dentro de cada mundo deve obrigatoriamente seguir a
progressão") — generaliza o desbloqueio sequencial (antes só famílias
Básico/Intermediário/Avançado de Idiomas, ver test_sequential_
progression.py) pra qualquer Mundo, usando a ordem de exibição já
curada (display_order) dentro do mesmo agrupamento visual que o client
já usa pra desenhar as seções ((world_id, block_id) — territórios sem
bloco ficam soltos juntos na tela do Mundo, territórios com block_id
formam sua própria seção).
"""

import uuid

from app import models
from app.db import SessionLocal

from .conftest import auth_header, conquer_territory


def _set_admin(user_id: str) -> None:
    with SessionLocal() as db:
        profile = db.get(models.Profile, user_id)
        profile.role = "admin"
        db.commit()


def _visible_map(client, headers) -> dict:
    progress = client.get("/progress", headers=headers).json()
    return {t["territory_id"]: t["visible"] for t in progress["territories"]}


def test_second_territory_of_a_generic_group_is_hidden_until_the_first_is_conquered(client):
    # Mundo dos Valores, sem block_id: bolsa(1) -> criptomoedas(2) ->
    # cenario_global(3) -> financas_dia_a_dia(4), nessa ordem de
    # display_order.
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    visible = _visible_map(client, headers)
    assert visible["bolsa"] is True
    assert visible["criptomoedas"] is False
    assert visible["cenario_global"] is False
    assert visible["financas_dia_a_dia"] is False

    conquer_territory(user, "bolsa")
    visible = _visible_map(client, headers)
    assert visible["criptomoedas"] is True
    assert visible["cenario_global"] is False


def test_grandfather_clause_keeps_an_already_attempted_generic_territory_reachable(client):
    """Progresso real de antes desta regra existir nunca é
    retroativamente trancado — mesmo raciocínio já aplicado à família de
    Idiomas (test_sequential_progression.py)."""
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    with SessionLocal() as db:
        challenge_id = db.query(models.Challenge.id).filter(models.Challenge.territory_id == "criptomoedas").limit(1).scalar()
        db.add(models.Attempt(attempt_id=models.new_uuid(), user_id=user, challenge_id=challenge_id))
        db.commit()

    resp = client.get("/challenges/next", params={"territory_id": "criptomoedas"}, headers=headers)
    assert resp.status_code == 200


def test_territory_locked_by_the_generic_gate_returns_403(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    resp = client.get("/challenges/next", params={"territory_id": "criptomoedas"}, headers=headers)
    assert resp.status_code == 403
    assert resp.json()["error"]["code"] == "TERRITORY_LOCKED"


def test_single_territory_groups_are_never_locked(client):
    # "regioes" é o único território do Mundo "regioes_brasil" — grupo de
    # 1, nunca trava (nada a esperar).
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    resp = client.get("/challenges/next", params={"territory_id": "regioes"}, headers=headers)
    assert resp.status_code == 200


def test_blocks_within_a_world_sequence_independently(client):
    # Mundo dos Esportes: bloco "copa_do_mundo" (4 territórios) e bloco
    # "futebol" (4 territórios) são grupos DIFERENTES — conquistar o
    # primeiro de um não destrava o outro nem é prerequisito dele.
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    visible = _visible_map(client, headers)
    assert visible["copa_mundo_primeiras_copas"] is True
    assert visible["futebol_origens"] is True
    assert visible["copa_mundo_expansao"] is False
    assert visible["futebol_grandes_nomes"] is False


def test_idiomas_family_based_sequencing_is_unaffected_by_the_generic_fallback(client):
    """O bloco "ingles" tem VÁRIAS famílias (ingles_basico/intermediario/
    avancado, ingles_phrasal_*, ingles_preposicoes_*, ...) — a sequência
    genérica por display_order NUNCA deve se aplicar aqui, cada família
    segue seu próprio gate independente (test_sequential_progression.py),
    senão todo o bloco viraria uma única cadeia gigante."""
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    visible = _visible_map(client, headers)
    # ingles_basico (família "ingles", nível 1) e ingles_phrasal_basico
    # (família "ingles_phrasal", nível 1) são AMBOS nível 1 de famílias
    # diferentes — ambos visíveis desde o início, mesmo o bloco "ingles"
    # tendo dezenas de territórios depois deles em display_order.
    assert visible["ingles_basico"] is True
    assert visible["ingles_phrasal_basico"] is True
    assert visible["ingles_preposicoes_basico"] is True


def test_admin_sees_every_territory_as_reachable_regardless_of_progress(client):
    """Pedido explícito de Rhoney (04/10/2026): "eu como adm posso ver
    tudos, mas o usuário comum não"."""
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)
    _set_admin(user)

    visible = _visible_map(client, headers)
    assert visible["criptomoedas"] is True
    assert visible["financas_dia_a_dia"] is True

    resp = client.get("/challenges/next", params={"territory_id": "financas_dia_a_dia"}, headers=headers)
    assert resp.status_code == 200
