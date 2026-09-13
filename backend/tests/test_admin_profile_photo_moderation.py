"""
Revisão 13/09/2026 (decisão de Rhoney): visibilidade da foto de perfil
deixou de depender de aprovação do admin — a fila de moderação (GET
/admin/profile-photos) virou um backlog real de semanas com 13+
usuários esperando revisão manual, deixando a foto de todo mundo
invisível no Ranking/Amigos/Batalhas. Agora é photo_is_public,
controlado pelo próprio usuário a qualquer momento (services.
public_photo_url). /admin/profile-photos e .../moderate continuam
existindo, mas como override administrativo (ex.: forçar invisível uma
foto reportada), não mais como portão de pré-publicação — por isso a
lista de pendentes fica sempre vazia agora (nada nasce 'pending').
"""

import uuid

from app import models
from app.db import SessionLocal

from .conftest import auth_header


def _promote_to_admin(user_id: str) -> None:
    with SessionLocal() as db:
        profile = db.get(models.Profile, user_id)
        profile.role = "admin"
        db.commit()


def test_non_admin_cannot_list_pending_photos(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    resp = client.get("/admin/profile-photos", headers=headers)
    assert resp.status_code == 403


def test_pending_photos_list_is_always_empty_now(client):
    admin, user = str(uuid.uuid4()), str(uuid.uuid4())
    admin_headers = auth_header(admin)
    client.post("/age-gate", json={"age_confirmed": True}, headers=admin_headers)
    client.post("/age-gate", json={"age_confirmed": True}, headers=auth_header(user))
    _promote_to_admin(admin)

    client.put("/profile", json={"photo_path": f"{user}/photo.jpg", "real_name": "João Silva"}, headers=auth_header(user))

    resp = client.get("/admin/profile-photos", headers=admin_headers)
    assert resp.status_code == 200
    assert resp.json()["items"] == []


def test_new_photo_is_public_by_default_no_admin_action_needed(client, monkeypatch):
    from app import supabase_admin
    from .test_friends import _get_invite_code

    monkeypatch.setattr(supabase_admin, "create_signed_photo_url", lambda path, expires_in_seconds=3600: f"https://signed.example/{path}")

    user_a, user_b = str(uuid.uuid4()), str(uuid.uuid4())
    headers_a, headers_b = auth_header(user_a), auth_header(user_b)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers_a)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers_b)

    client.put("/profile", json={"photo_path": f"{user_b}/photo.jpg"}, headers=headers_b)

    a_code = _get_invite_code(client, headers_a)
    client.post("/social/friends", json={"invite_code": a_code}, headers=headers_b)
    friendship_id = client.get("/social/friend-requests", headers=headers_a).json()["requests"][0]["friendship_id"]
    client.post(f"/social/friend-requests/{friendship_id}/accept", headers=headers_a)

    friends = client.get("/social/friends", headers=headers_a).json()["friends"]
    assert friends[0]["photo_url"] is not None, "foto nova já deve ser pública, sem depender de admin"


def test_user_can_make_their_own_photo_private_and_public_again(client, monkeypatch):
    from app import supabase_admin
    from .test_friends import _get_invite_code

    monkeypatch.setattr(supabase_admin, "create_signed_photo_url", lambda path, expires_in_seconds=3600: f"https://signed.example/{path}")

    user_a, user_b = str(uuid.uuid4()), str(uuid.uuid4())
    headers_a, headers_b = auth_header(user_a), auth_header(user_b)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers_a)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers_b)

    client.put("/profile", json={"photo_path": f"{user_b}/photo.jpg"}, headers=headers_b)

    a_code = _get_invite_code(client, headers_a)
    client.post("/social/friends", json={"invite_code": a_code}, headers=headers_b)
    friendship_id = client.get("/social/friend-requests", headers=headers_a).json()["requests"][0]["friendship_id"]
    client.post(f"/social/friend-requests/{friendship_id}/accept", headers=headers_a)

    client.put("/profile", json={"photo_path": f"{user_b}/photo.jpg", "photo_is_public": False}, headers=headers_b)
    friends = client.get("/social/friends", headers=headers_a).json()["friends"]
    assert friends[0]["photo_url"] is None, "usuário marcou como privada — não deve aparecer pra amigos"

    client.put("/profile", json={"photo_path": f"{user_b}/photo.jpg", "photo_is_public": True}, headers=headers_b)
    friends = client.get("/social/friends", headers=headers_a).json()["friends"]
    assert friends[0]["photo_url"] is not None, "usuário marcou como pública de novo — deve voltar a aparecer"


def test_admin_reject_overrides_user_choice_even_if_marked_public(client, monkeypatch):
    from app import supabase_admin

    monkeypatch.setattr(supabase_admin, "create_signed_photo_url", lambda path, expires_in_seconds=3600: f"https://signed.example/{path}")

    admin, user = str(uuid.uuid4()), str(uuid.uuid4())
    admin_headers = auth_header(admin)
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=admin_headers)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)
    _promote_to_admin(admin)

    client.put("/profile", json={"photo_path": f"{user}/photo.jpg"}, headers=headers)

    resp = client.post(f"/admin/profile-photos/{user}/moderate", json={"approved": False}, headers=admin_headers)
    assert resp.status_code == 200

    with SessionLocal() as db:
        profile = db.get(models.Profile, user)
        assert profile.photo_moderation_status == "rejected"

    # Usuário tenta reafirmar photo_is_public=True — override do admin continua valendo.
    resp = client.put("/profile", json={"photo_path": f"{user}/photo.jpg", "photo_is_public": True}, headers=headers)
    assert resp.status_code == 200
    assert resp.json()["photo_url"] is not None, "dono sempre vê a própria foto, independente do override"

    with SessionLocal() as db:
        profile = db.get(models.Profile, user)
        assert profile.photo_moderation_status == "rejected", "override do admin não deve ser desfeito por reenvio do mesmo path"
