"""
REGRA_OFICIAL_GAMIFICACAO_MENTAL.md Fase 3 (20/09/2026, decisões de
Rhoney): teto diário de XP de resposta, reparo de streak e boost de XP.

Regras de desenho (mesmas da Fase 2 — só o SERVIDOR decide, nada vem do
client):
- Teto: só o XP de PERFIL de resposta (Desafio + Relâmpago) para em
  DAILY_ANSWER_XP_CAP; o progresso do território segue contando. A última
  resposta que passa do teto paga só o que falta. Bônus (lote, login,
  streak, mundo, Movimento, Constelação…) ficam fora do teto.
- Boost: +20% no XP de resposta (arredondado pra cima), calculado ANTES
  do teto — o teto vale sobre o valor final.
- Gasto de moeda: saldo travado com FOR UPDATE, débito + efeito + registro
  no mesmo commit (2 compras concorrentes não gastam o mesmo saldo).
O dia do TETO é o dia civil de Brasília (timeutil.brasilia_today, decisão de
Rhoney 20/09/2026); reparo de streak e o resto seguem o dia UTC já usado no app.
"""

from dataclasses import dataclass
from datetime import date, datetime, timedelta

from sqlalchemy.orm import Session

from . import config, mentalcoins, models, rewards
from .timeutil import naive, utcnow, week_anchor


@dataclass
class AnswerXp:
    profile_xp: int  # o que entra no XP de perfil (já com boost e teto)
    territory_xp: int  # o que entra no território (com boost, sem teto)
    boost_applied: bool
    cap_reached: bool


def active_boost_expiry(db: Session, user_id: str, now: datetime | None = None) -> datetime | None:
    boost = db.get(models.XpBoost, user_id)
    now = naive(now or utcnow())
    if boost is not None and naive(boost.expires_at) > now:
        return boost.expires_at
    return None


def daily_answer_xp_earned(db: Session, user_id: str, today: date) -> int:
    row = db.get(models.DailyAnswerXp, (user_id, today))
    return row.xp_earned if row else 0


def apply_answer_xp(db: Session, user_id: str, xp_raw: int, today: date, now: datetime | None = None) -> AnswerXp:
    """Chamar com o Profile já travado (FOR UPDATE). Grava o contador
    diário, mas NÃO faz commit — quem chama comita junto com o resto."""
    if xp_raw <= 0:
        return AnswerXp(0, 0, False, False)
    boost_applied = active_boost_expiry(db, user_id, now) is not None
    boosted = xp_raw
    if boost_applied:
        boosted = (xp_raw * (100 + config.XP_BOOST_PERCENT) + 99) // 100

    row = db.get(models.DailyAnswerXp, (user_id, today))
    if row is None:
        row = models.DailyAnswerXp(user_id=user_id, xp_date=today, xp_earned=0)
        db.add(row)
    remaining = max(0, config.DAILY_ANSWER_XP_CAP - row.xp_earned)
    profile_xp = min(boosted, remaining)
    row.xp_earned += profile_xp
    return AnswerXp(profile_xp, boosted, boost_applied, profile_xp < boosted)


# --- gasto de MentalCoins ------------------------------------------------


def _spend_coins(db: Session, user_id: str, cost: int, reason: str) -> None:
    """Debita `cost` com o saldo travado. Sem commit (quem chama comita
    junto com o efeito da compra)."""
    balance = mentalcoins.get_or_create_balance(db, user_id)
    db.refresh(balance, with_for_update=True)
    if balance.balance < cost:
        raise mentalcoins.MentalCoinsError("INSUFFICIENT_BALANCE", "Saldo insuficiente")
    balance.balance -= cost
    balance.updated_at = utcnow()
    db.add(models.MentalCoinsTransaction(user_id=user_id, amount=-cost, reason=reason))


