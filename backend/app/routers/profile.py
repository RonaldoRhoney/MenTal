"""
Perfil do usuário (USER_PROFILE.md, aprovado; revisado 2026-08-26).
avatar_id/real_name/location_* continuam opcionais, nunca bloqueiam o
uso do app. real_name nunca aparece em nenhum outro endpoint
(FriendOut/RankingEntry/BattleOut) — só o próprio dono vê o próprio
nome real, via GET /profile.

Cadastro mínimo obrigatório (decisão de Rhoney, 2026-08-26): nome, país,
cidade, gênero e faixa etária passam a ser exigidos antes do usuário
jogar — USER_PROFILE.md §1/§3 bloqueava especificamente "cidade exata"
por risco de localizar um menor, mas essa restrição foi motivada pelo
público misto de antes da DIR-001 (MENTAL agora é exclusivo pra maiores
de 18 anos). onboarding_completed_at é marcado automaticamente aqui,
nunca pelo client, na primeira vez que os 5 campos chegam preenchidos
juntos — mesmo princípio de "backend é sempre autoridade" já usado em
todo o resto do MENTAL.
"""

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from .. import models, schemas, services
from ..auth import get_current_user_id
from ..db import get_db
from ..timeutil import utcnow

router = APIRouter()


def _profile_out(profile: models.Profile) -> schemas.ProfileOut:
    return schemas.ProfileOut(
        nickname=profile.nickname,
        avatar_id=profile.avatar_id,
        real_name=profile.real_name,
        location_state=profile.location_state,
        location_country=profile.location_country,
        location_public=profile.location_public,
        age_confirmed_at=profile.age_confirmed_at,
        city=profile.city,
        gender=profile.gender,
        age_range=profile.age_range,
        onboarding_completed_at=profile.onboarding_completed_at,
    )


@router.get("/profile", response_model=schemas.ProfileOut)
def get_profile(user_id: str = Depends(get_current_user_id), db: Session = Depends(get_db)):
    profile = services.get_or_create_profile(db, user_id)
    return _profile_out(profile)


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
    profile.city = body.city
    profile.gender = body.gender
    profile.age_range = body.age_range

    mandatory_fields = [body.real_name, body.location_country, body.city, body.gender, body.age_range]
    if profile.onboarding_completed_at is None and all(f is not None and f != "" for f in mandatory_fields):
        profile.onboarding_completed_at = utcnow()

    db.commit()
    return _profile_out(profile)
