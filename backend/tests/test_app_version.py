"""
SCREENSHOTS_LOJA_E_AVISO_ATUALIZACAO_V1.md §2 (05/09/2026) — aviso
gentil de nova versão disponível. Endpoint público (sem token), o
client compara os dois valores com sua própria versão instalada.
"""


def test_get_app_version_is_public_and_returns_configured_versions(client, monkeypatch):
    from app import config

    monkeypatch.setattr(config, "APP_LATEST_VERSION", "1.2.3")
    monkeypatch.setattr(config, "APP_MIN_REQUIRED_VERSION", "1.0.0")

    resp = client.get("/app/version")
    assert resp.status_code == 200
    body = resp.json()
    assert body["latest_version"] == "1.2.3"
    assert body["min_required_version"] == "1.0.0"