def buy_xp_boost(db: Session, user_id: str) -> datetime:
    now = utcnow()
    if active_boost_expiry(db, user_id, now) is not None:
        raise mentalcoins.MentalCoinsError("BOOST_ALREADY_ACTIVE", "Você já tem um boost de XP ativo")
    _spend_coins(db, user_id, config.XP_BOOST_COST, "Boost de XP (+20% por 24h)")
    expires_at = now + timedelta(hours=config.XP_BOOST_HOURS)
    boost = db.get(models.XpBoost, user_id)
    if boost is None:
        db.add(models.XpBoost(user_id=user_id, expires_at=expires_at))
    else:
        boost.expires_at = expires_at
    db.commit()
    return expires_at


# --- reparo de streak ----------------------------------------------------


MODE_BEFORE_PLAY = "before_play"
MODE_AFTER_PLAY = "after_play"


@dataclass
class RepairOffer:
    streak_to_restore: int
    expires_on: date
    mode: str  # MODE_BEFORE_PLAY (ainda não jogou hoje) | MODE_AFTER_PLAY (já recomeçou)


def _freeze_available(streak: models.Streak, today: date) -> bool:
    if streak.week_anchor != week_anchor(today):
        return True  # semana nova: a folga volta a valer na próxima jogada
    return bool(streak.freeze_available and not streak.freeze_used_this_week)


def streak_repair_offer(streak: models.Streak, today: date) -> RepairOffer | None:
    # Já recomeçou (jogou depois de quebrar) e ainda está na janela.
    if streak.lost_streak and streak.repair_until and today <= streak.repair_until:
        return RepairOffer(streak.lost_streak, streak.repair_until, MODE_AFTER_PLAY)
    # Ainda não jogou: a sequência só "quebra" de fato na próxima jogada.
    last = streak.last_played_date
    if last is None or streak.current_streak < config.STREAK_REPAIR_MIN_STREAK:
        return None
    gap = (today - last).days
    if gap < 2 or gap > config.STREAK_REPAIR_WINDOW_DAYS:
        return None
    if gap == 2 and _freeze_available(streak, today):
        return None  # a folga semanal grátis já cobre — é só jogar
    return RepairOffer(streak.current_streak, last + timedelta(days=config.STREAK_REPAIR_WINDOW_DAYS), MODE_BEFORE_PLAY)


def repair_streak(db: Session, user_id: str, today: date) -> tuple[models.Streak, str]:
    """Devolve (sequência, modo) — o modo diz se o efeito já aparece agora."""
    streak = db.get(models.Streak, user_id)
    if streak is None:
        raise mentalcoins.MentalCoinsError("NOTHING_TO_REPAIR", "Não há sequência para reparar")
    db.refresh(streak, with_for_update=True)  # dois toques não reparam duas vezes
    offer = streak_repair_offer(streak, today)
    if offer is None:
        raise mentalcoins.MentalCoinsError("NOTHING_TO_REPAIR", "Não há sequência para reparar")
    _spend_coins(db, user_id, config.STREAK_REPAIR_COST, f"Reparo de sequência ({offer.streak_to_restore} dias)")
    lost = offer.streak_to_restore
    if offer.mode == MODE_AFTER_PLAY:
        streak.current_streak = lost + streak.current_streak
        streak.lost_streak = None
        streak.repair_until = None
    else:
        # Perdoa os dias sem jogar: a próxima jogada (hoje) estende a sequência.
        streak.last_played_date = today - timedelta(days=1)
    db.commit()
    db.refresh(streak)
    if offer.mode == MODE_AFTER_PLAY:
        # Achado M2 (revisão de segurança, 20/09/2026): o reparo não passa
        # por register_play_for_streak, então o marco (ex.: 30 dias) que a
        # sequência restaurada alcança precisa ser pago aqui — só os marcos
        # ACIMA da sequência perdida (os de antes já foram pagos na época).
        profile = db.get(models.Profile, user_id)
        if profile is not None:
            for reached in range(lost + 1, streak.current_streak + 1):
                rewards.safely(rewards.on_streak_extended, db, profile, reached, today)
    return streak, offer.mode
