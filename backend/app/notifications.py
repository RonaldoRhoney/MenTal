"""
V2 item 8 — Notificações (NOTIFICATIONS.md). Backend é a única
autoridade sobre QUANDO e SE notificar — client nunca decide isso, só
recebe e exibe (mesma regra de autoridade central já aplicada a XP/
score/desbloqueio em todo o projeto). run_notification_checks() é
chamado pelo agendador em background (app/scheduler.py, só ligado com
config.NOTIFICATION_SCHEDULER_ENABLED=true) e também diretamente pelos
testes, sem depender de esperar o agendador de verdade disparar.
"""

from datetime import datetime, timedelta

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from . import config, models, movement, notification_copy, push
from .timeutil import utcnow


def _check_reengagement(db: Session, now: datetime) -> int:
    """
    NOTIFICATIONS.md §2 — dois estágios (24h, 48h), no máximo uma
    notificação de reengajamento por janela de inatividade. Nunca
    dispara as duas na mesma checagem: se o jogador já está inativo há
    48h+, a mensagem mais calorosa (48h) prevalece sobre a leve (24h).
    """
    sent = 0
    profiles = (
        db.execute(
            select(models.Profile)
            .where(models.Profile.notif_reengagement_enabled.is_(True))
            .where(models.Profile.push_token.is_not(None))
            .where(models.Profile.last_seen_at.is_not(None))
        )
        .scalars()
        .all()
    )

    for profile in profiles:
        inactivity = now - profile.last_seen_at
        if inactivity >= timedelta(hours=48):
            target_window = "48h"
        elif inactivity >= timedelta(hours=24):
            target_window = "24h"
        else:
            continue

        if profile.last_reengagement_notified_window == target_window:
            continue  # já notificado nesta janela — nunca insiste (NOTIFICATIONS.md §2)

        if target_window == "24h":
            title = notification_copy.REENGAGEMENT_24H["title"]
            body = notification_copy.REENGAGEMENT_24H["body"]
        else:
            title = notification_copy.REENGAGEMENT_48H_TITLE
            body = notification_copy.REENGAGEMENT_48H_BODY_TEMPLATE.format(level=profile.level)

        if push.send_push_notification(profile.push_token, title, body):
            profile.last_reengagement_notified_window = target_window
            sent += 1

    db.commit()
    return sent


def _check_social_overtakes(db: Session, now: datetime) -> int:
    """
    NOTIFICATIONS.md §3 — dispara quando outro jogador ultrapassa a
    posição do usuário no ranking semanal. Reaproveita exatamente o
    mesmo cálculo de ranking já usado em GET /ranking
    (routers/ranking.py) — nunca duas fontes de verdade para "quem está
    em que posição". Anonimizado para child_safe_mode (§3: nunca citar
    nome de outro jogador para criança).
    """
    since = now - timedelta(days=7)
    rows = db.execute(
        select(models.Attempt.user_id, func.sum(models.Attempt.xp_awarded).label("xp"))
        .where(models.Attempt.created_at >= since)
        .where(models.Attempt.is_correct.is_(True))
        .group_by(models.Attempt.user_id)
        .order_by(func.sum(models.Attempt.xp_awarded).desc())
    ).all()

    sent = 0
    for idx, (user_id, _xp) in enumerate(rows, start=1):
        profile = db.get(models.Profile, user_id)
        if profile is None or not profile.notif_social_enabled or not profile.push_token:
            continue

        previous_rank = profile.last_known_weekly_rank
        # Só dispara numa piora de posição REAL (foi ultrapassado agora),
        # nunca no primeiro cálculo (previous_rank ainda None) — senão
        # todo mundo levaria uma notificação "ultrapassado" só por ainda
        # não ter um histórico de posição salvo.
        if previous_rank is not None and idx > previous_rank:
            if profile.child_safe_mode:
                title = notification_copy.SOCIAL_OVERTAKE_CHILD_SAFE_TITLE
                body = notification_copy.SOCIAL_OVERTAKE_CHILD_SAFE_BODY
            else:
                overtaker_index = previous_rank - 1  # 0-indexado: quem ocupa sua posição antiga agora
                overtaker_user_id = rows[overtaker_index][0] if overtaker_index < len(rows) else None
                overtaker_profile = db.get(models.Profile, overtaker_user_id) if overtaker_user_id else None
                nickname = overtaker_profile.nickname if overtaker_profile else "Alguém"
                title = notification_copy.SOCIAL_OVERTAKE_GENERIC_TITLE
                body = notification_copy.SOCIAL_OVERTAKE_NAMED_BODY_TEMPLATE.format(nickname=nickname)

            if push.send_push_notification(profile.push_token, title, body):
                sent += 1

        profile.last_known_weekly_rank = idx

    db.commit()
    return sent


def _check_movement_reports(db: Session, now: datetime) -> int:
    """
    V2 item 9 (STEP_COUNTER_MOVIMENTO.md §3) — dispara o relatório de fim
    de ciclo assim que as 24h do usuário se completam, mesmo que ele
    nunca tenha aberto o app durante o ciclo (o registro do ciclo é
    criado aqui pela primeira vez se ainda não existir). report_sent
    evita reenviar o mesmo relatório mais de uma vez, mesmo padrão de
    last_reengagement_notified_window.
    """
    sent = 0
    profiles = (
        db.execute(
            select(models.Profile)
            .where(models.Profile.movement_enabled.is_(True))
            .where(models.Profile.push_token.is_not(None))
            .where(models.Profile.movement_cycle_anchor_at.is_not(None))
        )
        .scalars()
        .all()
    )

    for profile in profiles:
        current_start, _ = movement._cycle_window_for(profile.movement_cycle_anchor_at, now)
        previous_start = current_start - timedelta(hours=config.MOVEMENT_CYCLE_HOURS)
        if previous_start < profile.movement_cycle_anchor_at:
            continue  # ainda não completou nenhum ciclo desde a ativação

        previous_end = previous_start + timedelta(hours=config.MOVEMENT_CYCLE_HOURS)
        cycle = movement._get_or_create_cycle_for_window(db, profile.user_id, previous_start, previous_end)
        if cycle.report_sent:
            continue

        title = notification_copy.MOVEMENT_CYCLE_REPORT_TITLE
        body = notification_copy.MOVEMENT_CYCLE_REPORT_BODY_TEMPLATE.format(steps=cycle.steps_collected)
        if push.send_push_notification(profile.push_token, title, body):
            cycle.report_sent = True
            sent += 1

    db.commit()
    return sent


def run_notification_checks(db: Session, now: datetime | None = None) -> dict:
    now = now or utcnow()
    reengagement_sent = _check_reengagement(db, now)
    social_sent = _check_social_overtakes(db, now)
    movement_sent = _check_movement_reports(db, now)
    return {"reengagement_sent": reengagement_sent, "social_sent": social_sent, "movement_sent": movement_sent}
