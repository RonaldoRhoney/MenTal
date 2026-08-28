from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from .. import movement, schemas, services
from ..auth import require_age_confirmed_user_id
from ..db import get_db

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
        cycle, xp_awarded, level_up, new_level, goal_reached, checkpoints_reached = movement.collect_steps(
            db, user_id, body.steps, body.cycle_id
        )
    except movement.MovementError as e:
        raise HTTPException(status_code=400, detail={"error": {"code": e.code, "message": e.message}})
    return schemas.MovementCollectResponse(
        cycle=_cycle_out(cycle, db, with_snapshots=True),
        xp_awarded=xp_awarded,
        level_up=level_up,
        new_level=new_level,
        goal_reached=goal_reached,
        checkpoints_reached=checkpoints_reached,
    )
