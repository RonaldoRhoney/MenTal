"""
MENTAL_FLUXO_GUEST_3_QUESTOES_DIAGNOSTICO_TECNICO_V1.md (aprovado por
Rhoney 07/10/2026) — fluxo de 3 questões de qualquer Mundo antes do
cadastro/login, substituindo a regra antiga ("completar um desafio
inteiro antes do login"), que por sua vez nunca chegou a ser
implementada: hoje o login é a PRIMEIRA barreira do app, antes mesmo de
qualquer desafio aparecer.

Risco central que molda este desenho (ver §2 do diagnóstico): mesmo sem
conta, a resposta certa nunca pode ir pro cliente antes de ele responder
— "sem login" aqui significa "sem exigir token de usuário autenticado"
nestes 2 endpoints específicos, nunca "sem backend". E o XP provisório
nunca é um número que o cliente manda de volta: o cliente guarda só os
dados brutos das 3 respostas, e /guest/migrate-progress REPROCESSA cada
uma de verdade pelo mesmo caminho de POST /challenges/{id}/answer,
sujeito ao mesmo teto diário — fecha a brecha de forjar XP alto no
cliente.
"""

import random

from fastapi import APIRouter, Depends, HTTPException, Request
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.orm import Session

from .. import config, models, schemas, scoring, services
from ..auth import get_current_user_id
from ..db import get_db
from .challenges import submit_answer as _submit_answer

router = APIRouter(prefix="/guest", tags=["guest"])


def _client_ip(request: Request) -> str:
    # Sem proxy/load balancer com X-Forwarded-For confiável conhecido
    # neste projeto hoje (Render expõe o IP real em request.client.host)
    # — mesma simplicidade já aceita pelo rate limiter em memória de
    # services.enforce_rate_limit (ver comentário lá: zero-cost, por
    # processo único).
    return request.client.host if request.client else "unknown"


class GuestWorldOut(BaseModel):
    world_id: str
    world_name: str
    territory_id: str


@router.get("/worlds", response_model=list[GuestWorldOut])
def list_guest_worlds(request: Request, db: Session = Depends(get_db)):
    services.enforce_rate_limit("guest_worlds", _client_ip(request), max_calls=config.RATE_LIMIT_GUEST[0], window_seconds=config.RATE_LIMIT_GUEST[1])

    worlds = db.execute(select(models.World).order_by(models.World.display_order)).scalars().all()
    out: list[GuestWorldOut] = []
    for world in worlds:
        first_territory = db.execute(
            select(models.Territory)
            .where(models.Territory.world_id == world.id)
            .order_by(models.Territory.display_order)
            .limit(1)
        ).scalar_one_or_none()
        if first_territory is None:
            continue
        out.append(GuestWorldOut(world_id=world.id, world_name=world.name, territory_id=first_territory.id))
    return out


@router.get("/challenges/next", response_model=schemas.ChallengeOut)
def guest_next_challenge(request: Request, territory_id: str, db: Session = Depends(get_db)):
    services.enforce_rate_limit("guest_challenges_next", _client_ip(request), max_calls=config.RATE_LIMIT_GUEST[0], window_seconds=config.RATE_LIMIT_GUEST[1])

    territory = db.get(models.Territory, territory_id)
    if territory is None:
        raise HTTPException(status_code=404, detail={"error": {"code": "TERRITORY_NOT_FOUND", "message": territory_id}})

    # Só território que é a PRIMEIRA etapa de algum Mundo (menor
    # display_order dentre os territórios daquele world_id) pode ser
    # jogado sem conta — fecha a rota pra não virar um jeito de pular a
    # trava sequencial normal em territórios avançados/Relâmpago.
    first_territory_id = db.execute(
        select(models.Territory.id)
        .where(models.Territory.world_id == territory.world_id)
        .order_by(models.Territory.display_order)
        .limit(1)
    ).scalar_one_or_none()
    if territory.world_id is None or territory_id != first_territory_id:
        raise HTTPException(status_code=403, detail={"error": {"code": "TERRITORY_NOT_ALLOWED_FOR_GUEST", "message": territory_id}})

    candidates = (
        db.execute(
            select(models.Challenge)
            .where(models.Challenge.territory_id == territory_id)
            .where(models.Challenge.language_code == config.DEFAULT_LANGUAGE_CODE)
            .where(models.Challenge.difficulty_level == 1)
        )
        .scalars()
        .all()
    )
    if not candidates:
        raise HTTPException(status_code=404, detail={"error": {"code": "NO_CHALLENGES_AVAILABLE", "message": territory_id}})

    # Sem fila/estado persistido (diferente de GET /challenges/next):
    # guest não tem user_id de verdade pra atrelar ChallengeBatchProgress,
    # e são só 3 perguntas descartáveis — um sorteio simples já evita
    # repetição óbvia sem precisar de infraestrutura nova.
    challenge = random.choice(candidates)
    options = services.shuffled_options(challenge.options) if challenge.options else challenge.options
    hints_available = len(
        db.execute(select(models.ChallengeHint).where(models.ChallengeHint.challenge_id == challenge.id)).scalars().all()
    )

    return schemas.ChallengeOut(
        challenge_id=challenge.id,
        attempt_id=None,
        territory_id=challenge.territory_id,
        difficulty_level=challenge.difficulty_level,
        prompt=challenge.prompt,
        options=options,
        hints_available=hints_available,
        time_limit_seconds=None,
        prompt_image=challenge.prompt_image,
        clues=challenge.clues,
        audio_url=challenge.audio_url,
        audio_source_name=challenge.audio_source_name,
        audio_source_url=challenge.audio_source_url,
        audio_script=challenge.audio_script,
        vocab_media_url=challenge.vocab_media_url,
        vocab_media_type=challenge.vocab_media_type,
        vocab_media_source_name=challenge.vocab_media_source_name,
        vocab_media_source_url=challenge.vocab_media_source_url,
        reading_passage=challenge.reading_passage,
        is_new=False,
    )


