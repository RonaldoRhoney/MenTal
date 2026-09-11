"""
Achado real (07/09/2026, pedido de Rhoney: "a foto do usuário ainda não
aparece em ranking/feed/admin"): GET /admin/profile-photos e POST
/admin/profile-photos/{id}/moderate já existiam no backend, mas nunca
tiveram teste nem UI no client — fotos enviadas ficavam presas em
"pending" pra sempre, porque não havia como aprová-las de verdade.
services.public_photo_url (usado em Ranking/Amigos/Feed/detentor) é
fail-closed: só mostra a foto de outra pessoa depois de aprovada.
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


def test_admin_lists_only_pending_photos_with_a_photo_set(client):
    admin, user_with_photo, user_without_photo = str(uuid.uuid4()), str(uuid.uuid4()), str(uuid.uuid4())
    admin_headers = auth_header(admin)
    client.post("/age-gate", json={"age_confirmed": True}, headers=admin_headers)
    client.post("/age-gate", json={"age_confirmed": True}, headers=auth_header(user_with_photo))
    client.post("/age-gate", json={"age_confirmed": True}, headers=auth_header(user_without_photo))
    _promote_to_admin(admin)

    client.put("/profile", json={"photo_path": f"{user_with_photo}/photo.jpg"}, headers=auth_header(user_with_photo))

    resp = client.get("/admin/profile-photos", headers=admin_headers)
    assert resp.status_code == 200
    items = resp.json()["items"]
    pending_user_ids = {item["user_id"] for item in items}
    assert user_with_photo in pending_user_ids
    assert user_without_photo not in pending_user_ids


def test_admin_approves_a_pending_photo_and_it_becomes_visible_to_others(client, monkeypatch):
    from app import supabase_admin
    from .test_friends import _get_invite_code

    monkeypatch.setattr(supabase_admin, "create_signed_photo_url", lambda path, expires_in_seconds=3600: f"https://signed.example/{path}")

    admin, user_a, user_b = str(uuid.uuid4()), str(uuid.uuid4()), str(uuid.uuid4())
    admin_headers = auth_header(admin)
    headers_a = auth_header(user_a)
    headers_b = auth_header(user_b)
    client.post("/age-gate", json={"age_confirmed": True}, headers=admin_headers)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers_a)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers_b)
    _promote_to_admin(admin)

    client.put("/profile", json={"photo_path": f"{user_b}/photo.jpg"}, headers=headers_b)

    a_code = _get_invite_code(client, headers_a)
    client.post("/social/friends", json={"invite_code": a_code}, headers=headers_b)
    friendship_id = client.get("/social/friend-requests", headers=headers_a).json()["requests"][0]["friendship_id"]
    client.post(f"/social/friend-requests/{friendship_id}/accept", headers=headers_a)

    friends_before = client.get("/social/friends", headers=headers_a).json()["friends"]
    assert friends_before[0]["photo_url"] is None, "pendente não deve aparecer pra outros ainda"

    resp = client.post(f"/admin/profile-photos/{user_b}/moderate", json={"approved": True}, headers=admin_headers)
    assert resp.status_code == 200

    friends_after = client.get("/social/friends", headers=headers_a).json()["friends"]
    assert friends_after[0]["photo_url"] is not None


def test_admin_rejects_a_pending_photo(client):
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
