import random

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from .. import config, models, schemas, scoring, services
from ..auth import require_age_confirmed_user_id
from ..db import get_db
from ..timeutil import utcnow

router = APIRouter()


@router.get("/learning-pauses/next", response_model=schemas.LearningPauseOut)
def next_learning_pause(
    territory_id: str,
    language_code: str = config.DEFAULT_LANGUAGE_CODE,
    user_id: str = Depends(require_age_confirmed_user_id),
    db: Session = Depends(get_db),
):
    """
    V3.2 (V3/V3.2_TECNOLOGIA.md §3) — endpoint SEPARADO de GET
    /challenges/next de propósito: Pausa para Aprender é uma estrutura
    de conteúdo nova (sem options/correct_answer/timer), acessada como
    uma ação alternativa dentro do território (mesmo espírito do botão
    Relâmpago), nunca uma interrupção aleatória do fluxo normal de
    desafios — decisão de arquitetura tomada aqui porque o documento
    delega isso a Claude Code (§4) e deixa a frequência de aparição como
    escolha de curadoria (§3.4): quanto mais Pausas curadas existirem
    pra um território, mais variedade aparece nesse acesso dedicado.
    """
    territory = db.get(models.Territory, territory_id)
    if territory is None:
        raise HTTPException(status_code=404, detail={"error": {"code": "TERRITORY_NOT_FOUND", "message": territory_id}})
    if not services.is_territory_unlocked(db, user_id, territory):
        raise HTTPException(status_code=403, detail={"error": {"code": "TERRITORY_LOCKED", "message": "Requires active subscription"}})

    candidates = (
        db.execute(
            select(models.LearningPause)
            .where(models.LearningPause.territory_id == territory_id)
            .where(models.LearningPause.language_code == language_code)
        )
        .scalars()
        .all()
    )
    if not candidates:
        raise HTTPException(status_code=404, detail={"error": {"code": "NO_LEARNING_PAUSES_AVAILABLE", "message": territory_id}})

    pause = random.choice(candidates)

    # Achado de auditoria de segurança M2 (05/09/2026): registra que
    # este usuário recebeu esta Pausa agora — /complete exige este
    # registro e um tempo mínimo decorrido antes de conceder XP.
    serve = db.get(models.LearningPauseServe, (user_id, pause.id))
    if serve is None:
        db.add(models.LearningPauseServe(user_id=user_id, learning_pause_id=pause.id))
    else:
        serve.served_at = utcnow()
    db.commit()

    return schemas.LearningPauseOut(
        learning_pause_id=pause.id,
        territory_id=pause.territory_id,
        difficulty_level=pause.difficulty_level,
        text=pause.text,
        prompt_image=pause.prompt_image,
        video_url=pause.video_url,
        source_name=pause.source_name,
        source_url=pause.source_url,
    )


@router.post("/learning-pauses/{learning_pause_id}/complete", response_model=schemas.LearningPauseCompleteResponse)
def complete_learning_pause(
    learning_pause_id: str,
    user_id: str = Depends(require_age_confirmed_user_id),
    db: Session = Depends(get_db),
):
    """
    V3.2 §3.4: "concede uma quantidade pequena e FIXA de XP... não deve
    ser um atalho de XP fácil" — só credita na PRIMEIRA leitura
    concluída desta Pausa por este usuário; reler depois não paga de
    novo (mas nunca bloqueia a releitura em si). Nunca afeta estatística
    de acerto/erro — não é avaliação, é leitura (§3.3).
    """
    services.enforce_rate_limit("learning_pauses_complete", user_id, max_calls=config.RATE_LIMIT_LEARNING_PAUSE_COMPLETE[0], window_seconds=config.RATE_LIMIT_LEARNING_PAUSE_COMPLETE[1])

    pause = db.get(models.LearningPause, learning_pause_id)
    if pause is None:
        raise HTTPException(status_code=404, detail={"error": {"code": "LEARNING_PAUSE_NOT_FOUND", "message": learning_pause_id}})

    # Achado de auditoria de segurança M2 (05/09/2026): sem esta
    # checagem, /complete concedia XP sem nenhuma prova de que a Pausa
    # foi de fato aberta — exige ter passado por GET /next e um tempo
    # mínimo plausível de leitura desde então.
    serve = db.get(models.LearningPauseServe, (user_id, learning_pause_id))
    if serve is None or services.elapsed_ms_since(serve.served_at) < config.LEARNING_PAUSE_MIN_READ_SECONDS * 1000:
        raise HTTPException(
            status_code=400,
            detail={"error": {"code": "COMPLETION_TOO_FAST", "message": "Tempo de leitura implausível."}},
        )

    already_read = (
        db.execute(
            select(models.LearningPauseRead)
            .where(models.LearningPauseRead.user_id == user_id)
            .where(models.LearningPauseRead.learning_pause_id == learning_pause_id)
        )
        .scalars()
        .first()
        is not None
    )

    xp_awarded = 0
    if not already_read:
        db.add(models.LearningPauseRead(user_id=user_id, learning_pause_id=learning_pause_id, read_at=utcnow()))
        profile = services.get_or_create_profile(db, user_id)
        xp_awarded = config.LEARNING_PAUSE_XP_REWARD
        profile.xp_total += xp_awarded
        profile.level = scoring.level_from_xp(profile.xp_total)

    db.commit()
    return schemas.LearningPauseCompleteResponse(xp_awarded=xp_awarded, already_read_before=already_read)
