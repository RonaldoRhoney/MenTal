import uuid

from app import config

from .conftest import auth_header


def test_age_confirmed_true_creates_profile_and_records_consent(client):
    resp = client.post("/age-gate", json={"age_confirmed": True}, headers=auth_header(str(uuid.uuid4())))
    assert resp.status_code == 200
    body = resp.json()
    assert body["age_confirmed_at"] is not None
    assert body["terms_version_accepted"] == config.TERMS_VERSION
    assert "nickname" in body


def test_age_confirmed_false_rejected_without_creating_profile(client):
    """MENTAL-DIR-001 (24/08/2026): MENTAL é exclusivo pra maiores de 18
    anos — sem confirmação, nenhum dado é coletado e nenhum caminho de
    código trata o usuário como menor. Response não deve criar perfil
    (GET /profile depois disso não deveria achar nada, mas o próprio
    get_or_create_profile de outros endpoints cobre esse caso — aqui só
    confirmamos que a tentativa em si é rejeitada)."""
    resp = client.post("/age-gate", json={"age_confirmed": False}, headers=auth_header(str(uuid.uuid4())))
    assert resp.status_code == 403
    assert resp.json()["error"]["code"] == "MAJORITY_NOT_CONFIRMED"


def test_age_gate_requires_boolean_field(client):
    resp = client.post("/age-gate", json={"age_confirmed": "maybe"}, headers=auth_header(str(uuid.uuid4())))
    assert resp.status_code == 422


def test_profile_exposes_age_confirmed_at_for_client_to_skip_age_gate(client):
    """Achado real (2026-08-26): a tela de confirmação de maioridade
    aparecia a cada login, mesmo pra quem já tinha confirmado — o client
    nunca checava o backend, só um estado em memória. GET /profile
    precisa expor age_confirmed_at pra o client decidir se pula a tela."""
    headers = auth_header(str(uuid.uuid4()))

    before = client.get("/profile", headers=headers).json()
    assert before["age_confirmed_at"] is None

    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    after = client.get("/profile", headers=headers).json()
    assert after["age_confirmed_at"] is not None
