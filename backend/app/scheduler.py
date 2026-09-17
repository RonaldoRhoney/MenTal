"""
Agendador em background para as checagens de notificação (V2 item 8).
Só liga com config.NOTIFICATION_SCHEDULER_ENABLED=true (default false —
nunca roda em teste nem em dev casual). Reaproveita o processo do
backend já mantido acordado 24/7 via UptimeRobot — nenhum serviço novo
de cron precisa existir só para isto (custo zero com certeza, mesmo
raciocínio já aplicado ao restante da infraestrutura).
"""

import logging

from apscheduler.schedulers.background import BackgroundScheduler

from . import config, mentalcoins, notifications
from .db import SessionLocal

logger = logging.getLogger(__name__)

_scheduler: BackgroundScheduler | None = None


def _run_checks_job() -> None:
    with SessionLocal() as db:
        try:
            result = notifications.run_notification_checks(db)
            logger.info("Checagem de notificações concluída: %s", result)
        except Exception:
            # Uma falha aqui nunca pode derrubar o processo do backend —
            # é um job periódico em background, não uma requisição HTTP
            # com cliente esperando resposta.
            logger.exception("Falha na checagem periódica de notificações")


def _run_mentalcoins_job() -> None:
    with SessionLocal() as db:
        try:
            cycle_start, cycle_end = mentalcoins.closed_cycle_bounds()
            result = mentalcoins.run_weekly_apuration(db, cycle_start, cycle_end)
            logger.info("Apuração semanal de MentalCoins concluída: %s", result)
        except Exception:
            logger.exception("Falha na apuração semanal de MentalCoins")


def _run_movement_invite_job() -> None:
    with SessionLocal() as db:
        try:
            result = notifications.run_movement_activation_invite_check(db)
            logger.info("Convite diário de ativação de Movimento concluído: %s", result)
        except Exception:
            logger.exception("Falha no convite diário de ativação de Movimento")


def _run_notifications_purge_job() -> None:
    # Auditoria de segurança pré-lançamento mundial (17/09/2026, achado
    # A2): CENTRAL_DE_NOTIFICACOES_HOME_V1.md §3 promete retenção de 30
    # dias — antes disso só existia como filtro de leitura, nada
    # apagava de fato.
    from . import services

    with SessionLocal() as db:
        try:
            deleted = services.purge_old_notifications(db)
            logger.info("Limpeza de notificações além da retenção: %s linha(s) removida(s)", deleted)
        except Exception:
            logger.exception("Falha na limpeza diária de notificações")


def start_scheduler() -> None:
    global _scheduler
    if not config.NOTIFICATION_SCHEDULER_ENABLED and not config.MENTALCOINS_SCHEDULER_ENABLED:
        return
    if _scheduler is not None:
        return

    _scheduler = BackgroundScheduler()
    if config.NOTIFICATION_SCHEDULER_ENABLED:
        _scheduler.add_job(_run_checks_job, "interval", minutes=config.NOTIFICATION_CHECK_INTERVAL_MINUTES)
        logger.info("Agendador de notificações iniciado (a cada %s min)", config.NOTIFICATION_CHECK_INTERVAL_MINUTES)
        # Convite diário de Movimento (29/08/2026, pedido de Rhoney:
        # "todos os dias às 07:30") — cron dedicado, nunca o job de
        # intervalo acima (que rodaria isso a cada 30min o dia todo).
        _scheduler.add_job(
            _run_movement_invite_job, "cron", hour=7, minute=30, timezone=config.MENTALCOINS_TIMEZONE
        )
        logger.info("Agendador de convite de Movimento iniciado (diário 07:30 %s)", config.MENTALCOINS_TIMEZONE)
        # Limpeza de notificações além da retenção (achado A2) — horário
        # de baixo tráfego, mesmo fuso dos outros crons diários.
        _scheduler.add_job(
            _run_notifications_purge_job, "cron", hour=4, minute=0, timezone=config.MENTALCOINS_TIMEZONE
        )
        logger.info("Agendador de limpeza de notificações iniciado (diário 04:00 %s)", config.MENTALCOINS_TIMEZONE)
    if config.MENTALCOINS_SCHEDULER_ENABLED:
        # MentalCoins/MENTALCOINS_V1.md §2: fecha domingo 23:59:59, apura e
        # distribui na segunda-feira 08:00, horário de Brasília.
        _scheduler.add_job(
            _run_mentalcoins_job, "cron", day_of_week="mon", hour=8, minute=0, timezone=config.MENTALCOINS_TIMEZONE
        )
        logger.info("Agendador de MentalCoins iniciado (segundas 08:00 %s)", config.MENTALCOINS_TIMEZONE)
    _scheduler.start()
