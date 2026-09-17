"""
V4 item 1 — Perfil Público + Torcida (PERFIL_PUBLICO_E_TORCIDA_V1.md,
TORCIDA_MULTIPLA_V2.md). Acesso liberado a qualquer usuário autenticado
e com idade confirmada: o dado exposto aqui (nickname/real_name/foto
aprovada/nível/XP/badges/mundos/streak) já é público por precedente em
Ranking/Friends/Battles/Hall da Fama (§2 do documento original) — não
há checagem extra de "ponto de contato prévio" no backend porque isso
já é verdade pra QUALQUER usuário autenticado hoje (ex.: ranking
global). A restrição real de "sem busca livre" é 100% do lado do
client: nenhuma tela oferece um campo de busca por user_id, só toque
em nome/foto que já aparece numa lista (Ranking, Amigos, Batalhas,
Hall da Fama) — mesmo espírito de GET /social/users/search, que já
existe pra convite de amigo e tem sua própria restrição dedicada.
"""

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from .. import config, schemas, services
from ..auth import require_age_confirmed_user_id
from ..db import get_db

router = APIRouter()


@router.get("/profile/{target_user_id}/public", response_model=schemas.PublicProfileOut)
def get_public_profile(
    target_user_id: str,
    user_id: str = Depends(require_age_confirmed_user_id),
    db: Session = Depends(get_db),
):
    # Auditoria de segurança pré-lançamento mundial (17/09/2026, achado
    # M4): sem teto, dava pra combinar com GET /social/users/search pra
    # coletar user_id + dado público de um número arbitrário de contas
    # em sequência.
    services.enforce_rate_limit("public_profile_view", user_id, max_calls=config.RATE_LIMIT_PUBLIC_PROFILE_VIEW[0], window_seconds=config.RATE_LIMIT_PUBLIC_PROFILE_VIEW[1])
    result = services.get_public_profile(db, viewer_user_id=user_id, target_user_id=target_user_id)
    if result is None:
        raise HTTPException(status_code=404, detail={"error": {"code": "USER_NOT_FOUND", "message": target_user_id}})
    return schemas.PublicProfileOut(**result)


@router.post("/profile/{target_user_id}/torcida", response_model=schemas.TorcidaSendResponse)
def send_torcida(
    target_user_id: str,
    body: schemas.TorcidaSendRequest,
    user_id: str = Depends(require_age_confirmed_user_id),
    db: Session = Depends(get_db),
):
    try:
        sent_today = services.send_torcida(db, from_user_id=user_id, to_user_id=target_user_id, reaction_type=body.reaction_type)
    except services.PublicProfileError as e:
        status_code = {"USER_NOT_FOUND": 404, "TORCIDA_DAILY_LIMIT_REACHED": 429}.get(e.code, 422)
        raise HTTPException(status_code=status_code, detail={"error": {"code": e.code, "message": e.message}})
    return schemas.TorcidaSendResponse(sent_today_by_me=sent_today)


@router.post("/profile/{target_user_id}/invite-movement", response_model=schemas.MovementInviteSendResponse)
def send_movement_invite(
    target_user_id: str,
    user_id: str = Depends(require_age_confirmed_user_id),
    db: Session = Depends(get_db),
):
    """Pedido de Rhoney (05/09/2026): botão "GO" na mesma área de
    Torcida, convidando o visitado a ligar o Movimento — notificação
    push com deep link pra tela de Movimento (ver services.
    send_movement_invite)."""
    try:
        sent_today = services.send_movement_invite(db, from_user_id=user_id, to_user_id=target_user_id)
    except services.PublicProfileError as e:
        status_code = {"USER_NOT_FOUND": 404, "MOVEMENT_INVITE_DAILY_LIMIT_REACHED": 429}.get(e.code, 422)
        raise HTTPException(status_code=status_code, detail={"error": {"code": e.code, "message": e.message}})
    return schemas.MovementInviteSendResponse(sent_today_by_me=sent_today)


@router.post("/profile/{target_user_id}/follow", response_model=schemas.FollowResponse)
def follow_user(
    target_user_id: str,
    user_id: str = Depends(require_age_confirmed_user_id),
    db: Session = Depends(get_db),
):
    """FEED_SOCIAL_V1.md §4 — "seguir" é unilateral, sem aceite da outra
    parte. 422 genérico cobre tanto self-follow quanto bloqueio em
    qualquer direção (nunca revela QUAL dos dois motivos foi, mesmo
    princípio não-revelador já usado em USER_NOT_FOUND de bloqueio no
    perfil público) — já seguir também cai aqui (idempotente pro
    resultado que o client vê: seguindo=true)."""
    services.enforce_rate_limit("profile_follow", user_id, max_calls=config.RATE_LIMIT_FOLLOW[0], window_seconds=config.RATE_LIMIT_FOLLOW[1])
    services.follow_user(db, follower_id=user_id, followed_id=target_user_id)
    return schemas.FollowResponse(
        following=services.is_following(db, user_id, target_user_id),
        fan_count=services.get_fan_count(db, target_user_id),
    )


@router.delete("/profile/{target_user_id}/follow", response_model=schemas.FollowResponse)
def unfollow_user(
    target_user_id: str,
    user_id: str = Depends(require_age_confirmed_user_id),
    db: Session = Depends(get_db),
):
    """§4: deixar de seguir é livre e não notifica a outra parte."""
    services.unfollow_user(db, follower_id=user_id, followed_id=target_user_id)
    return schemas.FollowResponse(
        following=False,
        fan_count=services.get_fan_count(db, target_user_id),
    )
