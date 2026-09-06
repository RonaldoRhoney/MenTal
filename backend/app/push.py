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

from sqlalchemy.orm import Session

from . import config, models

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


def send_push_notification(db: Session, profile: "models.Profile", title: str, body: str, data: dict[str, str] | None = None) -> bool:
    """
    Achado real de produção (06/09/2026, BUG_PUSH_TORCIDA_E_LEMBRETES_
    NAO_CHEGAM.md): logs confirmaram `UnregisteredError: NotRegistered`
    do FCM — o token salvo não existe mais do lado do Google (app
    desinstalado, dados limpos, token rotacionado sem novo registro).
    Sem tratamento, o backend insistia pra sempre no mesmo token morto,
    sem nunca entregar nada. Agora, ao detectar especificamente esse
    erro, `profile.push_token` é limpo e commitado aqui mesmo — a
    própria função recebe `db`/`profile` (não mais só a string do
    token) justamente pra poder fazer essa limpeza sem exigir que cada
    um dos ~9 pontos de chamada replique a mesma lógica. Da próxima vez
    que o dispositivo abrir o app, `PushService.initializeAndRegister()`
    (client) registra um token novo normalmente.

    `data` (05/09/2026, convite de Movimento): payload extra pro client
    decidir deep link ao tocar na notificação (ex.: {"navigate":
    "movement"}) — mesma chave já usada pelo sinal do foreground service
    de Movimento (main.dart::_onForegroundTaskData), reaproveitada aqui
    pra manter um único formato de "navegar pra X" em todo o app.
    """
    push_token = profile.push_token
    if not push_token:
        return False

    app = _get_firebase_app()
    if app is None:
        return False

    try:
        from firebase_admin import messaging

        message = messaging.Message(
            token=push_token,
            notification=messaging.Notification(title=title, body=body),
            data=data,
        )
        messaging.send(message)
        return True
    except messaging.UnregisteredError:
        logger.info("Token push não registrado mais no FCM (dispositivo desinstalou/limpou o app) — limpando push_token de %s.", profile.user_id)
        profile.push_token = None
        db.commit()
        return False
    except Exception:
        logger.exception("Falha ao enviar notificação push")
        return False
