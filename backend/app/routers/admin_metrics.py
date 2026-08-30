"""
U.I/ADMIN_PAINEL_IN_APP_V1.md — painel administrativo leve, dentro do
próprio app Flutter, visível só pra role=admin (mesma checagem já usada
em /admin/profile-photos, /admin/reports etc.). Somente leitura — nunca
edita dado de jogador (mesma regra do painel externo, ADMIN_DASHBOARD_
V1.md §7).

Endpoint único (GET /admin/metrics/summary) em vez de um por métrica —
a versão leve pede poucos números pra uma tela só, então uma resposta
combinada evita 6 chamadas de rede seguidas pra montar a mesma tela.
"""

from datetime import timedelta

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import Integer, func, select
from sqlalchemy.orm import Session

from .. import models, schemas, services
from ..auth import require_age_confirmed_user_id
from ..db import get_db
from ..timeutil import naive, utcnow

router = APIRouter()

_PERIOD_DAYS = {"today": 1, "7d": 7, "30d": 30}


def _require_admin(db: Session, user_id: str) -> None:
    profile = db.get(models.Profile, user_id)
    if profile is None or profile.role != "admin":
        raise HTTPException(status_code=403, detail={"error": {"code": "ADMIN_ONLY", "message": "Requires admin role"}})


