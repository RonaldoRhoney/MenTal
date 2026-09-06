"""
Engenharia_Geral/BUG_PUSH_TORCIDA_E_LEMBRETES_NAO_CHEGAM.md — achado
real de produção (06/09/2026): logs confirmaram `UnregisteredError:
NotRegistered` do FCM (token salvo não existe mais do lado do Google).
Sem tratamento, o backend insistia pra sempre no mesmo token morto.
Estes testes provam que, ao detectar especificamente esse erro,
`profile.push_token` é limpo e commitado — não apenas registrado em
log e ignorado, como qualquer outra falha genérica de envio.
"""

import uuid

from firebase_admin import messaging

from app import models, push
from app.db import SessionLocal


def _make_profile(db, push_token: str) -> models.Profile:
    from app.services import get_or_create_profile

    user_id = str(uuid.uuid4())
    profile = get_or_create_profile(db, user_id)
    profile.push_token = push_token
    db.commit()
    return profile


def test_unregistered_token_is_cleared_and_committed(monkeypatch):
    monkeypatch.setattr(push, "_get_firebase_app", lambda: object())

    def _raise_unregistered(message):
        raise messaging.UnregisteredError("token not registered")

    monkeypatch.setattr(messaging, "send", _raise_unregistered)

    with SessionLocal() as db:
        profile = _make_profile(db, "dead-token")
        sent = push.send_push_notification(db, profile, "título", "corpo")
        assert sent is False
        assert profile.push_token is None

    # Persistiu de verdade (não só na instância em memória) — reabre
    # numa sessão nova e confirma que o commit aconteceu.
    with SessionLocal() as db:
        reloaded = db.get(models.Profile, profile.user_id)
        assert reloaded.push_token is None


def test_generic_send_failure_keeps_token_for_retry(monkeypatch):
    """Diferente do token morto: uma falha genérica (rede instável,
    erro transitório do FCM) não deve apagar o token — só o
    UnregisteredError, que é uma confirmação definitiva do Google de
    que aquele token nunca mais vai funcionar."""
    monkeypatch.setattr(push, "_get_firebase_app", lambda: object())

    def _raise_generic(message):
        raise RuntimeError("erro transitório qualquer")

    monkeypatch.setattr(messaging, "send", _raise_generic)

    with SessionLocal() as db:
        profile = _make_profile(db, "still-valid-token")
        sent = push.send_push_notification(db, profile, "título", "corpo")
        assert sent is False
        assert profile.push_token == "still-valid-token"


def test_no_push_token_returns_false_without_calling_firebase(monkeypatch):
    calls = []
    monkeypatch.setattr(push, "_get_firebase_app", lambda: calls.append(1))

    with SessionLocal() as db:
        profile = _make_profile(db, "")
        profile.push_token = None
        db.commit()
        assert push.send_push_notification(db, profile, "título", "corpo") is False
    assert calls == []  # nem chegou a tentar inicializar o Firebase
