from datetime import timedelta

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select
from sqlalchemy.orm import Session

from .. import config, mentalcoins, models, schemas, scoring, services
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
    # CONHECIMENTO_EXPANSAO_GERAL.md (aprovado 2026-08-22) / V3.0.1_
    # DESAFIO_CORES.md (aprovado 29/08/2026): em Conhecimento e Cores o
    # formato com tempo é OBRIGATÓRIO e único — nunca formato digitado,
    # independente de "mode". Generaliza o mesmo mecanismo do Palavras
    # Relâmpago (mesmo componente, territórios diferentes).
    timed = relampago or territory_id in config.ALWAYS_TIMED_TERRITORIES
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

    # BUG_PERGUNTAS_REPETINDO_SEQUENCIA.md — substitui a antiga heurística
    # probabilística (evitar repetir o último N, limitar repetições
    # recentes) por consumo de uma fila embaralhada persistente: garante
    # sequência sem repetição real até o lote inteiro (todos os
    # `candidates` desta chamada, por território+dificuldade+timed) ser
    # servido, reembaralhando do zero só quando esgota.
    challenge, is_last_of_batch = services.pick_next_challenge_from_batch(
        db, user_id, territory_id, difficulty, timed, candidates
    )
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
    services.create_served_attempt(db, attempt_id, user_id, challenge.id, timed=timed, was_last_of_batch=is_last_of_batch)

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
        clues=challenge.clues,
        audio_url=challenge.audio_url,
        audio_source_name=challenge.audio_source_name,
        audio_source_url=challenge.audio_source_url,
    )


@router.get("/challenges/search", response_model=schemas.ChallengeSearchResponse)
def search_challenges(
    # Achado de auditoria de segurança M4 (05/09/2026): sem max_length,
    # nada limitava o tamanho da busca antes de virar um padrão ILIKE.
    q: str = Query(max_length=200),
    language_code: str = config.DEFAULT_LANGUAGE_CODE,
    user_id: str = Depends(require_age_confirmed_user_id),
    db: Session = Depends(get_db),
):
    """
    Busca na Home (pedido de Rhoney, 2026-09-03): "tema, frase ou
    palavra"; "tema" já foi tentado no client (territories.dart) antes
    de chamar este endpoint — aqui só cobre "frase"/"palavra" (trecho
    literal no prompt de algum desafio). found=False é o resultado
    normal de "nada encontrado" (não é erro) — o client então oferece
    registrar via POST /content-suggestions.
    """
    services.enforce_rate_limit("challenges_search", user_id, max_calls=config.RATE_LIMIT_SEARCH[0], window_seconds=config.RATE_LIMIT_SEARCH[1])
    services.get_or_create_profile(db, user_id)

    challenge = services.find_challenge_by_search(db, language_code, q)
    if challenge is None:
        return schemas.ChallengeSearchResponse(found=False)

    territory = db.get(models.Territory, challenge.territory_id)
    if territory is None or not services.is_territory_unlocked(db, user_id, territory):
        # Território bloqueado (exige assinatura) ou inconsistente: trata
        # como "não encontrado" pro buscador — nunca revela a existência
        # de conteúdo pago/bloqueado a quem não tem acesso.
        return schemas.ChallengeSearchResponse(found=False)

    today = utcnow().date()
    allowed, _consumed = services.check_daily_limit(db, user_id, today)
    if not allowed:
        raise HTTPException(
            status_code=429,
            detail={"error": {"code": "DAILY_LIMIT_REACHED", "message": "Daily free challenge limit reached", "resets_at": str(today.isoformat())}},
        )

    hints_available = len(
        db.execute(select(models.ChallengeHint).where(models.ChallengeHint.challenge_id == challenge.id)).scalars().all()
    )
    # Resultado de busca nunca é cronometrado (V2 item 15 é sobre modo
    # deliberado escolhido pelo jogador, não uma pesquisa dirigida) —
    # sempre normal, mesma lógica de options de next_challenge com
    # timed=False.
    options = services.shuffled_options(challenge.options) if challenge.options else challenge.options

    attempt_id = models.new_uuid()
    services.create_served_attempt(db, attempt_id, user_id, challenge.id, timed=False, was_last_of_batch=True)

    return schemas.ChallengeSearchResponse(
        found=True,
        challenge=schemas.ChallengeOut(
            challenge_id=challenge.id,
            attempt_id=attempt_id,
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
        ),
    )


