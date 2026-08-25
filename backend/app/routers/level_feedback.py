"""
FEEDBACK_POS_NIVEL.md (aprovado) — tela rápida de feedback exibida pelo
client sempre que um nível (desafio) é concluído em qualquer território.
Coleta pura: nunca lida por hint_penalty_factor nem qualquer mecânica
adaptativa (scoring.py, services.pick_difficulty_for) — só o endpoint
admin abaixo consulta o dado, restrito a role=admin (mesmo escopo já
registrado em ADMIN_PANEL_E_CREDITO_INSTITUCIONAL.md).
"""

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from .. import models, schemas
from ..auth import get_current_user_id
from ..db import get_db

router = APIRouter()


@router.post("/level-feedback", response_model=schemas.LevelFeedbackResponse)
def submit_level_feedback(
    body: schemas.LevelFeedbackRequest,
    user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    challenge = db.get(models.Challenge, body.challenge_id)
    if challenge is None:
        raise HTTPException(status_code=404, detail={"error": {"code": "CHALLENGE_NOT_FOUND", "message": body.challenge_id}})

    comment = body.comment.strip() if body.comment else None
    feedback = models.LevelFeedback(
        user_id=user_id,
        territory_id=challenge.territory_id,
        challenge_id=challenge.id,
        action=body.action,
        difficulty_rating=body.difficulty_rating,
        comment=comment or None,
    )
    db.add(feedback)
    db.commit()
    return schemas.LevelFeedbackResponse()


@router.get("/admin/level-feedback", response_model=list[schemas.AdminLevelFeedbackItem])
def list_level_feedback(
    user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    profile = db.get(models.Profile, user_id)
    if profile is None or profile.role != "admin":
        raise HTTPException(status_code=403, detail={"error": {"code": "ADMIN_ONLY", "message": "Restricted to admin accounts"}})

    rows = (
        db.execute(select(models.LevelFeedback).order_by(models.LevelFeedback.created_at.desc()).limit(500))
        .scalars()
        .all()
    )
    return [
        schemas.AdminLevelFeedbackItem(
            id=row.id,
            user_id=row.user_id,
            territory_id=row.territory_id,
            challenge_id=row.challenge_id,
            action=row.action,
            difficulty_rating=row.difficulty_rating,
            comment=row.comment,
            created_at=row.created_at,
        )
        for row in rows
    ]