class GuestAnswerRequest(BaseModel):
    submitted_answer: str = Field(max_length=300)


class GuestAnswerResponse(BaseModel):
    is_correct: bool
    correct_answer: str
    explanation: str
    xp_preview: int


@router.post("/challenges/{challenge_id}/answer", response_model=GuestAnswerResponse)
def guest_submit_answer(challenge_id: str, body: GuestAnswerRequest, request: Request, db: Session = Depends(get_db)):
    services.enforce_rate_limit("guest_challenges_answer", _client_ip(request), max_calls=config.RATE_LIMIT_GUEST[0], window_seconds=config.RATE_LIMIT_GUEST[1])

    challenge = db.get(models.Challenge, challenge_id)
    if challenge is None:
        raise HTTPException(status_code=404, detail={"error": {"code": "CHALLENGE_NOT_FOUND", "message": challenge_id}})

    # Território de guest nunca é cronometrado (só "primeira etapa",
    # nunca Relâmpago) — timed_out sempre False aqui, igual o resto do
    # app faz pra território não-cronometrado.
    is_correct = services.is_submitted_answer_correct(challenge, body.submitted_answer, timed_out=False)
    xp_preview = scoring.xp_base_for(challenge.difficulty_level) if is_correct else 0

    return GuestAnswerResponse(
        is_correct=is_correct,
        correct_answer=challenge.correct_answer,
        explanation=challenge.explanation,
        xp_preview=xp_preview,
    )


class GuestMigrateAnswer(BaseModel):
    challenge_id: str
    submitted_answer: str = Field(max_length=300)


class GuestMigrateRequest(BaseModel):
    answers: list[GuestMigrateAnswer] = Field(max_length=3)


class GuestMigrateResponse(BaseModel):
    xp_awarded_total: int


@router.post("/migrate-progress", response_model=GuestMigrateResponse)
def migrate_guest_progress(
    body: GuestMigrateRequest,
    user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    xp_awarded_total = 0
    for item in body.answers:
        challenge = db.get(models.Challenge, item.challenge_id)
        if challenge is None:
            continue

        # Idempotência (diagnóstico §3.2): se este user_id já tem
        # qualquer Attempt respondido pra este challenge_id, a migração
        # já rodou antes (retry de rede, duplo-toque) — pula sem
        # duplicar XP.
        already_migrated = db.execute(
            select(models.Attempt.attempt_id)
            .where(models.Attempt.user_id == user_id)
            .where(models.Attempt.challenge_id == item.challenge_id)
            .where(models.Attempt.is_correct.is_not(None))
            .limit(1)
        ).scalar_one_or_none()
        if already_migrated is not None:
            continue

        attempt_id = models.new_uuid()
        services.create_served_attempt(db, attempt_id, user_id, item.challenge_id, timed=False)
        # Reaproveita a MESMA função do fluxo normal (POST /challenges/
        # {id}/answer) — nunca uma segunda implementação da regra de XP/
        # streak/badge/conquista de território, pro guest virar uma
        # réplica real da experiência normal, sujeita ao mesmo teto
        # diário (economy.apply_answer_xp), não a um atalho.
        answer_out = _submit_answer(
            item.challenge_id,
            schemas.AnswerRequest(attempt_id=attempt_id, submitted_answer=item.submitted_answer, timed_out=False),
            user_id,
            db,
        )
        xp_awarded_total += answer_out.xp_awarded

    return GuestMigrateResponse(xp_awarded_total=xp_awarded_total)
