"""
REGRA_OFICIAL_GAMIFICACAO_MENTAL.md — Fase 2 (19/09/2026, aprovada por
Rhoney): recompensas novas, todas com o MESMO mecanismo anti-farm — uma
linha em mental.reward_claims por (usuário, período/marco). A PK
composta é o que impede pagamento duplo, mesmo com duas requisições
concorrentes (a segunda inserção falha e não paga).

Regras de desenho (achados de auditoria de segurança do projeto):
- Só o SERVIDOR decide e paga; nenhum valor vem do client.
- Cada função é idempotente: chamar duas vezes no mesmo período não
  paga de novo.
- Nenhuma recompensa por ação que qualquer estranho pode disparar
  (Torcida só conta pra amigo confirmado).
- Falha em recompensa NUNCA pode quebrar o fluxo principal (resposta de
  desafio, login, aceite de amizade): os ganchos chamam `safely`.

Datas em UTC, mesma simplificação já registrada em mentalcoins.py.
"""

import logging
from datetime import date, timedelta

from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from . import config, mentalcoins, models, scoring
from .social import get_friend_user_ids
from .timeutil import utcnow

logger = logging.getLogger(__name__)


def safely(fn, *args, **kwargs) -> None:
    """Recompensa é bônus, nunca requisito: qualquer erro aqui é logado e
    engolido, nunca propagado ao fluxo principal."""
    try:
        fn(*args, **kwargs)
    except Exception:  # noqa: BLE001 — deliberado, ver docstring
        db = args[0] if args else None
        try:
            if db is not None:
                db.rollback()
        except Exception:  # noqa: BLE001
            pass
        logger.exception("Falha ao processar recompensa %s", getattr(fn, "__name__", fn))


def try_claim(db: Session, user_id: str, key: str) -> bool:
    """True se ESTA chamada registrou o claim (pode pagar); False se já
    existia. Não faz commit — quem paga comita junto com o crédito."""
    if db.get(models.RewardClaim, (user_id, key)) is not None:
        return False
    try:
        with db.begin_nested():
            db.add(models.RewardClaim(user_id=user_id, claim_key=key))
            db.flush()
    except IntegrityError:
        return False
    return True


def has_claim(db: Session, user_id: str, key: str) -> bool:
    return db.get(models.RewardClaim, (user_id, key)) is not None


def award_xp(db: Session, profile: models.Profile, amount: int) -> None:
    """XP de perfil avulso (sem território). Mesmas duas linhas já usadas
    por share/app-invite/constelação, num ponto só."""
    if amount <= 0:
        return
    # Achado M3 (revisão de segurança, 20/09/2026): o commit anterior solta
    # o lock — recarrega com FOR UPDATE pra 2 recompensas concorrentes
    # (ex.: login + lote) não perderem XP uma da outra.
    db.refresh(profile, with_for_update=True)
    profile.xp_total += amount
    profile.level = scoring.level_from_xp(profile.xp_total)
    db.commit()


def _award_coins(db: Session, user_id: str, amount: int, reason: str) -> None:
    if amount > 0:
        mentalcoins.credit(db, user_id, amount, reason)


def _profile(db: Session, user_id: str) -> models.Profile | None:
    return db.get(models.Profile, user_id)


def _days_back(today: date, n: int) -> list[date]:
    """As n datas terminando em `today` (inclusive)."""
    return [today - timedelta(days=i) for i in range(n)]


# ---------------------------------------------------------------- 4.1 login
def daily_login(db: Session, profile: models.Profile, today: date) -> None:
    """+1 XP e +0,5 MentalCoin por dia. O saldo é inteiro, então a meia
    moeda vira 1 moeda a cada 2 logins pagos (decisão de Rhoney)."""
    if not try_claim(db, profile.user_id, f"login:{today.isoformat()}"):
        return
    db.commit()  # persiste o claim antes de creditar
    award_xp(db, profile, config.LOGIN_DAILY_XP)
    logins = db.execute(
        select(func.count())
        .select_from(models.RewardClaim)
        .where(models.RewardClaim.user_id == profile.user_id, models.RewardClaim.claim_key.like("login:%"))
    ).scalar_one()
    if logins % config.LOGIN_COIN_EVERY_N_LOGINS == 0:
        _award_coins(db, profile.user_id, config.LOGIN_COIN_AMOUNT, "login_diario")


