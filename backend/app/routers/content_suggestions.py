"""
Busca na Home (pedido de Rhoney, 2026-09-03): quando a busca não
encontra nada (GET /challenges/search retorna found=False), o client
oferece registrar o termo pesquisado como sugestão de conteúdo. Fica
guardado aqui pra avaliação futura de um agente de curadoria (Motor B,
V4/MENTAL_AI_AGENT_TEAM_V1.md §5.3 — ainda não implementado). Por ora,
só o admin (Rhoney) consegue ver a lista, via ADMIN_PAINEL_IN_APP_V1.md.
"""

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from .. import models, schemas, services
from ..auth import require_age_confirmed_user_id
from ..db import get_db

router = APIRouter()


@router.post("/content-suggestions", response_model=schemas.ContentSuggestionResponse)
def submit_content_suggestion(
    body: schemas.ContentSuggestionRequest,
    user_id: str = Depends(require_age_confirmed_user_id),
    db: Session = Depends(get_db),
):
    query_text = body.query_text.strip()
    if not query_text:
        raise HTTPException(status_code=422, detail={"error": {"code": "EMPTY_QUERY", "message": "query_text cannot be blank"}})

    services.register_content_suggestion(db, user_id, query_text)
    return schemas.ContentSuggestionResponse()


@router.get("/admin/content-suggestions", response_model=schemas.AdminContentSuggestionListResponse)
def list_content_suggestions(user_id: str = Depends(require_age_confirmed_user_id), db: Session = Depends(get_db)):
    services.require_admin(db, user_id)

    rows = db.execute(select(models.ContentSuggestion).order_by(models.ContentSuggestion.created_at.desc()).limit(500)).scalars().all()
    return schemas.AdminContentSuggestionListResponse(
        items=[
            schemas.AdminContentSuggestionItem(id=row.id, query_text=row.query_text, created_at=row.created_at.isoformat())
            for row in rows
        ]
    )
