"""
Perfil do usuário (USER_PROFILE.md, aprovado). Todos os campos são
opcionais — nenhum bloqueia uso do app. real_name é interno, nunca
exposto em FriendOut/RankingEntry/BattleOut (só nickname/avatar_id vão
lá). location_public controla exibição, separado de preencher.
"""

import uuid

from .conftest import auth_header


def test_new_profile_has_all_optional_fields_empty(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    body = client.get("/profile", headers=headers).json()
    assert body["avatar_id"] is None
    assert body["real_name"] is None
    assert body["location_state"] is None
    assert body["location_country"] is None
    assert body["location_public"] is False
    assert body["city"] is None
    assert body["gender"] is None
    assert body["age_range"] is None
    assert body["onboarding_completed_at"] is None


def test_update_profile_persists_all_fields(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    resp = client.put(
        "/profile",
        json={
            "avatar_id": "otter",
            "real_name": "Nome Real Interno",
            "location_state": "SP",
            "location_country": "Brasil",
            "location_public": True,
        },
        headers=headers,
    )
    body = resp.json()
    assert resp.status_code == 200
    assert body["avatar_id"] == "otter"
    assert body["real_name"] == "Nome Real Interno"
    assert body["location_state"] == "SP"
    assert body["location_public"] is True

    refetched = client.get("/profile", headers=headers).json()
    assert refetched == body


def test_real_name_never_appears_in_friends_list(client):
    user_a, user_b = str(uuid.uuid4()), str(uuid.uuid4())
    headers_a = auth_header(user_a)
    headers_b = auth_header(user_b)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers_a)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers_b)
    client.put("/profile", json={"real_name": "Segredo", "avatar_id": "fox"}, headers=headers_b)

    code = client.get("/social/invite-code", headers=headers_a).json()["invite_code"]
    client.post("/social/friends", json={"invite_code": code}, headers=headers_b)

    friends = client.get("/social/friends", headers=headers_a).json()["friends"]
    assert len(friends) == 1
    assert "real_name" not in friends[0]
    assert friends[0]["avatar_id"] == "fox"


def test_onboarding_stays_incomplete_until_all_5_mandatory_fields_filled(client):
    """
    Cadastro mínimo obrigatório (26/08/2026): nome, país, cidade, gênero
    e faixa etária. onboarding_completed_at só é marcado quando os 5
    chegam preenchidos JUNTOS numa mesma chamada — nunca por decisão do
    client, sempre calculado pelo backend.
    """
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    # Só 4 dos 5 campos — ainda incompleto.
    resp = client.put(
        "/profile",
        json={
            "real_name": "Maria Silva",
            "location_country": "Brasil",
            "city": "Belém",
            "gender": "feminino",
        },
        headers=headers,
    )
    assert resp.json()["onboarding_completed_at"] is None


def test_onboarding_completes_when_all_5_mandatory_fields_filled(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    resp = client.put(
        "/profile",
        json={
            "real_name": "Maria Silva",
            "location_country": "Brasil",
            "city": "Belém",
            "gender": "feminino",
            "age_range": "26-30",
        },
        headers=headers,
    )
    body = resp.json()
    assert resp.status_code == 200
    assert body["city"] == "Belém"
    assert body["gender"] == "feminino"
    assert body["age_range"] == "26-30"
    assert body["onboarding_completed_at"] is not None

    refetched = client.get("/profile", headers=headers).json()
    assert refetched["onboarding_completed_at"] == body["onboarding_completed_at"]


def test_invalid_gender_or_age_range_rejected_by_schema(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    resp = client.put("/profile", json={"gender": "não é uma opção válida"}, headers=headers)
    assert resp.status_code == 422

    resp = client.put("/profile", json={"age_range": "100+"}, headers=headers)
    assert resp.status_code == 422


def test_avatar_appears_in_ranking(client):
    # "me" no lugar de "entries": a suíte inteira reaproveita o mesmo
    # banco (conftest.py, fixture de escopo "session") — com centenas de
    # usuários acumulados de outros testes, um usuário novo sem XP pode
    # ficar fora do corte de top-50 de "entries". "me" sempre inclui a
    # própria entrada, independente de posição.
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)
    client.put("/profile", json={"avatar_id": "owl"}, headers=headers)

    me = client.get("/ranking", params={"window": "all_time"}, headers=headers).json()["me"]
    assert me["avatar_id"] == "owl"