# --------------------------------------------------------------- 5 streak
def on_streak_extended(db: Session, profile: models.Profile, current_streak: int, today: date) -> None:
    """Marcos 7/15/30/100 dias. Chamado só quando o streak acabou de
    subir; o claim inclui a data, então repetir no mesmo dia não paga."""
    reward = config.STREAK_MILESTONE_REWARDS.get(current_streak)
    if reward is None:
        return
    if not try_claim(db, profile.user_id, f"streak:{current_streak}:{today.isoformat()}"):
        return
    db.commit()
    kind, value = reward
    if kind == "xp":
        award_xp(db, profile, value)
    else:
        _award_coins(db, profile.user_id, value, f"streak_{current_streak}_dias")


# -------------------------------------------------------- 1.3/1.4 lote
def on_batch_completed(db: Session, profile: models.Profile, attempt: models.Attempt, challenge: models.Challenge) -> None:
    """+3 XP ao terminar o lote de perguntas (o "Desafio inteiro"); +5 XP
    extra se TODAS as respostas do lote foram certas e sem dica. Só
    respostas normais (revisão nunca chega aqui) e uma vez por attempt."""
    if not attempt.was_last_of_batch or attempt.is_search:
        return
    if not try_claim(db, profile.user_id, f"batch:{attempt.attempt_id}"):
        return
    db.commit()
    award_xp(db, profile, config.BATCH_COMPLETE_BONUS_XP)

    base = (
        select(models.Attempt)
        .join(models.Challenge, models.Attempt.challenge_id == models.Challenge.id)
        .where(
            models.Attempt.user_id == profile.user_id,
            models.Challenge.territory_id == challenge.territory_id,
            models.Challenge.difficulty_level == challenge.difficulty_level,
            models.Attempt.timed == attempt.timed,
            models.Attempt.is_review.is_(False),
            models.Attempt.is_search.is_(False),
            models.Attempt.is_correct.isnot(None),
        )
    )
    previous_end = db.execute(
        select(func.max(models.Attempt.created_at))
        .join(models.Challenge, models.Attempt.challenge_id == models.Challenge.id)
        .where(
            models.Attempt.user_id == profile.user_id,
            models.Challenge.territory_id == challenge.territory_id,
            models.Challenge.difficulty_level == challenge.difficulty_level,
            models.Attempt.timed == attempt.timed,
            models.Attempt.is_review.is_(False),
            models.Attempt.is_search.is_(False),
            models.Attempt.was_last_of_batch.is_(True),
            models.Attempt.attempt_id != attempt.attempt_id,
            models.Attempt.created_at < attempt.created_at,
        )
    ).scalar_one_or_none()
    if previous_end is not None:
        base = base.where(models.Attempt.created_at > previous_end)
    run = db.execute(base.where(models.Attempt.created_at <= attempt.created_at)).scalars().all()
    perfect = len(run) >= config.BATCH_PERFECT_MIN_ANSWERS and all(a.is_correct and a.hints_used == 0 for a in run)
    if perfect and try_claim(db, profile.user_id, f"batchperfect:{attempt.attempt_id}"):
        db.commit()
        award_xp(db, profile, config.BATCH_PERFECT_BONUS_XP)


# ------------------------------------------------------------ 3.2 amigos
def on_friend_added(db: Session, user_id: str) -> None:
    """+1 XP a cada marco de 5 amigos confirmados (5, 10, 15...), único
    por marco — remover amigo depois nunca devolve nem repete o marco."""
    profile = _profile(db, user_id)
    if profile is None:
        return
    total = len(get_friend_user_ids(db, user_id))
    for milestone in range(config.FRIEND_MILESTONE_EVERY, total + 1, config.FRIEND_MILESTONE_EVERY):
        if try_claim(db, user_id, f"friends:{milestone}"):
            db.commit()
            award_xp(db, profile, config.FRIEND_MILESTONE_XP)


