"""
Menu de feedback geral (26/08/2026) — comentário livre sobre o app,
diferente de level_feedback (amarrado a um nível/desafio específico).
"""

import uuid

from .conftest import auth_header


def test_submit_app_feedback(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    resp = client.post("/feedback", json={"comment": "Adorei o app, só achei os desafios difíceis!"}, headers=headers)
    assert resp.status_code == 200
    assert resp.json() == {"ok": True}


def test_submit_app_feedback_blank_comment_rejected(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    resp = client.post("/feedback", json={"comment": "   "}, headers=headers)
    assert resp.status_code == 422


def test_admin_app_feedback_requires_admin_role(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    resp = client.get("/admin/feedback", headers=headers)
    assert resp.status_code == 403
    assert resp.json()["error"]["code"] == "ADMIN_ONLY"


def test_admin_app_feedback_lists_entries_for_admin(client):
    from app.db import SessionLocal
    from app import models

    submitter = str(uuid.uuid4())
    submitter_headers = auth_header(submitter)
    client.post("/age-gate", json={"age_confirmed": True}, headers=submitter_headers)
    client.post("/feedback", json={"comment": "Sugestão: mais territórios de matemática"}, headers=submitter_headers)

    admin_user = str(uuid.uuid4())
    admin_headers = auth_header(admin_user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=admin_headers)
    with SessionLocal() as db:
        profile = db.get(models.Profile, admin_user)
        profile.role = "admin"
        db.commit()

    resp = client.get("/admin/feedback", headers=admin_headers)
    assert resp.status_code == 200
    entries = resp.json()
    assert any(e["user_id"] == submitter and "matemática" in e["comment"] for e in entries)
