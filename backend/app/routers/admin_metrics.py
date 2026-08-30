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

    return schemas.AdminMetricsSummaryOut(
        active_users_today=active_users_today,
        active_users_week=active_users_week,
        new_signups_in_period=new_signups,
        average_streak_active_users=round(average_streak or 0.0, 1),
        top_progressors=top_progressors,
        accuracy_by_territory=accuracy_by_territory,
        feedback_distribution=schemas.AdminFeedbackDistributionOut(
            facil=feedback_counts.get("facil", 0),
            medio=feedback_counts.get("medio", 0),
            dificil=feedback_counts.get("dificil", 0),
            muito_dificil=feedback_counts.get("muito_dificil", 0),
        ),
    )
