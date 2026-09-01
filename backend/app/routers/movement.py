from datetime import timezone

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from .. import movement, schemas, services
from ..auth import require_age_confirmed_user_id
from ..db import get_db
from ..timeutil import utcnow

router = APIRouter()


def _cycle_out(cycle, db: Session, *, with_snapshots: bool = False) -> schemas.MovementCycleOut:
    snapshots = movement.get_snapshots_for_cycle(db, cycle.id) if with_snapshots else []
    return schemas.MovementCycleOut(
        id=cycle.id,
        cycle_start_at=cycle.cycle_start_at,
        cycle_end_at=cycle.cycle_end_at,
        steps_collected=cycle.steps_collected,
        xp_awarded=cycle.xp_awarded,
        snapshots=[schemas.MovementSnapshotOut(recorded_at=s.recorded_at, steps_total=s.steps_total) for s in snapshots],
    )


@router.post("/movement/enable")
def enable_movement(user_id: str = Depends(require_age_confirmed_user_id), db: Session = Depends(get_db)):
    movement.enable_movement(db, user_id)
    return {"status": "ok"}


@router.post("/movement/disable")
def disable_movement(user_id: str = Depends(require_age_confirmed_user_id), db: Session = Depends(get_db)):
    movement.disable_movement(db, user_id)
    return {"status": "ok"}


@router.get("/movement/status", response_model=schemas.MovementStatusResponse)
def movement_status(user_id: str = Depends(require_age_confirmed_user_id), db: Session = Depends(get_db)):
    profile = services.get_or_create_profile(db, user_id)
    current_cycle = None
    if profile.movement_enabled and profile.movement_cycle_anchor_at is not None:
        current_cycle = movement.get_current_cycle(db, profile)
    pending_cycle = movement.get_pending_report_cycle(db, profile)
    recent_cycles = movement.get_recent_cycles(db, user_id) if profile.movement_enabled else []
    return schemas.MovementStatusResponse(
        movement_enabled=profile.movement_enabled,
        daily_goal_steps=profile.movement_daily_goal_steps,
        current_cycle=_cycle_out(current_cycle, db, with_snapshots=True) if current_cycle else None,
        pending_report_cycle=_cycle_out(pending_cycle, db) if pending_cycle else None,
        recent_cycles=[_cycle_out(c, db) for c in recent_cycles],
    )


@router.get("/movement/cycles/{cycle_id}", response_model=schemas.MovementCycleOut)
def get_movement_cycle(
    cycle_id: str,
    user_id: str = Depends(require_age_confirmed_user_id),
    db: Session = Depends(get_db),
):
    """MOVIMENTO_REFORMULACAO §11/§12 — detalhamento de um dia específico
    (card "Hoje ›" ou tocar um dia na tela "Semana"). Sempre com
    snapshots, diferente de recent_cycles em /movement/status."""
    cycle = movement.get_cycle_by_id(db, user_id, cycle_id)
    if cycle is None:
        raise HTTPException(status_code=404, detail={"error": {"code": "CYCLE_NOT_FOUND", "message": "Ciclo de movimento não encontrado."}})
    return _cycle_out(cycle, db, with_snapshots=True)


@router.get("/movement/yearly-summary", response_model=schemas.MovementYearlySummaryOut)
def get_movement_yearly_summary(
    year: int | None = None,
    user_id: str = Depends(require_age_confirmed_user_id),
    db: Session = Depends(get_db),
):
    """MOVIMENTO_REFORMULACAO §13 — card "Ano ›". "Ano atual" (§17) tem
    que respeitar Brasília, não UTC puro — achado de revisão: perto da
    virada do ano, UTC já pode estar em 1º de janeiro enquanto Brasília
    (UTC-3) ainda está em 31 de dezembro, e vice-versa."""
    target_year = year or utcnow().replace(tzinfo=timezone.utc).astimezone(movement.BRAZIL_TZ).year
    return schemas.MovementYearlySummaryOut(**movement.get_yearly_summary(db, user_id, target_year))


@router.put("/movement/goal", response_model=schemas.MovementGoalResponse)
def set_movement_goal(
    body: schemas.MovementGoalRequest,
    user_id: str = Depends(require_age_confirmed_user_id),
    db: Session = Depends(get_db),
):
    profile = movement.set_daily_goal(db, user_id, body.daily_goal_steps)
    return schemas.MovementGoalResponse(daily_goal_steps=profile.movement_daily_goal_steps)


@router.post("/movement/collect", response_model=schemas.MovementCollectResponse)
def collect_steps(
    body: schemas.MovementCollectRequest,
    user_id: str = Depends(require_age_confirmed_user_id),
    db: Session = Depends(get_db),
):
    try:
        cycle, xp_awarded, level_up, new_level, goal_reached, checkpoints_reached, mentalcoins_awarded = movement.collect_steps(
            db, user_id, body.steps, body.cycle_id
        )
    except movement.MovementError as e:
        raise HTTPException(status_code=400, detail={"error": {"code": e.code, "message": e.message}})
    # with_snapshots=False (achado real, 30/08/2026): o client só lê
    # cycle.steps_collected desta resposta (movement_screen.dart nunca
    # consome result['cycle']['snapshots']) — buscar o histórico
    # completo aqui era trabalho puro descartado, e ficava cada vez mais
    # lento à medida que o ciclo acumulava snapshots (coleta automática a
    # cada ~20s some rápido numa sessão longa), até estourar o timeout do
    # client em ciclos com muitos registros — exatamente o "sem conexão"
    # reportado ao tentar coletar o ciclo pendente.
    return schemas.MovementCollectResponse(
        cycle=_cycle_out(cycle, db, with_snapshots=False),
        xp_awarded=xp_awarded,
        level_up=level_up,
        new_level=new_level,
        goal_reached=goal_reached,
        checkpoints_reached=checkpoints_reached,
        mentalcoins_awarded=mentalcoins_awarded,
    )
