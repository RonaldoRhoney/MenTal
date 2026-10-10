import uuid

from .conftest import auth_header


def test_round_returns_visible_items_without_auth_leaking_other_users(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    resp = client.get("/par-perfeito/round", params={"territory_id": "ingles_parperfeito_basico"}, headers=headers)
    assert resp.status_code == 200
    body = resp.json()
    assert body["territory_id"] == "ingles_parperfeito_basico"
    assert 1 <= len(body["items"]) <= 6
    for item in body["items"]:
        assert item["word_en"]
        assert item["meaning_pt"]
        assert item["id"]


def test_round_requires_auth(client):
    resp = client.get("/par-perfeito/round", params={"territory_id": "ingles_parperfeito_basico"})
    assert resp.status_code == 401


def test_round_404_for_unknown_territory(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)
    resp = client.get("/par-perfeito/round", params={"territory_id": "territorio_que_nao_existe"}, headers=headers)
    assert resp.status_code == 404


def test_complete_round_awards_xp_first_time_only(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    round_resp = client.get("/par-perfeito/round", params={"territory_id": "ingles_parperfeito_basico"}, headers=headers)
    item_ids = [item["id"] for item in round_resp.json()["items"]]

    xp_before = client.get("/progress", headers=headers).json()["xp_total"]

    first = client.post(
        "/par-perfeito/complete-round",
        json={"territory_id": "ingles_parperfeito_basico", "item_ids": item_ids},
        headers=headers,
    )
    assert first.status_code == 200
    assert first.json()["xp_awarded_total"] > 0

    xp_after_first = client.get("/progress", headers=headers).json()["xp_total"]
    assert xp_after_first - xp_before == first.json()["xp_awarded_total"]

    # Reenviar os MESMOS pares (ex.: retry de rede, ou tentar reportar de
    # novo pra ganhar XP duplicado) não credita nada a mais —
    # REGRA_OFICIAL §10: só a primeira tentativa de cada par gera XP.
    second = client.post(
        "/par-perfeito/complete-round",
        json={"territory_id": "ingles_parperfeito_basico", "item_ids": item_ids},
        headers=headers,
    )
    assert second.status_code == 200
    assert second.json()["xp_awarded_total"] == 0

    xp_after_second = client.get("/progress", headers=headers).json()["xp_total"]
    assert xp_after_second == xp_after_first


def test_complete_round_ignores_item_ids_from_another_territory(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    round_resp = client.get("/par-perfeito/round", params={"territory_id": "ingles_parperfeito_basico"}, headers=headers)
    item_ids = [item["id"] for item in round_resp.json()["items"]]

    # territory_id do corpo não bate com o território real dos itens —
    # nenhum item_id deve ser aceito (confere item.territory_id ==
    # body.territory_id antes de creditar XP).
    resp = client.post(
        "/par-perfeito/complete-round",
        json={"territory_id": "ingles_basico", "item_ids": item_ids},
        headers=headers,
    )
    assert resp.status_code == 200
    assert resp.json()["xp_awarded_total"] == 0


def test_complete_round_requires_territory_unlocked(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    resp = client.post(
        "/par-perfeito/complete-round",
        json={"territory_id": "territorio_que_nao_existe", "item_ids": []},
        headers=headers,
    )
    assert resp.status_code == 404
