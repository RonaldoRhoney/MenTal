"""
V2 item 14 — Batalha assíncrona (ASYNC_BATTLE.md, aprovado 2026-08-22).
A resposta em si passa pelo já existente POST /challenges/{id}/answer —
este router só cria a batalha, entrega o desafio de cada lado e lista o
estado. Nenhum cálculo de XP/acerto acontece aqui (services.
maybe_resolve_battle_side, chamado de dentro do endpoint de resposta,
cuida disso).
"""

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from .. import config, models, schemas, services
from ..auth import require_age_confirmed_user_id
from ..db import get_db
from ..timeutil import utcnow

router = APIRouter()


@router.post("/battles", response_model=schemas.CreateBattleResponse)
def create_battle(
    body: schemas.CreateBattleRequest,
    user_id: str = Depends(require_age_confirmed_user_id),
    db: Session = Depends(get_db),
):
    services.enforce_rate_limit("battles_create", user_id, max_calls=config.RATE_LIMIT_BATTLE_CREATE[0], window_seconds=config.RATE_LIMIT_BATTLE_CREATE[1])

    if body.opponent_user_id == user_id:
        raise HTTPException(status_code=400, detail={"error": {"code": "CANNOT_BATTLE_SELF", "message": "Não é possível desafiar a si mesmo."}})

    if body.opponent_user_id not in services.get_friend_user_ids(db, user_id):
        raise HTTPException(status_code=400, detail={"error": {"code": "NOT_FRIENDS", "message": "Só é possível desafiar amigos."}})

    territory = db.get(models.Territory, body.territory_id)
    if territory is None:
        raise HTTPException(status_code=404, detail={"error": {"code": "TERRITORY_NOT_FOUND", "message": body.territory_id}})

    if not (config.ADAPTIVE_DIFFICULTY_MIN_LEVEL <= body.difficulty_level <= config.ADAPTIVE_DIFFICULTY_MAX_LEVEL):
        raise HTTPException(status_code=400, detail={"error": {"code": "INVALID_DIFFICULTY_LEVEL", "message": str(body.difficulty_level)}})

    today = utcnow().date()
    if services.count_battles_sent_today(db, user_id, today) >= config.BATTLE_DAILY_SEND_LIMIT:
        raise HTTPException(
            status_code=429,
            detail={"error": {"code": "BATTLE_DAILY_LIMIT_REACHED", "message": "Daily battle send limit reached", "resets_at": str(today.isoformat())}},
        )

    battle = services.create_battle(db, user_id, body.opponent_user_id, body.territory_id, body.difficulty_level)
    if battle is None:
        raise HTTPException(status_code=404, detail={"error": {"code": "NO_CHALLENGES_AVAILABLE", "message": "Território/nível sem desafios suficientes para batalha"}})

    challenger_challenge = db.get(models.Challenge, battle.challenger_challenge_id)
    hints_available = len(
        db.execute(select(models.ChallengeHint).where(models.ChallengeHint.challenge_id == challenger_challenge.id)).scalars().all()
    )

    return schemas.CreateBattleResponse(
        battle_id=battle.id,
        challenge=schemas.ChallengeOut(
            challenge_id=challenger_challenge.id,
            attempt_id=battle.challenger_attempt_id,
            territory_id=challenger_challenge.territory_id,
            difficulty_level=challenger_challenge.difficulty_level,
            prompt=challenger_challenge.prompt,
            options=challenger_challenge.options,
            hints_available=hints_available,
            time_limit_seconds=None,
            prompt_image=challenger_challenge.prompt_image,
            clues=challenger_challenge.clues,
            audio_url=challenger_challenge.audio_url,
            audio_source_name=challenger_challenge.audio_source_name,
            audio_source_url=challenger_challenge.audio_source_url,
        ),
    )


