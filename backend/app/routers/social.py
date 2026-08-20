import secrets

from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.orm import Session

from .. import models
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