@router.get("/admin/metrics/summary", response_model=schemas.AdminMetricsSummaryOut)
def get_metrics_summary(
    period: str = "7d",
    user_id: str = Depends(require_age_confirmed_user_id),
    db: Session = Depends(get_db),
):
    _require_admin(db, user_id)
    if period not in _PERIOD_DAYS:
        raise HTTPException(status_code=422, detail={"error": {"code": "INVALID_PERIOD", "message": "period precisa ser 'today', '7d' ou '30d'"}})

    now = utcnow()
    today_start = naive(now).replace(hour=0, minute=0, second=0, microsecond=0)
    week_start = naive(now) - timedelta(days=7)
    period_start = naive(now) - timedelta(days=_PERIOD_DAYS[period])

    # Camada 1 — cards fixos (independem do seletor de período, mesma
    # semântica dos rótulos "hoje"/"semana" no doc, §3).
    active_users_today = db.execute(
        select(func.count(func.distinct(models.Profile.user_id))).where(models.Profile.last_seen_at >= today_start)
    ).scalar_one()
    active_users_week = db.execute(
        select(func.count(func.distinct(models.Profile.user_id))).where(models.Profile.last_seen_at >= week_start)
    ).scalar_one()
    average_streak = db.execute(
        select(func.avg(models.Streak.current_streak))
        .join(models.Profile, models.Profile.user_id == models.Streak.user_id)
        .where(models.Profile.last_seen_at >= week_start)
    ).scalar_one()

    # Camada 2 — escopadas pelo período selecionado.
    new_signups = db.execute(
        select(func.count(models.Profile.user_id)).where(models.Profile.created_at >= period_start)
    ).scalar_one()

    # "Quantos entraram e fizeram alguma ação" — proxy direto: usuário
    # distinto com pelo menos uma resposta registrada (Attempt) dentro do
    # período selecionado. Diferente de active_users_* (baseado em
    # last_seen_at, que marca só ter aberto o app) — este conta ação real.
    engaged_users_in_period = db.execute(
        select(func.count(func.distinct(models.Attempt.user_id))).where(models.Attempt.created_at >= period_start)
    ).scalar_one()

    xp_gained_rows = (
        db.execute(
            select(models.Attempt.user_id, func.sum(models.Attempt.xp_awarded).label("xp_gained"))
            .where(models.Attempt.created_at >= period_start)
            .where(models.Attempt.xp_awarded > 0)
            .group_by(models.Attempt.user_id)
            .order_by(func.sum(models.Attempt.xp_awarded).desc())
            .limit(5)
        )
        .all()
    )
    top_progressors = []
    for row_user_id, xp_gained in xp_gained_rows:
        profile = db.get(models.Profile, row_user_id)
        if profile is None:
            continue
        streak = db.get(models.Streak, row_user_id)
        top_progressors.append(
            schemas.AdminTopProgressorOut(
                user_id=row_user_id,
                nickname=profile.nickname,
                real_name=profile.real_name,
                photo_url=services.public_photo_url(profile),
                level=profile.level,
                xp_gained=xp_gained,
                current_streak=streak.current_streak if streak else 0,
            )
        )

    accuracy_rows = db.execute(
        select(
            models.Challenge.territory_id,
            func.count(models.Attempt.attempt_id),
            func.sum(func.cast(models.Attempt.is_correct, Integer)),
        )
        .join(models.Challenge, models.Challenge.id == models.Attempt.challenge_id)
        .where(models.Attempt.created_at >= period_start)
        .where(models.Attempt.is_correct.is_not(None))
        .group_by(models.Challenge.territory_id)
    ).all()
    accuracy_by_territory = [
        schemas.AdminTerritoryAccuracyOut(
            territory_id=territory_id,
            total_attempts=total,
            accuracy_percent=round((correct or 0) * 100 / total, 1) if total else 0.0,
        )
        for territory_id, total, correct in accuracy_rows
    ]
    accuracy_by_territory.sort(key=lambda t: t.territory_id)

    feedback_rows = db.execute(
        select(models.LevelFeedback.difficulty_rating, func.count(models.LevelFeedback.id))
        .where(models.LevelFeedback.created_at >= period_start)
        .group_by(models.LevelFeedback.difficulty_rating)
    ).all()
    feedback_counts = {rating: count for rating, count in feedback_rows}

    def _distribution(column, limit: int | None = None) -> list[schemas.AdminDemographicBucketOut]:
        query = (
            select(column, func.count(models.Profile.user_id))
            .where(column.is_not(None))
            .group_by(column)
            .order_by(func.count(models.Profile.user_id).desc())
        )
        if limit is not None:
            query = query.limit(limit)
        rows = db.execute(query).all()
        return [schemas.AdminDemographicBucketOut(label=label, count=count) for label, count in rows]

    demographics = schemas.AdminDemographicsOut(
        gender=_distribution(models.Profile.gender),
        age_range=_distribution(models.Profile.age_range),
        state=_distribution(models.Profile.location_state, limit=10),
        city=_distribution(models.Profile.city, limit=10),
    )

    movement_enabled_users = db.execute(
        select(func.count(models.Profile.user_id)).where(models.Profile.movement_enabled.is_(True))
    ).scalar_one()

    movement_cycles_in_period = db.execute(
        select(models.MovementCycle.user_id, models.MovementCycle.steps_collected, models.MovementCycle.xp_awarded)
        .where(models.MovementCycle.cycle_start_at >= period_start)
        .where(models.MovementCycle.steps_collected > 0)
    ).all()
    movement_active_users = {row[0] for row in movement_cycles_in_period}
    movement_total_steps = sum(row[1] for row in movement_cycles_in_period)
    movement_total_xp = sum(row[2] for row in movement_cycles_in_period)
    movement_average_steps = round(movement_total_steps / len(movement_active_users)) if movement_active_users else 0

    # Metas fixas (5k/10k/15k) viram bucket próprio; qualquer outro
    # valor é meta personalizada (U.I/MOVIMENTO_REDESIGN_V1.md §3, "o
    # último card deve ser editável") — agrupado sob um único rótulo pra
    # não espalhar a distribuição em dezenas de buckets de 1 usuário.
    goal_rows = db.execute(
        select(models.Profile.movement_daily_goal_steps, func.count(models.Profile.user_id))
        .where(models.Profile.movement_daily_goal_steps.is_not(None))
        .group_by(models.Profile.movement_daily_goal_steps)
    ).all()
    fixed_tier_labels = {5000: "5.000 (leve)", 10000: "10.000 (padrão)", 15000: "15.000 (intenso)"}
    goal_counts: dict[str, int] = {}
    for goal_steps, count in goal_rows:
        label = fixed_tier_labels.get(goal_steps, "Personalizada")
        goal_counts[label] = goal_counts.get(label, 0) + count
    goal_distribution = sorted(
        (schemas.AdminDemographicBucketOut(label=label, count=count) for label, count in goal_counts.items()),
        key=lambda b: b.count,
        reverse=True,
    )

    movement = schemas.AdminMovementMetricsOut(
        enabled_users=movement_enabled_users,
        active_users_in_period=len(movement_active_users),
        total_steps_in_period=movement_total_steps,
        total_xp_in_period=movement_total_xp,
        average_steps_per_active_user=movement_average_steps,
        goal_distribution=goal_distribution,
    )

    return schemas.AdminMetricsSummaryOut(
        active_users_today=active_users_today,
        active_users_week=active_users_week,
        new_signups_in_period=new_signups,
        engaged_users_in_period=engaged_users_in_period,
        average_streak_active_users=round(average_streak or 0.0, 1),
        top_progressors=top_progressors,
        accuracy_by_territory=accuracy_by_territory,
        feedback_distribution=schemas.AdminFeedbackDistributionOut(
            facil=feedback_counts.get("facil", 0),
            medio=feedback_counts.get("medio", 0),
            dificil=feedback_counts.get("dificil", 0),
            muito_dificil=feedback_counts.get("muito_dificil", 0),
        ),
        demographics=demographics,
        movement=movement,
    )
