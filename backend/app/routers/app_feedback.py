"""
Mural de feedback geral (pedido de Rhoney, 2026-08-26; revisado
29/08/2026) — comentário livre sobre o app. Diferente do Feedback
Pós-Nível (amarrado a completar um nível/desafio específico), este é
acessível a qualquer momento e, desde a revisão de 29/08/2026, PÚBLICO:
visível a todos os usuários (não só autor + admin), com reações de
curtir/amei — "isso ajudará mais usuários fazerem comentários sobre o
app". A resposta do admin é a única interação exclusiva de quem tem
role=admin.
"""

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from .. import models, schemas, services
from ..auth import require_age_confirmed_user_id
from ..db import get_db
from ..timeutil import utcnow

router = APIRouter()


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


@router.get("/feedback", response_model=schemas.PublicAppFeedbackListResponse)
def list_app_feedback(user_id: str = Depends(require_age_confirmed_user_id), db: Session = Depends(get_db)):
    rows = db.execute(select(models.AppFeedback).order_by(models.AppFeedback.created_at.desc()).limit(500)).scalars().all()
    if not rows:
        return schemas.PublicAppFeedbackListResponse(items=[])

    feedback_ids = [row.id for row in rows]
    reactions = db.execute(select(models.AppFeedbackReaction).where(models.AppFeedbackReaction.feedback_id.in_(feedback_ids))).scalars().all()

    like_counts: dict[str, int] = {}
    love_counts: dict[str, int] = {}
    my_reactions: dict[str, list[str]] = {}
    for reaction in reactions:
        counts = like_counts if reaction.reaction_type == "like" else love_counts
        counts[reaction.feedback_id] = counts.get(reaction.feedback_id, 0) + 1
        if reaction.user_id == user_id:
            my_reactions.setdefault(reaction.feedback_id, []).append(reaction.reaction_type)

    # FEEDBACK_NOME_REAL_E_TORCIDA_LAYOUT_V1.md §1 (05/09/2026, pré-
    # requisito A1 já aplicado): mural passa a exibir nome real do autor
    # (mesmo padrão de Ranking — real_name com fallback pro client pra
    # nickname). §2: quem está bloqueado entre si nunca vê o nome real
    # nem o nickname um do outro aqui, mesmo com os comentários de ambos
    # continuando visíveis ao restante da comunidade — usa um rótulo
    # genérico só para essa relação específica.
    display_names: dict[str | None, tuple[str, str | None]] = {}
    for row in rows:
        if row.user_id in display_names:
            continue
        if row.user_id is None:
            display_names[row.user_id] = ("?", None)
        elif services.is_blocked_either_way(db, user_id, row.user_id):
            display_names[row.user_id] = ("Usuário", None)
        else:
            profile = db.get(models.Profile, row.user_id)
            display_names[row.user_id] = (profile.nickname, profile.real_name) if profile else ("?", None)

    return schemas.PublicAppFeedbackListResponse(
        items=[
            schemas.PublicAppFeedbackItem(
                id=row.id,
                user_id=row.user_id,
                user_nickname=display_names[row.user_id][0],
                user_real_name=display_names[row.user_id][1],
                comment=row.comment,
                created_at=row.created_at,
                admin_reply=row.admin_reply,
                admin_reply_at=row.admin_reply_at,
                like_count=like_counts.get(row.id, 0),
                love_count=love_counts.get(row.id, 0),
                my_reactions=my_reactions.get(row.id, []),
            )
            for row in rows
        ]
    )


@router.post("/feedback/{feedback_id}/react")
def react_to_app_feedback(
    feedback_id: str,
    body: schemas.ReactToAppFeedbackRequest,
    user_id: str = Depends(require_age_confirmed_user_id),
    db: Session = Depends(get_db),
):
    feedback = db.get(models.AppFeedback, feedback_id)
    if feedback is None:
        raise HTTPException(status_code=404, detail={"error": {"code": "FEEDBACK_NOT_FOUND", "message": feedback_id}})

    existing = db.execute(
        select(models.AppFeedbackReaction).where(
            models.AppFeedbackReaction.feedback_id == feedback_id,
            models.AppFeedbackReaction.user_id == user_id,
            models.AppFeedbackReaction.reaction_type == body.reaction_type,
        )
    ).scalar_one_or_none()

    # Toggle: reagir de novo com o MESMO tipo remove a reação.
    if existing is not None:
        db.delete(existing)
        db.commit()
        return {"reacted": False}

    db.add(models.AppFeedbackReaction(feedback_id=feedback_id, user_id=user_id, reaction_type=body.reaction_type))
    db.commit()
    return {"reacted": True}


@router.post("/admin/feedback/{feedback_id}/reply")
def reply_app_feedback(
    feedback_id: str,
    body: schemas.ReplyAppFeedbackRequest,
    user_id: str = Depends(require_age_confirmed_user_id),
    db: Session = Depends(get_db),
):
    admin_profile = db.get(models.Profile, user_id)
    if admin_profile is None or admin_profile.role != "admin":
        raise HTTPException(status_code=403, detail={"error": {"code": "ADMIN_ONLY", "message": "Restricted to admin accounts"}})

    feedback = db.get(models.AppFeedback, feedback_id)
    if feedback is None:
        raise HTTPException(status_code=404, detail={"error": {"code": "FEEDBACK_NOT_FOUND", "message": feedback_id}})

    feedback.admin_reply = body.reply.strip()
    feedback.admin_reply_at = utcnow()
    feedback.reply_read_by_user = False
    db.commit()
    return {"ok": True}
