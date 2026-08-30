import random

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from .. import config, models, schemas, scoring, services
from ..auth import require_age_confirmed_user_id
from ..db import get_db
from ..timeutil import utcnow

router = APIRouter()


@router.get("/word-puzzles/next", response_model=schemas.WordPuzzleOut)
def next_word_puzzle(
    territory_id: str,
    language_code: str = config.DEFAULT_LANGUAGE_CODE,
    user_id: str = Depends(require_age_confirmed_user_id),
    db: Session = Depends(get_db),
):
    """
    V3.3 §6 (Jogos de Palavras — Fase 1: Caça-palavras). Endpoint
    próprio, separado de /challenges/next: a grade inteira já vem
    resolvida (nenhuma opção escondida pra proteger, diferente de MCQ) —
    resultado da própria natureza do jogo, não uma escolha de segurança.
    """
    territory = db.get(models.Territory, territory_id)
    if territory is None:
        raise HTTPException(status_code=404, detail={"error": {"code": "TERRITORY_NOT_FOUND", "message": territory_id}})
    if not services.is_territory_unlocked(db, user_id, territory):
        raise HTTPException(status_code=403, detail={"error": {"code": "TERRITORY_LOCKED", "message": "Requires active subscription"}})

    difficulty = services.pick_difficulty_for(db, user_id, territory_id)
    candidates = (
        db.execute(
            select(models.WordPuzzle)
            .where(models.WordPuzzle.territory_id == territory_id)
            .where(models.WordPuzzle.language_code == language_code)
            .where(models.WordPuzzle.difficulty_level == difficulty)
        )
        .scalars()
        .all()
    ) or (
        db.execute(
            select(models.WordPuzzle)
            .where(models.WordPuzzle.territory_id == territory_id)
            .where(models.WordPuzzle.language_code == language_code)
        )
        .scalars()
        .all()
    )
    if not candidates:
        raise HTTPException(status_code=404, detail={"error": {"code": "NO_WORD_PUZZLES_AVAILABLE", "message": territory_id}})

    puzzle = random.choice(candidates)

    result = models.WordPuzzleResult(user_id=user_id, word_puzzle_id=puzzle.id, started_at=utcnow())
    db.add(result)
    db.commit()
    db.refresh(result)

    return schemas.WordPuzzleOut(
        result_id=result.id,
        puzzle_id=puzzle.id,
        territory_id=puzzle.territory_id,
        difficulty_level=puzzle.difficulty_level,
        theme=puzzle.theme,
        grid_size=puzzle.grid_size,
        grid=puzzle.grid,
        words=puzzle.words,
    )


@router.post("/word-puzzles/{result_id}/complete", response_model=schemas.WordPuzzleCompleteResponse)
def complete_word_puzzle(
    result_id: str,
    body: schemas.WordPuzzleCompleteRequest,
    user_id: str = Depends(require_age_confirmed_user_id),
    db: Session = Depends(get_db),
):
    """
    Autoridade de XP/tempo 100% no backend (mesma regra de todo o app):
    tempo decorrido é sempre (agora - started_at), nunca um valor vindo
    do client; XP só é creditado na PRIMEIRA conclusão deste puzzle por
    este usuário (achado real reaproveitado de LearningPause — "não deve
    ser atalho de XP fácil" se o mesmo puzzle reaparecer no sorteio).
    """
    result = db.get(models.WordPuzzleResult, result_id)
    if result is None or result.user_id != user_id:
        raise HTTPException(status_code=404, detail={"error": {"code": "WORD_PUZZLE_RESULT_NOT_FOUND", "message": result_id}})

    puzzle = db.get(models.WordPuzzle, result.word_puzzle_id)
    if puzzle is None:
        raise HTTPException(status_code=404, detail={"error": {"code": "WORD_PUZZLE_NOT_FOUND", "message": result.word_puzzle_id}})

    if result.completed_at is not None:
        # Idempotência: reenvio do mesmo result_id devolve o resultado já
        # calculado, nunca recalcula XP nem duplica progresso.
        return schemas.WordPuzzleCompleteResponse(
            xp_awarded=result.xp_awarded or 0,
            speed_bonus_xp=0,
            already_completed_before=True,
        )

    found_upper = {w.strip().upper() for w in body.found_words}
    missing = [w for w in puzzle.words if w not in found_upper]
    if missing:
        raise HTTPException(status_code=400, detail={"error": {"code": "WORDS_MISSING", "message": ", ".join(missing)}})

    already_completed_before = (
        db.execute(
            select(models.WordPuzzleResult)
            .where(models.WordPuzzleResult.user_id == user_id)
            .where(models.WordPuzzleResult.word_puzzle_id == puzzle.id)
            .where(models.WordPuzzleResult.completed_at.is_not(None))
        )
        .scalars()
        .first()
        is not None
    )

    elapsed_ms = services.elapsed_ms_since(result.started_at)
    elapsed_seconds = elapsed_ms / 1000

    xp_awarded = 0
    speed_bonus_xp = 0
    if not already_completed_before:
        base_xp = scoring.xp_base_for(puzzle.difficulty_level)
        fast_threshold = config.WORD_PUZZLE_FAST_COMPLETION_SECONDS.get(puzzle.difficulty_level)
        if fast_threshold is not None and elapsed_seconds <= fast_threshold:
            speed_bonus_xp = round(base_xp * config.WORD_PUZZLE_SPEED_BONUS_MULTIPLIER)
        xp_awarded = base_xp + speed_bonus_xp

        profile = services.get_or_create_profile(db, user_id)
        profile.xp_total += xp_awarded
        profile.level = scoring.level_from_xp(profile.xp_total)

    result.completed_at = utcnow()
    result.elapsed_ms = elapsed_ms
    result.xp_awarded = xp_awarded
    db.commit()

    return schemas.WordPuzzleCompleteResponse(
        xp_awarded=xp_awarded,
        speed_bonus_xp=speed_bonus_xp,
        already_completed_before=already_completed_before,
    )
