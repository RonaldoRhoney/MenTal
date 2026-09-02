"""
Mural de feedback geral (26/08/2026; revisado 29/08/2026) — comentário
livre sobre o app, diferente de level_feedback (amarrado a um
nível/desafio específico). Desde 29/08/2026 é PÚBLICO: qualquer usuário
autenticado vê todos os feedbacks (não só o próprio), com reações de
curtir/amei; só a resposta continua exclusiva de quem tem role=admin.
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


def test_feedback_is_visible_to_any_authenticated_user(client):
    """Achado de decisão de produto (29/08/2026): feedback deixou de ser
    privado — qualquer usuário vê o feedback de qualquer outro."""
    submitter = str(uuid.uuid4())
    submitter_headers = auth_header(submitter)
    client.post("/age-gate", json={"age_confirmed": True}, headers=submitter_headers)
    client.post("/feedback", json={"comment": "Sugestão: mais territórios de matemática"}, headers=submitter_headers)

    other_user = str(uuid.uuid4())
    other_headers = auth_header(other_user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=other_headers)

    resp = client.get("/feedback", headers=other_headers)
    assert resp.status_code == 200
    entries = resp.json()["items"]
    assert any(e["user_id"] == submitter and "matemática" in e["comment"] for e in entries)


def test_feedback_survives_author_deletion_shown_anonymized(client):
    """
    Migration 048 (LGPD, 01/09/2026): excluir a conta do autor NÃO
    apaga o feedback (mural público com possível resposta do admin) —
    anonimiza via ON DELETE SET NULL. Simula esse estado direto no
    banco (a cascata real só acontece no Postgres de produção via
    Supabase Auth, fora do alcance do SQLite de teste) pra garantir que
    o endpoint tolera user_id=None sem quebrar.
    """
    from app.db import SessionLocal
    from app import models

    submitter = str(uuid.uuid4())
    submitter_headers = auth_header(submitter)
    client.post("/age-gate", json={"age_confirmed": True}, headers=submitter_headers)
    client.post("/feedback", json={"comment": "Feedback de quem depois vai excluir a conta"}, headers=submitter_headers)

    with SessionLocal() as db:
        feedback = db.execute(
            models.AppFeedback.__table__.select().where(models.AppFeedback.user_id == submitter)
        ).first()
        db.execute(models.AppFeedback.__table__.update().where(models.AppFeedback.id == feedback.id).values(user_id=None))
        db.commit()

    other_user = str(uuid.uuid4())
    other_headers = auth_header(other_user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=other_headers)

    resp = client.get("/feedback", headers=other_headers)
    assert resp.status_code == 200
    item = next(i for i in resp.json()["items"] if "excluir a conta" in i["comment"])
    assert item["user_id"] is None
    assert item["user_nickname"] == "?"


def test_admin_can_reply_and_reply_is_publicly_visible(client):
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

    feedback_id = next(i for i in client.get("/feedback", headers=admin_headers).json()["items"] if i["user_id"] == submitter)["id"]

    resp = client.post(f"/admin/feedback/{feedback_id}/reply", json={"reply": "Já identificamos e vamos corrigir!"}, headers=admin_headers)
    assert resp.status_code == 200

    # Qualquer usuário (não só o autor) já vê a resposta.
    other_user = str(uuid.uuid4())
    other_headers = auth_header(other_user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=other_headers)
    item = next(i for i in client.get("/feedback", headers=other_headers).json()["items"] if i["id"] == feedback_id)
    assert item["admin_reply"] == "Já identificamos e vamos corrigir!"


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


def test_react_toggles_like_and_updates_count(client):
    submitter = str(uuid.uuid4())
    submitter_headers = auth_header(submitter)
    client.post("/age-gate", json={"age_confirmed": True}, headers=submitter_headers)
    client.post("/feedback", json={"comment": "Testando reações"}, headers=submitter_headers)
    feedback_id = client.get("/feedback", headers=submitter_headers).json()["items"][0]["id"]

    reactor = str(uuid.uuid4())
    reactor_headers = auth_header(reactor)
    client.post("/age-gate", json={"age_confirmed": True}, headers=reactor_headers)

    resp = client.post(f"/feedback/{feedback_id}/react", json={"reaction_type": "like"}, headers=reactor_headers)
    assert resp.status_code == 200
    assert resp.json()["reacted"] is True

    item = client.get("/feedback", headers=reactor_headers).json()["items"][0]
    assert item["like_count"] == 1
    assert item["love_count"] == 0
    assert item["my_reactions"] == ["like"]

    # Reagir de novo com o MESMO tipo remove a reação (toggle).
    resp = client.post(f"/feedback/{feedback_id}/react", json={"reaction_type": "like"}, headers=reactor_headers)
    assert resp.json()["reacted"] is False

    item = client.get("/feedback", headers=reactor_headers).json()["items"][0]
    assert item["like_count"] == 0
    assert item["my_reactions"] == []


def test_react_to_unknown_feedback_returns_404(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    resp = client.post("/feedback/nao-existe/react", json={"reaction_type": "love"}, headers=headers)
    assert resp.status_code == 404


def test_like_and_love_are_independent_reactions(client):
    submitter = str(uuid.uuid4())
    submitter_headers = auth_header(submitter)
    client.post("/age-gate", json={"age_confirmed": True}, headers=submitter_headers)
    client.post("/feedback", json={"comment": "Testando like e love juntos"}, headers=submitter_headers)
    feedback_id = client.get("/feedback", headers=submitter_headers).json()["items"][0]["id"]

    reactor = str(uuid.uuid4())
    reactor_headers = auth_header(reactor)
    client.post("/age-gate", json={"age_confirmed": True}, headers=reactor_headers)

    client.post(f"/feedback/{feedback_id}/react", json={"reaction_type": "like"}, headers=reactor_headers)
    client.post(f"/feedback/{feedback_id}/react", json={"reaction_type": "love"}, headers=reactor_headers)

    item = client.get("/feedback", headers=reactor_headers).json()["items"][0]
    assert item["like_count"] == 1
    assert item["love_count"] == 1
    assert set(item["my_reactions"]) == {"like", "love"}
