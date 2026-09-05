from datetime import timedelta

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from .. import config, models, schemas
from ..auth import require_age_confirmed_user_id
from ..db import get_db
from ..timeutil import utcnow

router = APIRouter()


@router.get("/subscription/status", response_model=schemas.SubscriptionStatusResponse)
def get_status(user_id: str = Depends(require_age_confirmed_user_id), db: Session = Depends(get_db)):
    sub = db.get(models.Subscription, user_id)
    if sub is None:
        return schemas.SubscriptionStatusResponse(status="none", expires_at=None)
    return schemas.SubscriptionStatusResponse(status=sub.status, expires_at=sub.expires_at.isoformat() if sub.expires_at else None)


@router.post("/subscription/validate-receipt", response_model=schemas.SubscriptionStatusResponse)
def validate_receipt(
    body: schemas.ValidateReceiptRequest,
    user_id: str = Depends(require_age_confirmed_user_id),
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

    Achado de auditoria de qualidade B3 (05/09/2026): a "porta de pais"
    que existia aqui (POST /subscription/parental-gate + checagem de
    validade de janela) foi removida — fazia sentido quando o app podia
    incluir menores; desde DIR-001 (MENTAL exclusivo 18+), não há mais
    cenário de uso real pra esse fluxo.
    """
    # Achado de auditoria de segurança (28/08/2026): o token fixo de teste
    # sempre funcionou, mesmo em produção — hoje é inofensivo porque
    # MONETIZATION_ENABLED=false neutraliza is_territory_unlocked, mas já
    # dava pra contornar o limite diário de desafios (check_daily_limit
    # confere Subscription.status=="active"). Reaproveita a mesma flag de
    # DEV_INSECURE (config.ALLOW_DEV_INSECURE_AUTH) — mesma categoria de
    # atalho "só pra desenvolvimento", nunca deveria estar disponível sem
    # opt-in explícita.
    if not config.ALLOW_DEV_INSECURE_AUTH:
        raise HTTPException(status_code=501, detail={"error": {"code": "NOT_IMPLEMENTED", "message": "Real Google Play receipt validation not implemented yet"}})

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
    sub.validated_at = utcnow()
    sub.expires_at = utcnow() + timedelta(days=30)
    db.commit()
    db.refresh(sub)

    return schemas.SubscriptionStatusResponse(status=sub.status, expires_at=sub.expires_at.isoformat())
