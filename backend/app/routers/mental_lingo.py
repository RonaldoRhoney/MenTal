"""
MENTAL LINGO — assistente de voz do Mundo dos Idiomas (aprovado por
Rhoney, 23/09/2026, escopo V1 100% custo zero — ver app/mental_lingo.py).
Só leitura: nunca grava XP/MentalCoins/ranking, conforme o próprio
documento de especificação (§Qualidade pedagógica: "não conceder
XP/ranking nesta fase").
"""

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from .. import config, mental_lingo, schemas, services
from ..auth import require_age_confirmed_user_id
from ..db import get_db

router = APIRouter()


@router.post("/mental-lingo/ask", response_model=schemas.MentalLingoAskOut)
def ask_mental_lingo(
    body: schemas.MentalLingoAskRequest,
    user_id: str = Depends(require_age_confirmed_user_id),
    db: Session = Depends(get_db),
):
    services.enforce_rate_limit(
        "mental_lingo", user_id,
        max_calls=config.RATE_LIMIT_MENTAL_LINGO[0],
        window_seconds=config.RATE_LIMIT_MENTAL_LINGO[1],
    )
    return schemas.MentalLingoAskOut(**mental_lingo.answer_question(db, body.question))


@router.post("/mental-lingo/feedback")
def mental_lingo_feedback(
    body: schemas.MentalLingoFeedbackRequest,
    user_id: str = Depends(require_age_confirmed_user_id),
    db: Session = Depends(get_db),
):
    """Voto de utilidade numa resposta de fonte aberta — só contador agregado
    (prioriza a revisão de Rhoney), sem guardar quem votou."""
    services.enforce_rate_limit(
        "mental_lingo", user_id,
        max_calls=config.RATE_LIMIT_MENTAL_LINGO[0],
        window_seconds=config.RATE_LIMIT_MENTAL_LINGO[1],
    )
    return {"ok": mental_lingo.vote(db, body.word, body.target_language, body.useful)}
