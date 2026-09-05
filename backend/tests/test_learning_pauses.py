"""
V3.2 (V3/V3.2_TECNOLOGIA.md §3) — Pausa para Aprender: leitura sem
options/correct_answer/timer, XP fixo só na primeira conclusão.
"""

import uuid
from datetime import timedelta

from app import config, models
from app.db import SessionLocal
from app.timeutil import utcnow

from .conftest import auth_header


def _serve_and_backdate(client, headers, user_id: str, territory_id: str) -> str:
    """Passa pelo fluxo real (GET /next, que agora grava
    LearningPauseServe — achado de auditoria de segurança M2, 05/09/2026)
    e empurra served_at pro passado o suficiente pra passar do piso
    LEARNING_PAUSE_MIN_READ_SECONDS, simulando "levou um tempo real pra
    ler", nunca "completou instantaneamente". Retorna o pause_id
    REALMENTE servido por /next (a base de teste é compartilhada entre
    testes na mesma sessão — outro teste pode ter semeado uma Pausa no
    mesmo território, então /next pode sortear uma diferente da que
    este teste acabou de criar)."""
    served = client.get("/learning-pauses/next", params={"territory_id": territory_id}, headers=headers).json()
    pause_id = served["learning_pause_id"]
    with SessionLocal() as db:
        serve = db.get(models.LearningPauseServe, (user_id, pause_id))
        serve.served_at = utcnow() - timedelta(seconds=config.LEARNING_PAUSE_MIN_READ_SECONDS + 5)
        db.commit()
    return pause_id


def _seed_pause(territory_id: str = "tecnologia_fundamentos", text: str = "O que é a internet, de verdade?") -> str:
    with SessionLocal() as db:
        pause = models.LearningPause(territory_id=territory_id, difficulty_level=1, text=text, age_reviewed=True)
        db.add(pause)
        db.commit()
        db.refresh(pause)
        return pause.id


def test_next_learning_pause_404_when_territory_has_none(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    resp = client.get("/learning-pauses/next", params={"territory_id": "tecnologia_seguranca"}, headers=headers)
    assert resp.status_code == 404
    assert resp.json()["error"]["code"] == "NO_LEARNING_PAUSES_AVAILABLE"


def test_next_learning_pause_returns_reading_content(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)
    _seed_pause()

    resp = client.get("/learning-pauses/next", params={"territory_id": "tecnologia_fundamentos"}, headers=headers)
    assert resp.status_code == 200
    body = resp.json()
    assert body["territory_id"] == "tecnologia_fundamentos"
    assert body["text"]
    assert "options" not in body
    assert "correct_answer" not in body


def test_complete_learning_pause_awards_xp_once(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)
    _seed_pause()

    with SessionLocal() as db:
        profile_before = db.get(models.Profile, user.replace("-", ""))
        xp_before = profile_before.xp_total if profile_before else 0

    pause_id = _serve_and_backdate(client, headers, user, "tecnologia_fundamentos")
    resp1 = client.post(f"/learning-pauses/{pause_id}/complete", headers=headers)
    assert resp1.status_code == 200
    body1 = resp1.json()
    assert body1["xp_awarded"] > 0
    assert body1["already_read_before"] is False

    resp2 = client.post(f"/learning-pauses/{pause_id}/complete", headers=headers)
    body2 = resp2.json()
    assert body2["xp_awarded"] == 0
    assert body2["already_read_before"] is True

    with SessionLocal() as db:
        profile_after = db.get(models.Profile, user.replace("-", ""))
        assert profile_after.xp_total - xp_before == body1["xp_awarded"]


def test_next_learning_pause_includes_institutional_video_when_present(client):
    """V3.4 (V3/V3.4_LIBRAS.md §2/§3.2) — vídeo institucional opcional
    com atribuição de fonte, reaproveitando Pausa para Aprender."""
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)
    with SessionLocal() as db:
        pause = models.LearningPause(
            territory_id="libras",
            difficulty_level=1,
            text="O sinal de 'obrigado(a)' em Libras...",
            age_reviewed=True,
            video_url="https://dicionario.ines.gov.br/exemplo",
            source_name="INES — Instituto Nacional de Educação de Surdos",
            source_url="https://www.ines.gov.br",
        )
        db.add(pause)
        db.commit()

    resp = client.get("/learning-pauses/next", params={"territory_id": "libras"}, headers=headers)
    assert resp.status_code == 200
    body = resp.json()
    assert body["video_url"] == "https://dicionario.ines.gov.br/exemplo"
    assert body["source_name"] == "INES — Instituto Nacional de Educação de Surdos"
    assert body["source_url"] == "https://www.ines.gov.br"


def test_next_learning_pause_video_fields_absent_by_default(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)
    _seed_pause()

    resp = client.get("/learning-pauses/next", params={"territory_id": "tecnologia_fundamentos"}, headers=headers)
    body = resp.json()
    assert body["video_url"] is None
    assert body["source_name"] is None
    assert body["source_url"] is None


def test_complete_without_ever_calling_next_is_rejected(client):
    """Achado de auditoria de segurança M2 (05/09/2026): sem nunca ter
    passado por GET /next, /complete não pode conceder XP — nenhuma
    prova de que a Pausa foi de fato aberta."""
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)
    pause_id = _seed_pause()

    resp = client.post(f"/learning-pauses/{pause_id}/complete", headers=headers)
    assert resp.status_code == 400
    assert resp.json()["error"]["code"] == "COMPLETION_TOO_FAST"


def test_completing_instantly_after_next_is_rejected(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)
    pause_id = _seed_pause()

    client.get("/learning-pauses/next", params={"territory_id": "tecnologia_fundamentos"}, headers=headers)
    resp = client.post(f"/learning-pauses/{pause_id}/complete", headers=headers)
    assert resp.status_code == 400
    assert resp.json()["error"]["code"] == "COMPLETION_TOO_FAST"


def test_complete_unknown_learning_pause_404s(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    resp = client.post(f"/learning-pauses/{uuid.uuid4()}/complete", headers=headers)
    assert resp.status_code == 404
    assert resp.json()["error"]["code"] == "LEARNING_PAUSE_NOT_FOUND"
