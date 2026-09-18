"""
MAPA_TRAJETORIA_MUNDOS_V1.md — Fase 1 (dados). GET /progress/trajectory-map
devolve um "planeta" por Mundo de primeiro nível, mais um planeta extra
por SubMundo confirmado (services.SUBMUNDO_BLOCK_IDS). Estes testes
provam: separação Mundo pai vs. SubMundo (territórios nunca contam nos
dois), cálculo de %/status/estrelas fiel ao progresso real, e que um
Mundo sem nenhum território não aparece.
"""

import uuid

from app import models
from app.db import SessionLocal

from .conftest import auth_header


def _set_territory_xp(user_id: str, territory_id: str, xp: int) -> None:
    with SessionLocal() as db:
        progress = db.get(models.UserTerritoryProgress, (user_id, territory_id))
        if progress is None:
            progress = models.UserTerritoryProgress(user_id=user_id, territory_id=territory_id, xp_in_territory=xp)
            db.add(progress)
        else:
            progress.xp_in_territory = xp
        db.commit()


def test_tecnologia_world_and_internet_submundo_appear_as_separate_nodes(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    body = client.get("/progress/trajectory-map", headers=headers).json()
    nodes_by_id = {n["id"]: n for n in body["nodes"]}

    assert "tecnologia" in nodes_by_id
    assert nodes_by_id["tecnologia"]["type"] == "world"
    assert nodes_by_id["tecnologia"]["parent_id"] is None

    assert "tecnologia:internet" in nodes_by_id
    submundo = nodes_by_id["tecnologia:internet"]
    assert submundo["type"] == "submundo"
    assert submundo["parent_id"] == "tecnologia"
    assert submundo["name"] == "Internet"

    # Territórios do SubMundo nunca contam no Mundo pai (senão
    # apareceriam duplicados nos dois planetas).
    for internet_territory in submundo["territory_ids"]:
        assert internet_territory not in nodes_by_id["tecnologia"]["territory_ids"]


def test_esportes_world_has_two_submundo_planets_copa_do_mundo_and_futebol(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    body = client.get("/progress/trajectory-map", headers=headers).json()
    nodes_by_id = {n["id"]: n for n in body["nodes"]}

    assert "esportes:copa_do_mundo" in nodes_by_id
    assert "esportes:futebol" in nodes_by_id
    assert nodes_by_id["esportes:copa_do_mundo"]["parent_id"] == "esportes"
    assert nodes_by_id["esportes:futebol"]["parent_id"] == "esportes"

    # Território clássico "esportes" (sem bloco) continua só no planeta
    # do Mundo pai, nunca nos SubMundos.
    assert "esportes" in nodes_by_id["esportes"]["territory_ids"]
    assert "esportes" not in nodes_by_id["esportes:copa_do_mundo"]["territory_ids"]
    assert "esportes" not in nodes_by_id["esportes:futebol"]["territory_ids"]


def test_percent_status_and_stars_reflect_real_progress(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    body = client.get("/progress/trajectory-map", headers=headers).json()
    nodes_by_id = {n["id"]: n for n in body["nodes"]}
    node = nodes_by_id["esportes:copa_do_mundo"]
    assert node["percent"] == 0.0
    assert node["status"] == "not_started"
    assert node["stars"] == 0
    assert node["xp_total"] == len(node["territory_ids"]) * 200

    # 200 XP (teto de conquista) no primeiro território, 0 nos outros 3
    # -> 1 de 4 territórios conquistado -> 25% do Mundo.
    _set_territory_xp(user, "copa_mundo_primeiras_copas", 200)

    body = client.get("/progress/trajectory-map", headers=headers).json()
    node = next(n for n in body["nodes"] if n["id"] == "esportes:copa_do_mundo")
    assert node["percent"] == 25.0
    assert node["status"] == "in_progress"
    assert node["stars"] == 0  # abaixo do primeiro marco (33%)

    # Completa os 4 territórios (200 XP cada, teto respeitado mesmo se
    # xp_in_territory viesse maior que o teto).
    for territory_id in node["territory_ids"]:
        _set_territory_xp(user, territory_id, 500)

    body = client.get("/progress/trajectory-map", headers=headers).json()
    node = next(n for n in body["nodes"] if n["id"] == "esportes:copa_do_mundo")
    assert node["percent"] == 100.0
    assert node["status"] == "completed"
    assert node["stars"] == 3
    assert node["xp_earned"] == node["xp_total"]  # teto respeitado, nunca ultrapassa


def test_world_without_any_territory_is_not_included(client):
    """Mesmo princípio já usado em services.get_blocks — Mundo sem
    nenhum território (nem próprio, nem de SubMundo) não vira planeta
    vazio no mapa."""
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    body = client.get("/progress/trajectory-map", headers=headers).json()
    node_ids = {n["id"] for n in body["nodes"]}
    # "vida_pratica_pensamento" e similares podem não existir mais
    # como mundo vazio — checagem estrutural: todo node tem pelo menos
    # 1 território somando o próprio + eventuais SubMundos.
    for node in body["nodes"]:
        assert len(node["territory_ids"]) > 0, f"{node['id']} não deveria aparecer sem território nenhum"
    assert len(node_ids) > 0


def test_trajectory_map_requires_age_confirmed_user(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    resp = client.get("/progress/trajectory-map", headers=headers)
    assert resp.status_code == 403
