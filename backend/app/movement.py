"""
V2 item 9 — Contador de passos & movimento (STEP_COUNTER_MOVIMENTO.md).

O sensor de passos (`TYPE_STEP_COUNTER`) vive no aparelho — o backend
nunca lê hardware, só recebe deltas que o cliente decide submeter via
POST /movement/collect. Mesmo assim o backend continua sendo autoridade
sobre XP: a conversão de passos em bônus (faixa escalonada,
config.MOVEMENT_STEP_TIERS) é calculada aqui, nunca no cliente, e o
teto por faixa (§4: "quem andar 19.000 recebe o mesmo múltiplo da faixa
mais alta") já limita sozinho o proveito de qualquer valor client-side
inflado — não precisa de anti-cheat adicional além do teto de sanidade
em MOVEMENT_MAX_STEPS_PER_COLLECTION.
"""

from datetime import datetime, timedelta

from sqlalchemy import select
from sqlalchemy.orm import Session

from . import config, mentalcoins, models, scoring, services
from .timeutil import naive, utcnow


class MovementError(Exception):
    def __init__(self, code: str, message: str):
        self.code = code
        self.message = message
        super().__init__(message)


def _bonus_for_steps(total_steps: int, fraction: float = 1.0) -> int:
    for threshold, multiplier in config.MOVEMENT_STEP_TIERS:
        if total_steps >= threshold * fraction:
            return config.MOVEMENT_XP_BASE * multiplier
    return 0


def _checkpoint_bonus(cycle: models.MovementCycle, now: datetime) -> tuple[int, int]:
    """
    Avalia os checkpoints intradiários já fechados (janela terminou, ou
    seja, `now` já passou do fim daquela fração do ciclo) e ainda não
    pagos. Retorna (xp extra total, quantidade de checkpoints pagos
    NESTA chamada) — chamado de dentro de collect_steps a cada coleta,
    nunca por um agendador: como o backend só sabe quantos passos
    existem quando o cliente efetivamente coleta, avaliar de forma
    preguiçosa (na próxima coleta depois do fechamento) é o único jeito
    consistente com a arquitetura "catch-up" já decidida para o sensor.
    A última parte (índice PARTS-1) nunca é avaliada aqui — ela coincide
    com o fim do próprio ciclo, já coberto pelo bônus de faixa cheio.
    """
    parts = config.MOVEMENT_CHECKPOINT_PARTS
    cycle_len = cycle.cycle_end_at - cycle.cycle_start_at
    xp_total = 0
    reached = 0
    for i in range(parts - 1):
        bit = 1 << i
        if cycle.checkpoint_bonus_mask & bit:
            continue
        window_end = cycle.cycle_start_at + cycle_len * (i + 1) / parts
        if now < window_end:
            continue
        fraction = (i + 1) / parts
        bonus = _bonus_for_steps(cycle.steps_collected, fraction)
        cycle.checkpoint_bonus_mask |= bit
        if bonus > 0:
            xp_total += bonus
            reached += 1
    return xp_total, reached


def enable_movement(db: Session, user_id: str, now: datetime | None = None) -> models.Profile:
    profile = services.get_or_create_profile(db, user_id)
    profile.movement_enabled = True
    if profile.movement_cycle_anchor_at is None:
        profile.movement_cycle_anchor_at = now or utcnow()
    db.commit()
    db.refresh(profile)
    return profile


def disable_movement(db: Session, user_id: str) -> models.Profile:
    profile = services.get_or_create_profile(db, user_id)
    profile.movement_enabled = False
    db.commit()
    db.refresh(profile)
    return profile


def set_daily_goal(db: Session, user_id: str, daily_goal_steps: int | None) -> models.Profile:
    profile = services.get_or_create_profile(db, user_id)
    profile.movement_daily_goal_steps = daily_goal_steps
    db.commit()
    db.refresh(profile)
    return profile


