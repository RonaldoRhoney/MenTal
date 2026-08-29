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
    entries = resp.json()["items"]
    assert any(e["user_id"] == submitter and "matemática" in e["comment"] for e in entries)


def test_admin_can_reply_and_user_sees_the_reply(client):
    from app.db import SessionLocal
    from app import models

    submitter = str(uuid.uuid4())
    submitter_headers = auth_header(submitter)
    client.post("/age-gate", json={"age_confirmed": True}, headers=submitter_headers)
    client.post("/feedback", json={"comment": "O app trava ao marcar a resposta"}, headers=submitter_headers)

    admin_user = str(uuid.uuid4())
    admin_headers = auth_header(admin_user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=admin_headers)
    with SessionLocal() as db:
        profile = db.get(models.Profile, admin_user)
        profile.role = "admin"
        db.commit()

    feedback_id = client.get("/admin/feedback", headers=admin_headers).json()["items"][0]["id"]

    resp = client.post(f"/admin/feedback/{feedback_id}/reply", json={"reply": "Já identificamos e vamos corrigir!"}, headers=admin_headers)
    assert resp.status_code == 200

    admin_view = client.get("/admin/feedback", headers=admin_headers).json()["items"][0]
    assert admin_view["admin_reply"] == "Já identificamos e vamos corrigir!"
    assert admin_view["admin_reply_at"] is not None

    mine = client.get("/feedback/mine", headers=submitter_headers).json()["items"]
    assert mine[0]["admin_reply"] == "Já identificamos e vamos corrigir!"


def test_reply_requires_admin_role(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)
    client.post("/feedback", json={"comment": "teste"}, headers=headers)

    resp = client.post("/admin/feedback/qualquer-id/reply", json={"reply": "oi"}, headers=headers)
    assert resp.status_code == 403


def test_reply_to_unknown_feedback_returns_404(client):
    from app.db import SessionLocal
    from app import models

    admin_user = str(uuid.uuid4())
    admin_headers = auth_header(admin_user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=admin_headers)
    with SessionLocal() as db:
        profile = db.get(models.Profile, admin_user)
        profile.role = "admin"
        db.commit()

    resp = client.post("/admin/feedback/nao-existe/reply", json={"reply": "oi"}, headers=admin_headers)
    assert resp.status_code == 404


def test_my_feedback_list_only_returns_own_entries(client):
    user_a = str(uuid.uuid4())
    headers_a = auth_header(user_a)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers_a)
    client.post("/feedback", json={"comment": "feedback do usuário A"}, headers=headers_a)

    user_b = str(uuid.uuid4())
    headers_b = auth_header(user_b)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers_b)
    client.post("/feedback", json={"comment": "feedback do usuário B"}, headers=headers_b)

    mine_a = client.get("/feedback/mine", headers=headers_a).json()["items"]
    assert len(mine_a) == 1
    assert mine_a[0]["comment"] == "feedback do usuário A"
