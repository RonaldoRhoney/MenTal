from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from .. import config, models, schemas
from ..auth import get_current_user_id
from ..db import get_db
from ..nickname import generate_anonymous_nickname
from ..timeutil import utcnow

router = APIRouter()


@router.post("/age-gate", response_model=schemas.AgeGateResponse)
def submit_age_gate(
    body: schemas.AgeGateRequest,
    user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    # MENTAL-DIR-001/POL-002 (24/08/2026): sem confirmação, nenhum dado é
    # coletado e nenhum perfil é criado/alterado — "não deve restar
    # nenhum caminho de código... que trate um usuário como menor de
    # idade" (DIR-001 §1). O client trata este 403 exibindo a tela de
    # encerramento cordial (POL-002 §3.2), nunca avançando pro app.
    if not body.age_confirmed:
        raise HTTPException(
            status_code=403,
            detail={"error": {"code": "MAJORITY_NOT_CONFIRMED", "message": "Age confirmation is required to use MENTAL"}},
        )

    profile = db.get(models.Profile, user_id)
    if profile is None:
        profile = models.Profile(user_id=user_id, nickname=generate_anonymous_nickname())
        db.add(profile)

    profile.age_confirmed_at = utcnow()
    profile.terms_version_accepted = config.TERMS_VERSION
    if profile.nickname_is_system_generated is None:
        profile.nickname_is_system_generated = True

    db.commit()
    db.refresh(profile)

    return schemas.AgeGateResponse(
        nickname=profile.nickname,
        age_confirmed_at=profile.age_confirmed_at,
        terms_version_accepted=profile.terms_version_accepted,
    )
