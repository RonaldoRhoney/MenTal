from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from .. import models, schemas
from ..auth import get_current_user_id
from ..db import get_db
from ..nickname import generate_anonymous_nickname

router = APIRouter()


@router.post("/age-gate", response_model=schemas.AgeGateResponse)
def submit_age_gate(
    body: schemas.AgeGateRequest,
    user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    if body.age_mode not in ("child", "adult"):
        raise HTTPException(status_code=422, detail={"error": {"code": "INVALID_AGE_MODE", "message": "age_mode must be 'child' or 'adult'"}})

    profile = db.get(models.Profile, user_id)
    if profile is None:
        profile = models.Profile(user_id=user_id, nickname=generate_anonymous_nickname())
        db.add(profile)

    profile.age_mode = body.age_mode
    profile.child_safe_mode = body.age_mode != "adult"

    # Regra: nickname livre só é permitido para age_mode == "adult".
    # Para child/unknown, nickname é sempre gerado pelo sistema.
    if profile.child_safe_mode and not profile.nickname_is_system_generated:
        profile.nickname = generate_anonymous_nickname()
        profile.nickname_is_system_generated = True
    elif profile.nickname_is_system_generated is None:
        profile.nickname_is_system_generated = True

    db.commit()
    db.refresh(profile)

    return schemas.AgeGateResponse(child_safe_mode=profile.child_safe_mode, nickname=profile.nickname)