def _cycle_window_for(anchor: datetime, now: datetime) -> tuple[datetime, datetime]:
    anchor = naive(anchor)
    cycle_len = timedelta(hours=config.MOVEMENT_CYCLE_HOURS)
    elapsed = now - anchor
    cycles_elapsed = max(0, int(elapsed // cycle_len))
    cycle_start = anchor + cycles_elapsed * cycle_len
    return cycle_start, cycle_start + cycle_len


def _get_or_create_cycle_for_window(
    db: Session, user_id: str, cycle_start: datetime, cycle_end: datetime
) -> models.MovementCycle:
    cycle = db.execute(
        select(models.MovementCycle).where(
            models.MovementCycle.user_id == user_id,
            models.MovementCycle.cycle_start_at == cycle_start,
        )
    ).scalar_one_or_none()
    if cycle is None:
        cycle = models.MovementCycle(user_id=user_id, cycle_start_at=cycle_start, cycle_end_at=cycle_end)
        db.add(cycle)
        db.commit()
        db.refresh(cycle)
    return cycle


def get_current_cycle(db: Session, profile: models.Profile, now: datetime | None = None) -> models.MovementCycle:
    now = now or utcnow()
    cycle_start, cycle_end = _cycle_window_for(profile.movement_cycle_anchor_at, now)
    return _get_or_create_cycle_for_window(db, profile.user_id, cycle_start, cycle_end)


def get_pending_report_cycle(
    db: Session, profile: models.Profile, now: datetime | None = None
) -> models.MovementCycle | None:
    """
    Ciclo imediatamente anterior ao atual, se ainda estiver dentro da
    janela de graça (§2 — "antes do próximo ciclo avançar" interpretado
    como "antes do ciclo seguinte também fechar", dando tempo real de
    reagir ao relatório). Fora da graça, retorna None — os passos
    daquele ciclo estão perdidos, mesmo que nunca coletados.
    """
    now = now or utcnow()
    if profile.movement_cycle_anchor_at is None:
        return None
    current_start, _ = _cycle_window_for(profile.movement_cycle_anchor_at, now)
    previous_start = current_start - timedelta(hours=config.MOVEMENT_CYCLE_HOURS)
    if previous_start < naive(profile.movement_cycle_anchor_at):
        return None
    previous_end = previous_start + timedelta(hours=config.MOVEMENT_CYCLE_HOURS)
    grace_deadline = previous_end + timedelta(hours=config.MOVEMENT_COLLECTION_GRACE_HOURS)
    if now >= grace_deadline:
        return None
    return db.execute(
        select(models.MovementCycle).where(
            models.MovementCycle.user_id == profile.user_id,
            models.MovementCycle.cycle_start_at == previous_start,
        )
    ).scalar_one_or_none()


def collect_steps(
    db: Session,
    user_id: str,
    steps: int,
    cycle_id: str | None = None,
    now: datetime | None = None,
) -> tuple[models.MovementCycle, int, bool, int | None, bool, int, int]:
    """Retorna (ciclo, xp ganho nesta chamada, level_up, new_level, goal_reached, checkpoints_reached, mentalcoins_awarded)."""
    now = now or utcnow()
    profile = services.get_or_create_profile(db, user_id)
    if not profile.movement_enabled or profile.movement_cycle_anchor_at is None:
        raise MovementError("MOVEMENT_DISABLED", "Contador de passos não está ativado.")
    if steps < 0 or steps > config.MOVEMENT_MAX_STEPS_PER_COLLECTION:
        raise MovementError("INVALID_STEPS", "Quantidade de passos inválida.")

    if cycle_id is None:
        cycle = get_current_cycle(db, profile, now)
    else:
        cycle = db.get(models.MovementCycle, cycle_id)
        if cycle is None or cycle.user_id != user_id:
            raise MovementError("CYCLE_NOT_FOUND", "Ciclo de movimento não encontrado.")
        grace_deadline = naive(cycle.cycle_end_at) + timedelta(hours=config.MOVEMENT_COLLECTION_GRACE_HOURS)
        if now >= grace_deadline:
            raise MovementError("CYCLE_EXPIRED", "O prazo para coletar este ciclo já passou.")

    previous_bonus = _bonus_for_steps(cycle.steps_collected)
    previous_total = cycle.steps_collected
    # Achado real de produção (31/08/2026): teto por chamada acima não
    # impede que uma SEQUÊNCIA de deltas plausíveis-isoladamente infle o
    # ciclo sem limite (foi assim que um ciclo chegou a ~165.000 passos
    # em minutos via auto-coleta). Clampa no que falta pro teto do
    # ciclo, nunca rejeita — um valor único e absurdo numa só chamada
    # continua caindo normalmente na faixa máxima de XP (ver
    # MOVEMENT_MAX_STEPS_PER_CYCLE em config.py para o raciocínio).
    headroom = max(0, config.MOVEMENT_MAX_STEPS_PER_CYCLE - previous_total)
    cycle.steps_collected += min(steps, headroom)
    new_bonus = _bonus_for_steps(cycle.steps_collected)
    xp_delta = max(0, new_bonus - previous_bonus)

    # MentalCoins por passo (29/08/2026, pedido de Rhoney: "a cada 1000
    # passos = 5 MentalCoins") — por CICLO (mesma janela de 24h da faixa
    # de XP acima), calculado por marco cruzado (previous_total//1000 →
    # steps_collected//1000), não por "steps//1000" isolado — suporta
    # coletas pequenas e repetidas (auto-coleta) sem pagar de novo o
    # mesmo marco já cruzado numa chamada anterior.
    previous_milestones = previous_total // config.MOVEMENT_STEPS_PER_MENTALCOIN
    new_milestones = cycle.steps_collected // config.MOVEMENT_STEPS_PER_MENTALCOIN
    milestones_crossed = new_milestones - previous_milestones
    mentalcoins_awarded = 0
    if milestones_crossed > 0:
        mentalcoins_awarded = milestones_crossed * config.MOVEMENT_MENTALCOINS_PER_MILESTONE
        mentalcoins.credit(db, user_id, mentalcoins_awarded, "movement_steps_milestone")

    goal_reached = False
    goal = profile.movement_daily_goal_steps
    if goal and not cycle.goal_bonus_awarded and cycle.steps_collected >= goal:
        xp_delta += config.MOVEMENT_GOAL_BONUS_XP
        cycle.goal_bonus_awarded = True
        goal_reached = True

    checkpoint_xp, checkpoints_reached = _checkpoint_bonus(cycle, now)
    xp_delta += checkpoint_xp

    cycle.xp_awarded += xp_delta

    # Registra o total acumulado NESTE momento — histórico intradiário
    # real pro gráfico de progressão do dia (não deriva de checkpoint_
    # bonus_mask, que só sabe SE um bônus foi pago, não quantos passos
    # existiam em cada ponto do tempo).
    db.add(models.MovementSnapshot(cycle_id=cycle.id, recorded_at=now, steps_total=cycle.steps_collected))

    level_before = profile.level
    if xp_delta:
        profile.xp_total += xp_delta
        profile.level = scoring.level_from_xp(profile.xp_total)
    level_up = profile.level > level_before

    db.commit()
    db.refresh(cycle)
    return cycle, xp_delta, level_up, (profile.level if level_up else None), goal_reached, checkpoints_reached, mentalcoins_awarded


def get_recent_cycles(db: Session, user_id: str, limit: int = 7) -> list[models.MovementCycle]:
    """Últimos N ciclos (mais recente primeiro) — gráfico semanal de
    barras da tela Movimento. Inclui o ciclo em andamento se já existir
    (parcial, com o que já foi coletado até agora)."""
    return list(
        db.execute(
            select(models.MovementCycle)
            .where(models.MovementCycle.user_id == user_id)
            .order_by(models.MovementCycle.cycle_start_at.desc())
            .limit(limit)
        )
        .scalars()
        .all()
    )


def get_snapshots_for_cycle(db: Session, cycle_id: str) -> list[models.MovementSnapshot]:
    return list(
        db.execute(
            select(models.MovementSnapshot)
            .where(models.MovementSnapshot.cycle_id == cycle_id)
            .order_by(models.MovementSnapshot.recorded_at)
        )
        .scalars()
        .all()
    )
