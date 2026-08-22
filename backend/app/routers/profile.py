"""
Perfil do usuário (USER_PROFILE.md, aprovado). Todos os campos aqui são
opcionais — nenhum bloqueia ou degrada o uso do app se não preenchidos
(§1 do documento). real_name nunca aparece em nenhum outro endpoint
(FriendOut/RankingEntry/BattleOut) — só o próprio dono vê o próprio
nome real, via GET /profile.
"""

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from .. import models, schemas, services
from ..auth import get_current_user_id
from ..db import get_db

router = APIRouter()


@router.get("/profile", response_model=schemas.ProfileOut)
def get_profile(user_id: str = Depends(get_current_user_id), db: Session = Depends(get_db)):
    profile = services.get_or_create_profile(db, user_id)
    return schemas.ProfileOut(
        nickname=profile.nickname,
        avatar_id=profile.avatar_id,
        real_name=profile.real_name,
        location_state=profile.location_state,
        location_country=profile.location_country,
        location_public=profile.location_public,
    )


@router.put("/profile", response_model=schemas.ProfileOut)
def update_profile(
    body: schemas.UpdateProfileRequest,
    user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    profile = services.get_or_create_profile(db, user_id)
    profile.avatar_id = body.avatar_id
    profile.real_name = body.real_name
    profile.location_state = body.location_state
    profile.location_country = body.location_country
    # Preencher ≠ exibir automaticamente (§4 do documento) — location_public
    # é um campo opcional DENTRO do opcional, sempre explícito do usuário.
    profile.location_public = body.location_public
    db.commit()
    return schemas.ProfileOut(
        nickname=profile.nickname,
        avatar_id=profile.avatar_id,
        real_name=profile.real_name,
        location_state=profile.location_state,
        location_country=profile.location_country,
        location_public=profile.location_public,
    )
