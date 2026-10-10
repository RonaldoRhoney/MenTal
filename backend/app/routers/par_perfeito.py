import random

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from .. import config, economy, models, schemas, scoring, services
from ..auth import require_age_confirmed_user_id
from ..db import get_db
from ..timeutil import brasilia_today

router = APIRouter()

# MUNDO_IDIOMAS_INGLES_PAR_PERFEITO_V1.md §3 — "Rodada: 4 a 6 pares ou
# perguntas, rápida".
_ROUND_SIZE = 5


@router.get("/par-perfeito/round", response_model=schemas.ParPerfeitoRoundOut)
def next_par_perfeito_round(
    territory_id: str,
    user_id: str = Depends(require_age_confirmed_user_id),
    db: Session = Depends(get_db),
):
    """
    Endpoint próprio, separado de /challenges/next, mesmo raciocínio de
    /word-puzzles/next: a rodada inteira já vem visível (sem resposta
    escondida pra proteger — o desafio do jogo é lembrar o par, não
    adivinhar entre alternativas). Sem fila/estado persistido por
    usuário (diferente de GET /challenges/next): sorteio simples a cada
    chamada, mesma simplificação já aceita em /guest/challenges/next
    pelo mesmo motivo (jogo de baixo risco, poucos itens por rodada).
    """
    territory = db.get(models.Territory, territory_id)
    if territory is None:
        raise HTTPException(status_code=404, detail={"error": {"code": "TERRITORY_NOT_FOUND", "message": territory_id}})
    if not services.is_territory_unlocked(db, user_id, territory):
        raise HTTPException(status_code=403, detail={"error": {"code": "TERRITORY_LOCKED", "message": "Requires active subscription"}})

    difficulty = services.pick_difficulty_for(db, user_id, territory_id)
    candidates = (
        db.execute(
            select(models.ParPerfeitoItem)
            .where(models.ParPerfeitoItem.territory_id == territory_id)
            .where(models.ParPerfeitoItem.difficulty_level == difficulty)
        )
        .scalars()
        .all()
    ) or (
        db.execute(select(models.ParPerfeitoItem).where(models.ParPerfeitoItem.territory_id == territory_id))
        .scalars()
        .all()
    )
    if not candidates:
        raise HTTPException(status_code=404, detail={"error": {"code": "NO_PAR_PERFEITO_ITEMS_AVAILABLE", "message": territory_id}})

    chosen = random.sample(candidates, k=min(_ROUND_SIZE, len(candidates)))
    # Achado A2 de auditoria de segurança (09/10/2026, migration 123):
    # registra a rodada sorteada — POST /complete-round só vai aceitar
    # item_ids que estejam DENTRO desta rodada, nunca a soma de várias
    # chamadas de GET /round sem nunca ter jogado nenhuma de verdade.
    db.add(models.ParPerfeitoRound(user_id=user_id, territory_id=territory_id, item_ids=[item.id for item in chosen]))
    db.commit()
    return schemas.ParPerfeitoRoundOut(
        territory_id=territory_id,
        difficulty_level=chosen[0].difficulty_level,
        items=[schemas.ParPerfeitoItemOut(id=item.id, word_en=item.word_en, meaning_pt=item.meaning_pt) for item in chosen],
    )


@router.post("/par-perfeito/complete-round", response_model=schemas.ParPerfeitoCompleteRoundResponse)
def complete_par_perfeito_round(
    body: schemas.ParPerfeitoCompleteRoundRequest,
    user_id: str = Depends(require_age_confirmed_user_id),
    db: Session = Depends(get_db),
):
    """
    REGRA_OFICIAL proposta em MUNDO_IDIOMAS_INGLES_PAR_PERFEITO_V1.md §10
    (aceita): só o acerto na PRIMEIRA tentativa gera XP. O client forma
    os pares e dá feedback 100% local (sem resposta escondida a
    proteger, ver GET /par-perfeito/round) — só reporta aqui, no fim da
    rodada, os item_ids que formou sem nenhum erro antes. O servidor é a
    autoridade de XP: confere idempotência por (user_id, item_id) antes
    de aplicar, e todo crédito passa por economy.apply_answer_xp, o
    MESMO teto diário de qualquer resposta de Challenge — nenhum valor
    novo é criado, só a mesma fórmula (scoring.xp_base_for) reaplicada
    por item.
    """
    services.enforce_rate_limit("par_perfeito_complete_round", user_id, max_calls=config.RATE_LIMIT_PAR_PERFEITO_COMPLETE[0], window_seconds=config.RATE_LIMIT_PAR_PERFEITO_COMPLETE[1])

    territory = db.get(models.Territory, body.territory_id)
    if territory is None:
        raise HTTPException(status_code=404, detail={"error": {"code": "TERRITORY_NOT_FOUND", "message": body.territory_id}})
    if not services.is_territory_unlocked(db, user_id, territory):
        raise HTTPException(status_code=403, detail={"error": {"code": "TERRITORY_LOCKED", "message": "Requires active subscription"}})

    # Achado A2 (09/10/2026, migration 123): só aceita item_ids que
    # estejam DENTRO da rodada mais recente registrada por GET /round
    # pra este (user_id, territory_id) — fecha o harvesting de ids
    # somados de várias rodadas nunca realmente jogadas.
    latest_round = db.execute(
        select(models.ParPerfeitoRound)
        .where(models.ParPerfeitoRound.user_id == user_id)
        .where(models.ParPerfeitoRound.territory_id == body.territory_id)
        .order_by(models.ParPerfeitoRound.issued_at.desc())
        .limit(1)
    ).scalar_one_or_none()
    allowed_item_ids = set(latest_round.item_ids) if latest_round is not None else set()

    today = brasilia_today()
    xp_awarded_total = 0
    for item_id in body.item_ids:
        if item_id not in allowed_item_ids:
            continue
        item = db.get(models.ParPerfeitoItem, item_id)
        if item is None or item.territory_id != body.territory_id:
            continue

        already_awarded = (
            db.execute(
                select(models.ParPerfeitoMatch.id)
                .where(models.ParPerfeitoMatch.user_id == user_id)
                .where(models.ParPerfeitoMatch.item_id == item_id)
                .limit(1)
            ).scalar_one_or_none()
            is not None
        )
        if already_awarded:
            continue

        base_xp = scoring.xp_base_for(item.difficulty_level)
        profile = services.get_or_create_profile(db, user_id, for_update=True)
        db.refresh(profile, with_for_update=True)
        answer_xp = economy.apply_answer_xp(db, user_id, base_xp, today)
        profile.xp_total += answer_xp.profile_xp
        profile.level = scoring.level_from_xp(profile.xp_total)
        # Achado de qualidade de código (09/10/2026): o Match era
        # inserido DEPOIS do commit do XP — uma corrida (crash entre os
        # dois commits) podia deixar o XP creditado sem o registro que
        # prova idempotência, abrindo brecha pra crédito duplo num
        # reenvio. Agora os dois commitam juntos, atomicamente.
        db.add(models.ParPerfeitoMatch(user_id=user_id, item_id=item_id, xp_awarded=answer_xp.profile_xp))
        db.commit()
        services.apply_xp_to_territory(db, user_id, body.territory_id, answer_xp.territory_xp)
        xp_awarded_total += answer_xp.profile_xp

    return schemas.ParPerfeitoCompleteRoundResponse(xp_awarded_total=xp_awarded_total)
