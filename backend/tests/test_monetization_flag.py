"""
MONETIZATION_UPDATE_FREE_LAUNCH.md — MENTAL lança 100% gratuito.

Cobre os dois estados da flag MONETIZATION_ENABLED (ponto único de
verificação em services.is_territory_unlocked):
- false (default de lançamento): todo território fica acessível a
  qualquer usuário, independente de assinatura.
- true (ativação futura): volta a valer o modelo freemium documentado em
  MONETIZATION.md — território pago exige assinatura após a amostra
  grátis (já coberto em test_core_loop.py::test_paid_territory_...).
"""

import uuid

import app.services as services_module

from .conftest import auth_header


def test_monetization_disabled_by_default(client):
    assert services_module.config.MONETIZATION_ENABLED is False


def test_all_territories_unlocked_when_monetization_disabled(client, monkeypatch):
    monkeypatch.setattr(services_module.config, "MONETIZATION_ENABLED", False)

    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    # 'logica' e 'conhecimento' exigem assinatura no seed (requires_subscription=True),
    # mas com a flag desligada nenhum usuário deve ser bloqueado, mesmo
    # sem assinatura e além da amostra grátis.
    for territory_id in ["palavras", "numeros", "logica", "conhecimento"]:
        for _ in range(3):  # 3 > free_sample_count (2) dos territórios pagos
            resp = client.get("/challenges/next", params={"territory_id": territory_id}, headers=headers)
            assert resp.status_code == 200, f"{territory_id} deveria estar liberado com MONETIZATION_ENABLED=false"
            challenge = resp.json()
            client.post(
                f"/challenges/{challenge['challenge_id']}/answer",
                json={"attempt_id": challenge["attempt_id"], "submitted_answer": "qualquer"},
                headers=headers,
            )


def test_progress_reports_all_territories_unlocked_when_disabled(client, monkeypatch):
    monkeypatch.setattr(services_module.config, "MONETIZATION_ENABLED", False)

    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    progress = client.get("/progress", headers=headers).json()
    for territory in progress["territories"]:
        assert territory["unlocked"] is True, f"{territory['territory_id']} deveria aparecer unlocked=true"
