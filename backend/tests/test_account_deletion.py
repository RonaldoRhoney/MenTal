"""
Achado de auditoria de segurança (28/08/2026) — DIR-001 item 5, LGPD:
não existia nenhuma forma de excluir de verdade uma conta, só zerar
campos manualmente. DELETE /profile agora delega ao Supabase Auth
(services.delete_account) — apagar o usuário lá derruba em cascata
todo o resto (FKs `on delete cascade`, migrations/001_initial_schema.sql).
"""

import uuid

from app import config

from .conftest import auth_header


def test_delete_account_returns_501_without_service_role_key(client, monkeypatch):
    """
    Ambiente de teste local nunca tem SUPABASE_SERVICE_ROLE_KEY
    configurado — confirma que isso é tratado como limitação de
    ambiente conhecida (501), nunca um 500 genérico nem, pior, um
    sucesso silencioso que na verdade não apagou nada.
    """
    monkeypatch.setattr(config, "SUPABASE_SERVICE_ROLE_KEY", None)
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    resp = client.delete("/profile", headers=headers)
    assert resp.status_code == 501
    assert resp.json()["error"]["code"] == "ACCOUNT_DELETION_UNAVAILABLE"


def test_delete_account_succeeds_when_admin_api_confirms(client, monkeypatch):
    from app import supabase_admin

    monkeypatch.setattr(config, "SUPABASE_SERVICE_ROLE_KEY", "fake-service-role-key-for-test")
    monkeypatch.setattr(supabase_admin, "delete_auth_user", lambda user_id: True)

    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    resp = client.delete("/profile", headers=headers)
    assert resp.status_code == 200
    assert resp.json()["status"] == "deleted"


def test_delete_account_returns_502_when_admin_api_fails(client, monkeypatch):
    from app import supabase_admin

    monkeypatch.setattr(config, "SUPABASE_SERVICE_ROLE_KEY", "fake-service-role-key-for-test")
    monkeypatch.setattr(supabase_admin, "delete_auth_user", lambda user_id: False)

    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    resp = client.delete("/profile", headers=headers)
    assert resp.status_code == 502
    assert resp.json()["error"]["code"] == "ACCOUNT_DELETION_FAILED"


def test_delete_account_requires_age_confirmation(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    # Sem POST /age-gate de propósito.

    resp = client.delete("/profile", headers=headers)
    assert resp.status_code == 403
