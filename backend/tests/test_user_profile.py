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
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers)

    body = client.get("/profile", headers=headers).json()
    assert body["avatar_id"] is None
    assert body["real_name"] is None
    assert body["location_state"] is None
    assert body["location_country"] is None
    assert body["location_public"] is False


def test_update_profile_persists_all_fields(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers)

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
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers_a)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers_b)
    client.put("/profile", json={"real_name": "Segredo", "avatar_id": "fox"}, headers=headers_b)

    code = client.get("/social/invite-code", headers=headers_a).json()["invite_code"]
    client.post("/social/friends", json={"invite_code": code}, headers=headers_b)

    friends = client.get("/social/friends", headers=headers_a).json()["friends"]
    assert len(friends) == 1
    assert "real_name" not in friends[0]
    assert friends[0]["avatar_id"] == "fox"


def test_avatar_appears_in_ranking(client):
    # "me" no lugar de "entries": a suíte inteira reaproveita o mesmo
    # banco (conftest.py, fixture de escopo "session") — com centenas de
    # usuários acumulados de outros testes, um usuário novo sem XP pode
    # ficar fora do corte de top-50 de "entries". "me" sempre inclui a
    # própria entrada, independente de posição.
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers)
    client.put("/profile", json={"avatar_id": "owl"}, headers=headers)

    me = client.get("/ranking", params={"window": "all_time"}, headers=headers).json()["me"]
    assert me["avatar_id"] == "owl"
