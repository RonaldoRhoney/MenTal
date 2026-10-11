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

C1 (fechado de verdade, 10/10/2026): o risco residual documentado
abaixo até esta correção — repetir GET /next sem limite pra "garimpar"
o deck inteiro de um território liberado pra guest — é fechado sem
precisar de um banco de conteúdo exclusivo de preview (mudança de
produto maior, adiada): o fluxo sempre foi desenhado pra NO MÁXIMO 3
perguntas por visita (GuestChallengeService.maxQuestions no client),
só que o servidor nunca impunha isso. Agora impõe: no máximo
GUEST_MAX_DISTINCT_CHALLENGES challenge_ids DIFERENTES por (IP,
território) dentro de GUEST_DISTINCT_WINDOW_SECONDS — depois disso,
/next só torna a servir um dos já vistos (nunca um challenge_id novo
daquele território), então o "deck" exposto por IP fica permanentemente
limitado a esse punhado pequeno, nunca o território inteiro.
"""

import hashlib
import hmac
import json
import random
import time
from base64 import urlsafe_b64decode, urlsafe_b64encode
from collections import defaultdict

from fastapi import APIRouter, Depends, HTTPException, Request
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.orm import Session

from .. import config, models, schemas, scoring, services
from ..auth import require_age_confirmed_user_id
from ..db import get_db
from ..timeutil import brasilia_today
from .challenges import submit_answer as _submit_answer
from .par_perfeito import credit_match_if_new as _credit_par_perfeito_match_if_new

router = APIRouter(prefix="/guest", tags=["guest"])

# C1 (10/10/2026) — ver nota no topo do arquivo. Mesmo padrão em memória
# já aceito por services._rate_limit_hits (zero-custo, processo único no
# Render); a lista se auto-poda a cada chamada (entradas fora da janela
# saem), então o único resíduo de memória é a CHAVE (ip:território) em
# si — mesma característica já aceita e documentada (M2) pro rate
# limiter genérico, não resolvida aqui de novo por ser um achado à parte.
_guest_served_challenge_ids: dict[str, list[tuple[str, float]]] = defaultdict(list)


def _pick_challenge_for_guest(candidates: list[models.Challenge], ip: str, territory_id: str) -> models.Challenge:
    key = f"{ip}:{territory_id}"
    now = time.monotonic()
    cutoff = now - config.GUEST_DISTINCT_WINDOW_SECONDS
    seen = _guest_served_challenge_ids[key]
    while seen and seen[0][1] < cutoff:
        seen.pop(0)
    seen_ids = {challenge_id for challenge_id, _ in seen}
    already_seen_candidates = [c for c in candidates if c.id in seen_ids]
    if len(seen_ids) >= config.GUEST_MAX_DISTINCT_CHALLENGES and already_seen_candidates:
        return random.choice(already_seen_candidates)
    challenge = random.choice(candidates)
    seen.append((challenge.id, now))
    return challenge


# Achado de auditoria de segurança (mental-security, 10/10/2026): GET
# /guest/par-perfeito/round sorteava livre entre TODOS os itens do
# território em toda chamada, sem o mesmo teto de ids DISTINTOS por
# (IP, território) que _pick_challenge_for_guest já impõe pro quiz —
# reabria a forma do achado C1 (território inteiro "garimpável" num
# IP só, só que sem oráculo de resposta certa pra proteger aqui, já
# que o formato nunca escondeu resposta). Mesmo padrão de memória/
# janela, generalizado pra devolver ROUND_SIZE itens por chamada em
# vez de 1: enquanto o IP não tiver visto GUEST_MAX_DISTINCT_CHALLENGES
# itens diferentes daquele território, cada rodada completa o que
# falta com itens novos; depois disso, toda rodada sorteia só dentre
# os já vistos — nunca mais o território inteiro.
_guest_served_par_perfeito_item_ids: dict[str, list[tuple[str, float]]] = defaultdict(list)


def _pick_par_perfeito_items_for_guest(
    candidates: list[models.ParPerfeitoItem], ip: str, territory_id: str, round_size: int
) -> list[models.ParPerfeitoItem]:
    key = f"pp:{ip}:{territory_id}"
    now = time.monotonic()
    cutoff = now - config.GUEST_DISTINCT_WINDOW_SECONDS
    seen = _guest_served_par_perfeito_item_ids[key]
    while seen and seen[0][1] < cutoff:
        seen.pop(0)
    seen_ids = {item_id for item_id, _ in seen}
    by_id = {c.id: c for c in candidates}

    if len(seen_ids) >= config.GUEST_MAX_DISTINCT_CHALLENGES:
        pool = [by_id[i] for i in seen_ids if i in by_id]
        return random.sample(pool, k=min(round_size, len(pool)))

    room = config.GUEST_MAX_DISTINCT_CHALLENGES - len(seen_ids)
    unseen = [c for c in candidates if c.id not in seen_ids]
    new_items = random.sample(unseen, k=min(room, round_size, len(unseen))) if unseen else []
    for item in new_items:
        seen.append((item.id, now))

    remaining = round_size - len(new_items)
    if remaining > 0:
        new_ids = {item.id for item in new_items}
        fill_pool = [by_id[i] for i in (seen_ids | new_ids) if i in by_id and i not in new_ids]
        new_items += random.sample(fill_pool, k=min(remaining, len(fill_pool))) if fill_pool else []
    return new_items


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
    # Pedido de Rhoney (10/10/2026): o Mundo dos Idiomas passou a abrir
    # no jogo Par Perfeito (pareamento de cards), não no quiz de
    # múltipla escolha — o client precisa saber qual tela abrir.
    # "quiz" é o default/único valor pra todo mundo que não tiver essa
    # regra especial (nunca inferido do nome do território).
    game_type: str = "quiz"


@router.get("/worlds", response_model=list[GuestWorldOut])
def list_guest_worlds(request: Request, db: Session = Depends(get_db)):
    services.enforce_rate_limit("guest_worlds", _client_ip(request), max_calls=config.RATE_LIMIT_GUEST[0], window_seconds=config.RATE_LIMIT_GUEST[1])

    worlds = db.execute(select(models.World).order_by(models.World.display_order)).scalars().all()
    out: list[GuestWorldOut] = []
    for world in worlds:
        # Pedido de Rhoney (10/10/2026): no Mundo dos Idiomas, os 3
        # primeiros desafios sem login são Par Perfeito de Inglês
        # básico, não o território de menor display_order (hoje
        # Libras). Território fixo (config.GUEST_PAR_PERFEITO_
        # TERRITORY_ID), nunca inferido — mesma allow-list usada por
        # _is_guest_allowed_par_perfeito_territory abaixo.
        if world.id == "idiomas":
            out.append(GuestWorldOut(
                world_id=world.id,
                world_name=world.name,
                territory_id=config.GUEST_PAR_PERFEITO_TERRITORY_ID,
                game_type="par_perfeito",
            ))
            continue

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


def _is_guest_allowed_par_perfeito_territory(territory_id: str) -> bool:
    """
    Allow-list de UM território só, deliberadamente hardcoded (ver
    config.GUEST_PAR_PERFEITO_TERRITORY_ID) — nunca "qualquer território
    de Par Perfeito", mesmo espírito restritivo de
    _is_guest_allowed_territory pro quiz.
    """
    return territory_id == config.GUEST_PAR_PERFEITO_TERRITORY_ID


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
    challenge = _pick_challenge_for_guest(candidates, _client_ip(request), territory_id)
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


class GuestParPerfeitoRoundOut(BaseModel):
    territory_id: str
    difficulty_level: int
    items: list[schemas.ParPerfeitoItemOut]
    # Prova de que o servidor serviu ESTES item_ids juntos, nesta
    # rodada — exigido por POST /guest/migrate-progress antes de
    # creditar XP real, mesmo raciocínio do achado A2 (ver
    # par_perfeito.py: GET /round sempre precisa registrar o que
    # sorteou, nunca confiar no que o client diz ter formado).
    round_token: str


@router.get("/par-perfeito/round", response_model=GuestParPerfeitoRoundOut)
def guest_next_par_perfeito_round(request: Request, db: Session = Depends(get_db)):
    services.enforce_rate_limit("guest_par_perfeito_round", _client_ip(request), max_calls=config.RATE_LIMIT_GUEST[0], window_seconds=config.RATE_LIMIT_GUEST[1])

    territory_id = config.GUEST_PAR_PERFEITO_TERRITORY_ID
    candidates = (
        db.execute(
            select(models.ParPerfeitoItem)
            .where(models.ParPerfeitoItem.territory_id == territory_id)
            .where(models.ParPerfeitoItem.difficulty_level == 1)
        )
        .scalars()
        .all()
    )
    if not candidates:
        raise HTTPException(status_code=404, detail={"error": {"code": "NO_PAR_PERFEITO_ITEMS_AVAILABLE", "message": territory_id}})

    chosen = _pick_par_perfeito_items_for_guest(
        candidates, _client_ip(request), territory_id, config.GUEST_PAR_PERFEITO_ROUND_SIZE
    )
    round_token = _sign({
        "round_item_ids": [item.id for item in chosen],
        "territory_id": territory_id,
        "exp": time.time() + config.GUEST_RECEIPT_TTL_SECONDS,
    })

    return GuestParPerfeitoRoundOut(
        territory_id=territory_id,
        difficulty_level=chosen[0].difficulty_level,
        items=[schemas.ParPerfeitoItemOut(id=item.id, word_en=item.word_en, meaning_pt=item.meaning_pt) for item in chosen],
        round_token=round_token,
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


class GuestMigrateParPerfeito(BaseModel):
    # Emitido por GET /guest/par-perfeito/round — prova que ESTES
    # item_ids foram servidos juntos, como uma rodada real (mesmo
    # raciocínio do achado A2 em par_perfeito.py).
    round_token: str
    # Pares que o visitante formou sem nenhum erro antes, só reportado
    # aqui no fim (mesmo contrato de POST /par-perfeito/complete-round
    # autenticado) — teto = GUEST_PAR_PERFEITO_ROUND_SIZE, nunca mais
    # que uma rodada guest inteira.
    item_ids: list[str] = Field(max_length=config.GUEST_PAR_PERFEITO_ROUND_SIZE)


class GuestMigrateRequest(BaseModel):
    answers: list[GuestMigrateAnswer] = Field(default_factory=list, max_length=3)
    par_perfeito: GuestMigrateParPerfeito | None = None


class GuestMigrateResponse(BaseModel):
    xp_awarded_total: int


@router.post("/migrate-progress", response_model=GuestMigrateResponse)
def migrate_guest_progress(
    body: GuestMigrateRequest,
    user_id: str = Depends(require_age_confirmed_user_id),
    db: Session = Depends(get_db),
):
    services.enforce_rate_limit(
        "guest_migrate_progress", user_id, max_calls=config.RATE_LIMIT_GUEST_MIGRATE[0], window_seconds=config.RATE_LIMIT_GUEST_MIGRATE[1]
    )

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

    if body.par_perfeito is not None:
        round_payload = _verify(body.par_perfeito.round_token)
        territory_id = config.GUEST_PAR_PERFEITO_TERRITORY_ID
        territory = db.get(models.Territory, territory_id)
        if (
            round_payload is not None
            and round_payload.get("territory_id") == territory_id
            and _is_guest_allowed_par_perfeito_territory(territory_id)
            and territory is not None
            and services.is_territory_unlocked(db, user_id, territory)
        ):
            # Mesma defesa do achado A2: só credita item_id que estava
            # DENTRO desta rodada servida — nunca a soma de várias
            # chamadas de GET /round nunca realmente jogadas.
            allowed_item_ids = set(round_payload.get("round_item_ids") or [])
            today = brasilia_today()
            for item_id in body.par_perfeito.item_ids:
                if item_id not in allowed_item_ids:
                    continue
                xp_awarded_total += _credit_par_perfeito_match_if_new(db, user_id, item_id, territory_id, today)

    return GuestMigrateResponse(xp_awarded_total=xp_awarded_total)

# C1 fechado (10/10/2026, ver nota no topo do arquivo): até esta
# correção, GET /guest/challenges/next + POST /guest/.../answer
# revelavam correct_answer de conteúdo real das 16 primeiras etapas de
# Mundo pra quem repetisse a chamada o suficiente, mitigado só pelo
# rate limit genérico (chamadas/minuto, não challenge_ids DIFERENTES
# vistos). _pick_challenge_for_guest agora limita a no máximo
# GUEST_MAX_DISTINCT_CHALLENGES challenge_ids diferentes por (IP,
# território) — exatamente o tamanho do preview que o fluxo sempre
# pretendeu mostrar (3 perguntas, GuestChallengeService.maxQuestions),
# nunca mais o território inteiro. Uma solução com banco de conteúdo
# EXCLUSIVO de preview guest (nunca compartilhado com o conteúdo real)
# continua sendo a opção mais forte caso o produto evolua, mas deixou
# de ser necessária pra fechar o risco original.