@router.get("/battles/{battle_id}/my-challenge", response_model=schemas.ChallengeOut)
def get_my_battle_challenge(
    battle_id: str,
    user_id: str = Depends(require_age_confirmed_user_id),
    db: Session = Depends(get_db),
):
    services.enforce_rate_limit("battles_my_challenge", user_id, max_calls=config.RATE_LIMIT_BATTLE_MY_CHALLENGE[0], window_seconds=config.RATE_LIMIT_BATTLE_MY_CHALLENGE[1])

    battle = db.get(models.Battle, battle_id)
    if battle is None:
        raise HTTPException(status_code=404, detail={"error": {"code": "BATTLE_NOT_FOUND", "message": battle_id}})

    if user_id == battle.challenger_user_id:
        challenge_id = battle.challenger_challenge_id
        attempt_id = battle.challenger_attempt_id
    elif user_id == battle.opponent_user_id:
        challenge_id = battle.opponent_challenge_id
        services.get_or_serve_opponent_challenge(db, battle)
        attempt_id = battle.opponent_attempt_id
    else:
        raise HTTPException(status_code=403, detail={"error": {"code": "NOT_A_PARTICIPANT", "message": "Você não faz parte desta batalha."}})

    challenge = db.get(models.Challenge, challenge_id)
    hints_available = len(
        db.execute(select(models.ChallengeHint).where(models.ChallengeHint.challenge_id == challenge.id)).scalars().all()
    )
    return schemas.ChallengeOut(
        challenge_id=challenge.id,
        attempt_id=attempt_id,
        territory_id=challenge.territory_id,
        difficulty_level=challenge.difficulty_level,
        prompt=challenge.prompt,
        options=services.shuffled_options(challenge.options) if challenge.options else challenge.options,
        hints_available=hints_available,
        time_limit_seconds=None,
        prompt_image=challenge.prompt_image,
        clues=challenge.clues,
        audio_url=challenge.audio_url,
        audio_source_name=challenge.audio_source_name,
        audio_source_url=challenge.audio_source_url,
    )


@router.get("/battles", response_model=schemas.BattlesResponse)
def list_battles(user_id: str = Depends(require_age_confirmed_user_id), db: Session = Depends(get_db)):
    rows = db.execute(
        select(models.Battle)
        .where((models.Battle.challenger_user_id == user_id) | (models.Battle.opponent_user_id == user_id))
        .order_by(models.Battle.created_at.desc())
    ).scalars().all()

    out = []
    for battle in rows:
        is_challenger = battle.challenger_user_id == user_id
        opponent_id = battle.opponent_user_id if is_challenger else battle.challenger_user_id
        opponent_profile = db.get(models.Profile, opponent_id)
        i_answered = (battle.challenger_is_correct if is_challenger else battle.opponent_is_correct) is not None
        opponent_answered = (battle.opponent_is_correct if is_challenger else battle.challenger_is_correct) is not None

        winner = None
        win_bonus_xp = 0
        if battle.status == "resolved":
            if battle.winner_user_id is None:
                winner = "tie"
            elif battle.winner_user_id == user_id:
                winner = "me"
                win_bonus_xp = config.BATTLE_WIN_BONUS_XP
            else:
                winner = "opponent"

        out.append(
            schemas.BattleOut(
                battle_id=battle.id,
                opponent_user_id=opponent_id,
                opponent_nickname=opponent_profile.nickname if opponent_profile else "?",
                opponent_avatar_id=opponent_profile.avatar_id if opponent_profile else None,
                opponent_real_name=opponent_profile.real_name if opponent_profile else None,
                opponent_photo_url=services.public_photo_url(opponent_profile) if opponent_profile else None,
                territory_id=battle.territory_id,
                difficulty_level=battle.difficulty_level,
                role="challenger" if is_challenger else "opponent",
                status=battle.status,
                i_answered=i_answered,
                opponent_answered=opponent_answered,
                winner=winner,
                win_bonus_xp=win_bonus_xp,
            )
        )

    return schemas.BattlesResponse(battles=out)
