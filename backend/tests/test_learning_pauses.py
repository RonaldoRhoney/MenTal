"""
V3.2 (V3/V3.2_TECNOLOGIA.md §3) — Pausa para Aprender: leitura sem
options/correct_answer/timer, XP fixo só na primeira conclusão.
"""

import uuid

from app import models
from app.db import SessionLocal

from .conftest import auth_header


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
    pause_id = _seed_pause()

    with SessionLocal() as db:
        profile_before = db.get(models.Profile, user.replace("-", ""))
        xp_before = profile_before.xp_total if profile_before else 0

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


def test_complete_unknown_learning_pause_404s(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    resp = client.post(f"/learning-pauses/{uuid.uuid4()}/complete", headers=headers)
    assert resp.status_code == 404
    assert resp.json()["error"]["code"] == "LEARNING_PAUSE_NOT_FOUND"
