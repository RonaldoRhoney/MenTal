from datetime import date, timedelta

from sqlalchemy.orm import Session

from . import config, models
from .nickname import generate_anonymous_nickname


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
    from sqlalchemy import select, func

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
        from datetime import datetime

        progress.conquered_at = datetime.utcnow()

    db.commit()
    db.refresh(progress)
    return progress
