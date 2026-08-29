from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from .. import config, models, schemas, scoring, services
from ..auth import require_age_confirmed_user_id
from ..db import get_db
from ..timeutil import utcnow

router = APIRouter()


@router.get("/challenges/next", response_model=schemas.ChallengeOut)
def next_challenge(
    territory_id: str,
    language_code: str = config.DEFAULT_LANGUAGE_CODE,
    mode: str = "normal",
    user_id: str = Depends(require_age_confirmed_user_id),
    db: Session = Depends(get_db),
):
    # V2 item 15 — Palavras Relâmpago (PALAVRAS_RELAMPAGO.md), generalizado
    # pra todos os territórios (29/08/2026, pedido de Rhoney: "em todos os
    # módulos tem que haver um relâmpago"). Modo OPCIONAL — território
    # normal sem "mode=relampago" segue o fluxo de sempre, sem mudança.
    relampago = mode == "relampago"
    # CONHECIMENTO_EXPANSAO_GERAL.md (aprovado 2026-08-22): em
    # Conhecimento o formato com tempo é OBRIGATÓRIO e único — nunca
    # formato digitado, independente de "mode". Generaliza o mesmo
    # mecanismo do Palavras Relâmpago (mesmo componente, dois territórios).
    timed = relampago or territory_id == "conhecimento"
    territory = db.get(models.Territory, territory_id)
    if territory is None:
        raise HTTPException(status_code=404, detail={"error": {"code": "TERRITORY_NOT_FOUND", "message": territory_id}})

    services.get_or_create_profile(db, user_id)

    if not services.is_territory_unlocked(db, user_id, territory):
        raise HTTPException(status_code=403, detail={"error": {"code": "TERRITORY_LOCKED", "message": "Requires active subscription"}})

    # utcnow().date(), não date.today(): Attempt.created_at é
    # gravado em UTC (utcnow() em toda a base) — usar a data
    # LOCAL do servidor aqui desalinha o "dia" do limite diário/streak do
    # "dia" em que as tentativas foram de fato registradas. Achado real
    # implementando Estatísticas (item 5): a "sequência mais longa"
    # (derivada de Attempt.created_at) aparecia MENOR que a "sequência
    # atual" (Streak.current_streak, calculada com date.today() local) —
    # logicamente impossível, já que a atual é sempre parte da mais longa.
    today = utcnow().date()
    allowed, consumed = services.check_daily_limit(db, user_id, today)
    if not allowed:
        raise HTTPException(
            status_code=429,
            detail={"error": {"code": "DAILY_LIMIT_REACHED", "message": "Daily free challenge limit reached", "resets_at": str(today.isoformat())}},
        )

    difficulty = services.pick_difficulty_for(db, user_id, territory_id)
    if relampago:
        # Nível fácil nunca entra no modo relâmpago (decisão fechada na
        # spec) — a dificuldade adaptativa continua valendo, só com piso
        # em "médio" quando o modo relâmpago está ativo.
        difficulty = max(difficulty, config.PALAVRAS_RELAMPAGO_MIN_DIFFICULTY_LEVEL)

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

    if relampago and challenge.options is None:
        # Só "palavras" não tem múltipla escolha curada nos desafios
        # digitados normais (challenge.options is None) — pra esse
        # território, sintetiza alternativas a partir de correct_answer
        # REAL de outros desafios do mesmo nível (nunca inventadas).
        # Todo território que JÁ nasce com options curadas (a imensa
        # maioria) simplesmente reaproveita essas opções reais no modo
        # relâmpago, só ganhando o timer — sem precisar sintetizar nada.
        options = services.generate_relampago_options(db, challenge)
    else:
        # Conhecimento (timed=True aqui) já nasce com options curadas de
        # verdade (4 alternativas reais por pergunta) — nunca precisa
        # sintetizar nada, só reaproveitar o que já existe. Territórios
        # normais (timed=False) também já usam challenge.options como
        # sempre usaram. Embaralhado a cada chamada (achado real,
        # 2026-08-23): sem isso, a posição da resposta certa era sempre
        # a mesma no conteúdo curado, dando pra decorar a posição em vez
        # de saber a resposta.
        options = services.shuffled_options(challenge.options) if challenge.options else challenge.options
    time_limit_seconds = config.TIMED_MULTIPLE_CHOICE_TIME_LIMIT_SECONDS.get(challenge.difficulty_level) if timed else None

    # Achado de auditoria de segurança (28/08/2026): attempt_id nasce
    # aqui, no servidor, com served_at=agora — é o que permite calcular o
    # bônus de velocidade em POST /answer a partir do tempo REAL decorrido
    # no servidor, em vez de confiar em response_time_ms mandado pelo
    # client (que dava pra zerar e dobrar o bônus). _get_or_create_pending_attempt
    # só cria de fato quando o attempt_id não existir ainda — aqui ele
    # sempre não existe (uuid novo), então é sempre uma criação.
    attempt_id = models.new_uuid()
    services.create_served_attempt(db, attempt_id, user_id, challenge.id)

    return schemas.ChallengeOut(
        challenge_id=challenge.id,
        attempt_id=attempt_id,
        territory_id=challenge.territory_id,
        difficulty_level=challenge.difficulty_level,
        prompt=challenge.prompt,
        options=options,
        hints_available=hints_available,
        time_limit_seconds=time_limit_seconds,
        prompt_image=challenge.prompt_image,
    )


