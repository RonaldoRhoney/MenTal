from datetime import date, datetime

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from .. import config, models, schemas, scoring, services
from ..auth import get_current_user_id
from ..db import get_db

router = APIRouter()


def _pick_difficulty_for(db: Session, user_id: str, territory_id: str) -> int:
    """
    Dificuldade adaptativa (ADAPTIVE_DIFFICULTY.md): olha a taxa de acerto
    da janela recente de desafios respondidos pelo jogador naquele
    território. Sobe 1 nível após acerto >= limiar de subida, desce 1
    nível após acerto < limiar de descida, mantém caso contrário. Janela e
    limiares são decisão do Vertical Slice 01 (ADAPTIVE_DIFFICULTY.md §6
    deixava a fórmula em aberto) — centralizados em config.py para ajuste
    num único lugar quando houver dado real de uso.
    """
    recent = (
        db.execute(
            select(models.Attempt)
            .join(models.Challenge, models.Attempt.challenge_id == models.Challenge.id)
            .where(models.Attempt.user_id == user_id)
            .where(models.Challenge.territory_id == territory_id)
            .where(models.Attempt.is_correct.is_not(None))
            .order_by(models.Attempt.created_at.desc())
            .limit(config.ADAPTIVE_DIFFICULTY_WINDOW)
        )
        .scalars()
        .all()
    )

    current_level = config.ADAPTIVE_DIFFICULTY_MIN_LEVEL
    if recent:
        last_challenge = db.get(models.Challenge, recent[0].challenge_id)
        current_level = last_challenge.difficulty_level if last_challenge else current_level

    if len(recent) >= config.ADAPTIVE_DIFFICULTY_MIN_SAMPLE:
        accuracy = sum(1 for a in recent if a.is_correct) / len(recent)
        if accuracy >= config.ADAPTIVE_DIFFICULTY_UP_THRESHOLD:
            current_level += 1
        elif accuracy < config.ADAPTIVE_DIFFICULTY_DOWN_THRESHOLD:
            current_level -= 1

    return max(config.ADAPTIVE_DIFFICULTY_MIN_LEVEL, min(config.ADAPTIVE_DIFFICULTY_MAX_LEVEL, current_level))


