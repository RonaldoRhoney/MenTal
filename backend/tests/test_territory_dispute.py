"""
V2 item 13 — Disputa territorial (TERRITORY_DISPUTE.md, aprovado
2026-08-22). "Detentor" é sempre relativo a você + amigos confirmados
(nunca global) e é sempre derivado de UserTerritoryProgress.
xp_in_territory (já existente), nunca armazenado.
"""

import uuid

from .conftest import auth_header


def _make_friends(client, user_a, user_b):
    headers_a = auth_header(user_a)
    headers_b = auth_header(user_b)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers_a)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers_b)
    code = client.get("/social/invite-code", headers=headers_a).json()["invite_code"]
    client.post("/social/friends", json={"invite_code": code}, headers=headers_b)
    # Achado de auditoria de segurança (28/08/2026): resgatar o código
    # só cria um PEDIDO agora — precisa do aceite explícito de quem
    # convidou antes de virar amizade de verdade.
    friendship_id = client.get("/social/friend-requests", headers=headers_a).json()["requests"][0]["friendship_id"]
    client.post(f"/social/friend-requests/{friendship_id}/accept", headers=headers_a)
    return headers_a, headers_b


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


def test_no_detentor_when_nobody_has_xp_in_territory(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    progress = client.get("/progress", headers=headers).json()
    palavras = next(t for t in progress["territories"] if t["territory_id"] == "palavras")
    assert palavras["detentor_nickname"] is None
    assert palavras["is_detentor"] is False


def test_sole_scorer_becomes_detentor(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    _answer_until_correct(client, headers)

    progress = client.get("/progress", headers=headers).json()
    palavras = next(t for t in progress["territories"] if t["territory_id"] == "palavras")
    assert palavras["is_detentor"] is True


def test_dispute_is_scoped_to_friends_never_global_strangers(client):
    user_a, stranger = str(uuid.uuid4()), str(uuid.uuid4())
    headers_a = auth_header(user_a)
    headers_stranger = auth_header(stranger)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers_a)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers_stranger)

    # Estranho acumula MUITO mais XP que user_a, mas nunca foram amigos.
    for _ in range(5):
        _answer_until_correct(client, headers_stranger)
    _answer_until_correct(client, headers_a)

    progress_a = client.get("/progress", headers=headers_a).json()
    palavras_a = next(t for t in progress_a["territories"] if t["territory_id"] == "palavras")
    # user_a continua detentor do próprio ponto de vista — o estranho
    # nunca entra na conta, por mais XP que tenha.
    assert palavras_a["is_detentor"] is True


def test_friend_with_more_xp_becomes_detentor_and_dethrones_previous(client):
    user_a, user_b = str(uuid.uuid4()), str(uuid.uuid4())
    headers_a, headers_b = _make_friends(client, user_a, user_b)
    # ADENDO_NOTIFICACAO_RANKING_NOME_REAL.md (12/09/2026): varredura
    # ampla encontrou dethroned_nickname usando o apelido cru de quem
    # perdeu o território, sem preferir o nome real.
    client.put("/profile", json={"real_name": "Detentor A Real"}, headers=headers_a)

    _answer_until_correct(client, headers_a)  # A vira detentor primeiro

    progress_a = client.get("/progress", headers=headers_a).json()
    assert next(t for t in progress_a["territories"] if t["territory_id"] == "palavras")["is_detentor"] is True

    # B acerta várias vezes até assumir a liderança de XP no território.
    dethroned = False
    for _ in range(10):
        result = _answer_until_correct(client, headers_b)
        if result["territory_detentor_gained"]:
            dethroned = True
            assert result["dethroned_nickname"] == "Detentor A Real"
            break

    assert dethroned, "B deveria ter assumido o território de A em algum momento"

    progress_a_after = client.get("/progress", headers=headers_a).json()
    palavras_a_after = next(t for t in progress_a_after["territories"] if t["territory_id"] == "palavras")
    assert palavras_a_after["is_detentor"] is False
    assert palavras_a_after["detentor_nickname"] is not None


def test_detentor_nickname_field_prefers_real_name_when_set(client):
    """Pedido de Rhoney (07/09/2026): "em todas as telas... o nome do
    usuário deve aparecer e não o código" — apesar do nome do campo
    (detentor_nickname, mantido por compatibilidade), o valor prioriza
    real_name sobre o apelido gerado, mesmo padrão de Ranking/Amigos."""
    from app import models
    from app.db import SessionLocal

    user_a, user_b = str(uuid.uuid4()), str(uuid.uuid4())
    headers_a, headers_b = _make_friends(client, user_a, user_b)

    with SessionLocal() as db:
        profile_b = db.get(models.Profile, user_b)
        profile_b.real_name = "Beltrano da Silva"
        db.commit()

    _answer_until_correct(client, headers_b)

    progress_a = client.get("/progress", headers=headers_a).json()
    palavras_a = next(t for t in progress_a["territories"] if t["territory_id"] == "palavras")
    assert palavras_a["detentor_nickname"] == "Beltrano da Silva"


def test_detentor_photo_url_present_by_default_hidden_when_private_and_never_for_self(client, monkeypatch):
    """Pedido de Rhoney (07/09/2026): "agora que os nomes aparecem em
    qualquer tela, ponha as fotos também". Revisão 13/09/2026: foto é
    pública por padrão (photo_is_public, escolha do próprio usuário),
    não depende mais de aprovação de admin."""
    from app import supabase_admin

    monkeypatch.setattr(supabase_admin, "create_signed_photo_url", lambda path, expires_in_seconds=3600: f"https://signed.example/{path}")

    user_a, user_b = str(uuid.uuid4()), str(uuid.uuid4())
    headers_a, headers_b = _make_friends(client, user_a, user_b)

    _answer_until_correct(client, headers_a)
    progress_a_self = client.get("/progress", headers=headers_a).json()
    palavras_a_self = next(t for t in progress_a_self["territories"] if t["territory_id"] == "palavras")
    assert palavras_a_self["is_detentor"] is True
    assert palavras_a_self["detentor_photo_url"] is None, "detentor sendo o próprio jogador não precisa de foto"

    client.put("/profile", json={"photo_path": f"{user_b}/photo.jpg"}, headers=headers_b)

    # Uma única resposta correta não garante ultrapassar o XP de user_a
    # nesse território (mesmo achado já documentado em
    # test_friend_with_more_xp_becomes_detentor_and_dethrones_previous)
    # — repete até user_b assumir o território.
    dethroned = False
    for _ in range(10):
        _answer_until_correct(client, headers_b)
        progress_a = client.get("/progress", headers=headers_a).json()
        palavras_a = next(t for t in progress_a["territories"] if t["territory_id"] == "palavras")
        if palavras_a["is_detentor"] is False:
            dethroned = True
            break
    assert dethroned, "user_b deveria ter assumido o território de user_a em algum momento"
    assert palavras_a["detentor_photo_url"] is not None, "pública por padrão, sem depender de admin"

    client.put("/profile", json={"photo_path": f"{user_b}/photo.jpg", "photo_is_public": False}, headers=headers_b)

    progress_a_after = client.get("/progress", headers=headers_a).json()
    palavras_a_after = next(t for t in progress_a_after["territories"] if t["territory_id"] == "palavras")
    assert palavras_a_after["detentor_photo_url"] is None, "user_b marcou a foto como privada"


def test_no_dethroned_nickname_on_first_ever_detentor(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    result = _answer_until_correct(client, headers)
    if result["territory_detentor_gained"]:
        assert result["dethroned_nickname"] is None
