"""
Bloqueio de usuário (auditoria de conformidade Google Play, 29/08/2026,
item 6 — "UGC precisa de mecanismo de bloqueio, além da denúncia").
Direcional (A bloqueia B não implica B bloqueia A), mas qualquer
bloqueio em qualquer direção impede novo pedido de amizade.
"""

import uuid

from .conftest import auth_header


def _get_invite_code(client, headers) -> str:
    return client.get("/social/invite-code", headers=headers).json()["invite_code"]


def test_block_user_prevents_future_friend_request(client):
    a = str(uuid.uuid4())
    b = str(uuid.uuid4())
    a_headers = auth_header(a)
    b_headers = auth_header(b)
    client.post("/age-gate", json={"age_confirmed": True}, headers=a_headers)
    client.post("/age-gate", json={"age_confirmed": True}, headers=b_headers)

    resp = client.post("/social/block", json={"blocked_user_id": b}, headers=a_headers)
    assert resp.status_code == 200
    assert resp.json()["status"] == "blocked"

    b_code = _get_invite_code(client, b_headers)
    client.post("/social/friends", json={"invite_code": b_code}, headers=a_headers)
    a_code = _get_invite_code(client, a_headers)
    client.post("/social/friends", json={"invite_code": a_code}, headers=b_headers)

    # Nenhum dos dois lados deve conseguir criar um pedido pendente,
    # não importa quem tentou (o bloqueio é checado nos dois sentidos).
    assert client.get("/social/friend-requests", headers=a_headers).json()["requests"] == []
    assert client.get("/social/friend-requests", headers=b_headers).json()["requests"] == []


def test_blocking_an_existing_friend_removes_the_friendship(client):
    a = str(uuid.uuid4())
    b = str(uuid.uuid4())
    a_headers = auth_header(a)
    b_headers = auth_header(b)
    client.post("/age-gate", json={"age_confirmed": True}, headers=a_headers)
    client.post("/age-gate", json={"age_confirmed": True}, headers=b_headers)

    a_code = _get_invite_code(client, a_headers)
    client.post("/social/friends", json={"invite_code": a_code}, headers=b_headers)
    friendship_id = client.get("/social/friend-requests", headers=a_headers).json()["requests"][0]["friendship_id"]
    client.post(f"/social/friend-requests/{friendship_id}/accept", headers=a_headers)
    assert len(client.get("/social/friends", headers=a_headers).json()["friends"]) == 1

    client.post("/social/block", json={"blocked_user_id": b}, headers=a_headers)

    assert client.get("/social/friends", headers=a_headers).json()["friends"] == []
    assert client.get("/social/friends", headers=b_headers).json()["friends"] == []


def test_unblock_allows_friend_request_again(client):
    a = str(uuid.uuid4())
    b = str(uuid.uuid4())
    a_headers = auth_header(a)
    b_headers = auth_header(b)
    client.post("/age-gate", json={"age_confirmed": True}, headers=a_headers)
    client.post("/age-gate", json={"age_confirmed": True}, headers=b_headers)

    client.post("/social/block", json={"blocked_user_id": b}, headers=a_headers)
    client.post("/social/unblock", json={"blocked_user_id": b}, headers=a_headers)

    b_code = _get_invite_code(client, b_headers)
    resp = client.post("/social/friends", json={"invite_code": b_code}, headers=a_headers)
    assert resp.status_code == 200
    assert len(client.get("/social/friend-requests", headers=b_headers).json()["requests"]) == 1


def test_list_blocked_users_shows_who_was_blocked(client):
    a = str(uuid.uuid4())
    b = str(uuid.uuid4())
    a_headers = auth_header(a)
    b_headers = auth_header(b)
    client.post("/age-gate", json={"age_confirmed": True}, headers=a_headers)
    client.post("/age-gate", json={"age_confirmed": True}, headers=b_headers)

    client.post("/social/block", json={"blocked_user_id": b}, headers=a_headers)

    blocked = client.get("/social/blocked", headers=a_headers).json()["blocked"]
    assert len(blocked) == 1
    assert blocked[0]["user_id"] == b

    # B bloqueou A não aparece na lista de A — é direcional.
    assert client.get("/social/blocked", headers=b_headers).json()["blocked"] == []


def test_block_is_idempotent_never_duplicates(client):
    a = str(uuid.uuid4())
    b = str(uuid.uuid4())
    a_headers = auth_header(a)
    b_headers = auth_header(b)
    client.post("/age-gate", json={"age_confirmed": True}, headers=a_headers)
    client.post("/age-gate", json={"age_confirmed": True}, headers=b_headers)

    client.post("/social/block", json={"blocked_user_id": b}, headers=a_headers)
    client.post("/social/block", json={"blocked_user_id": b}, headers=a_headers)

    assert len(client.get("/social/blocked", headers=a_headers).json()["blocked"]) == 1


def test_cannot_block_self(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    resp = client.post("/social/block", json={"blocked_user_id": user}, headers=headers)
    assert resp.status_code == 400
    assert resp.json()["error"]["code"] == "CANNOT_BLOCK_SELF"
