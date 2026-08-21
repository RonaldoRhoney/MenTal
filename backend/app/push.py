"""
Envio de push via Firebase Cloud Messaging — ZERO_COST confirmado
(skill zero-cost-api, 2026-08-21): plano Spark, sem cartão, sem taxa por
mensagem, sem limite de volume. Credencial vem de
config.FIREBASE_SERVICE_ACCOUNT_JSON (variável de ambiente, nunca
commitada) — enquanto o projeto Firebase do MENTAL não existir, esta
variável fica vazia e send_push_notification() só registra em log e
retorna False, sem quebrar nenhum fluxo que dependa dela.

Falha de push nunca pode derrubar o job agendado nem qualquer outro
fluxo do backend — mesmo princípio de zero-cost-api.md ("falha de fonte
externa nunca derruba o produto"): nenhuma exceção escapa desta função.
"""

import json
import logging

from . import config

logger = logging.getLogger(__name__)

_firebase_app = None
_firebase_init_attempted = False


def _get_firebase_app():
    global _firebase_app, _firebase_init_attempted
    if _firebase_app is not None:
        return _firebase_app
    if _firebase_init_attempted:
        return None
    _firebase_init_attempted = True

    if not config.FIREBASE_SERVICE_ACCOUNT_JSON:
        logger.info("FIREBASE_SERVICE_ACCOUNT_JSON não configurado — notificações push desativadas.")
        return None

    try:
        import firebase_admin
        from firebase_admin import credentials

        cred = credentials.Certificate(json.loads(config.FIREBASE_SERVICE_ACCOUNT_JSON))
        _firebase_app = firebase_admin.initialize_app(cred)
        return _firebase_app
    except Exception:
        logger.exception("Falha ao inicializar Firebase Admin SDK")
        return None


def send_push_notification(push_token: str, title: str, body: str) -> bool:
    app = _get_firebase_app()
    if app is None:
        return False

    try:
        from firebase_admin import messaging

        message = messaging.Message(
            token=push_token,
            notification=messaging.Notification(title=title, body=body),
        )
        messaging.send(message)
        return True
    except Exception:
        logger.exception("Falha ao enviar notificação push (token possivelmente inválido/expirado)")
        return False
