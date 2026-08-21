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

from . import config, notifications
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


def start_scheduler() -> None:
    global _scheduler
    if not config.NOTIFICATION_SCHEDULER_ENABLED:
        return
    if _scheduler is not None:
        return

    _scheduler = BackgroundScheduler()
    _scheduler.add_job(_run_checks_job, "interval", minutes=config.NOTIFICATION_CHECK_INTERVAL_MINUTES)
    _scheduler.start()
    logger.info("Agendador de notificações iniciado (a cada %s min)", config.NOTIFICATION_CHECK_INTERVAL_MINUTES)
