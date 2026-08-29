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
    if config.MENTALCOINS_SCHEDULER_ENABLED:
        # U.I/MENTALCOINS_V1.md §2: fecha domingo 23:59:59, apura e
        # distribui na segunda-feira 08:00, horário de Brasília.
        _scheduler.add_job(
            _run_mentalcoins_job, "cron", day_of_week="mon", hour=8, minute=0, timezone=config.MENTALCOINS_TIMEZONE
        )
        logger.info("Agendador de MentalCoins iniciado (segundas 08:00 %s)", config.MENTALCOINS_TIMEZONE)
    _scheduler.start()
