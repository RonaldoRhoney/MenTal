"""
Menu de feedback geral (pedido de Rhoney, 2026-08-26) — comentário livre
sobre o app, acessível a qualquer momento pelo usuário, diferente do
Feedback Pós-Nível (que é amarrado a completar um nível/desafio
específico). Mesmo padrão de acesso admin read-only do level_feedback.
"""

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from .. import models, schemas
from ..auth import get_current_user_id
from ..db import get_db

router = APIRouter()


@router.post("/feedback", response_model=schemas.AppFeedbackResponse)
def submit_app_feedback(
    body: schemas.AppFeedbackRequest,
    user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    comment = body.comment.strip()
    if not comment:
        raise HTTPException(status_code=422, detail={"error": {"code": "EMPTY_COMMENT", "message": "Comment cannot be blank"}})

    db.add(models.AppFeedback(user_id=user_id, comment=comment))
    db.commit()
    return schemas.AppFeedbackResponse()


@router.get("/admin/feedback", response_model=list[schemas.AdminAppFeedbackItem])
def list_app_feedback(
    user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    profile = db.get(models.Profile, user_id)
    if profile is None or profile.role != "admin":
        raise HTTPException(status_code=403, detail={"error": {"code": "ADMIN_ONLY", "message": "Restricted to admin accounts"}})

    rows = (
        db.execute(select(models.AppFeedback).order_by(models.AppFeedback.created_at.desc()).limit(500))
        .scalars()
        .all()
    )
    return [
        schemas.AdminAppFeedbackItem(id=row.id, user_id=row.user_id, comment=row.comment, created_at=row.created_at)
        for row in rows
    ]
