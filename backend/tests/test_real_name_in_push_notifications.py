"""
NOME_REAL_E_FOTO_EM_TODO_LUGAR_V1.md (11/09/2026) corrigiu 5 pontos de
notificação push em services.py pra usar `real_name or nickname` em vez
de `.nickname` direto — mas nenhum teste verificava o CORPO dessas
notificações antes ou depois da correção (achado do agente MentalQA na
rodada da AUDITORIA_COMPLETA_PRE_PRODUCAO_V1.md, seção 5). Este arquivo
fecha essa lacuna: um teste por ponto, provando que o nome real aparece
quando preenchido.
"""

import uuid

from .conftest import auth_header


def _capture_pushes(monkeypatch):
    from app import services

    sent = []
    monkeypatch.setattr(
        services.push,
        "send_push_notification",
        lambda db, profile, title, body, data=None: sent.append((profile.push_token, title, body)),
    )
    return sent


def _set_real_name(client, headers, real_name):
    client.put("/profile", json={"real_name": real_name}, headers=headers)


def _make_friends(client, user_a, user_b):
    headers_a = auth_header(user_a)
    headers_b = auth_header(user_b)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers_a)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers_b)
    code = client.get("/social/invite-code", headers=headers_a).json()["invite_code"]
    client.post("/social/friends", json={"invite_code": code}, headers=headers_b)
    friendship_id = client.get("/social/friend-requests", headers=headers_a).json()["requests"][0]["friendship_id"]
    client.post(f"/social/friend-requests/{friendship_id}/accept", headers=headers_a)
    return headers_a, headers_b


def test_torcida_notification_prefers_sender_real_name_over_nickname(client, monkeypatch):
    sent = _capture_pushes(monkeypatch)

    sender = str(uuid.uuid4())
    sender_headers = auth_header(sender)
    client.post("/age-gate", json={"age_confirmed": True}, headers=sender_headers)
    _set_real_name(client, sender_headers, "Fulano de Tal")

    target = str(uuid.uuid4())
    target_headers = auth_header(target)
    client.post("/age-gate", json={"age_confirmed": True}, headers=target_headers)
    client.post("/notifications/register-token", json={"push_token": "target-token"}, headers=target_headers)

    resp = client.post(f"/profile/{target}/torcida", json={"reaction_type": "coracao"}, headers=sender_headers)
    assert resp.status_code == 200

    assert len(sent) == 1
    _, _, body = sent[0]
    assert "Fulano de Tal" in body


def test_movement_invite_notification_prefers_sender_real_name_over_nickname(client, monkeypatch):
    sent = _capture_pushes(monkeypatch)

    sender = str(uuid.uuid4())
    sender_headers = auth_header(sender)
    client.post("/age-gate", json={"age_confirmed": True}, headers=sender_headers)
    _set_real_name(client, sender_headers, "Beltrano da Silva")

    target = str(uuid.uuid4())
    target_headers = auth_header(target)
    client.post("/age-gate", json={"age_confirmed": True}, headers=target_headers)
    client.post("/notifications/register-token", json={"push_token": "target-token"}, headers=target_headers)

    resp = client.post(f"/profile/{target}/invite-movement", headers=sender_headers)
    assert resp.status_code == 200

    assert len(sent) == 1
    _, _, body = sent[0]
    assert "Beltrano da Silva" in body


def test_battle_challenge_received_notification_prefers_challenger_real_name(client, monkeypatch):
    sent = _capture_pushes(monkeypatch)

    user_a, user_b = str(uuid.uuid4()), str(uuid.uuid4())
    headers_a, headers_b = _make_friends(client, user_a, user_b)
    _set_real_name(client, headers_a, "Ciclana Pereira")
    client.post("/notifications/register-token", json={"push_token": "opponent-token"}, headers=headers_b)

    resp = client.post(
        "/battles",
        json={"opponent_user_id": user_b, "territory_id": "palavras", "difficulty_level": 1},
        headers=headers_a,
    )
    assert resp.status_code == 200

    assert len(sent) == 1
    _, _, body = sent[0]
    assert "Ciclana Pereira" in body


def test_battle_result_notification_prefers_opponent_real_name(client, monkeypatch):
    from app.seed import CHALLENGES

    def _answer(client, headers, challenge, submitted_answer):
        return client.post(
            f"/challenges/{challenge['challenge_id']}/answer",
            json={"attempt_id": challenge["attempt_id"], "submitted_answer": submitted_answer},
            headers=headers,
        ).json()

    user_a, user_b = str(uuid.uuid4()), str(uuid.uuid4())
    headers_a, headers_b = _make_friends(client, user_a, user_b)
    _set_real_name(client, headers_a, "Vencedor Real")
    _set_real_name(client, headers_b, "Perdedor Real")
    client.post("/notifications/register-token", json={"push_token": "a-token"}, headers=headers_a)
    client.post("/notifications/register-token", json={"push_token": "b-token"}, headers=headers_b)

    created = client.post(
        "/battles",
        json={"opponent_user_id": user_b, "territory_id": "palavras", "difficulty_level": 1},
        headers=headers_a,
    ).json()
    battle_id = created["battle_id"]
    opponent_challenge = client.get(f"/battles/{battle_id}/my-challenge", headers=headers_b).json()

    sent = _capture_pushes(monkeypatch)  # só captura a partir daqui — ignora a notificação de desafio recebido

    correct = next(c["correct_answer"] for c in CHALLENGES if c["prompt"] == created["challenge"]["prompt"])
    _answer(client, headers_a, created["challenge"], correct)
    _answer(client, headers_b, opponent_challenge, "resposta errada de propósito")

    bodies_by_token = {token: body for token, _, body in sent}
    assert "Perdedor Real" in bodies_by_token["a-token"], "vencedor recebe notificação citando o nome do oponente"
    assert "Vencedor Real" in bodies_by_token["b-token"], "perdedor recebe notificação citando o nome do oponente"


def test_territory_dethroned_notification_prefers_new_detentor_real_name(client, monkeypatch):
    def _answer_until_correct(client, headers, territory_id="palavras", tries=30):
        from app.seed import CHALLENGES

        for _ in range(tries):
            ch = client.get("/challenges/next", params={"territory_id": territory_id}, headers=headers).json()
            correct = next(
                c["correct_answer"] for c in CHALLENGES
                if c["territory_id"] == territory_id and c["prompt"] == ch["prompt"] and c["difficulty_level"] == ch["difficulty_level"]
            )
            result = client.post(
                f"/challenges/{ch['challenge_id']}/answer",
                json={"attempt_id": ch["attempt_id"], "submitted_answer": correct},
                headers=headers,
            ).json()
            if result["is_correct"]:
                return result
        raise AssertionError("não conseguiu acertar nenhuma tentativa")

    user_a, user_b = str(uuid.uuid4()), str(uuid.uuid4())
    headers_a, headers_b = _make_friends(client, user_a, user_b)
    client.post("/notifications/register-token", json={"push_token": "a-token"}, headers=headers_a)
    _set_real_name(client, headers_b, "Novo Detentor Real")

    _answer_until_correct(client, headers_a)  # A vira detentor primeiro

    sent = _capture_pushes(monkeypatch)  # só captura a partir daqui — ignora notificações anteriores

    for _ in range(30):
        result = _answer_until_correct(client, headers_b)
        if result["territory_detentor_gained"]:
            break

    assert len(sent) == 1
    token, _, body = sent[0]
    assert token == "a-token"
    assert "Novo Detentor Real" in body