# ------------------------------------------------ 3.1/3.3 social diário
def record_friend_interaction(db: Session, user_id: str, today: date) -> None:
    """Marca "interagi com um amigo hoje" (Torcida, Batalha ou convite de
    Movimento — decisão de Rhoney). 7 dias seguidos = +10 XP; depois de
    pago, só volta a pagar quando fechar OUTRA sequência completa de 7."""
    if not try_claim(db, user_id, f"friendact:{today.isoformat()}"):
        return
    db.commit()
    days = _days_back(today, config.FRIEND_INTERACTION_STREAK_DAYS)
    marked = db.execute(
        select(func.count())
        .select_from(models.RewardClaim)
        .where(
            models.RewardClaim.user_id == user_id,
            models.RewardClaim.claim_key.in_([f"friendact:{d.isoformat()}" for d in days]),
        )
    ).scalar_one()
    if marked < config.FRIEND_INTERACTION_STREAK_DAYS:
        return
    recently_paid = db.execute(
        select(func.count())
        .select_from(models.RewardClaim)
        .where(
            models.RewardClaim.user_id == user_id,
            models.RewardClaim.claim_key.in_([f"friendact7:{d.isoformat()}" for d in days[1:]]),
        )
    ).scalar_one()
    if recently_paid:
        return
    profile = _profile(db, user_id)
    if profile is not None and try_claim(db, user_id, f"friendact7:{today.isoformat()}"):
        db.commit()
        award_xp(db, profile, config.FRIEND_INTERACTION_STREAK_XP)


def on_torcida_sent(db: Session, from_user_id: str, to_user_id: str, today: date) -> None:
    """+1 XP por dia ao enviar Torcida a um AMIGO confirmado (Torcida está
    aberta a qualquer perfil — só amigo conta, senão vira farm)."""
    if to_user_id not in get_friend_user_ids(db, from_user_id):
        return
    record_friend_interaction(db, from_user_id, today)
    profile = _profile(db, from_user_id)
    if profile is not None and try_claim(db, from_user_id, f"torcida:{today.isoformat()}"):
        db.commit()
        award_xp(db, profile, config.TORCIDA_FRIEND_DAILY_XP)


def on_friend_action(db: Session, from_user_id: str, to_user_id: str, today: date) -> None:
    """Batalha ou convite de Movimento a amigo confirmado (conta só pra
    sequência social de 7 dias, sem XP próprio)."""
    if to_user_id in get_friend_user_ids(db, from_user_id):
        record_friend_interaction(db, from_user_id, today)


# ------------------------------------------------------------- 4.3 feedback
def on_feedback(db: Session, user_id: str, comment: str, today: date) -> None:
    """+5 XP por semana ISO, só com texto de tamanho mínimo."""
    if len(comment.strip()) < config.FEEDBACK_REWARD_MIN_CHARS:
        return
    profile = _profile(db, user_id)
    if profile is None:
        return
    iso = today.isocalendar()
    if try_claim(db, user_id, f"feedback:{iso.year}-W{iso.week:02d}"):
        db.commit()
        award_xp(db, profile, config.FEEDBACK_WEEKLY_XP)


# ----------------------------------------------------------- 2.2 Movimento
def on_movement_active_day(db: Session, user_id: str, cycle_day: date) -> None:
    """Chamado quando um ciclo cruza o piso de passos (dia ativo). 7 dias
    ativos seguidos = +10 MentalCoins; só volta a pagar numa sequência
    nova completa (mesma lógica da sequência social)."""
    if not try_claim(db, user_id, f"moveactive:{cycle_day.isoformat()}"):
        return
    db.commit()
    days = _days_back(cycle_day, config.MOVEMENT_ACTIVE_STREAK_DAYS)
    marked = db.execute(
        select(func.count())
        .select_from(models.RewardClaim)
        .where(
            models.RewardClaim.user_id == user_id,
            models.RewardClaim.claim_key.in_([f"moveactive:{d.isoformat()}" for d in days]),
        )
    ).scalar_one()
    if marked < config.MOVEMENT_ACTIVE_STREAK_DAYS:
        return
    recently_paid = db.execute(
        select(func.count())
        .select_from(models.RewardClaim)
        .where(
            models.RewardClaim.user_id == user_id,
            models.RewardClaim.claim_key.in_([f"move7:{d.isoformat()}" for d in days[1:]]),
        )
    ).scalar_one()
    if recently_paid:
        return
    if try_claim(db, user_id, f"move7:{cycle_day.isoformat()}"):
        db.commit()
        _award_coins(db, user_id, config.MOVEMENT_ACTIVE_STREAK_COINS, "movimento_7_dias_ativos")
