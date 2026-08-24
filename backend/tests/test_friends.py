"""
V2 item 12 — Amigos (V2_KICKOFF.md §6A, aprovado 2026-08-22). Usa o
MESMO invite_code/deep link já existente (/social/invite-code) como
ponto de entrada — nenhuma tela nova de convite. Deliberadamente uma
tabela N:N separada (Friendship), não reaproveita InviteConversion (1
atribuição por usuário, pensado pra métrica de crescimento).
"""

import uuid

from .conftest import auth_header


def _get_invite_code(client, headers) -> str:
    return client.get("/social/invite-code", headers=headers).json()["invite_code"]


def test_add_friend_via_invite_code_creates_bidirectional_friendship(client):
    a = str(uuid.uuid4())
    b = str(uuid.uuid4())
    a_headers = auth_header(a)
    b_headers = auth_header(b)
    client.post("/age-gate", json={"age_confirmed": True}, headers=a_headers)
    client.post("/age-gate", json={"age_confirmed": True}, headers=b_headers)

    a_code = _get_invite_code(client, a_headers)
    resp = client.post("/social/friends", json={"invite_code": a_code}, headers=b_headers)
    assert resp.status_code == 200

    # Bidirecional: aparece na lista de amigos de QUEM adicionou (b) e de
    # quem foi adicionado (a), mesmo a relação tendo sido criada só pelo
    # lado de b.
    b_friends = client.get("/social/friends", headers=b_headers).json()["friends"]
    a_friends = client.get("/social/friends", headers=a_headers).json()["friends"]

    assert len(b_friends) == 1
    assert len(a_friends) == 1


def test_add_friend_rejects_own_invite_code(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    code = _get_invite_code(client, headers)
    resp = client.post("/social/friends", json={"invite_code": code}, headers=headers)
    assert resp.status_code == 400
    assert resp.json()["error"]["code"] == "CANNOT_FRIEND_SELF"


def test_add_friend_rejects_unknown_invite_code(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    resp = client.post("/social/friends", json={"invite_code": "does-not-exist"}, headers=headers)
    assert resp.status_code == 404
    assert resp.json()["error"]["code"] == "INVITE_NOT_FOUND"


def test_add_friend_is_idempotent_never_duplicates(client):
    a = str(uuid.uuid4())
    b = str(uuid.uuid4())
    a_headers = auth_header(a)
    b_headers = auth_header(b)
    client.post("/age-gate", json={"age_confirmed": True}, headers=a_headers)
    client.post("/age-gate", json={"age_confirmed": True}, headers=b_headers)

    a_code = _get_invite_code(client, a_headers)
    client.post("/social/friends", json={"invite_code": a_code}, headers=b_headers)
    client.post("/social/friends", json={"invite_code": a_code}, headers=b_headers)

    b_friends = client.get("/social/friends", headers=b_headers).json()["friends"]
    assert len(b_friends) == 1


def test_ranking_scope_friends_filters_to_friends_and_self(client):
    from app.seed import CHALLENGES

    a = str(uuid.uuid4())
    b = str(uuid.uuid4())
    stranger = str(uuid.uuid4())
    a_headers = auth_header(a)
    b_headers = auth_header(b)
    stranger_headers = auth_header(stranger)
    client.post("/age-gate", json={"age_confirmed": True}, headers=a_headers)
    client.post("/age-gate", json={"age_confirmed": True}, headers=b_headers)
    client.post("/age-gate", json={"age_confirmed": True}, headers=stranger_headers)

    a_code = _get_invite_code(client, a_headers)
    client.post("/social/friends", json={"invite_code": a_code}, headers=b_headers)

    def _answer(headers):
        ch = client.get("/challenges/next", params={"territory_id": "numeros"}, headers=headers).json()
        correct = next(c["correct_answer"] for c in CHALLENGES if c["prompt"] == ch["prompt"] and sorted(c["options"]) == sorted(ch["options"]))
        client.post(
            f"/challenges/{ch['challenge_id']}/answer",
            json={"attempt_id": str(uuid.uuid4()), "submitted_answer": correct},
            headers=headers,
        )

    _answer(a_headers)
    _answer(b_headers)
    _answer(stranger_headers)

    friends_ranking = client.get("/ranking", params={"scope": "friends", "window": "weekly"}, headers=b_headers).json()

    # O ranking de amigos de b só pode conter b mesmo e a (amigo) — nunca
    # o estranho, mesmo ele tendo XP essa semana igual aos outros dois.
    assert len(friends_ranking["entries"]) == 2
    assert friends_ranking["me"] is not None


# test_child_safe_mode_nickname_is_anonymized_in_friends_list removido
# (MENTAL-DIR-001, 24/08/2026): MENTAL passa a ser exclusivo pra
# maiores de 18 anos — não existe mais child_safe_mode nem nickname
# anonimizado por faixa etária.
