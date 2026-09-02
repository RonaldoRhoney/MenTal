"""
FEEDBACK_POS_NIVEL.md — coleta pura de opinião pós-nível. Confirma que o
POST grava o registro associado a usuário/território/desafio sem tocar
em XP/scoring, e que a leitura admin é restrita a role=admin.
"""

import uuid

from .conftest import auth_header


def _get_challenge(client, headers, territory="palavras"):
    resp = client.get(f"/challenges/next?territory_id={territory}", headers=headers)
    assert resp.status_code == 200
    return resp.json()


def test_submit_level_feedback_round_trip(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    challenge = _get_challenge(client, headers)
    profile_before = client.get("/profile", headers=headers).json()

    resp = client.post(
        "/level-feedback",
        json={
            "challenge_id": challenge["challenge_id"],
            "action": "continue",
            "difficulty_rating": "medio",
            "comment": "gostei bastante",
        },
        headers=headers,
    )
    assert resp.status_code == 200
    assert resp.json() == {"ok": True}

    # Coleta pura — não pode ter alterado o perfil/XP do usuário.
    profile_after = client.get("/profile", headers=headers).json()
    assert profile_after == profile_before


def test_submit_level_feedback_comment_is_optional(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)
    challenge = _get_challenge(client, headers)

    resp = client.post(
        "/level-feedback",
        json={"challenge_id": challenge["challenge_id"], "action": "repeat", "difficulty_rating": "facil"},
        headers=headers,
    )
    assert resp.status_code == 200


def test_submit_level_feedback_unknown_challenge_404s(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    resp = client.post(
        "/level-feedback",
        json={"challenge_id": str(uuid.uuid4()), "action": "continue", "difficulty_rating": "dificil"},
        headers=headers,
    )
    assert resp.status_code == 404
    assert resp.json()["error"]["code"] == "CHALLENGE_NOT_FOUND"


def test_admin_level_feedback_requires_admin_role(client):
    regular_user = str(uuid.uuid4())
    headers = auth_header(regular_user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    resp = client.get("/admin/level-feedback", headers=headers)
    assert resp.status_code == 403
    assert resp.json()["error"]["code"] == "ADMIN_ONLY"


def test_admin_level_feedback_lists_entries_for_admin(client):
    from app.db import SessionLocal
    from app import models

    submitter = str(uuid.uuid4())
    submitter_headers = auth_header(submitter)
    client.post("/age-gate", json={"age_confirmed": True}, headers=submitter_headers)
    challenge = _get_challenge(client, submitter_headers)
    client.post(
        "/level-feedback",
        json={"challenge_id": challenge["challenge_id"], "action": "continue", "difficulty_rating": "muito_dificil"},
        headers=submitter_headers,
    )

    admin_user = str(uuid.uuid4())
    admin_headers = auth_header(admin_user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=admin_headers)
    with SessionLocal() as db:
        profile = db.get(models.Profile, admin_user)
        profile.role = "admin"
        db.commit()

    resp = client.get("/admin/level-feedback", headers=admin_headers)
    assert resp.status_code == 200
    entries = resp.json()
    assert any(e["user_id"] == submitter and e["difficulty_rating"] == "muito_dificil" for e in entries)


def test_admin_level_feedback_survives_author_deletion_shown_anonymized(client):
    """
    Migration 048 (LGPD, 01/09/2026): excluir a conta do autor NÃO
    apaga o registro (insumo de calibração de dificuldade de conteúdo)
    — anonimiza via ON DELETE SET NULL. Simula esse estado direto no
    banco (a cascata real só acontece no Postgres de produção via
    Supabase Auth, fora do alcance do SQLite de teste) pra garantir que
    o endpoint admin tolera user_id=None sem quebrar (AdminLevelFeedbackItem
    precisou virar user_id: str | None pra isso).
    """
    from app.db import SessionLocal
    from app import models

    submitter = str(uuid.uuid4())
    submitter_headers = auth_header(submitter)
    client.post("/age-gate", json={"age_confirmed": True}, headers=submitter_headers)
    challenge = _get_challenge(client, submitter_headers)
    client.post(
        "/level-feedback",
        json={"challenge_id": challenge["challenge_id"], "action": "continue", "difficulty_rating": "dificil", "comment": "insumo valioso"},
        headers=submitter_headers,
    )

    with SessionLocal() as db:
        feedback = db.execute(
            models.LevelFeedback.__table__.select().where(models.LevelFeedback.user_id == submitter)
        ).first()
        db.execute(models.LevelFeedback.__table__.update().where(models.LevelFeedback.id == feedback.id).values(user_id=None))
        db.commit()

    admin_user = str(uuid.uuid4())
    admin_headers = auth_header(admin_user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=admin_headers)
    with SessionLocal() as db:
        profile = db.get(models.Profile, admin_user)
        profile.role = "admin"
        db.commit()

    resp = client.get("/admin/level-feedback", headers=admin_headers)
    assert resp.status_code == 200
    entry = next(e for e in resp.json() if e["comment"] == "insumo valioso")
    assert entry["user_id"] is None
    assert entry["difficulty_rating"] == "dificil"