@router.get("/challenges/next", response_model=schemas.ChallengeOut)
def next_challenge(
    territory_id: str,
    language_code: str = config.DEFAULT_LANGUAGE_CODE,
    user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    territory = db.get(models.Territory, territory_id)
    if territory is None:
        raise HTTPException(status_code=404, detail={"error": {"code": "TERRITORY_NOT_FOUND", "message": territory_id}})

    services.get_or_create_profile(db, user_id)

    if not services.is_territory_unlocked(db, user_id, territory):
        raise HTTPException(status_code=403, detail={"error": {"code": "TERRITORY_LOCKED", "message": "Requires active subscription"}})

    today = date.today()
    allowed, consumed = services.check_daily_limit(db, user_id, today)
    if not allowed:
        raise HTTPException(
            status_code=429,
            detail={"error": {"code": "DAILY_LIMIT_REACHED", "message": "Daily free challenge limit reached", "resets_at": str(today.isoformat())}},
        )

    difficulty = _pick_difficulty_for(db, user_id, territory_id)

    # ARCHITECTURE_UPDATE_I18N_READY.md §3: endpoint já aceita/filtra por
    # idioma, mesmo com um único valor possível hoje (pt-BR) — critério de
    # aceite é que popular language_code diferente no futuro não exija
    # mudança de código aqui.
    candidates = (
        db.execute(
            select(models.Challenge)
            .where(models.Challenge.territory_id == territory_id)
            .where(models.Challenge.language_code == language_code)
            .where(models.Challenge.difficulty_level == difficulty)
        )
        .scalars()
        .all()
    ) or (
        db.execute(
            select(models.Challenge)
            .where(models.Challenge.territory_id == territory_id)
            .where(models.Challenge.language_code == language_code)
        )
        .scalars()
        .all()
    )

    if not candidates:
        raise HTTPException(status_code=404, detail={"error": {"code": "NO_CHALLENGES_AVAILABLE", "message": territory_id}})

    import random

    # Achado testando no celular real: com poucos candidatos por nível de
    # dificuldade (2-3 no seed atual), random.choice puro repete o mesmo
    # desafio imediatamente com chance alta (~50% com 2 candidatos) —
    # rodou 20x seguidas em teste manual e saiu sequência de 5 iguais.
    # Não é falta de embaralhamento no cliente, é ausência de "não repetir
    # o último" no sorteio do backend. Exclui o último desafio já servido
    # pra esse usuário+território (via Attempt mais recente), mas só
    # quando sobra pelo menos 1 outro candidato — nunca bloqueia o único
    # desafio existente.
    last_challenge_id = db.execute(
        select(models.Attempt.challenge_id)
        .join(models.Challenge, models.Attempt.challenge_id == models.Challenge.id)
        .where(models.Attempt.user_id == user_id)
        .where(models.Challenge.territory_id == territory_id)
        .order_by(models.Attempt.created_at.desc())
        .limit(1)
    ).scalar_one_or_none()

    if last_challenge_id is not None and len(candidates) > 1:
        narrowed = [c for c in candidates if c.id != last_challenge_id]
        if narrowed:
            candidates = narrowed

    challenge = random.choice(candidates)
    hints_available = len(
        db.execute(select(models.ChallengeHint).where(models.ChallengeHint.challenge_id == challenge.id)).scalars().all()
    )

    return schemas.ChallengeOut(
        challenge_id=challenge.id,
        territory_id=challenge.territory_id,
        difficulty_level=challenge.difficulty_level,
        prompt=challenge.prompt,
        options=challenge.options,
        hints_available=hints_available,
    )


def _get_or_create_pending_attempt(db: Session, attempt_id: str, user_id: str, challenge_id: str) -> models.Attempt:
    attempt = db.get(models.Attempt, attempt_id)
    if attempt is not None:
        return attempt
    try:
        attempt = models.Attempt(attempt_id=attempt_id, user_id=user_id, challenge_id=challenge_id, hints_used=0)
        db.add(attempt)
        db.commit()
        db.refresh(attempt)
        return attempt
    except IntegrityError:
        # Corrida: outra requisição concorrente já criou a mesma attempt_id.
        db.rollback()
        return db.get(models.Attempt, attempt_id)


@router.post("/challenges/{challenge_id}/hint", response_model=schemas.HintResponse)
def request_hint(
    challenge_id: str,
    body: schemas.HintRequest,
    user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    challenge = db.get(models.Challenge, challenge_id)
    if challenge is None:
        raise HTTPException(status_code=404, detail={"error": {"code": "CHALLENGE_NOT_FOUND", "message": challenge_id}})

    attempt = _get_or_create_pending_attempt(db, body.attempt_id, user_id, challenge_id)

    if attempt.is_correct is not None:
        raise HTTPException(status_code=409, detail={"error": {"code": "ATTEMPT_ALREADY_ANSWERED", "message": "Cannot request hint after answering"}})

    hints = (
        db.execute(
            select(models.ChallengeHint)
            .where(models.ChallengeHint.challenge_id == challenge_id)
            .order_by(models.ChallengeHint.hint_level)
        )
        .scalars()
        .all()
    )

    next_level = attempt.hints_used + 1
    hint = next((h for h in hints if h.hint_level == next_level), None)
    if hint is None:
        raise HTTPException(status_code=404, detail={"error": {"code": "NO_MORE_HINTS", "message": "No hint available at this level"}})

    attempt.hints_used = next_level
    db.commit()

    return schemas.HintResponse(hint_level=hint.hint_level, content=hint.content)


@router.post("/challenges/{challenge_id}/answer", response_model=schemas.AnswerResponse)
def submit_answer(
    challenge_id: str,
    body: schemas.AnswerRequest,
    user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    challenge = db.get(models.Challenge, challenge_id)
    if challenge is None:
        raise HTTPException(status_code=404, detail={"error": {"code": "CHALLENGE_NOT_FOUND", "message": challenge_id}})

    attempt = _get_or_create_pending_attempt(db, body.attempt_id, user_id, challenge_id)

    if attempt.is_correct is not None:
        # Idempotência: reenvio do mesmo attempt_id retorna o resultado já
        # calculado, nunca recalcula XP nem duplica progresso.
        territory_progress = db.get(models.UserTerritoryProgress, (user_id, challenge.territory_id))
        streak = services.get_or_create_streak(db, user_id)
        return schemas.AnswerResponse(
            is_correct=attempt.is_correct,
            correct_answer=challenge.correct_answer,
            explanation=challenge.explanation,
            xp_base=attempt.xp_base or 0,
            hints_used=attempt.hints_used,
            xp_awarded=attempt.xp_awarded or 0,
            streak=schemas.StreakOut(current_streak=streak.current_streak, freeze_available=streak.freeze_available),
            territory_progress=schemas.TerritoryProgressOut(
                xp_in_territory=territory_progress.xp_in_territory if territory_progress else 0,
                conquered=bool(territory_progress and territory_progress.conquered_at),
            ),
        )

    is_correct = body.submitted_answer.strip().lower() == challenge.correct_answer.strip().lower()
    xp_base = scoring.xp_base_for(challenge.difficulty_level) if is_correct else 0
    xp_final = scoring.xp_awarded(xp_base, attempt.hints_used) if is_correct else 0

    attempt.submitted_answer = body.submitted_answer
    attempt.is_correct = is_correct
    attempt.xp_base = xp_base
    attempt.xp_awarded = xp_final
    db.commit()

    profile = services.get_or_create_profile(db, user_id)
    territory_progress = None
    if is_correct and xp_final > 0:
        profile.xp_total += xp_final
        profile.level = scoring.level_from_xp(profile.xp_total)
        db.commit()
        territory_progress = services.apply_xp_to_territory(db, user_id, challenge.territory_id, xp_final)
    else:
        territory_progress = db.get(models.UserTerritoryProgress, (user_id, challenge.territory_id))

    services.register_daily_usage(db, user_id, date.today())
    streak = services.register_play_for_streak(db, user_id, date.today())

    return schemas.AnswerResponse(
        is_correct=is_correct,
        correct_answer=challenge.correct_answer,
        explanation=challenge.explanation,
        xp_base=xp_base,
        hints_used=attempt.hints_used,
        xp_awarded=xp_final,
        streak=schemas.StreakOut(current_streak=streak.current_streak, freeze_available=streak.freeze_available),
        territory_progress=schemas.TerritoryProgressOut(
            xp_in_territory=territory_progress.xp_in_territory if territory_progress else 0,
            conquered=bool(territory_progress and territory_progress.conquered_at),
        ),
    )
