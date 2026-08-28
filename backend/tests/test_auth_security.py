"""
Achado de auditoria de segurança (28/08/2026): sem SUPABASE_URL nem
SUPABASE_JWT_SECRET configurados, auth.py caía no modo DEV_INSECURE
(token = user_id em texto puro, sem verificar assinatura) SEM nenhuma
trava — se uma dessas env vars sumisse por engano em produção, o backend
continuava rodando normalmente e aceitando qualquer UUID como identidade
de qualquer usuário. Este teste prova que agora isso exige uma opt-in
explícita (config.ALLOW_DEV_INSECURE_AUTH), e falha alto sem ela.
"""

import uuid

from app import config

from .conftest import auth_header


def test_dev_insecure_auth_refuses_without_explicit_opt_in(client, monkeypatch):
    monkeypatch.setattr(config, "ALLOW_DEV_INSECURE_AUTH", False)

    resp = client.get("/profile", headers=auth_header(str(uuid.uuid4())))

    assert resp.status_code == 500
    assert resp.json()["error"]["code"] == "AUTH_MISCONFIGURED"


def test_dev_insecure_auth_works_normally_with_opt_in(client, monkeypatch):
    monkeypatch.setattr(config, "ALLOW_DEV_INSECURE_AUTH", True)

    resp = client.get("/profile", headers=auth_header(str(uuid.uuid4())))

    assert resp.status_code == 200