def _get_or_create_pending_attempt(db: Session, attempt_id: str, user_id: str, challenge_id: str) -> models.Attempt:
    attempt = db.get(models.Attempt, attempt_id)
    if attempt is not None:
        # Achado de auditoria de segurança (28/08/2026): antes disso, um
        # attempt_id de OUTRO usuário (ou de outro desafio) era aceito sem
        # checagem nenhuma — devolvia correct_answer/explanation de uma
        # tentativa alheia em /hint e /answer, e um reenvio conseguia
        # gravar submitted_answer/xp_awarded na tentativa da vítima,
        # creditando XP a quem não jogou (o ranking agrupa por
        # Attempt.user_id). attempt_id é gerado client-side (uuid v4,
        # não-enumerável), então a exploração exige um valor vazado —
        # mas a checagem correta é "dono confere", nunca "não dá pra
        # adivinhar".
        if attempt.user_id != user_id or attempt.challenge_id != challenge_id:
            raise HTTPException(status_code=404, detail={"error": {"code": "ATTEMPT_NOT_FOUND", "message": attempt_id}})
        return attempt
    try:
        # Fallback só usado pelo fluxo de Batalha (o attempt_id nasce no
        # client via GET /battles/{id}/my-challenge, que não passa por
        # /challenges/next). served_at cai no default (agora), o que
        # ainda deixa o bônus de velocidade de batalhas vulnerável ao
        # mesmo problema que este commit corrigiu pro fluxo normal —
        # servir corretamente exigiria gravar o served_at real de
        # get_or_serve_opponent_challenge (services.py), fora do escopo
        # deste fix. Registrado como pendência de segurança conhecida.
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
    user_id: str = Depends(require_age_confirmed_user_id),
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
    user_id: str = Depends(require_age_confirmed_user_id),
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
            timed_out=attempt.timed_out,
            speed_bonus_xp=attempt.speed_bonus_xp,
        )

    # Achado de auditoria de segurança (28/08/2026): este endpoint nunca
    # checava o limite diário (só GET /challenges/next checava) — dava pra
    # ignorar /next completamente e chamar /answer em loop com um
    # attempt_id novo a cada vez (a resposta certa já vem em
    # correct_answer desta própria rota), gerando XP e conquistando
    # território/ranking sem limite. Checado aqui, DEPOIS do early-return
    # idempotente acima, pra nunca bloquear o replay de uma tentativa já
    # paga — só tentativas NOVAS consomem o limite.
    today = utcnow().date()
    allowed, _consumed = services.check_daily_limit(db, user_id, today)
    if not allowed:
        raise HTTPException(
            status_code=429,
            detail={"error": {"code": "DAILY_LIMIT_REACHED", "message": "Daily free challenge limit reached", "resets_at": str(today.isoformat())}},
        )

    # V2 item 15 — Palavras Relâmpago: timed_out=True nunca confia em
    # submitted_answer vindo do cliente pra decidir acerto — tempo
    # esgotado é sempre tratado como resposta não dada, mesmo que o
    # corpo da requisição contenha algo (defesa contra cliente malicioso
    # tentando reportar acerto depois do prazo).
    is_correct = (
        not body.timed_out
        and body.submitted_answer.strip().lower() == challenge.correct_answer.strip().lower()
    )
    xp_base = scoring.xp_base_for(challenge.difficulty_level) if is_correct else 0
    xp_from_hints = scoring.xp_awarded(xp_base, attempt.hints_used) if is_correct else 0

    # Achado de auditoria de segurança (28/08/2026): response_time_ms do
    # corpo da requisição NUNCA mais alimenta o bônus — vinha 100% do
    # client, e mandar 0 dobrava o bônus de velocidade em qualquer
    # território cronometrado. server_response_time_ms é sempre o tempo
    # real decorrido desde que o servidor entregou este desafio a este
    # usuário (GET /challenges/next) — services.elapsed_ms_since cuida
    # do detalhe aware/naive (bug real em produção logo após o primeiro
    # deploy desta correção: todo POST /answer quebrava com 500).
    server_response_time_ms = services.elapsed_ms_since(attempt.served_at)

    speed_bonus_xp = 0
    time_limit_seconds = config.TIMED_MULTIPLE_CHOICE_TIME_LIMIT_SECONDS.get(challenge.difficulty_level)
    # CONHECIMENTO_EXPANSAO_GERAL.md (aprovado 2026-08-22): generaliza o
    # bônus de velocidade além de Palavras — mesma regra, agora vale pra
    # qualquer território do formato com tempo (config.
    # TIMED_MULTIPLE_CHOICE_TERRITORIES).
    if is_correct and challenge.territory_id in config.TIMED_MULTIPLE_CHOICE_TERRITORIES and time_limit_seconds:
        speed_bonus_xp = services.compute_speed_bonus_xp(xp_base, server_response_time_ms, time_limit_seconds)

    xp_final = xp_from_hints + speed_bonus_xp

    attempt.submitted_answer = body.submitted_answer
    attempt.is_correct = is_correct
    attempt.xp_base = xp_base
    attempt.xp_awarded = xp_final
    attempt.response_time_ms = server_response_time_ms
    attempt.timed_out = body.timed_out
    attempt.speed_bonus_xp = speed_bonus_xp
    db.commit()

    profile = services.get_or_create_profile(db, user_id)
    # MICROINTERACTIONS.md: captura o "antes" pra detectar a TRANSIÇÃO
    # exata (nível subiu / território acabou de ser conquistado agora),
    # nunca o estado absoluto — senão o client celebraria de novo a cada
    # resposta seguinte num território já conquistado.
    level_before = profile.level
    # Achado real testando no aparelho (2026-08-22): estava dentro do
    # bloco `if is_correct`, então numa resposta ERRADA a um território
    # JÁ conquistado antes, was_conquered_before ficava preso em False
    # (nunca recalculado) e territory_just_conquered abaixo dava um falso
    # positivo — "Território conquistado!" aparecendo numa resposta
    # errada. Precisa ser capturado ANTES e incondicionalmente, mesmo
    # raciocínio já usado (corretamente) em was_world_completed_before/
    # detentor_before logo abaixo.
    existing_progress = db.get(models.UserTerritoryProgress, (user_id, challenge.territory_id))
    was_conquered_before = bool(existing_progress and existing_progress.conquered_at)
    territory_progress = existing_progress
    # V2 item 10 — captura o "antes" do mundo, mesmo raciocínio de
    # level_before/was_conquered_before acima: precisa saber se o mundo
    # JÁ estava completo antes desta resposta pra detectar a transição
    # exata, nunca celebrar de novo num mundo já fechado.
    world_id = db.get(models.Territory, challenge.territory_id).world_id
    was_world_completed_before = services.is_world_completed(db, user_id, world_id) if world_id else False
    # V2 item 13 — Disputa territorial: captura o detentor ANTES de
    # aplicar o XP desta resposta, pra detectar a transição exata de
    # "acabei de assumir" (mesmo raciocínio de was_conquered_before/
    # was_world_completed_before acima).
    detentor_before = services.get_territory_detentor(db, user_id, challenge.territory_id)
    if is_correct and xp_final > 0:
        profile.xp_total += xp_final
        profile.level = scoring.level_from_xp(profile.xp_total)
        db.commit()
        territory_progress = services.apply_xp_to_territory(db, user_id, challenge.territory_id, xp_final)

    territory_detentor_gained = False
    dethroned_nickname = None
    detentor_after = services.get_territory_detentor(db, user_id, challenge.territory_id)
    if detentor_after and detentor_after.user_id == user_id and (detentor_before is None or detentor_before.user_id != user_id):
        territory_detentor_gained = True
        if detentor_before is not None:
            dethroned_nickname = detentor_before.nickname
            services.notify_territory_dethroned(db, profile, detentor_before, challenge.territory_id)

    territory_just_conquered = bool(territory_progress and territory_progress.conquered_at and not was_conquered_before)
    world_just_completed = False
    completed_world_name = None
    world_completion_bonus_xp = 0
    if world_id and services.is_world_completed(db, user_id, world_id) and not was_world_completed_before:
        world_just_completed = True
        completed_world_name = db.get(models.World, world_id).name
        world_completion_bonus_xp = config.WORLD_COMPLETION_BONUS_XP
        profile.xp_total += world_completion_bonus_xp
        profile.level = scoring.level_from_xp(profile.xp_total)
        db.commit()

    level_up = profile.level > level_before

    today = utcnow().date()
    services.register_daily_usage(db, user_id, today)
    streak_count_before = services.get_or_create_streak(db, user_id).current_streak
    streak = services.register_play_for_streak(db, user_id, today)
    streak_just_extended = streak.current_streak > streak_count_before

    # V2 item 1 — Badges/Conquistas: avalia depois que XP/território/streak
    # já estão commitados, para os avaliadores lerem o estado final desta
    # tentativa. Badges recém-concedidos AGORA voltam na própria resposta
    # (MICROINTERACTIONS.md) — GET /badges continua sendo a fonte de
    # verdade do catálogo completo, isto aqui é só o "flash" do momento.
    # V2 item 14 — Batalha assíncrona: hook aditivo, não muda nada do
    # cálculo acima. Só age se este challenge_id+user_id for de fato um
    # lado de uma batalha pendente (Attempt normal não é afetado).
    services.maybe_resolve_battle_side(db, user_id, challenge_id, is_correct)

    newly_awarded = services.check_and_award_badges(db, user_id)
    newly_awarded_out = [
        schemas.BadgeOut(
            code=b.code,
            name=b.name,
            description=b.description,
            earned=True,
            earned_at=utcnow().isoformat(),
        )
        for b in newly_awarded
    ]

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
        level_up=level_up,
        new_level=profile.level if level_up else None,
        territory_just_conquered=territory_just_conquered,
        streak_just_extended=streak_just_extended,
        newly_awarded_badges=newly_awarded_out,
        world_just_completed=world_just_completed,
        completed_world_name=completed_world_name,
        world_completion_bonus_xp=world_completion_bonus_xp,
        timed_out=body.timed_out,
        speed_bonus_xp=speed_bonus_xp,
        territory_detentor_gained=territory_detentor_gained,
        dethroned_nickname=dethroned_nickname,
    )
