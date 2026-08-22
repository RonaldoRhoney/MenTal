import random
from datetime import date, datetime, timedelta

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from . import config, models, notification_copy, push, scoring
from .nickname import generate_anonymous_nickname


def _mastery_score(attempt: "models.Attempt") -> float:
    """
    V2 item 6 — Dificuldade adaptativa evoluída (V2_KICKOFF.md §2: evoluir
    a fórmula com mais variedade de sinal disponível, não reescrever do
    zero). Antes desta evolução, cada tentativa da janela contava 1.0 se
    correta e 0.0 se errada — um acerto que só saiu depois de 2 dicas
    pesava exatamente igual a um acerto de primeira, o que não reflete
    domínio real do território.

    Reaproveita scoring.hint_penalty_factor (a MESMA fórmula já travada
    para XP, não um peso novo inventado): acerto sem dica = 1.0, acerto
    com 1 dica = 0.75, com 2 dicas = 0.5 e assim por diante, erro = 0.0.
    Isso já existia como dado (Attempt.hints_used sempre foi gravado),
    só não era usado aqui — "mais variedade de sinal disponível" é
    literalmente isto: sinal que já estava sendo coletado.
    """
    if not attempt.is_correct:
        return 0.0
    return scoring.hint_penalty_factor(attempt.hints_used)


