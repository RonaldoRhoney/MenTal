from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from .. import schemas, services
from ..auth import require_age_confirmed_user_id
from ..db import get_db

router = APIRouter()


@router.get("/stats", response_model=schemas.StatsResponse)
def get_stats(user_id: str = Depends(require_age_confirmed_user_id), db: Session = Depends(get_db)):
    return schemas.StatsResponse(**services.compute_stats(db, user_id))
