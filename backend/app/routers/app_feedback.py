"""
Mural de feedback geral (pedido de Rhoney, 2026-08-26; revisado
29/08/2026) — comentário livre sobre o app. Diferente do Feedback
Pós-Nível (amarrado a completar um nível/desafio específico), este é
acessível a qualquer momento e, desde a revisão de 29/08/2026, PÚBLICO:
visível a todos os usuários (não só autor + admin), com reações de
curtir/amei — "isso ajudará mais usuários fazerem comentários sobre o
app". Desde 20/09/2026 (decisão de Rhoney) o mural é ABERTO: qualquer
usuário comenta E responde aos comentários dos outros; a "Resposta da
equipe" (admin) continua como resposta oficial destacada. Como todos
escrevem, há rate limit + teto diário (achado M1 da auditoria) e o autor
(ou o admin) pode apagar uma resposta.
"""

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from .. import config, models, rewards, schemas, services
from ..auth import require_age_confirmed_user_id
from ..db import get_db
from ..timeutil import utcnow

router = APIRouter()


def _enforce_feedback_limits(db: Session, user_id: str) -> None:
    """Freio contra flood do mural aberto: por minuto e por dia (comentários
    + respostas somados)."""
    services.enforce_rate_limit(
        "app_feedback", user_id, max_calls=config.RATE_LIMIT_FEEDBACK_POST[0], window_seconds=config.RATE_LIMIT_FEEDBACK_POST[1]
    )
    day_start = utcnow().replace(hour=0, minute=0, second=0, microsecond=0)
    posted = (
        db.execute(select(func.count()).select_from(models.AppFeedback).where(models.AppFeedback.user_id == user_id, models.AppFeedback.created_at >= day_start)).scalar_one()
        + db.execute(select(func.count()).select_from(models.AppFeedbackReply).where(models.AppFeedbackReply.user_id == user_id, models.AppFeedbackReply.created_at >= day_start)).scalar_one()
    )
    if posted >= config.APP_FEEDBACK_DAILY_LIMIT:
        raise HTTPException(status_code=429, detail={"error": {"code": "DAILY_FEEDBACK_LIMIT", "message": "Limite diário de comentários atingido"}})


def _display_name(db: Session, viewer_id: str, target_id: str | None, cache: dict) -> tuple[str, str | None]:
    """Nome exibido de um autor (FEEDBACK_NOME_REAL_E_TORCIDA_LAYOUT_V1.md §1/§2):
    real_name com fallback pro nickname; bloqueados entre si só veem um
    rótulo genérico um do outro."""
    if target_id in cache:
        return cache[target_id]
    if target_id is None:
        cache[target_id] = ("?", None)
    elif services.is_blocked_either_way(db, viewer_id, target_id):
        cache[target_id] = ("Usuário", None)
    else:
        profile = db.get(models.Profile, target_id)
        cache[target_id] = (profile.nickname, profile.real_name) if profile else ("?", None)
    return cache[target_id]


@router.post("/feedback", response_model=schemas.AppFeedbackResponse)
def submit_app_feedback(
    body: schemas.AppFeedbackRequest,
    user_id: str = Depends(require_age_confirmed_user_id),
    db: Session = Depends(get_db),
):
    comment = body.comment.strip()
    if not comment:
        raise HTTPException(status_code=422, detail={"error": {"code": "EMPTY_COMMENT", "message": "Comment cannot be blank"}})
    _enforce_feedback_limits(db, user_id)

    db.add(models.AppFeedback(user_id=user_id, comment=comment))
    db.commit()
    rewards.safely(rewards.on_feedback, db, user_id, comment, utcnow().date())
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
        _display_name(db, user_id, row.user_id, display_names)

    replies_by_feedback: dict[str, list[schemas.PublicAppFeedbackReply]] = {}
    reply_rows = (
        db.execute(
            select(models.AppFeedbackReply)
            .where(models.AppFeedbackReply.feedback_id.in_(feedback_ids))
            .order_by(models.AppFeedbackReply.created_at.asc())
        )
        .scalars()
        .all()
    )
    for reply in reply_rows:
        nickname, real_name = _display_name(db, user_id, reply.user_id, display_names)
        replies_by_feedback.setdefault(reply.feedback_id, []).append(
            schemas.PublicAppFeedbackReply(
                id=reply.id,
                user_id=reply.user_id,
                user_nickname=nickname,
                user_real_name=real_name,
                comment=reply.comment,
                created_at=reply.created_at,
                is_mine=reply.user_id == user_id,
            )
        )

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
                replies=replies_by_feedback.get(row.id, []),
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


@router.post("/feedback/{feedback_id}/replies", response_model=schemas.PublicAppFeedbackReply)
def reply_to_feedback_as_user(
    feedback_id: str,
    body: schemas.AppFeedbackReplyRequest,
    user_id: str = Depends(require_age_confirmed_user_id),
    db: Session = Depends(get_db),
):
    """Qualquer usuário responde a um comentário do mural (decisão de Rhoney,
    20/09/2026). Sem XP/recompensa — só conversa (anti-farm)."""
    comment = body.comment.strip()
    if not comment:
        raise HTTPException(status_code=422, detail={"error": {"code": "EMPTY_COMMENT", "message": "Reply cannot be blank"}})
    feedback = db.get(models.AppFeedback, feedback_id)
    if feedback is None:
        raise HTTPException(status_code=404, detail={"error": {"code": "FEEDBACK_NOT_FOUND", "message": feedback_id}})
    _enforce_feedback_limits(db, user_id)

    reply = models.AppFeedbackReply(feedback_id=feedback_id, user_id=user_id, comment=comment)
    db.add(reply)
    db.commit()
    db.refresh(reply)
    nickname, real_name = _display_name(db, user_id, user_id, {})
    return schemas.PublicAppFeedbackReply(
        id=reply.id, user_id=user_id, user_nickname=nickname, user_real_name=real_name, comment=reply.comment, created_at=reply.created_at, is_mine=True
    )


@router.delete("/feedback/replies/{reply_id}")
def delete_feedback_reply(
    reply_id: str,
    user_id: str = Depends(require_age_confirmed_user_id),
    db: Session = Depends(get_db),
):
    """O autor apaga a própria resposta; o admin apaga qualquer uma
    (moderação de um mural aberto). Outro usuário recebe 404 — nunca
    revela que a resposta existe."""
    reply = db.get(models.AppFeedbackReply, reply_id)
    if reply is None:
        raise HTTPException(status_code=404, detail={"error": {"code": "REPLY_NOT_FOUND", "message": reply_id}})
    if reply.user_id != user_id:
        profile = db.get(models.Profile, user_id)
        if profile is None or profile.role != "admin":
            raise HTTPException(status_code=404, detail={"error": {"code": "REPLY_NOT_FOUND", "message": reply_id}})
    db.delete(reply)
    db.commit()
    return {"ok": True}


@router.post("/admin/feedback/{feedback_id}/reply")
def reply_app_feedback(
    feedback_id: str,
    body: schemas.ReplyAppFeedbackRequest,
    user_id: str = Depends(require_age_confirmed_user_id),
    db: Session = Depends(get_db),
):
    services.require_admin(db, user_id)

    feedback = db.get(models.AppFeedback, feedback_id)
    if feedback is None:
        raise HTTPException(status_code=404, detail={"error": {"code": "FEEDBACK_NOT_FOUND", "message": feedback_id}})

    feedback.admin_reply = body.reply.strip()
    feedback.admin_reply_at = utcnow()
    feedback.reply_read_by_user = False
    db.commit()
    return {"ok": True}
