from datetime import datetime, timedelta

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from .. import models, schemas, services
from ..auth import get_current_user_id
from ..db import get_db

router = APIRouter()


@router.get("/subscription/status", response_model=schemas.SubscriptionStatusResponse)
def get_status(user_id: str = Depends(get_current_user_id), db: Session = Depends(get_db)):
    sub = db.get(models.Subscription, user_id)
    if sub is None:
        return schemas.SubscriptionStatusResponse(status="none", expires_at=None)
    return schemas.SubscriptionStatusResponse(status=sub.status, expires_at=sub.expires_at.isoformat() if sub.expires_at else None)


@router.post("/subscription/parental-gate")
def pass_parental_gate(user_id: str = Depends(get_current_user_id), db: Session = Depends(get_db)):
    profile = services.get_or_create_profile(db, user_id)
    profile.parental_gate_passed_at = datetime.utcnow()
    db.commit()
    return {"parental_gate_passed": True}


@router.post("/subscription/validate-receipt", response_model=schemas.SubscriptionStatusResponse)
def validate_receipt(
    body: schemas.ValidateReceiptRequest,
    user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    """
    STUB — fora de escopo do Vertical Slice 01 (MENTAL_KICKOFF.md §10:
    "não implementar ainda... integração real com Google Play Billing").
    Este endpoint existe para satisfazer o contrato de API_CONTRACT.md §6 e
    permitir testar o fluxo de desbloqueio fim a fim, mas NÃO valida um
    recibo real do Google Play — apenas simula o resultado a partir de um
    purchase_token fixo de teste. Antes de qualquer build de release, este
    endpoint precisa ser substituído pela chamada real à API server-side
    do Google Play (SECURITY.md §4).
    """
    profile = db.get(models.Profile, user_id)
    if profile is None or profile.parental_gate_passed_at is None:
        raise HTTPException(status_code=403, detail={"error": {"code": "PARENTAL_GATE_REQUIRED", "message": "Call /subscription/parental-gate first"}})

    if body.purchase_token != "TEST_TOKEN_VALID":
        raise HTTPException(status_code=422, detail={"error": {"code": "INVALID_RECEIPT", "message": "Stub only accepts TEST_TOKEN_VALID in V1"}})

    sub = db.get(models.Subscription, user_id)
    if sub is None:
        sub = models.Subscription(user_id=user_id)
        db.add(sub)

    if sub.google_play_purchase_token == body.purchase_token and sub.status == "active":
        # Proteção contra replay: mesmo token já processado não reativa/estende de novo.
        db.commit()
        return schemas.SubscriptionStatusResponse(status=sub.status, expires_at=sub.expires_at.isoformat() if sub.expires_at else None)

    sub.google_play_purchase_token = body.purchase_token
    sub.status = "active"
    sub.validated_at = datetime.utcnow()
    sub.expires_at = datetime.utcnow() + timedelta(days=30)
    db.commit()
    db.refresh(sub)

    return schemas.SubscriptionStatusResponse(status=sub.status, expires_at=sub.expires_at.isoformat())
