"""
Menu de feedback geral (pedido de Rhoney, 2026-08-26) — comentário livre
sobre o app, acessível a qualquer momento pelo usuário, diferente do
Feedback Pós-Nível (que é amarrado a completar um nível/desafio
específico). Mesmo padrão de acesso admin read-only do level_feedback.

Resposta do admin (29/08/2026): "deve haver... campos que eu possa
responder, discutir e interagir com o usuário" — resposta única por
feedback (não é uma thread completa; ver models.AppFeedback).
"""

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from .. import models, schemas
from ..auth import get_current_user_id, require_age_confirmed_user_id
from ..db import get_db
from ..timeutil import utcnow

router = APIRouter()


def _require_admin(db: Session, user_id: str) -> models.Profile:
    profile = db.get(models.Profile, user_id)
    if profile is None or profile.role != "admin":
        raise HTTPException(status_code=403, detail={"error": {"code": "ADMIN_ONLY", "message": "Restricted to admin accounts"}})
    return profile


@router.post("/feedback", response_model=schemas.AppFeedbackResponse)
def submit_app_feedback(
    body: schemas.AppFeedbackRequest,
    user_id: str = Depends(require_age_confirmed_user_id),
    db: Session = Depends(get_db),
):
    comment = body.comment.strip()
    if not comment:
        raise HTTPException(status_code=422, detail={"error": {"code": "EMPTY_COMMENT", "message": "Comment cannot be blank"}})

    db.add(models.AppFeedback(user_id=user_id, comment=comment))
    db.commit()
    return schemas.AppFeedbackResponse()


@router.get("/feedback/mine", response_model=schemas.MyAppFeedbackListResponse)
def list_my_app_feedback(user_id: str = Depends(require_age_confirmed_user_id), db: Session = Depends(get_db)):
    rows = (
        db.execute(select(models.AppFeedback).where(models.AppFeedback.user_id == user_id).order_by(models.AppFeedback.created_at.desc()))
        .scalars()
        .all()
    )
    # Abrir a própria lista marca as respostas como lidas — mesmo
    # princípio de "ler = marcar como visto" já usado em outras notificações
    # do app, sem precisar de um endpoint dedicado só para isso.
    changed = False
    for row in rows:
        if row.admin_reply is not None and not row.reply_read_by_user:
            row.reply_read_by_user = True
            changed = True
    if changed:
        db.commit()

    return schemas.MyAppFeedbackListResponse(
        items=[
            schemas.MyAppFeedbackItem(
                id=row.id, comment=row.comment, created_at=row.created_at, admin_reply=row.admin_reply, admin_reply_at=row.admin_reply_at
            )
            for row in rows
        ]
    )


@router.get("/admin/feedback", response_model=schemas.AdminAppFeedbackListResponse)
def list_app_feedback(user_id: str = Depends(get_current_user_id), db: Session = Depends(get_db)):
    _require_admin(db, user_id)

    rows = (
        db.execute(select(models.AppFeedback).order_by(models.AppFeedback.created_at.desc()).limit(500))
        .scalars()
        .all()
    )
    nicknames: dict[str, str] = {}
    for row in rows:
        if row.user_id not in nicknames:
            profile = db.get(models.Profile, row.user_id)
            nicknames[row.user_id] = profile.nickname if profile else "?"
    return schemas.AdminAppFeedbackListResponse(
        items=[
            schemas.AdminAppFeedbackItem(
                id=row.id,
                user_id=row.user_id,
                user_nickname=nicknames[row.user_id],
                comment=row.comment,
                created_at=row.created_at,
                admin_reply=row.admin_reply,
                admin_reply_at=row.admin_reply_at,
            )
            for row in rows
        ]
    )


@router.post("/admin/feedback/{feedback_id}/reply")
def reply_app_feedback(
    feedback_id: str,
    body: schemas.ReplyAppFeedbackRequest,
    user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    _require_admin(db, user_id)

    feedback = db.get(models.AppFeedback, feedback_id)
    if feedback is None:
        raise HTTPException(status_code=404, detail={"error": {"code": "FEEDBACK_NOT_FOUND", "message": feedback_id}})

    feedback.admin_reply = body.reply.strip()
    feedback.admin_reply_at = utcnow()
    feedback.reply_read_by_user = False
    db.commit()
    return {"ok": True}
