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

ACHADOS CRÍTICOS de auditoria de segurança pré-AAB (09/10/2026),
corrigidos nesta versão:

C1 (parcial — risco residual documentado, ver nota no fim do arquivo):
POST /guest/challenges/{id}/answer aceitava QUALQUER challenge_id
existente no banco (inclusive de território pago/avançado) e devolvia
correct_answer de graça, sem exigir conta — um oráculo gratuito de
resposta certa. Corrigido: (a) só território "primeira etapa de algum
Mundo" é aceito (_is_guest_allowed_territory); (b) o endpoint agora
exige um `serve_token` assinado pelo servidor, emitido só por GET
/guest/challenges/next — fecha a sondagem de challenge_id arbitrário
não servido antes.

C2 (fechado): POST /guest/migrate-progress criava Attempt e creditava
XP/progresso de território REAL pra qualquer challenge_id+
submitted_answer que o cliente mandasse, sem nenhuma prova de que
aquela resposta passou pelo fluxo guest de verdade — dava pra fabricar
XP e "desbloquear" território pago sem nunca ter jogado. Corrigido: o
endpoint agora exige um `completion_token` assinado, emitido só por
POST /guest/challenges/{id}/answer, provando que aquele
(challenge_id, submitted_answer) exato foi processado de verdade pelo
fluxo guest antes de ser migrado.

