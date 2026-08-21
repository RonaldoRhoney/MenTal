from datetime import date, datetime, timedelta

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from . import config, models, scoring
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


_BADGE_EVALUATORS = {
    "territory_conquered_count": lambda db, user_id, value: _count_conquered_territories(db, user_id) >= value,
    "all_territories_conquered": lambda db, user_id, value: _all_territories_conquered(db, user_id),
    "streak_days": lambda db, user_id, value: (
        (streak := db.get(models.Streak, user_id)) is not None and streak.current_streak >= value
    ),
    "total_correct_answers": lambda db, user_id, value: _count_total_correct_answers(db, user_id) >= value,
    "hint_free_correct_answers": lambda db, user_id, value: _count_hint_free_correct_answers(db, user_id) >= value,
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
