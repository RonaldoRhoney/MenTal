"""
Perfil do usuário (USER_PROFILE.md, aprovado; revisado 2026-08-26).
Campos base continuam opcionais — nenhum bloqueia uso do app.
real_name/photo_url agora aparecem publicamente (foto só se aprovada na
moderação) — reversão da regra anterior de "nunca exposto".
"""

import uuid

from app import config, models
from app.db import SessionLocal

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


def test_real_name_appears_publicly_in_friends_list(client):
    """
    Revisão 26/08/2026 (decisão de Rhoney): nome real passa a ser
    público, ao lado da foto de perfil — reverte a regra anterior
    ("nunca exibido publicamente"), registrada agora em USER_PROFILE.md.
    """
    user_a, user_b = str(uuid.uuid4()), str(uuid.uuid4())
    headers_a = auth_header(user_a)
    headers_b = auth_header(user_b)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers_a)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers_b)
    client.put("/profile", json={"real_name": "Maria Silva", "avatar_id": "fox"}, headers=headers_b)

    code = client.get("/social/invite-code", headers=headers_a).json()["invite_code"]
    client.post("/social/friends", json={"invite_code": code}, headers=headers_b)
    friendship_id = client.get("/social/friend-requests", headers=headers_a).json()["requests"][0]["friendship_id"]
    client.post(f"/social/friend-requests/{friendship_id}/accept", headers=headers_a)

    friends = client.get("/social/friends", headers=headers_a).json()["friends"]
    assert len(friends) == 1
    assert friends[0]["real_name"] == "Maria Silva"
    assert friends[0]["avatar_id"] == "fox"


def test_photo_url_only_appears_publicly_after_admin_approval(client, monkeypatch):
    """
    USER_PROFILE.md §3.1 — fail-closed: foto pendente/rejeitada nunca
    aparece pra outros usuários, só depois de aprovada por um admin.

    Revisão 28/08/2026 (bucket privado): photo_url na resposta agora é
    sempre uma URL ASSINADA gerada por services.own_photo_url/
    public_photo_url via supabase_admin — sem SUPABASE_SERVICE_ROLE_KEY
    configurado (ambiente de teste local), essa chamada real ao
    Supabase não existe, então o teste monkeypatcha
    create_signed_photo_url pra simular a assinatura sem precisar de
    rede/credencial real, mantendo o foco no que este teste prova de
    verdade: a transição pending → approved.
    """
    from app import supabase_admin

    monkeypatch.setattr(supabase_admin, "create_signed_photo_url", lambda path, expires_in_seconds=3600: f"https://signed.example/{path}")

    user_a, user_b = str(uuid.uuid4()), str(uuid.uuid4())
    headers_a = auth_header(user_a)
    headers_b = auth_header(user_b)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers_a)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers_b)

    photo_path = f"{user_b}/photo.jpg"
    client.put("/profile", json={"photo_path": photo_path}, headers=headers_b)

    code = client.get("/social/invite-code", headers=headers_a).json()["invite_code"]
    client.post("/social/friends", json={"invite_code": code}, headers=headers_b)
    friendship_id = client.get("/social/friend-requests", headers=headers_a).json()["requests"][0]["friendship_id"]
    client.post(f"/social/friend-requests/{friendship_id}/accept", headers=headers_a)

    friends_before = client.get("/social/friends", headers=headers_a).json()["friends"]
    assert friends_before[0]["photo_url"] is None, "pendente não deve aparecer pra outros ainda"

    with SessionLocal() as db:
        profile_b = db.get(models.Profile, user_b)
        profile_b.photo_moderation_status = "approved"
        db.commit()

    friends_after = client.get("/social/friends", headers=headers_a).json()["friends"]
    assert friends_after[0]["photo_url"] == f"https://signed.example/{photo_path}"


def test_photo_path_pointing_to_another_users_folder_is_rejected(client):
    """
    Achado de auditoria de segurança (28/08/2026): _is_valid_photo_path
    só conferia prefixo do bucket + extensão — um usuário podia mandar o
    path da foto de OUTRO usuário (já aprovada) como se fosse sua e
    passar a exibi-la como própria depois de aprovada pelo admin. Agora
    o path precisa apontar pra dentro da PRÓPRIA pasta do usuário
    autenticado.
    """
    user_a, user_b = str(uuid.uuid4()), str(uuid.uuid4())
    headers_a = auth_header(user_a)
    headers_b = auth_header(user_b)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers_a)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers_b)

    stolen_photo_path = f"{user_b}/photo.jpg"

    resp = client.put("/profile", json={"photo_path": stolen_photo_path}, headers=headers_a)
    assert resp.status_code == 422
    assert resp.json()["error"]["code"] == "INVALID_PHOTO_URL"


def test_onboarding_stays_incomplete_until_all_5_mandatory_fields_filled(client):
    """
    Cadastro mínimo obrigatório (26/08/2026, revisado 28/08/2026): nome,
    país, cidade, faixa etária e foto de perfil — gênero passou a ser
    OPCIONAL nessa revisão, e foto entrou no lugar dele.
    onboarding_completed_at só é marcado quando os 5 chegam preenchidos
    JUNTOS (numa mesma chamada ou acumulados por chamadas anteriores) —
    nunca por decisão do client, sempre calculado pelo backend.
    """
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    # Só 3 dos 5 campos (falta faixa etária e foto) — ainda incompleto.
    resp = client.put(
        "/profile",
        json={
            "real_name": "Maria Silva",
            "location_country": "Brasil",
            "city": "Belém",
        },
        headers=headers,
    )
    assert resp.json()["onboarding_completed_at"] is None


def test_onboarding_completes_when_all_5_mandatory_fields_filled(client):
    """Gênero de propósito NUNCA enviado neste teste — prova que não é
    mais exigido pra completar o onboarding (revisão 28/08/2026)."""
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    resp = client.put(
        "/profile",
        json={
            "real_name": "Maria Silva",
            "location_country": "Brasil",
            "city": "Belém",
            "age_range": "26-35",
            "photo_path": f"{user}/photo.jpg",
        },
        headers=headers,
    )
    body = resp.json()
    assert resp.status_code == 200
    assert body["city"] == "Belém"
    assert body["gender"] is None
    assert body["age_range"] == "26-35"
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