A4 (fechado): migrate-progress usava get_current_user_id (sem exigir
maioridade confirmada) e era chamado pelo client ANTES da tela de
idade — uma conta que nunca confirmou 18+ podia acumular Attempt/XP
reais. Agora exige require_age_confirmed_user_id; client (main.dart)
passou a chamar isto só depois do Age Gate.
"""

import hashlib
import hmac
import json
import random
import time
from base64 import urlsafe_b64decode, urlsafe_b64encode

from fastapi import APIRouter, Depends, HTTPException, Request
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.orm import Session

from .. import config, models, schemas, scoring, services
from ..auth import require_age_confirmed_user_id
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


def _is_guest_allowed_territory(db: Session, territory_id: str) -> bool:
    """
    Só território que é a PRIMEIRA etapa de algum Mundo (menor
    display_order dentre os territórios daquele world_id) pode ser
    jogado sem conta — fecha a rota pra não virar um jeito de pular a
    trava sequencial normal em territórios avançados/Relâmpago/pagos.
    """
    territory = db.get(models.Territory, territory_id)
    if territory is None or territory.world_id is None:
        return False
    first_territory_id = db.execute(
        select(models.Territory.id)
        .where(models.Territory.world_id == territory.world_id)
        .order_by(models.Territory.display_order)
        .limit(1)
    ).scalar_one_or_none()
    return territory_id == first_territory_id


def _sign(payload: dict) -> str:
    """
    Recibo assinado HMAC-SHA256 — propósito único: provar que um passo
    do fluxo guest (servir um desafio, ou gradear uma resposta) realmente
    aconteceu no servidor, sem precisar de sessão/estado persistido (o
    fluxo guest é deliberadamente stateless). NUNCA usado como prova de
    identidade de usuário — só de integridade de conteúdo de preview
    público. `exp` sempre incluso pelo chamador.
    """
    payload_json = json.dumps(payload, separators=(",", ":"), sort_keys=True)
    payload_b64 = urlsafe_b64encode(payload_json.encode()).decode()
    sig = hmac.new(config.GUEST_RECEIPT_SECRET.encode(), payload_b64.encode(), hashlib.sha256).hexdigest()
    return f"{payload_b64}.{sig}"


def _verify(token: str) -> dict | None:
    try:
        payload_b64, sig = token.rsplit(".", 1)
    except ValueError:
        return None
    expected_sig = hmac.new(config.GUEST_RECEIPT_SECRET.encode(), payload_b64.encode(), hashlib.sha256).hexdigest()
    if not hmac.compare_digest(sig, expected_sig):
        return None
    try:
        payload = json.loads(urlsafe_b64decode(payload_b64.encode()).decode())
    except Exception:
        return None
    if payload.get("exp", 0) < time.time():
        return None
    return payload


def _hash_answer(text: str) -> str:
    return hashlib.sha256(text.encode()).hexdigest()


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

    if not _is_guest_allowed_territory(db, territory_id):
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

    serve_token = _sign({"challenge_id": challenge.id, "exp": time.time() + config.GUEST_RECEIPT_TTL_SECONDS})

    return schemas.ChallengeOut(
        challenge_id=challenge.id,
        attempt_id=None,
        serve_token=serve_token,
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
    # Emitido por GET /guest/challenges/next — prova que o servidor
    # realmente serviu ESTE challenge_id antes de gradear a resposta.
    serve_token: str


class GuestAnswerResponse(BaseModel):
    is_correct: bool
    correct_answer: str
    explanation: str
    xp_preview: int
    # Prova de que este (challenge_id, submitted_answer) foi gradeado de
    # verdade aqui — exigido por POST /guest/migrate-progress.
    completion_token: str


@router.post("/challenges/{challenge_id}/answer", response_model=GuestAnswerResponse)
def guest_submit_answer(challenge_id: str, body: GuestAnswerRequest, request: Request, db: Session = Depends(get_db)):
    services.enforce_rate_limit("guest_challenges_answer", _client_ip(request), max_calls=config.RATE_LIMIT_GUEST[0], window_seconds=config.RATE_LIMIT_GUEST[1])

    serve_payload = _verify(body.serve_token)
    if serve_payload is None or serve_payload.get("challenge_id") != challenge_id:
        raise HTTPException(status_code=403, detail={"error": {"code": "INVALID_SERVE_TOKEN", "message": "Desafio não foi servido por este fluxo."}})

    challenge = db.get(models.Challenge, challenge_id)
    if challenge is None:
        raise HTTPException(status_code=404, detail={"error": {"code": "CHALLENGE_NOT_FOUND", "message": challenge_id}})
    if not _is_guest_allowed_territory(db, challenge.territory_id):
        raise HTTPException(status_code=403, detail={"error": {"code": "TERRITORY_NOT_ALLOWED_FOR_GUEST", "message": challenge.territory_id}})

    # Território de guest nunca é cronometrado (só "primeira etapa",
    # nunca Relâmpago) — timed_out sempre False aqui, igual o resto do
    # app faz pra território não-cronometrado.
    is_correct = services.is_submitted_answer_correct(challenge, body.submitted_answer, timed_out=False)
    xp_preview = scoring.xp_base_for(challenge.difficulty_level) if is_correct else 0

    completion_token = _sign({
        "challenge_id": challenge_id,
        "answer_hash": _hash_answer(body.submitted_answer),
        "exp": time.time() + config.GUEST_RECEIPT_TTL_SECONDS,
    })

    return GuestAnswerResponse(
        is_correct=is_correct,
        correct_answer=challenge.correct_answer,
        explanation=challenge.explanation,
        xp_preview=xp_preview,
        completion_token=completion_token,
    )


class GuestMigrateAnswer(BaseModel):
    challenge_id: str
    submitted_answer: str = Field(max_length=300)
    completion_token: str


class GuestMigrateRequest(BaseModel):
    answers: list[GuestMigrateAnswer] = Field(max_length=3)


class GuestMigrateResponse(BaseModel):
    xp_awarded_total: int


@router.post("/migrate-progress", response_model=GuestMigrateResponse)
def migrate_guest_progress(
    body: GuestMigrateRequest,
    user_id: str = Depends(require_age_confirmed_user_id),
    db: Session = Depends(get_db),
):
    xp_awarded_total = 0
    for item in body.answers:
        # Prova de que ESTE (challenge_id, submitted_answer) foi
        # realmente processado por POST /guest/challenges/{id}/answer —
        # sem isso, qualquer par challenge_id+submitted_answer "correto"
        # (descoberto por fora, ex. via o próprio endpoint de resposta)
        # virava XP e progresso de território reais sem nunca ter
        # passado pelo fluxo guest de verdade.
        completion_payload = _verify(item.completion_token)
        if completion_payload is None:
            continue
        if completion_payload.get("challenge_id") != item.challenge_id:
            continue
        if completion_payload.get("answer_hash") != _hash_answer(item.submitted_answer):
            continue

        challenge = db.get(models.Challenge, item.challenge_id)
        if challenge is None:
            continue
        if not _is_guest_allowed_territory(db, challenge.territory_id):
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

# Risco residual documentado (C1, auditoria 09/10/2026): GET /guest/
# challenges/next + POST /guest/.../answer ainda revelam correct_answer
# de conteúdo real das 16 primeiras etapas de Mundo (as mesmas usadas
# por jogadores autenticados) pra quem repetir a chamada o suficiente —
# isso é inerente a mostrar conteúdo real num preview público sem exigir
# conta, decisão de produto já tomada no documento original (§2 do
# diagnóstico: "mesmo sem conta, a resposta certa nunca pode ir pro
# cliente antes de ele responder" — mas DEPOIS de responder, sempre
# mostra, de propósito, pra servir de aprendizado). O serve_token acima
# fecha a sondagem de challenge_id ARBITRÁRIO (não servido antes), mas
# não impede alguém de chamar /next repetidas vezes pra colecionar
# respostas dos itens de preview — mitigado hoje só pelo rate limit
# (RATE_LIMIT_GUEST). Se Rhoney quiser fechar esse resíduo por completo,
# a solução correta é um banco de conteúdo EXCLUSIVO de preview guest,
# nunca compartilhado com o conteúdo real jogado por usuário autenticado
# — mudança de produto/conteúdo, não só de código, fora do escopo desta
# correção.