def pick_difficulty_for(db: Session, user_id: str, territory_id: str) -> int:
    """
    Dificuldade adaptativa (ADAPTIVE_DIFFICULTY.md, evoluída no item 6 da
    V2): olha o domínio médio (não mais a taxa de acerto bruta — ver
    _mastery_score) da janela recente de desafios respondidos pelo
    jogador naquele território. Sobe 1 nível quando esse domínio médio
    é >= limiar de subida, desce 1 nível quando é < limiar de descida,
    mantém caso contrário. Janela, amostra mínima e limiares continuam os
    mesmos do Vertical Slice 01 (só o significado de "acerto" mudou, não
    os números de config.py) — centralizados em config.py para ajuste num
    único lugar quando houver dado real de uso.

    Movida de routers/challenges.py para services.py no item 5 da V2
    (Estatísticas) — o endpoint de estatísticas precisa do mesmo cálculo
    ("nível de dificuldade atual por território") e duplicá-lo ali criaria
    duas fontes de verdade para a mesma regra.
    """
    recent = (
        db.execute(
            select(models.Attempt)
            .join(models.Challenge, models.Attempt.challenge_id == models.Challenge.id)
            .where(models.Attempt.user_id == user_id)
            .where(models.Challenge.territory_id == territory_id)
            .where(models.Attempt.is_correct.is_not(None))
            # Desempate por attempt_id além de created_at: achado real
            # rodando o item 5 (Estatísticas) — respostas seguidas rápido
            # o bastante (sem round-trip de rede real, ex.: TestClient em
            # processo) podem colidir no timestamp, e sem uma chave de
            # desempate estável o ORDER BY dava resultado diferente a cada
            # chamada para o EXATO MESMO estado do banco — /stats e
            # /challenges/next calculavam dificuldades diferentes a partir
            # do mesmo histórico. attempt_id não reflete ordem real de
            # criação (é UUID aleatório), mas garante que a mesma consulta
            # sempre devolve o mesmo resultado, o que é o que importa aqui.
            .order_by(models.Attempt.created_at.desc(), models.Attempt.attempt_id.desc())
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
        avg_mastery = sum(_mastery_score(a) for a in recent) / len(recent)
        if avg_mastery >= config.ADAPTIVE_DIFFICULTY_UP_THRESHOLD:
            current_level += 1
        elif avg_mastery < config.ADAPTIVE_DIFFICULTY_DOWN_THRESHOLD:
            current_level -= 1

    return max(config.ADAPTIVE_DIFFICULTY_MIN_LEVEL, min(config.ADAPTIVE_DIFFICULTY_MAX_LEVEL, current_level))


def get_or_create_profile(db: Session, user_id: str) -> models.Profile:
    profile = db.get(models.Profile, user_id)
    if profile is None:
        profile = models.Profile(user_id=user_id, nickname=generate_anonymous_nickname())
        db.add(profile)
        db.commit()
        db.refresh(profile)
    return profile


def get_or_create_streak(db: Session, user_id: str) -> models.Streak:
    streak = db.get(models.Streak, user_id)
    if streak is None:
        streak = models.Streak(user_id=user_id)
        db.add(streak)
        db.commit()
        db.refresh(streak)
    return streak


def _week_anchor(d: date) -> date:
    return d - timedelta(days=d.weekday())


def register_play_for_streak(db: Session, user_id: str, today: date) -> models.Streak:
    streak = get_or_create_streak(db, user_id)
    anchor = _week_anchor(today)

    if streak.week_anchor != anchor:
        streak.week_anchor = anchor
        streak.freeze_available = True
        streak.freeze_used_this_week = False

    if streak.last_played_date == today:
        pass  # já contabilizado hoje, idempotente para múltiplos desafios no mesmo dia
    elif streak.last_played_date == today - timedelta(days=1):
        streak.current_streak += 1
        streak.last_played_date = today
    elif streak.last_played_date is None:
        streak.current_streak = 1
        streak.last_played_date = today
    else:
        gap_days = (today - streak.last_played_date).days
        if gap_days == 2 and streak.freeze_available and not streak.freeze_used_this_week:
            # Streak freeze: perdoa 1 falha por semana (RISKS_AND_OPEN_DECISIONS.md §1)
            streak.freeze_used_this_week = True
            streak.freeze_available = False
            streak.current_streak += 1
            streak.last_played_date = today
        else:
            streak.current_streak = 1
            streak.last_played_date = today

    db.commit()
    db.refresh(streak)
    return streak


def check_daily_limit(db: Session, user_id: str, today: date) -> tuple[bool, int]:
    subscription = db.get(models.Subscription, user_id)
    if subscription and subscription.status == "active":
        return True, 0

    usage = db.get(models.DailyChallengeUsage, (user_id, today))
    consumed = usage.challenges_consumed if usage else 0
    return consumed < config.DAILY_FREE_CHALLENGE_LIMIT, consumed


def register_daily_usage(db: Session, user_id: str, today: date) -> None:
    usage = db.get(models.DailyChallengeUsage, (user_id, today))
    if usage is None:
        usage = models.DailyChallengeUsage(user_id=user_id, usage_date=today, challenges_consumed=0)
        db.add(usage)
    usage.challenges_consumed += 1
    db.commit()


def is_territory_unlocked(db: Session, user_id: str, territory: models.Territory) -> bool:
    # MONETIZATION_UPDATE_FREE_LAUNCH.md §2: ponto único de verificação da
    # flag de lançamento gratuito — nenhuma outra função do backend decide
    # acesso a território. Ativar cobrança no futuro é só mudar a env var
    # MONETIZATION_ENABLED, sem caçar checagem espalhada pelo código.
    if not config.MONETIZATION_ENABLED:
        return True

    if not territory.requires_subscription:
        return True

    subscription = db.get(models.Subscription, user_id)
    if subscription and subscription.status == "active":
        return True

    # Amostra grátis em território pago (TERRITORIES.md §2,
    # MONETIZATION.md §2: "com amostra free"). Conta tentativas já
    # respondidas (is_correct preenchido) em desafios daquele território —
    # pedir uma dica ou abrir o desafio sem responder não consome amostra.
    answered_count = db.execute(
        select(func.count(models.Attempt.attempt_id))
        .join(models.Challenge, models.Attempt.challenge_id == models.Challenge.id)
        .where(models.Attempt.user_id == user_id)
        .where(models.Challenge.territory_id == territory.id)
        .where(models.Attempt.is_correct.is_not(None))
    ).scalar_one()

    return answered_count < territory.free_sample_count


def apply_xp_to_territory(db: Session, user_id: str, territory_id: str, xp: int) -> models.UserTerritoryProgress:
    progress = db.get(models.UserTerritoryProgress, (user_id, territory_id))
    if progress is None:
        progress = models.UserTerritoryProgress(user_id=user_id, territory_id=territory_id, xp_in_territory=0)
        db.add(progress)

    progress.xp_in_territory += xp
    if progress.conquered_at is None and progress.xp_in_territory >= config.CONQUEST_XP_THRESHOLD:
        progress.conquered_at = datetime.utcnow()

    db.commit()
    db.refresh(progress)
    return progress


# V2 item 1 — Badges/Conquistas (V2_KICKOFF.md §6A). Cada avaliador lê
# dado que já existe (Attempt, UserTerritoryProgress, Streak) — nenhuma
# contagem nova é mantida só para badge, evitando duas fontes de verdade
# para o mesmo número.
def _count_conquered_territories(db: Session, user_id: str) -> int:
    return db.execute(
        select(func.count(models.UserTerritoryProgress.territory_id))
        .where(models.UserTerritoryProgress.user_id == user_id)
        .where(models.UserTerritoryProgress.conquered_at.is_not(None))
    ).scalar_one()


def _all_territories_conquered(db: Session, user_id: str) -> bool:
    total_territories = db.execute(select(func.count(models.Territory.id))).scalar_one()
    if total_territories == 0:
        return False
    return _count_conquered_territories(db, user_id) >= total_territories


# V2 item 10 — Mundos completos (V2_KICKOFF.md §2/§6A). "Mundo completo"
# nunca é armazenado — sempre derivado de UserTerritoryProgress.
# conquered_at, mesmo raciocínio de _all_territories_conquered acima,
# só que por world_id em vez de global.
def is_world_completed(db: Session, user_id: str, world_id: str) -> bool:
    territory_ids = db.execute(
        select(models.Territory.id).where(models.Territory.world_id == world_id)
    ).scalars().all()
    if not territory_ids:
        return False
    conquered_count = db.execute(
        select(func.count(models.UserTerritoryProgress.territory_id))
        .where(models.UserTerritoryProgress.user_id == user_id)
        .where(models.UserTerritoryProgress.territory_id.in_(territory_ids))
        .where(models.UserTerritoryProgress.conquered_at.is_not(None))
    ).scalar_one()
    return conquered_count >= len(territory_ids)


def get_worlds_progress(db: Session, user_id: str) -> list[dict]:
    worlds = db.execute(select(models.World).order_by(models.World.display_order)).scalars().all()
    out = []
    for world in worlds:
        territory_ids = db.execute(
            select(models.Territory.id).where(models.Territory.world_id == world.id)
        ).scalars().all()
        out.append(
            {
                "world_id": world.id,
                "name": world.name,
                "territory_ids": territory_ids,
                "completed": is_world_completed(db, user_id, world.id),
            }
        )
    return out


# V2 item 12 — Amigos (V2_KICKOFF.md §6A). Par sempre canônico
# (user_id_a < user_id_b como string) — quem chama nunca precisa saber
# de que lado da linha o próprio user_id está.
def _canonical_pair(user_id_1: str, user_id_2: str) -> tuple[str, str]:
    return (user_id_1, user_id_2) if user_id_1 < user_id_2 else (user_id_2, user_id_1)


def add_friendship(db: Session, user_id_1: str, user_id_2: str) -> models.Friendship | None:
    """Idempotente: retorna None se já eram amigos, sem duplicar linha."""
    a, b = _canonical_pair(user_id_1, user_id_2)
    existing = db.execute(
        select(models.Friendship).where(models.Friendship.user_id_a == a, models.Friendship.user_id_b == b)
    ).scalar_one_or_none()
    if existing is not None:
        return None
    friendship = models.Friendship(user_id_a=a, user_id_b=b)
    db.add(friendship)
    db.commit()
    db.refresh(friendship)
    return friendship


def get_friend_user_ids(db: Session, user_id: str) -> list[str]:
    rows = db.execute(
        select(models.Friendship).where(
            (models.Friendship.user_id_a == user_id) | (models.Friendship.user_id_b == user_id)
        )
    ).scalars().all()
    return [f.user_id_b if f.user_id_a == user_id else f.user_id_a for f in rows]


def _count_total_correct_answers(db: Session, user_id: str) -> int:
    return db.execute(
        select(func.count(models.Attempt.attempt_id))
        .where(models.Attempt.user_id == user_id)
        .where(models.Attempt.is_correct.is_(True))
    ).scalar_one()


def _count_hint_free_correct_answers(db: Session, user_id: str) -> int:
    return db.execute(
        select(func.count(models.Attempt.attempt_id))
        .where(models.Attempt.user_id == user_id)
        .where(models.Attempt.is_correct.is_(True))
        .where(models.Attempt.hints_used == 0)
    ).scalar_one()


def _world_completed_by_display_order(db: Session, user_id: str, display_order: int) -> bool:
    world = db.execute(select(models.World).where(models.World.display_order == display_order)).scalar_one_or_none()
    return bool(world) and is_world_completed(db, user_id, world.id)


_BADGE_EVALUATORS = {
    "territory_conquered_count": lambda db, user_id, value: _count_conquered_territories(db, user_id) >= value,
    "all_territories_conquered": lambda db, user_id, value: _all_territories_conquered(db, user_id),
    "streak_days": lambda db, user_id, value: (
        (streak := db.get(models.Streak, user_id)) is not None and streak.current_streak >= value
    ),
    "total_correct_answers": lambda db, user_id, value: _count_total_correct_answers(db, user_id) >= value,
    "hint_free_correct_answers": lambda db, user_id, value: _count_hint_free_correct_answers(db, user_id) >= value,
    # V2 item 11 — usa display_order do mundo como "value" em vez de um
    # world_id novo no schema de Badge (reaproveita o campo numérico já
    # existente, mesmo padrão de streak_days/total_correct_answers —
    # nenhuma coluna nova só pra isto).
    "world_completed_by_display_order": _world_completed_by_display_order,
}


def check_and_award_badges(db: Session, user_id: str) -> list[models.Badge]:
    """
    Chamado após eventos que podem destravar um badge (hoje: toda resposta
    de desafio, correta ou não — os avaliadores conferem a condição real).
    Idempotente: nunca concede o mesmo badge duas vezes. Retorna a lista de
    badges recém-concedidos nesta chamada (para o client poder celebrar o
    momento, se quiser — não usado ainda no V2 item 1, mas já disponível).
    """
    already_earned_ids = set(
        db.execute(select(models.UserBadge.badge_id).where(models.UserBadge.user_id == user_id)).scalars().all()
    )
    all_badges = db.execute(select(models.Badge)).scalars().all()

    newly_awarded = []
    for badge in all_badges:
        if badge.id in already_earned_ids:
            continue
        evaluator = _BADGE_EVALUATORS.get(badge.criteria_type)
        if evaluator is None:
            continue
        if evaluator(db, user_id, badge.criteria_value):
            db.add(models.UserBadge(user_id=user_id, badge_id=badge.id))
            newly_awarded.append(badge)

    if newly_awarded:
        db.commit()
    return newly_awarded


# V2 item 5 — Estatísticas (V2_KICKOFF.md §6A). Todo número aqui vem de
# Attempt/UserTerritoryProgress/Streak/Badge já existentes — nenhuma
# contagem nova é persistida só para esta tela, mesmo princípio já usado
# em badges (evita duas fontes de verdade para o mesmo dado).
def _longest_streak_ever(db: Session, user_id: str) -> int:
    """
    "Sequência mais longa" não tem coluna própria — é derivada dos dias
    distintos em que o jogador tem pelo menos uma tentativa registrada
    (mesmo critério de "jogou hoje" usado em register_play_for_streak,
    que não exige acerto). Reconstrói a maior sequência de dias
    consecutivos já vivida, não só a atual (Streak.current_streak já
    cobre a atual).
    """
    timestamps = db.execute(
        select(models.Attempt.created_at).where(models.Attempt.user_id == user_id)
    ).scalars().all()
    if not timestamps:
        return 0

    days = sorted({ts.date() for ts in timestamps})
    longest = 1
    current = 1
    for i in range(1, len(days)):
        gap = (days[i] - days[i - 1]).days
        if gap == 1:
            current += 1
            longest = max(longest, current)
        elif gap > 1:
            current = 1
    return longest


def compute_stats(db: Session, user_id: str) -> dict:
    profile = get_or_create_profile(db, user_id)
    streak = get_or_create_streak(db, user_id)

    total_attempts = db.execute(
        select(func.count(models.Attempt.attempt_id))
        .where(models.Attempt.user_id == user_id)
        .where(models.Attempt.is_correct.is_not(None))
    ).scalar_one()
    total_correct = _count_total_correct_answers(db, user_id)
    total_hints_used = db.execute(
        select(func.coalesce(func.sum(models.Attempt.hints_used), 0)).where(models.Attempt.user_id == user_id)
    ).scalar_one()
    hint_free_correct = _count_hint_free_correct_answers(db, user_id)

    badges_earned = db.execute(
        select(func.count(models.UserBadge.badge_id)).where(models.UserBadge.user_id == user_id)
    ).scalar_one()
    badges_total = db.execute(select(func.count(models.Badge.id))).scalar_one()

    territories = db.execute(select(models.Territory).order_by(models.Territory.display_order)).scalars().all()
    by_territory = []
    for territory in territories:
        territory_attempts = (
            db.execute(
                select(models.Attempt)
                .join(models.Challenge, models.Attempt.challenge_id == models.Challenge.id)
                .where(models.Attempt.user_id == user_id)
                .where(models.Challenge.territory_id == territory.id)
                .where(models.Attempt.is_correct.is_not(None))
            )
            .scalars()
            .all()
        )
        t_total = len(territory_attempts)
        t_correct = sum(1 for a in territory_attempts if a.is_correct)
        progress = db.get(models.UserTerritoryProgress, (user_id, territory.id))

        by_territory.append(
            {
                "territory_id": territory.id,
                "total_attempts": t_total,
                "total_correct": t_correct,
                "accuracy": (t_correct / t_total) if t_total else 0.0,
                "current_difficulty_level": pick_difficulty_for(db, user_id, territory.id),
                "xp_in_territory": progress.xp_in_territory if progress else 0,
                "conquered": bool(progress and progress.conquered_at),
            }
        )

    return {
        "xp_total": profile.xp_total,
        "level": profile.level,
        "total_attempts": total_attempts,
        "total_correct": total_correct,
        "accuracy": (total_correct / total_attempts) if total_attempts else 0.0,
        "total_hints_used": int(total_hints_used),
        "hint_free_correct": hint_free_correct,
        "current_streak": streak.current_streak,
        "longest_streak": _longest_streak_ever(db, user_id),
        "badges_earned": badges_earned,
        "badges_total": badges_total,
        "by_territory": by_territory,
    }


# V2 item 8 — Notificações (NOTIFICATIONS.md).
def update_last_seen(db: Session, user_id: str) -> None:
    profile = get_or_create_profile(db, user_id)
    profile.last_seen_at = datetime.utcnow()
    db.commit()


def set_push_token(db: Session, user_id: str, push_token: str) -> None:
    profile = get_or_create_profile(db, user_id)
    profile.push_token = push_token
    db.commit()


def set_notification_preferences(db: Session, user_id: str, reengagement_enabled: bool, social_enabled: bool) -> models.Profile:
    profile = get_or_create_profile(db, user_id)
    profile.notif_reengagement_enabled = reengagement_enabled
    profile.notif_social_enabled = social_enabled
    db.commit()
    db.refresh(profile)
    return profile


# V2 item 15 — Palavras Relâmpago (PALAVRAS_RELAMPAGO.md, aprovado
# 2026-08-22). Reaproveita 100% o banco de desafios já curado — as
# alternativas erradas nunca são geradas por IA nem inventadas, são
# correct_answer REAIS de outros desafios do mesmo território/nível
# (RISKS_AND_OPEN_DECISIONS.md §2: curadoria manual, sem geração
# automática de conteúdo). Sem duplicar dado: as opções são calculadas
# em tempo real a cada chamada, nunca persistidas no Challenge.
def generate_relampago_options(db: Session, challenge: models.Challenge) -> list[str]:
    other_answers = db.execute(
        select(models.Challenge.correct_answer)
        .where(models.Challenge.territory_id == challenge.territory_id)
        .where(models.Challenge.difficulty_level == challenge.difficulty_level)
        .where(models.Challenge.id != challenge.id)
    ).scalars().all()
    distractors = random.sample(other_answers, k=min(2, len(other_answers)))
    options = [challenge.correct_answer, *distractors]
    random.shuffle(options)
    return options


def compute_speed_bonus_xp(xp_base: int, response_time_ms: int, time_limit_seconds: int) -> int:
    """
    Bônus decrescente conforme o tempo consumido (PALAVRAS_RELAMPAGO.md
    §4): platô de bônus máximo até FAST_FRACTION do tempo, decaimento
    linear até zero em SLOW_FRACTION, platô zero depois disso. Nunca
    negativo — responder devagar dentro do tempo só deixa de ganhar
    bônus, nunca perde o XP base do acerto.
    """
    if time_limit_seconds <= 0:
        return 0
    fraction_used = min(1.0, max(0.0, response_time_ms / (time_limit_seconds * 1000)))
    fast = config.PALAVRAS_RELAMPAGO_SPEED_BONUS_FAST_FRACTION
    slow = config.PALAVRAS_RELAMPAGO_SPEED_BONUS_SLOW_FRACTION
    max_multiplier = config.PALAVRAS_RELAMPAGO_SPEED_BONUS_MAX_MULTIPLIER

    if fraction_used <= fast:
        multiplier = max_multiplier
    elif fraction_used >= slow:
        multiplier = 0.0
    else:
        progress = (fraction_used - fast) / (slow - fast)
        multiplier = max_multiplier * (1 - progress)

    return round(xp_base * multiplier)


def award_share_reward(db: Session, profile: "models.Profile") -> tuple[int, bool]:
    """
    Pedido de Rhoney (2026-08-22): compartilhar uma conquista (nível,
    território, mundo, badge, meta de passos) rende XP. O app não tem
    como confirmar que o compartilhamento via OS share sheet foi
    concluído de fato (share_plus só garante que o sheet abriu sem
    erro) — a defesa contra farm não é "verificar o compartilhamento em
    si", é um teto de 1 recompensa por dia civil (UTC), independente de
    quantas vezes o botão de compartilhar for tocado no mesmo dia.

    Retorna (xp_awarded, already_rewarded_today).
    """
    today = date.today()
    if profile.last_share_reward_date == today:
        return 0, True

    profile.last_share_reward_date = today
    profile.xp_total += config.SHARE_XP_REWARD
    profile.level = scoring.level_from_xp(profile.xp_total)
    db.commit()
    return config.SHARE_XP_REWARD, False


def count_battles_sent_today(db: Session, user_id: str, today: date) -> int:
    day_start = datetime(today.year, today.month, today.day)
    day_end = day_start + timedelta(days=1)
    return db.execute(
        select(func.count())
        .select_from(models.Battle)
        .where(models.Battle.challenger_user_id == user_id)
        .where(models.Battle.created_at >= day_start)
        .where(models.Battle.created_at < day_end)
    ).scalar_one()


def pick_two_distinct_challenges(db: Session, territory_id: str, difficulty_level: int) -> tuple["models.Challenge", "models.Challenge"] | None:
    """
    V2 item 14 — Batalha assíncrona (ASYNC_BATTLE.md §2.2/§2.3): os dois
    lados respondem desafios DIFERENTES do mesmo território/nível, nunca
    o mesmo (evita cola entre amigos combinando resposta). Retorna None
    se não houver pelo menos 2 desafios distintos disponíveis.
    """
    candidates = (
        db.execute(
            select(models.Challenge)
            .where(models.Challenge.territory_id == territory_id)
            .where(models.Challenge.difficulty_level == difficulty_level)
        )
        .scalars()
        .all()
    )
    if len(candidates) < 2:
        return None
    a, b = random.sample(candidates, k=2)
    return a, b


def create_battle(
    db: Session,
    challenger_user_id: str,
    opponent_user_id: str,
    territory_id: str,
    difficulty_level: int,
) -> "models.Battle | None":
    pair = pick_two_distinct_challenges(db, territory_id, difficulty_level)
    if pair is None:
        return None
    challenger_challenge, opponent_challenge = pair

    battle = models.Battle(
        challenger_user_id=challenger_user_id,
        opponent_user_id=opponent_user_id,
        territory_id=territory_id,
        difficulty_level=difficulty_level,
        challenger_challenge_id=challenger_challenge.id,
        opponent_challenge_id=opponent_challenge.id,
        challenger_served_at=datetime.utcnow(),
    )
    db.add(battle)
    db.commit()
    db.refresh(battle)

    challenger_profile = db.get(models.Profile, challenger_user_id)
    opponent_profile = db.get(models.Profile, opponent_user_id)
    if opponent_profile and opponent_profile.notif_social_enabled and opponent_profile.push_token:
        territory_label = notification_copy.TERRITORY_NAMES.get(territory_id, territory_id)
        title = notification_copy.BATTLE_CHALLENGE_RECEIVED_TITLE
        body = notification_copy.BATTLE_CHALLENGE_RECEIVED_BODY_TEMPLATE.format(
            nickname=challenger_profile.nickname if challenger_profile else "Um amigo",
            territory=territory_label,
        )
        push.send_push_notification(opponent_profile.push_token, title, body)

    return battle


def get_or_serve_opponent_challenge(db: Session, battle: "models.Battle") -> None:
    """Marca opponent_served_at na PRIMEIRA vez que o desafiado abre o próprio desafio (nunca reescreve depois)."""
    if battle.opponent_served_at is None:
        battle.opponent_served_at = datetime.utcnow()
        db.commit()


def _resolve_battle_winner(battle: "models.Battle") -> str | None:
    """ASYNC_BATTLE.md §2.5: acerto > erro; entre dois acertos, vence quem respondeu mais rápido; entre dois erros, empate."""
    if battle.challenger_is_correct and not battle.opponent_is_correct:
        return battle.challenger_user_id
    if battle.opponent_is_correct and not battle.challenger_is_correct:
        return battle.opponent_user_id
    if battle.challenger_is_correct and battle.opponent_is_correct:
        challenger_ms = battle.challenger_response_ms or 0
        opponent_ms = battle.opponent_response_ms or 0
        return battle.challenger_user_id if challenger_ms <= opponent_ms else battle.opponent_user_id
    return None  # os dois erraram — empate


def maybe_resolve_battle_side(db: Session, user_id: str, challenge_id: str, is_correct: bool) -> None:
    """
    Hook aditivo chamado no final de POST /challenges/{id}/answer — não
    muda em nada o cálculo de XP/streak/badges já existente ali, só
    verifica se este challenge_id+user_id corresponde a um lado de uma
    batalha pendente e, se sim, registra o resultado. Nunca dispara em
    respostas normais (fora de batalha), que são a grande maioria.
    """
    battle = db.execute(
        select(models.Battle)
        .where(models.Battle.status == "pending")
        .where(
            ((models.Battle.challenger_user_id == user_id) & (models.Battle.challenger_challenge_id == challenge_id))
            | ((models.Battle.opponent_user_id == user_id) & (models.Battle.opponent_challenge_id == challenge_id))
        )
    ).scalars().first()
    if battle is None:
        return

    now = datetime.utcnow()
    if battle.challenger_user_id == user_id and battle.challenger_is_correct is None:
        battle.challenger_is_correct = is_correct
        battle.challenger_response_ms = int((now - battle.challenger_served_at).total_seconds() * 1000)
    elif battle.opponent_user_id == user_id and battle.opponent_is_correct is None:
        get_or_serve_opponent_challenge(db, battle)
        battle.opponent_is_correct = is_correct
        served_at = battle.opponent_served_at or now
        battle.opponent_response_ms = int((now - served_at).total_seconds() * 1000)
    else:
        return  # este lado já tinha respondido (reenvio idempotente do attempt) — não reprocessa

    if battle.challenger_is_correct is not None and battle.opponent_is_correct is not None:
        battle.status = "resolved"
        battle.resolved_at = now
        winner_user_id = _resolve_battle_winner(battle)
        battle.winner_user_id = winner_user_id

        if winner_user_id:
            winner_profile = db.get(models.Profile, winner_user_id)
            winner_profile.xp_total += config.BATTLE_WIN_BONUS_XP
            winner_profile.level = scoring.level_from_xp(winner_profile.xp_total)

        challenger_profile = db.get(models.Profile, battle.challenger_user_id)
        opponent_profile = db.get(models.Profile, battle.opponent_user_id)
        _notify_battle_result(challenger_profile, opponent_profile, winner_user_id)

    db.commit()


def get_territory_detentor(db: Session, user_id: str, territory_id: str) -> "models.Profile | None":
    """
    V2 item 13 — Disputa territorial (TERRITORY_DISPUTE.md, aprovado
    2026-08-22). "Detentor" é SEMPRE relativo a quem pergunta: quem tem
    mais XP acumulado naquele território (UserTerritoryProgress.
    xp_in_territory, já existente — nunca um dado novo) entre você e seus
    amigos confirmados (item 12). Escopo deliberadamente restrito a
    amigos, nunca global — mesma razão já aplicada à Batalha assíncrona
    e ao ranking de amigos: evita a dinâmica de "perder território pra um
    estranho", incompatível com o Princípio de Não-Humilhação num público
    que inclui crianças. Sempre derivado, nunca armazenado — mesmo
    princípio já usado em "mundo completo". Retorna None se ninguém no
    grupo (incluindo você) tem XP nesse território ainda.
    """
    candidate_ids = [user_id] + get_friend_user_ids(db, user_id)
    rows = db.execute(
        select(models.UserTerritoryProgress)
        .where(models.UserTerritoryProgress.territory_id == territory_id)
        .where(models.UserTerritoryProgress.user_id.in_(candidate_ids))
        .where(models.UserTerritoryProgress.xp_in_territory > 0)
    ).scalars().all()
    if not rows:
        return None
    # Empate exato: desempate determinístico por user_id, nunca
    # aleatório — evita notificação de "assumiu" oscilando a cada
    # resposta sem mudança real de liderança.
    leader = max(rows, key=lambda r: (r.xp_in_territory, r.user_id))
    return db.get(models.Profile, leader.user_id)


def notify_territory_dethroned(db: Session, new_detentor_profile: "models.Profile", previous_detentor_profile: "models.Profile", territory_id: str) -> None:
    if not (previous_detentor_profile.notif_social_enabled and previous_detentor_profile.push_token):
        return
    territory_label = notification_copy.TERRITORY_NAMES.get(territory_id, territory_id)
    push.send_push_notification(
        previous_detentor_profile.push_token,
        notification_copy.TERRITORY_DETENTOR_LOST_TITLE,
        notification_copy.TERRITORY_DETENTOR_LOST_BODY_TEMPLATE.format(nickname=new_detentor_profile.nickname, territory=territory_label),
    )


def _notify_battle_result(challenger_profile: "models.Profile", opponent_profile: "models.Profile", winner_user_id: str | None) -> None:
    for me, other in ((challenger_profile, opponent_profile), (opponent_profile, challenger_profile)):
        if not (me and me.notif_social_enabled and me.push_token):
            continue
        other_nickname = other.nickname if other else "seu amigo"
        if winner_user_id is None:
            title, body = notification_copy.BATTLE_RESULT_TIE_TITLE, notification_copy.BATTLE_RESULT_TIE_BODY_TEMPLATE.format(nickname=other_nickname)
        elif winner_user_id == me.user_id:
            title, body = notification_copy.BATTLE_RESULT_WIN_TITLE, notification_copy.BATTLE_RESULT_WIN_BODY_TEMPLATE.format(nickname=other_nickname)
        else:
            title, body = notification_copy.BATTLE_RESULT_LOSS_TITLE, notification_copy.BATTLE_RESULT_LOSS_BODY_TEMPLATE.format(nickname=other_nickname)
        push.send_push_notification(me.push_token, title, body)