@router.get("/challenges/{challenge_id}/reattempt", response_model=schemas.ChallengeOut)
def reattempt_challenge(
    challenge_id: str,
    user_id: str = Depends(require_age_confirmed_user_id),
    db: Session = Depends(get_db),
):
    """
    REGRA_REVISAO_ERROS_FIM_RODADA.md — reapresenta um desafio já visto
    NESTA MESMA rodada, especificamente pra revisão de um erro. Nunca
    consome o limite diário (não é um desafio "novo": já foi contado
    quando servido a primeira vez) e a resposta nunca gera XP/streak/
    badge/progresso de território — submit_answer detecta
    attempt.is_review e pula toda mutação, devolvendo só se acertou ou
    não ("apenas confirmar o aprendizado", nunca pontuação nova).

    Achado de auditoria de segurança CRÍTICO (05/09/2026): sem a
    checagem abaixo, este endpoint aceitava QUALQUER challenge_id —
    inclusive um nunca servido ao usuário — e o caminho is_review de
    POST /answer devolve correct_answer/explanation sem consumir limite
    diário. Isso virava um oráculo de respostas de custo zero pra todo
    o banco de conteúdo. Exige um Attempt real e recente deste usuário
    neste desafio com is_correct=False (nunca outro is_review) — a
    aproximação server-side mais forte de "errou isso nesta rodada".
    """
    services.enforce_rate_limit("challenges_reattempt", user_id, max_calls=config.RATE_LIMIT_REATTEMPT[0], window_seconds=config.RATE_LIMIT_REATTEMPT[1])

    challenge = db.get(models.Challenge, challenge_id)
    if challenge is None:
        raise HTTPException(status_code=404, detail={"error": {"code": "CHALLENGE_NOT_FOUND", "message": challenge_id}})

    services.get_or_create_profile(db, user_id)
    territory = db.get(models.Territory, challenge.territory_id)
    if territory is None or not services.is_territory_unlocked(db, user_id, territory):
        raise HTTPException(status_code=403, detail={"error": {"code": "TERRITORY_LOCKED", "message": "Requires active subscription"}})

    min_created_at = utcnow() - timedelta(hours=config.REVIEW_REATTEMPT_MAX_AGE_HOURS)
    prior_wrong_attempt = db.execute(
        select(models.Attempt)
        .where(
            models.Attempt.user_id == user_id,
            models.Attempt.challenge_id == challenge_id,
            models.Attempt.is_correct.is_(False),
            models.Attempt.is_review.is_(False),
            models.Attempt.created_at >= min_created_at,
        )
        .limit(1)
    ).scalar_one_or_none()
    if prior_wrong_attempt is None:
        raise HTTPException(
            status_code=403,
            detail={"error": {"code": "REVIEW_NOT_ALLOWED", "message": "Só é possível revisar um desafio que você errou recentemente."}},
        )

    hints_available = len(
        db.execute(select(models.ChallengeHint).where(models.ChallengeHint.challenge_id == challenge.id)).scalars().all()
    )
    options = services.shuffled_options(challenge.options) if challenge.options else challenge.options

    attempt_id = models.new_uuid()
    services.create_served_attempt(db, attempt_id, user_id, challenge.id, timed=False, was_last_of_batch=False, is_review=True)

    return schemas.ChallengeOut(
        challenge_id=challenge.id,
        attempt_id=attempt_id,
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
    # Achado de auditoria de segurança CRÍTICO (01/09/2026): esta função
    # tinha um fallback que criava uma tentativa nova pra QUALQUER
    # attempt_id desconhecido (originalmente pensado só pro fluxo de
    # Batalha, onde o client inventava o id). Na prática isso aceitava
    # qualquer attempt_id novo pra qualquer challenge_id, permitindo
    # responder o MESMO desafio repetidamente (attempt_id novo a cada
    # chamada) sem nunca passar por GET /challenges/next, rendendo XP
    # ilimitado. Corrigido na origem: Batalha agora gera o attempt_id no
    # SERVIDOR (migration 047, services.create_battle/
    # get_or_serve_opponent_challenge) — todo attempt_id que chega aqui
    # tem que ter sido criado por um "serve" real do servidor
    # (/challenges/next ou Batalha), nunca inventado pelo client.
    raise HTTPException(status_code=404, detail={"error": {"code": "ATTEMPT_NOT_FOUND", "message": attempt_id}})


@router.post("/challenges/{challenge_id}/hint", response_model=schemas.HintResponse)
def request_hint(
    challenge_id: str,
    body: schemas.HintRequest,
    user_id: str = Depends(require_age_confirmed_user_id),
    db: Session = Depends(get_db),
):
    services.enforce_rate_limit("challenges_hint", user_id, max_calls=config.RATE_LIMIT_HINT[0], window_seconds=config.RATE_LIMIT_HINT[1])

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
    services.enforce_rate_limit("challenges_answer", user_id, max_calls=config.RATE_LIMIT_ANSWER_SUBMIT[0], window_seconds=config.RATE_LIMIT_ANSWER_SUBMIT[1])

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
            batch_exhausted=attempt.was_last_of_batch,
        )

    # REGRA_REVISAO_ERROS_FIM_RODADA.md — tentativa servida via GET
    # /challenges/{id}/reattempt (attempt.is_review, gravado pelo
    # SERVIDOR no momento do serve, nunca por flag do client): responde
    # se acertou ou não, mas NUNCA mexe em XP/streak/badge/progresso de
    # território/limite diário — "apenas confirmar o aprendizado", não
    # uma segunda chance de pontuar. Sai ANTES da checagem de limite
    # diário abaixo de propósito: revisão nunca consome esse limite.
    if attempt.is_review:
        is_correct = services.is_submitted_answer_correct(challenge, body.submitted_answer, body.timed_out)
        attempt.submitted_answer = body.submitted_answer
        attempt.is_correct = is_correct
        attempt.xp_base = 0
        attempt.xp_awarded = 0
        attempt.response_time_ms = services.elapsed_ms_since(attempt.served_at)
        attempt.timed_out = body.timed_out
        db.commit()
        streak = services.get_or_create_streak(db, user_id)
        territory_progress = db.get(models.UserTerritoryProgress, (user_id, challenge.territory_id))
        return schemas.AnswerResponse(
            is_correct=is_correct,
            correct_answer=challenge.correct_answer,
            explanation=challenge.explanation,
            xp_base=0,
            hints_used=attempt.hints_used,
            xp_awarded=0,
            streak=schemas.StreakOut(current_streak=streak.current_streak, freeze_available=streak.freeze_available),
            territory_progress=schemas.TerritoryProgressOut(
                xp_in_territory=territory_progress.xp_in_territory if territory_progress else 0,
                conquered=bool(territory_progress and territory_progress.conquered_at),
            ),
            timed_out=body.timed_out,
            batch_exhausted=False,
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
    is_correct = services.is_submitted_answer_correct(challenge, body.submitted_answer, body.timed_out)
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
    # Generalização do Relâmpago pra todos os territórios (29/08/2026,
    # pedido de Rhoney: "quanto menos tempo o jogador acertar melhor
    # será seus pontos"): elegibilidade decidida por attempt.timed
    # (gravado pelo servidor em GET /challenges/next), não mais pela
    # allowlist fixa TIMED_MULTIPLE_CHOICE_TERRITORIES — essa allowlist
    # só cobria os 2 territórios originais e deixava de fora qualquer
    # outro território jogado em modo relâmpago.
    if is_correct and attempt.timed and time_limit_seconds:
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
    # MICROINTERACTIONS.md + achados reais de 22/08 e 02/09/2026: tudo
    # aqui detecta a TRANSIÇÃO exata (nível subiu / território ou mundo
    # acabou de fechar / marco de XP-MentalCoins cruzado / detentor
    # trocou AGORA), nunca o estado absoluto — senão o client celebraria
    # de novo a cada resposta seguinte num território já conquistado.
    # Capturado incondicionalmente, ANTES de qualquer mutação abaixo
    # (mesmo numa resposta ERRADA — achado real testando no aparelho:
    # capturar só dentro do `if is_correct` deixava was_conquered preso
    # em False e gerava falso positivo de "Território conquistado!").
    before = services.capture_answer_before_snapshot(db, user_id, profile, challenge.territory_id)
    level_before = before.level
    xp_before = before.xp_total
    mentalcoins_before = before.mentalcoins_balance
    was_conquered_before = before.was_conquered
    territory_progress = before.territory_progress
    world_id = before.world_id
    was_world_completed_before = before.was_world_completed
    detentor_before = before.detentor
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

    coin_milestone_reached = services.crossed_coin_milestone(
        xp_before,
        profile.xp_total,
        mentalcoins_before,
        mentalcoins.get_or_create_balance(db, user_id).balance,
    )

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
        batch_exhausted=attempt.was_last_of_batch,
        coin_milestone_reached=coin_milestone_reached,
    )
