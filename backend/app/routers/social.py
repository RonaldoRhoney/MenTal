import secrets

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from .. import models, schemas, services
from ..auth import get_current_user_id
from ..db import get_db

router = APIRouter()


@router.get("/social/invite-code")
def get_invite_code(user_id: str = Depends(get_current_user_id), db: Session = Depends(get_db)):
    invite = db.execute(select(models.Invite).where(models.Invite.inviter_user_id == user_id)).scalars().first()
    if invite is None:
        invite = models.Invite(inviter_user_id=user_id, invite_code=secrets.token_urlsafe(6))
        db.add(invite)
        db.commit()
        db.refresh(invite)
    return {"invite_code": invite.invite_code}


@router.post("/social/invite-conversions")
def register_conversion(invite_code: str, user_id: str = Depends(get_current_user_id), db: Session = Depends(get_db)):
    invite = db.execute(select(models.Invite).where(models.Invite.invite_code == invite_code)).scalars().first()
    if invite is None:
        return {"registered": False}

    existing = db.execute(select(models.InviteConversion).where(models.InviteConversion.invited_user_id == user_id)).scalars().first()
    if existing is not None:
        return {"registered": True, "already_registered": True}

    conversion = models.InviteConversion(invite_id=invite.id, invited_user_id=user_id)
    db.add(conversion)
    db.commit()
    return {"registered": True}


@router.post("/social/achievement-card")
def generate_achievement_card(user_id: str = Depends(get_current_user_id), db: Session = Depends(get_db)):
    """
    STUB no Vertical Slice 01 — geração real de imagem (server-side vs.
    client-side) é decisão de implementação pendente (MENTAL_KICKOFF.md
    §6: "Claude Code deve propor a abordagem mais simples e de menor custo
    de manutenção antes de implementar"), fora do escopo travado para este
    slice (só os 4 tipos de desafio + loop completo). Endpoint existe para
    não quebrar o contrato, retorna os dados que alimentariam o card.
    """
    profile = db.get(models.Profile, user_id)
    return {
        "nickname": profile.nickname if profile else None,
        "xp_total": profile.xp_total if profile else 0,
        "level": profile.level if profile else 1,
        "image_url": None,
        "note": "geração de imagem não implementada no Vertical Slice 01",
    }


# V2 item 12 — Amigos (V2_KICKOFF.md §6A, aprovado 2026-08-22). Usa o
# MESMO invite_code de /social/invite-code como ponto de entrada —
# nenhuma tela nova de convite. Deliberadamente NÃO reaproveita
# InviteConversion (1 atribuição por usuário, pensado pra métrica de
# crescimento) — grava em mental.friendships, N:N de verdade.
@router.post("/social/friends")
def add_friend(
    body: schemas.AddFriendRequest,
    user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    invite = db.execute(select(models.Invite).where(models.Invite.invite_code == body.invite_code)).scalars().first()
    if invite is None:
        raise HTTPException(status_code=404, detail={"error": {"code": "INVITE_NOT_FOUND", "message": "Código de convite não encontrado."}})
    if invite.inviter_user_id == user_id:
        raise HTTPException(status_code=400, detail={"error": {"code": "CANNOT_FRIEND_SELF", "message": "Não é possível adicionar a si mesmo como amigo."}})

    services.add_friendship(db, user_id, invite.inviter_user_id)
    return {"status": "ok"}


@router.get("/social/friends", response_model=schemas.FriendsResponse)
def list_friends(user_id: str = Depends(get_current_user_id), db: Session = Depends(get_db)):
    friend_ids = services.get_friend_user_ids(db, user_id)
    friends = []
    for friend_id in friend_ids:
        profile = db.get(models.Profile, friend_id)
        if profile is None:
            continue
        friends.append(schemas.FriendOut(user_id=friend_id, nickname=profile.nickname, avatar_id=profile.avatar_id, xp_total=profile.xp_total, level=profile.level))
    return schemas.FriendsResponse(friends=friends)


# Pedido de Rhoney (2026-08-22): compartilhar uma conquista (nível,
# território, mundo, badge, meta de passos) rende XP. Backend é a única
# autoridade — client nunca calcula nem decide o valor, só avisa "um
# compartilhamento aconteceu". Teto de 1 recompensa/dia (services.
# award_share_reward) é a defesa contra farm, já que o app não confirma
# conclusão real do compartilhamento no SO.
@router.post("/social/share-reward", response_model=schemas.ShareRewardResponse)
def reward_share(user_id: str = Depends(get_current_user_id), db: Session = Depends(get_db)):
    profile = db.get(models.Profile, user_id)
    if profile is None:
        raise HTTPException(status_code=404, detail={"error": {"code": "PROFILE_NOT_FOUND", "message": "Perfil não encontrado."}})

    xp_awarded, already_rewarded_today = services.award_share_reward(db, profile)
    return schemas.ShareRewardResponse(
        xp_awarded=xp_awarded,
        already_rewarded_today=already_rewarded_today,
        xp_total=profile.xp_total,
        level=profile.level,
    )
