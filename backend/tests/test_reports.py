"""
Achado de auditoria de segurança (28/08/2026) — DIR-001 §4/POL-003 §2.4
exigem um canal de denúncia pra conteúdo já aprovado (foto/nome) que se
revele impróprio depois. Puramente reativo: só registra, nunca esconde
nada sozinho.
"""

import uuid

from .conftest import auth_header


def test_report_user_and_admin_sees_it(client):
    from app import models
    from app.db import SessionLocal

    reporter = str(uuid.uuid4())
    reported = str(uuid.uuid4())
    admin = str(uuid.uuid4())
    reporter_headers = auth_header(reporter)
    reported_headers = auth_header(reported)
    admin_headers = auth_header(admin)
    client.post("/age-gate", json={"age_confirmed": True}, headers=reporter_headers)
    client.post("/age-gate", json={"age_confirmed": True}, headers=reported_headers)
    client.post("/age-gate", json={"age_confirmed": True}, headers=admin_headers)

    with SessionLocal() as db:
        db.get(models.Profile, admin).role = "admin"
        db.commit()

    resp = client.post(
        "/social/report",
        json={"reported_user_id": reported, "reason": "Foto imprópria"},
        headers=reporter_headers,
    )
    assert resp.status_code == 200
    assert resp.json()["status"] == "reported"

    admin_view = client.get("/admin/reports", headers=admin_headers).json()
    assert len(admin_view) == 1
    assert admin_view[0]["reporter_user_id"] == reporter
    assert admin_view[0]["reported_user_id"] == reported
    assert admin_view[0]["reason"] == "Foto imprópria"


def test_cannot_report_self(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    resp = client.post("/social/report", json={"reported_user_id": user, "reason": "teste"}, headers=headers)
    assert resp.status_code == 400
    assert resp.json()["error"]["code"] == "CANNOT_REPORT_SELF"


def test_admin_reports_endpoint_requires_admin_role(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    resp = client.get("/admin/reports", headers=headers)
    assert resp.status_code == 403
