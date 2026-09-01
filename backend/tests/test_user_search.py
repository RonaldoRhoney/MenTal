"""
AMIGOS_CONVITE_POR_NOME.md — busca de amigos por nome (autocomplete),
complementando o convite por código já existente (test_friends.py).
Escopo estrito (§2 do doc): resultado só leva a "enviar convite", nunca
abre perfil completo; nunca dado além de nome/foto/nível.
"""

import uuid

from .conftest import auth_header


def _set_real_name(client, headers, real_name: str) -> None:
    client.put("/profile", json={"real_name": real_name}, headers=headers)


def test_search_finds_user_by_real_name_prefix(client):
    searcher = str(uuid.uuid4())
    target = str(uuid.uuid4())
    searcher_headers = auth_header(searcher)
    target_headers = auth_header(target)
    client.post("/age-gate", json={"age_confirmed": True}, headers=searcher_headers)
    client.post("/age-gate", json={"age_confirmed": True}, headers=target_headers)
    _set_real_name(client, target_headers, "Fernanda Lima")

    resp = client.get("/social/users/search", params={"q": "Fern"}, headers=searcher_headers)
    assert resp.status_code == 200
    results = resp.json()["results"]
    assert any(r["user_id"] == target and r["real_name"] == "Fernanda Lima" for r in results)


def test_search_requires_at_least_three_letters(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    resp = client.get("/social/users/search", params={"q": "Fe"}, headers=headers)
    assert resp.status_code == 200
    assert resp.json()["results"] == []


def test_search_never_returns_requester_itself(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)
    _set_real_name(client, headers, "Ronaldo Martins")

    resp = client.get("/social/users/search", params={"q": "Ronaldo"}, headers=headers)
    results = resp.json()["results"]
    assert all(r["user_id"] != user for r in results)


def test_search_excludes_blocked_users_either_direction(client):
    searcher = str(uuid.uuid4())
    target = str(uuid.uuid4())
    searcher_headers = auth_header(searcher)
    target_headers = auth_header(target)
    client.post("/age-gate", json={"age_confirmed": True}, headers=searcher_headers)
    client.post("/age-gate", json={"age_confirmed": True}, headers=target_headers)
    _set_real_name(client, target_headers, "Carlos Bloqueado")

    client.post("/social/block", json={"blocked_user_id": target}, headers=searcher_headers)

    resp = client.get("/social/users/search", params={"q": "Carlos"}, headers=searcher_headers)
    results = resp.json()["results"]
    assert all(r["user_id"] != target for r in results)


def test_search_result_reflects_existing_friendship_status(client):
    a = str(uuid.uuid4())
    b = str(uuid.uuid4())
    a_headers = auth_header(a)
    b_headers = auth_header(b)
    client.post("/age-gate", json={"age_confirmed": True}, headers=a_headers)
    client.post("/age-gate", json={"age_confirmed": True}, headers=b_headers)
    _set_real_name(client, b_headers, "Beatriz Amiga")

    a_code = client.get("/social/invite-code", headers=a_headers).json()["invite_code"]
    client.post("/social/friends", json={"invite_code": a_code}, headers=b_headers)

    resp = client.get("/social/users/search", params={"q": "Beatriz"}, headers=a_headers)
    match = next(r for r in resp.json()["results"] if r["user_id"] == b)
    assert match["friendship_status"] == "pending"


def test_send_friend_request_by_user_id_from_search_result(client):
    a = str(uuid.uuid4())
    b = str(uuid.uuid4())
    a_headers = auth_header(a)
    b_headers = auth_header(b)
    client.post("/age-gate", json={"age_confirmed": True}, headers=a_headers)
    client.post("/age-gate", json={"age_confirmed": True}, headers=b_headers)
    _set_real_name(client, b_headers, "Paulo Encontrado")

    results = client.get("/social/users/search", params={"q": "Paulo"}, headers=a_headers).json()["results"]
    match = next(r for r in results if r["user_id"] == b)

    resp = client.post("/social/friend-requests", json={"to_user_id": match["user_id"]}, headers=a_headers)
    assert resp.status_code == 200
    assert resp.json()["status"] == "pending"

    incoming = client.get("/social/friend-requests", headers=b_headers).json()["requests"]
    assert any(r["from_user_id"] == a for r in incoming)


def test_send_friend_request_rejects_self(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    resp = client.post("/social/friend-requests", json={"to_user_id": user}, headers=headers)
    assert resp.status_code == 400
    assert resp.json()["error"]["code"] == "CANNOT_FRIEND_SELF"


def test_search_does_not_expose_unapproved_photo(client):
    searcher = str(uuid.uuid4())
    target = str(uuid.uuid4())
    searcher_headers = auth_header(searcher)
    target_headers = auth_header(target)
    client.post("/age-gate", json={"age_confirmed": True}, headers=searcher_headers)
    client.post("/age-gate", json={"age_confirmed": True}, headers=target_headers)
    _set_real_name(client, target_headers, "Juliana Semfoto")

    resp = client.get("/social/users/search", params={"q": "Juliana"}, headers=searcher_headers)
    match = next(r for r in resp.json()["results"] if r["user_id"] == target)
    assert match["photo_url"] is None
